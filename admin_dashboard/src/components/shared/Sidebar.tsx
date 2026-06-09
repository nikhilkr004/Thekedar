'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { useAdminStore } from '@/core/store';
import { hasPermission } from '@/core/rbac';
import { 
  LayoutDashboard, 
  Users, 
  FileText, 
  Flag, 
  Settings, 
  Bell, 
  BarChart3, 
  History, 
  LifeBuoy, 
  LogOut,
  ShieldCheck
} from 'lucide-react';

interface SidebarItem {
  name: string;
  href: string;
  icon: React.ComponentType<{ className?: string }>;
  module: 'users' | 'cms' | 'flags' | 'config' | 'notifications' | 'analytics' | 'support' | 'audits';
}

const menuItems: SidebarItem[] = [
  { name: 'Dashboard', href: '/dashboard', icon: LayoutDashboard, module: 'analytics' },
  { name: 'User Management', href: '/users', icon: Users, module: 'users' },
  { name: 'App CMS', href: '/cms', icon: FileText, module: 'cms' },
  { name: 'Feature Flags', href: '/feature-flags', icon: Flag, module: 'flags' },
  { name: 'App Configuration', href: '/config', icon: Settings, module: 'config' },
  { name: 'Notifications Center', href: '/notifications', icon: Bell, module: 'notifications' },
  { name: 'Analytics Insights', href: '/analytics', icon: BarChart3, module: 'analytics' },
  { name: 'Support Tickets', href: '/support', icon: LifeBuoy, module: 'support' },
  { name: 'System Audit Logs', href: '/audit-logs', icon: History, module: 'audits' },
];

export default function Sidebar() {
  const pathname = usePathname();
  const { user, logout } = useAdminStore();
  const userRole = user?.role || 'Support';

  return (
    <aside className="w-64 bg-slate-900 border-r border-slate-800 text-slate-200 flex flex-col h-screen fixed left-0 top-0">
      {/* Brand Header */}
      <div className="h-16 flex items-center px-6 border-b border-slate-800 gap-3 bg-slate-950">
        <div className="bg-sky-500 p-2 rounded-lg text-white">
          <ShieldCheck className="w-5 h-5" />
        </div>
        <div>
          <h1 className="font-bold text-sm tracking-wide text-white uppercase">Thekedar Connect</h1>
          <p className="text-xs text-sky-400 font-semibold uppercase tracking-wider">Web Control Panel</p>
        </div>
      </div>

      {/* Nav Menu */}
      <nav className="flex-1 px-4 py-6 space-y-1 overflow-y-auto">
        {menuItems.map((item) => {
          const isAllowed = hasPermission(userRole, item.module, 'view');
          if (!isAllowed) return null;

          const isActive = pathname === item.href;
          const Icon = item.icon;

          return (
            <Link
              key={item.href}
              href={item.href}
              className={`flex items-center px-4 py-3 rounded-xl text-sm font-medium transition-all duration-200 ${
                isActive
                  ? 'bg-gradient-to-r from-sky-500 to-sky-600 text-white shadow-md shadow-sky-500/10'
                  : 'text-slate-400 hover:bg-slate-800/60 hover:text-slate-100'
              }`}
            >
              <Icon className="w-5 h-5 mr-3 shrink-0" />
              {item.name}
            </Link>
          );
        })}
      </nav>

      {/* Footer Profile / Log out */}
      <div className="p-4 border-t border-slate-800 bg-slate-950">
        <div className="flex items-center justify-between mb-3 px-2">
          <div>
            <p className="text-xs text-slate-500 font-bold uppercase tracking-wider">Role</p>
            <p className="text-sm font-semibold text-sky-400">{userRole}</p>
          </div>
        </div>
        <button
          onClick={logout}
          className="w-full flex items-center px-4 py-3 text-sm font-medium text-rose-400 hover:bg-rose-950/20 rounded-xl transition-colors duration-200"
        >
          <LogOut className="w-5 h-5 mr-3 shrink-0" />
          Sign Out
        </button>
      </div>
    </aside>
  );
}
