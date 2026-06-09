import { createClient } from '@supabase/supabase-js';

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL || 'https://eswjtunzibrhimcpcnss.supabase.co';
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVzd2p0dW56aWJyaGltY3BjbnNzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODAyMTQ2MjgsImV4cCI6MjA5NTc5MDYyOH0.eojuoOsB5ne9pBIH1GRBKZSBcy7dX3ec4nsCaw-2ew0';

if (supabaseUrl.includes('placeholder')) {
  console.warn(
    '⚠️ Next.js Web Admin Dashboard is running on PLACEHOLDER credentials. Please configure NEXT_PUBLIC_SUPABASE_URL and NEXT_PUBLIC_SUPABASE_ANON_KEY env variables.'
  );
}

export const supabase = createClient(supabaseUrl, supabaseAnonKey, {
  auth: {
    persistSession: true,
    autoRefreshToken: true,
  },
});
