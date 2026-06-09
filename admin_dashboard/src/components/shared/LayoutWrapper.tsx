'use client';

import { useAdminStore } from '@/core/store';
import Sidebar from './Sidebar';
import Header from './Header';
import { useState, useEffect } from 'react';
import { supabase } from '@/core/supabase';
import { 
  ShieldAlert, Lock, Mail, User, ShieldCheck, ChevronDown, ChevronUp, 
  Sparkles, Loader2, LogOut
} from 'lucide-react';

export default function LayoutWrapper({ children }: { children: React.ReactNode }) {
  const { isAuthenticated, login, logout, user: storeUser } = useAdminStore();
  const [mounted, setMounted] = useState(false);

  // UI state
  const [showDevLogin, setShowDevLogin] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [authError, setAuthError] = useState('');
  
  // Local/Dev form inputs
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [role, setRole] = useState<'Super Admin' | 'Admin' | 'Moderator' | 'Support' | 'Accountant'>('Admin');
  const [name, setName] = useState('');

  useEffect(() => {
    setMounted(true);

    // Subscribe to Supabase OAuth Session Changes
    const { data: { subscription } } = supabase.auth.onAuthStateChange(async (event, session) => {
      if (session?.user) {
        setIsLoading(true);
        setAuthError('');
        try {
          const userEmail = session.user.email;
          const userFullName = session.user.user_metadata?.full_name || session.user.user_metadata?.name || 'Authorized User';

          // Query the admin_users whitelist table
          const { data: adminRecord, error: adminError } = await supabase
            .from('admin_users')
            .select('role, full_name')
            .eq('email', userEmail)
            .maybeSingle();

          if (adminError) throw adminError;

          if (adminRecord) {
            // WHitelisted admin - grant entry
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
        // Clear store if Supabase session is ended
        if (event === 'SIGNED_OUT') {
          logout();
        }
      }
    });

    return () => {
      subscription.unsubscribe();
    };
  }, [login, logout]);

  // Handle Google OAuth Action
  async function handleGoogleLogin() {
    setIsLoading(true);
    setAuthError('');
    try {
      const { error } = await supabase.auth.signInWithOAuth({
        provider: 'google',
        options: {
          redirectTo: window.location.origin,
        },
      });
      if (error) throw error;
    } catch (err: any) {
      console.error(err);
      setAuthError(err.message || 'Failed to initiate Google Authentication.');
      setIsLoading(false);
    }
  }

  // Handle Local Dev Login Bypasses
  const handleDevLoginSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!email || !password || !name) {
      setAuthError('Please fill in all fields to login as developer.');
      return;
    }
    setIsLoading(true);
    setAuthError('');
    setTimeout(() => {
      login({
        id: Math.random().toString(),
        email,
        fullName: name,
        role: role,
      });
      setIsLoading(false);
    }, 800);
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
        {/* Modern Vibrant Gradient Mesh */}
        <div className="absolute top-[-20%] left-[-20%] w-[60%] h-[60%] bg-sky-500/10 rounded-full blur-[120px] pointer-events-none"></div>
        <div className="absolute bottom-[-20%] right-[-20%] w-[60%] h-[60%] bg-indigo-500/10 rounded-full blur-[120px] pointer-events-none"></div>
        <div className="absolute inset-0 bg-[linear-gradient(to_right,#0f172a_1px,transparent_1px),linear-gradient(to_bottom,#0f172a_1px,transparent_1px)] bg-[size:4rem_4rem] [mask-image:radial-gradient(ellipse_60%_50%_at_50%_50%,#000_70%,transparent_100%)] pointer-events-none"></div>

        <div className="relative w-full max-w-md bg-slate-900/80 border border-slate-800 rounded-[32px] p-8 shadow-2xl backdrop-blur-xl transition-all duration-300">
          
          {/* Header */}
          <div className="flex flex-col items-center mb-8 text-center">
            <div className="w-14 h-14 bg-gradient-to-tr from-sky-400 to-indigo-600 rounded-2xl flex items-center justify-center shadow-lg shadow-sky-500/20 mb-4 animate-pulse-slow">
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

          <div className="space-y-6">
            
            {/* Primary Google Login Button */}
            <button
              onClick={handleGoogleLogin}
              disabled={isLoading}
              className="w-full bg-white hover:bg-slate-50 text-slate-800 font-extrabold py-3.5 px-4 rounded-2xl text-xs flex items-center justify-center gap-3 transition-all duration-200 shadow-md shadow-white/5 active:scale-[0.98] disabled:opacity-50 cursor-pointer"
            >
              {isLoading ? (
                <Loader2 className="w-4 h-4 animate-spin text-slate-500" />
              ) : (
                <svg className="w-4 h-4 mr-1" viewBox="0 0 24 24">
                  <path
                    fill="#4285F4"
                    d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"
                  />
                  <path
                    fill="#34A853"
                    d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"
                  />
                  <path
                    fill="#FBBC05"
                    d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.06H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.94l2.85-2.22.81-.63z"
                  />
                  <path
                    fill="#EA4335"
                    d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.06l3.66 2.84c.87-2.6 3.3-4.52 6.16-4.52z"
                  />
                </svg>
              )}
              {isLoading ? 'Verifying Session...' : 'Sign in with Google'}
            </button>

            {/* Divider */}
            <div className="flex items-center gap-3 text-slate-700">
              <div className="h-[1px] bg-slate-800 flex-grow"></div>
              <span className="text-[10px] font-bold uppercase tracking-wider text-slate-500 select-none">or</span>
              <div className="h-[1px] bg-slate-800 flex-grow"></div>
            </div>

            {/* Collapsible Local Dev Bypass */}
            <div className="space-y-4">
              <button
                type="button"
                onClick={() => setShowDevLogin(!showDevLogin)}
                className="w-full text-slate-500 hover:text-slate-300 text-[11px] font-bold flex items-center justify-center gap-1.5 transition-colors uppercase tracking-wider py-1"
              >
                <span>Local Developer Login</span>
                {showDevLogin ? <ChevronUp className="w-3.5 h-3.5" /> : <ChevronDown className="w-3.5 h-3.5" />}
              </button>

              {showDevLogin && (
                <form onSubmit={handleDevLoginSubmit} className="space-y-4 border-t border-slate-800/80 pt-4 animate-fade-in">
                  <div>
                    <label className="block text-[10px] font-bold text-slate-500 uppercase tracking-wider mb-2">Dev Operator Name</label>
                    <div className="relative">
                      <User className="absolute left-4 top-3 w-4 h-4 text-slate-500" />
                      <input
                        type="text"
                        value={name}
                        onChange={(e) => setName(e.target.value)}
                        placeholder="Nikhil Kumar"
                        required
                        className="w-full bg-slate-950/80 border border-slate-800 text-white rounded-xl py-2.5 pl-11 pr-4 text-xs focus:border-sky-500 focus:outline-none transition-colors"
                      />
                    </div>
                  </div>

                  <div>
                    <label className="block text-[10px] font-bold text-slate-500 uppercase tracking-wider mb-2">Email Address</label>
                    <div className="relative">
                      <Mail className="absolute left-4 top-3 w-4 h-4 text-slate-500" />
                      <input
                        type="email"
                        value={email}
                        onChange={(e) => setEmail(e.target.value)}
                        placeholder="developer@thekedar.com"
                        required
                        className="w-full bg-slate-950/80 border border-slate-800 text-white rounded-xl py-2.5 pl-11 pr-4 text-xs focus:border-sky-500 focus:outline-none transition-colors"
                      />
                    </div>
                  </div>

                  <div>
                    <label className="block text-[10px] font-bold text-slate-500 uppercase tracking-wider mb-2">Bypass Security Pin</label>
                    <div className="relative">
                      <Lock className="absolute left-4 top-3 w-4 h-4 text-slate-500" />
                      <input
                        type="password"
                        value={password}
                        onChange={(e) => setPassword(e.target.value)}
                        placeholder="••••••••"
                        required
                        className="w-full bg-slate-950/80 border border-slate-800 text-white rounded-xl py-2.5 pl-11 pr-4 text-xs focus:border-sky-500 focus:outline-none transition-colors"
                      />
                    </div>
                  </div>

                  <div>
                    <label className="block text-[10px] font-bold text-slate-500 uppercase tracking-wider mb-2">Privilege Level</label>
                    <select
                      value={role}
                      onChange={(e) => setRole(e.target.value as any)}
                      className="w-full bg-slate-950/80 border border-slate-800 text-white rounded-xl py-2.5 px-4 text-xs focus:border-sky-500 focus:outline-none cursor-pointer"
                    >
                      <option value="Super Admin">Super Admin (Full Access)</option>
                      <option value="Admin">Admin (Create & Edit)</option>
                      <option value="Moderator">Moderator (Review Content)</option>
                      <option value="Support">Support Operator (Support Tickets)</option>
                      <option value="Accountant">Accountant (Transaction Audits)</option>
                    </select>
                  </div>

                  <button
                    type="submit"
                    disabled={isLoading}
                    className="w-full bg-slate-800 hover:bg-slate-700 text-white font-extrabold py-3 rounded-xl transition-all duration-200 active:scale-[0.98] text-xs flex items-center justify-center gap-2"
                  >
                    <Sparkles className="w-4 h-4 text-sky-400" />
                    Bypass Login Authentication
                  </button>
                </form>
              )}
            </div>

          </div>
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
