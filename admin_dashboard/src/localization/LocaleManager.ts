import { initializeApp, getApps } from "firebase/app";
import { getAuth } from "firebase/auth";
import { getFirestore, doc, updateDoc, setDoc } from "firebase/firestore";

const firebaseConfig = {
  apiKey: process.env.NEXT_PUBLIC_FIREBASE_API_KEY,
  authDomain: process.env.NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN,
  projectId: process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID,
  storageBucket: process.env.NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET,
  messagingSenderId: process.env.NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID,
  appId: process.env.NEXT_PUBLIC_FIREBASE_APP_ID
};

// Initialize Firebase if not already initialized
const app = getApps().length === 0 ? initializeApp(firebaseConfig) : getApps()[0];
const auth = getAuth(app);
const db = getFirestore(app);

export class LocaleManager {
  private static CACHE_KEY = "preferred_language";

  static getCachedLocale(): string {
    if (typeof window !== "undefined") {
      return localStorage.getItem(this.CACHE_KEY) || "en";
    }
    return "en";
  }

  static cacheLocale(locale: string) {
    if (typeof window !== "undefined") {
      localStorage.setItem(this.CACHE_KEY, locale);
    }
  }

  static async syncLocaleToFirebase(locale: string): Promise<void> {
    const user = auth.currentUser;
    if (!user) return;

    const userRef = doc(db, "users", user.uid);
    const data = {
      preferred_language: locale,
      language_updated_at: Date.now(),
      language_source: "web"
    };

    try {
      await updateDoc(userRef, data);
    } catch (e) {
      // Document might not exist, merge instead
      await setDoc(userRef, data, { merge: true });
    }
  }

  // Locales formatter utility
  static formatCurrency(amount: number, locale: string = "en-IN", currency: string = "INR"): string {
    return new Intl.NumberFormat(locale, {
      style: "currency",
      currency: currency
    }).format(amount);
  }

  static formatDate(date: Date, locale: string = "en-IN", options?: Intl.DateTimeFormatOptions): string {
    const defaultOptions: Intl.DateTimeFormatOptions = options || {
      year: 'numeric',
      month: 'long',
      day: 'numeric'
    };
    return new Intl.DateTimeFormat(locale, defaultOptions).format(date);
  }

  static formatNumber(value: number, locale: string = "en-IN"): string {
    return new Intl.NumberFormat(locale).format(value);
  }
}
