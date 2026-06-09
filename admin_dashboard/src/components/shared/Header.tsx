'use client';

import { useAdminStore } from '@/core/store';
import { ShieldAlert, Globe, Server, CheckCircle2 } from 'lucide-react';

export default function Header() {
  const { user, activeSocketsCount } = useAdminStore();

  return (
    <header className="h-16 border-b border-slate-100 bg-white flex items-center justify-between px-8 sticky top-0 z-30 shadow-sm">
      {/* Search / Section title */}
      <div className="flex items-center gap-3">
        <Server className="w-5 h-5 text-emerald-500" />
        <span className="text-sm font-semibold text-slate-700">Production Servers</span>
        <span className="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-semibold bg-emerald-50 text-emerald-700 gap-1 border border-emerald-200">
          <CheckCircle2 className="w-3 h-3" /> Online
        </span>
      </div>

      {/* Profile & Live Counter metrics */}
      <div className="flex items-center gap-6">
        {/* Live Counters */}
        <div className="flex items-center gap-4 text-xs font-semibold text-slate-500 border-r border-slate-200 pr-6">
          <div className="flex items-center gap-1.5">
            <Globe className="w-4 h-4 text-sky-500 animate-spin [animation-duration:8s]" />
            <span>Live Clients: <span className="text-slate-800 font-bold">{activeSocketsCount * 12}</span></span>
          </div>
          <div className="flex items-center gap-1.5">
            <ShieldAlert className="w-4 h-4 text-amber-500" />
            <span>Alerts: <span className="text-slate-800 font-bold">0</span></span>
          </div>
        </div>

        {/* User Card */}
        <div className="flex items-center gap-3">
          <div className="text-right">
            <p className="text-sm font-bold text-slate-800">{user?.fullName || 'Verified Operator'}</p>
            <p className="text-xs text-sky-600 font-bold uppercase tracking-wider">{user?.role || 'Guest'}</p>
          </div>
          <div className="w-9 h-9 rounded-xl bg-gradient-to-tr from-sky-500 to-indigo-600 text-white flex items-center justify-center font-bold shadow-md shadow-sky-500/10">
            {(user?.fullName || 'OP')[0].toUpperCase()}
          </div>
        </div>
      </div>
    </header>
  );
}
