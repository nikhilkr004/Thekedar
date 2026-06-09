import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.8";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") || "";
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") || "";
const FIREBASE_SERVICE_ACCOUNT = Deno.env.get("FIREBASE_SERVICE_ACCOUNT_KEY") || "";
const WEBHOOK_SECRET_KEY = Deno.env.get("WEBHOOK_SECRET_KEY") || "super-secret-notification-token-2026";

Deno.serve(async (req) => {
  try {
    // 1. Auth check
    const authHeader = req.headers.get("X-Webhook-Secret");
    if (!authHeader || authHeader !== WEBHOOK_SECRET_KEY) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { "Content-Type": "application/json" },
      });
    }

    // 2. Parse input payload
    const { recipient_id, notification_id, user_id } = await req.json();
    if (!recipient_id || !notification_id || !user_id) {
      return new Response(JSON.stringify({ error: "Missing payload params" }), {
        status: 400,
        headers: { "Content-Type": "application/json" },
      });
    }

    // Initialize Supabase Client
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    // 3. Fetch Notification Metadata
    const { data: notification, error: notifError } = await supabase
      .from("notifications")
      .select("*")
      .eq("id", notification_id)
      .single();

    if (notifError || !notification) {
      console.error("Error fetching notification details:", notifError);
      return new Response(JSON.stringify({ error: "Notification not found" }), {
        status: 404,
        headers: { "Content-Type": "application/json" },
      });
    }

    // 4. Fetch user's active device tokens
    const { data: devices, error: deviceError } = await supabase
      .from("user_devices")
      .select("fcm_token, platform")
      .eq("user_id", user_id)
      .eq("is_active", true);

    if (deviceError || !devices || devices.length === 0) {
      console.log(`No active device tokens found for user: ${user_id}`);
      return new Response(JSON.stringify({ message: "No active devices to notify" }), {
        status: 200,
        headers: { "Content-Type": "application/json" },
      });
    }

    // 5. Send FCM Push Notification
    let fcmConfig: any = null;
    if (FIREBASE_SERVICE_ACCOUNT) {
      try {
        fcmConfig = JSON.parse(FIREBASE_SERVICE_ACCOUNT);
      } catch (err) {
        console.error("Error parsing Firebase Service Account JSON secret:", err);
      }
    }

    // Fallback: Query from app_configurations table in database
    if (!fcmConfig) {
      const { data: configData, error: configError } = await supabase
        .from("app_configurations")
        .select("value")
        .eq("key", "firebase_service_account_key")
        .maybeSingle();

      if (!configError && configData?.value) {
        try {
          fcmConfig = JSON.parse(configData.value);
        } catch (err) {
          console.error("Error parsing Firebase Service Account JSON from app_configurations:", err);
        }
      }
    }

    if (!fcmConfig) {
      console.warn("FCM credentials missing from both env and app_configurations. Simulating delivery.");
      // Update delivery logs
      await supabase
        .from("notification_recipients")
        .update({ delivered_at: new Date().toISOString() })
        .eq("id", recipient_id);

      return new Response(
        JSON.stringify({ message: "Simulated notification delivery (no FCM credentials set)" }),
        { status: 200, headers: { "Content-Type": "application/json" } }
      );
    }

    // Generate Google OAuth2 Token
    const oauthToken = await getGoogleOAuth2Token(fcmConfig);
    const projectId = fcmConfig.project_id;
    const fcmEndpoint = `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`;

    let successCount = 0;
    let failCount = 0;

    for (const device of devices) {
      try {
        const payload = {
          message: {
            token: device.fcm_token,
            notification: {
              title: notification.title,
              body: notification.message,
            },
            data: {
              notification_id: notification.id,
              recipient_id: recipient_id,
              type: notification.notification_type,
              priority: notification.priority,
              click_action: "/notifications",
            },
            android: {
              priority: notification.priority === "high" || notification.priority === "critical" ? "high" : "normal",
              notification: {
                sound: "default",
                channel_id: "high_importance_channel",
              },
            },
            apns: {
              payload: {
                aps: {
                  sound: "default",
                  badge: 1,
                },
              },
            },
          },
        };

        const fcmResponse = await fetch(fcmEndpoint, {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            Authorization: `Bearer ${oauthToken}`,
          },
          body: JSON.stringify(payload),
        });

        if (fcmResponse.ok) {
          successCount++;
        } else {
          const errText = await fcmResponse.text();
          console.error(`FCM send error response for token ${device.fcm_token}:`, errText);
          failCount++;
        }
      } catch (fcmErr) {
        console.error("FCM dispatch exception:", fcmErr);
        failCount++;
      }
    }

    // 6. Update Delivery Status on success
    if (successCount > 0) {
      await supabase
        .from("notification_recipients")
        .update({ delivered_at: new Date().toISOString() })
        .eq("id", recipient_id);
    }

    return new Response(
      JSON.stringify({
        success: true,
        sent: successCount,
        failed: failCount,
      }),
      { status: 200, headers: { "Content-Type": "application/json" } }
    );
  } catch (err: any) {
    console.error("Critical edge function error:", err);
    return new Response(JSON.stringify({ error: err.message }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});

// Helper: base64url encoding
function base64url(arr: Uint8Array): string {
  const binString = Array.from(arr, (x) => String.fromCharCode(x)).join("");
  return btoa(binString)
    .replace(/=/g, "")
    .replace(/\+/g, "-")
    .replace(/\//g, "_");
}

// Helper: JWT Signer via Web Crypto API for Google OAuth2
async function getGoogleOAuth2Token(serviceAccount: any): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  
  const header = { alg: "RS256", typ: "JWT" };
  const claims = {
    iss: serviceAccount.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    exp: now + 3600,
    iat: now,
  };

  const textEncoder = new TextEncoder();
  const headerEncoded = base64url(textEncoder.encode(JSON.stringify(header)));
  const claimsEncoded = base64url(textEncoder.encode(JSON.stringify(claims)));
  
  const tokenInput = `${headerEncoded}.${claimsEncoded}`;

  // Parse Private Key PKCS#8 format
  const pemContents = serviceAccount.private_key
    .replace(/-----BEGIN PRIVATE KEY-----/, "")
    .replace(/-----END PRIVATE KEY-----/, "")
    .replace(/\\n/g, "")
    .replace(/\n/g, "")
    .replace(/\s/g, "");
  
  const binaryDer = Uint8Array.from(atob(pemContents), (c) => c.charCodeAt(0));
  
  const privateKey = await crypto.subtle.importKey(
    "pkcs8",
    binaryDer,
    {
      name: "RSASSA-PKCS1-v1_5",
      hash: "SHA-256",
    },
    false,
    ["sign"]
  );

  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    privateKey,
    textEncoder.encode(tokenInput)
  );

  const signatureEncoded = base64url(new Uint8Array(signature));
  const jwt = `${tokenInput}.${signatureEncoded}`;

  // Exchange JWT for Access Token
  const tokenResponse = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
  });

  if (!tokenResponse.ok) {
    const errorText = await tokenResponse.text();
    throw new Error(`Google OAuth token exchange failed: ${errorText}`);
  }

  const tokenData = await tokenResponse.json();
  return tokenData.access_token;
}
