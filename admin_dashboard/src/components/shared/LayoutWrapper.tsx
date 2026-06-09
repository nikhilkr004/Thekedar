'use client';

import { useAdminStore } from '@/core/store';
import Sidebar from './Sidebar';
import Header from './Header';
import { useState, useEffect } from 'react';
import { ShieldAlert, Lock, Mail, User, ShieldCheck } from 'lucide-react';

export default function LayoutWrapper({ children }: { children: React.ReactNode }) {
  const { isAuthenticated, login } = useAdminStore();
  const [mounted, setMounted] = useState(false);

  // Auth local inputs
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [role, setRole] = useState<'Super Admin' | 'Admin' | 'Moderator' | 'Support' | 'Accountant'>('Admin');
  const [name, setName] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState('');

  useEffect(() => {
    setMounted(true);
  }, []);

  if (!mounted) {
    return (
      <div className="min-h-screen bg-slate-950 flex items-center justify-center">
        <div className="w-16 h-16 border-4 border-sky-500 border-t-transparent rounded-full animate-spin"></div>
      </div>
    );
  }

  // If not authenticated, render login page
  if (!isAuthenticated) {
    const handleLoginSubmit = (e: React.FormEvent) => {
      e.preventDefault();
      if (!email || !password || !name) {
        setError('Please fill in all fields to login.');
        return;
      }
      setIsLoading(true);
      setError('');
      setTimeout(() => {
        login({
          id: Math.random().toString(),
          email,
          fullName: name,
          role: role,
        });
        setIsLoading(false);
      }, 1000);
    };

    return (
      <div className="min-h-screen bg-slate-950 flex items-center justify-center p-4">
        {/* Decorative Grid */}
        <div className="absolute inset-0 bg-[linear-gradient(to_right,#0f172a_1px,transparent_1px),linear-gradient(to_bottom,#0f172a_1px,transparent_1px)] bg-[size:4rem_4rem] [mask-image:radial-gradient(ellipse_60%_50%_at_50%_50%,#000_70%,transparent_100%)] pointer-events-none"></div>

        <div className="relative w-full max-w-md bg-slate-900 border border-slate-800 rounded-3xl p-8 shadow-2xl backdrop-blur-xl">
          {/* Header */}
          <div className="flex flex-col items-center mb-8 text-center">
            <div className="w-14 h-14 bg-gradient-to-tr from-sky-400 to-indigo-600 rounded-2xl flex items-center justify-center shadow-lg shadow-sky-500/10 mb-4">
              <ShieldCheck className="w-8 h-8 text-white" />
            </div>
            <h2 className="text-2xl font-bold text-white tracking-tight">Thekedar Connect</h2>
            <p className="text-sm text-slate-400 mt-1">Sign in to control dashboard console</p>
          </div>

          {/* Form */}
          <form onSubmit={handleLoginSubmit} className="space-y-5">
            {error && (
              <div className="bg-rose-500/10 border border-rose-500/20 text-rose-400 text-xs p-3.5 rounded-xl flex items-center gap-2">
                <ShieldAlert className="w-4 h-4" />
                <span>{error}</span>
              </div>
            )}

            <div>
              <label className="block text-xs font-semibold text-slate-400 uppercase tracking-wider mb-2">Operator Name</label>
              <div className="relative">
                <User className="absolute left-4 top-3.5 w-5 h-5 text-slate-500" />
                <input
                  type="text"
                  value={name}
                  onChange={(e) => setName(e.target.value)}
                  placeholder="Amit Sharma"
                  className="w-full bg-slate-950 border border-slate-800 text-white rounded-xl py-3 pl-12 pr-4 text-sm focus:border-sky-500 focus:outline-none transition-colors"
                />
              </div>
            </div>

            <div>
              <label className="block text-xs font-semibold text-slate-400 uppercase tracking-wider mb-2">Email Address</label>
              <div className="relative">
                <Mail className="absolute left-4 top-3.5 w-5 h-5 text-slate-500" />
                <input
                  type="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="admin@thekedar.com"
                  className="w-full bg-slate-950 border border-slate-800 text-white rounded-xl py-3 pl-12 pr-4 text-sm focus:border-sky-500 focus:outline-none transition-colors"
                />
              </div>
            </div>

            <div>
              <label className="block text-xs font-semibold text-slate-400 uppercase tracking-wider mb-2">Access Token Key</label>
              <div className="relative">
                <Lock className="absolute left-4 top-3.5 w-5 h-5 text-slate-500" />
                <input
                  type="password"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  placeholder="••••••••"
                  className="w-full bg-slate-950 border border-slate-800 text-white rounded-xl py-3 pl-12 pr-4 text-sm focus:border-sky-500 focus:outline-none transition-colors"
                />
              </div>
            </div>

            <div>
              <label className="block text-xs font-semibold text-slate-400 uppercase tracking-wider mb-2">Role Group Privilege</label>
              <select
                value={role}
                onChange={(e) => setRole(e.target.value as any)}
                className="w-full bg-slate-950 border border-slate-800 text-white rounded-xl py-3 px-4 text-sm focus:border-sky-500 focus:outline-none transition-colors"
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
              className="w-full bg-gradient-to-r from-sky-500 to-sky-600 hover:from-sky-600 hover:to-sky-700 text-white font-bold py-3.5 rounded-xl transition-all duration-200 shadow-lg shadow-sky-500/10 active:scale-[0.98] disabled:opacity-50"
            >
              {isLoading ? 'Decrypting credentials...' : 'Authenticate Operator'}
            </button>
          </form>
        </div>
      </div>
    );
  }

  // If authenticated, render full page layout
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
