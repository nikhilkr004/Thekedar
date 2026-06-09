'use client';

import { useAdminStore } from '@/core/store';
import Sidebar from './Sidebar';
import Header from './Header';
import { useState, useEffect } from 'react';
import { supabase } from '@/core/supabase';
import { 
  ShieldAlert, Lock, Mail, User, ShieldCheck, Loader2
} from 'lucide-react';

export default function LayoutWrapper({ children }: { children: React.ReactNode }) {
  const { isAuthenticated, login, logout } = useAdminStore();
  const [mounted, setMounted] = useState(false);

  // UI state
  const [isLoading, setIsLoading] = useState(false);
  const [authError, setAuthError] = useState('');
  
  // Login form inputs
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');

  useEffect(() => {
    setMounted(true);

    // Subscribe to Supabase Session Changes
    const { data: { subscription } } = supabase.auth.onAuthStateChange(async (event, session) => {
      if (session?.user) {
        setIsLoading(true);
        setAuthError('');
        try {
          const userEmail = session.user.email;
          const userFullName = session.user.user_metadata?.full_name || session.user.user_metadata?.name || 'Admin Operator';

          // Query the admin_users whitelist table
          const { data: adminRecord, error: adminError } = await supabase
            .from('admin_users')
            .select('role, full_name')
            .eq('email', userEmail)
            .maybeSingle();

          if (adminError) throw adminError;

          if (adminRecord) {
            // Whitelisted admin - grant entry
            login({
              id: session.user.id,
              email: userEmail || '',
              fullName: adminRecord.full_name || userFullName,
              role: adminRecord.role as any,
            });
          } else {
            // Non-whitelisted email - deny access & logout from Supabase session
            await supabase.auth.signOut();
            setAuthError(`Access Denied: ${userEmail} is not whitelisted in the admin database.`);
            logout();
          }
        } catch (err) {
          console.error('Auth verification exception:', err);
          setAuthError('An error occurred verifying your administrator privileges.');
          logout();
        } finally {
          setIsLoading(false);
        }
      } else {
        if (event === 'SIGNED_OUT') {
          logout();
        }
      }
    });

    return () => {
      subscription.unsubscribe();
    };
  }, [login, logout]);

  // Handle Supabase Email & Password Sign-in
  const handleLoginSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!email || !password) {
      setAuthError('Please enter both your email and password.');
      return;
    }
    setIsLoading(true);
    setAuthError('');
    try {
      const { error } = await supabase.auth.signInWithPassword({
        email,
        password,
      });
      if (error) throw error;
      // onAuthStateChange will handle whitelist verification
    } catch (err: any) {
      console.error('Login error:', err);
      setAuthError(err.message || 'Authentication failed. Please verify your email and password.');
      setIsLoading(false);
    }
  };

  if (!mounted) {
    return (
      <div className="min-h-screen bg-slate-950 flex items-center justify-center">
        <Loader2 className="w-10 h-10 text-sky-500 animate-spin" />
      </div>
    );
  }

  // Render Login Panel if not authenticated
  if (!isAuthenticated) {
    return (
      <div className="min-h-screen bg-slate-950 flex items-center justify-center p-4 relative overflow-hidden">
        {/* Modern Gradient Background Mesh */}
        <div className="absolute top-[-20%] left-[-20%] w-[60%] h-[60%] bg-sky-500/10 rounded-full blur-[120px] pointer-events-none"></div>
        <div className="absolute bottom-[-20%] right-[-20%] w-[60%] h-[60%] bg-indigo-500/10 rounded-full blur-[120px] pointer-events-none"></div>
        <div className="absolute inset-0 bg-[linear-gradient(to_right,#0f172a_1px,transparent_1px),linear-gradient(to_bottom,#0f172a_1px,transparent_1px)] bg-[size:4rem_4rem] [mask-image:radial-gradient(ellipse_60%_50%_at_50%_50%,#000_70%,transparent_100%)] pointer-events-none"></div>

        <div className="relative w-full max-w-md bg-slate-900/85 border border-slate-800 rounded-[32px] p-8 shadow-2xl backdrop-blur-xl transition-all duration-300">
          
          {/* Header */}
          <div className="flex flex-col items-center mb-8 text-center">
            <div className="w-14 h-14 bg-gradient-to-tr from-sky-400 to-indigo-600 rounded-2xl flex items-center justify-center shadow-lg shadow-sky-500/20 mb-4">
              <ShieldCheck className="w-8 h-8 text-white" />
            </div>
            <h2 className="text-2xl font-black text-white tracking-tight flex items-center gap-1.5 font-sans">
              Thekedar Connect
              <span className="text-[10px] bg-sky-500/10 border border-sky-500/20 text-sky-400 font-bold px-2 py-0.5 rounded-full uppercase tracking-wider">
                Admin
              </span>
            </h2>
            <p className="text-sm text-slate-400 mt-1.5 font-medium">SaaS Management Platform Console</p>
          </div>

          {authError && (
            <div className="bg-rose-500/10 border border-rose-500/20 text-rose-400 text-xs p-3.5 rounded-2xl flex items-start gap-2.5 mb-6 leading-relaxed">
              <ShieldAlert className="w-4 h-4 shrink-0 mt-0.5 text-rose-500" />
              <span>{authError}</span>
            </div>
          )}

          {/* Email/Password Login Form */}
          <form onSubmit={handleLoginSubmit} className="space-y-5">
            <div>
              <label className="block text-[10px] font-bold text-slate-500 uppercase tracking-wider mb-2">Email Address</label>
              <div className="relative">
                <Mail className="absolute left-4 top-3.5 w-4 h-4 text-slate-500" />
                <input
                  type="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="admin@thekedar.com"
                  required
                  disabled={isLoading}
                  className="w-full bg-slate-950/80 border border-slate-800 text-white rounded-xl py-3 pl-11 pr-4 text-xs focus:border-sky-500 focus:outline-none transition-colors"
                />
              </div>
            </div>

            <div>
              <label className="block text-[10px] font-bold text-slate-500 uppercase tracking-wider mb-2">Password</label>
              <div className="relative">
                <Lock className="absolute left-4 top-3.5 w-4 h-4 text-slate-500" />
                <input
                  type="password"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  placeholder="••••••••"
                  required
                  disabled={isLoading}
                  className="w-full bg-slate-950/80 border border-slate-800 text-white rounded-xl py-3 pl-11 pr-4 text-xs focus:border-sky-500 focus:outline-none transition-colors"
                />
              </div>
            </div>

            <button
              type="submit"
              disabled={isLoading}
              className="w-full bg-sky-500 hover:bg-sky-600 text-white font-extrabold py-3.5 rounded-2xl text-xs flex items-center justify-center gap-2 transition-all shadow-md shadow-sky-500/10 active:scale-[0.98] disabled:opacity-50 cursor-pointer"
            >
              {isLoading ? (
                <Loader2 className="w-4 h-4 animate-spin text-white" />
              ) : (
                <ShieldCheck className="w-4 h-4" />
              )}
              {isLoading ? 'Verifying Credentials...' : 'Authenticate Operator'}
            </button>
          </form>

        </div>
      </div>
    );
  }

  // Render Dashboard Interface when Authenticated
  return (
    <div className="min-h-screen bg-slate-50 flex">
      {/* Navigation Sidebar */}
      <Sidebar />

      {/* Main Panel Content */}
      <div className="flex-1 pl-64 flex flex-col min-h-screen">
        <Header />
        <main className="flex-grow p-8 bg-slate-50">
          <div className="max-w-7xl mx-auto space-y-8">
            {children}
          </div>
        </main>
      </div>
    </div>
  );
}
