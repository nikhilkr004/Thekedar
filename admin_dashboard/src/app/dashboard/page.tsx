'use client';

import { useState, useEffect } from 'react';
import { supabase } from '@/core/supabase';
import { useAdminStore } from '@/core/store';
import { 
  Users, 
  Construction, 
  Wallet, 
  TrendingUp, 
  Zap, 
  UserPlus, 
  Clock, 
  AlertCircle 
} from 'lucide-react';

export default function DashboardPage() {
  const { recentActivities, addActivity } = useAdminStore();
  const [stats, setStats] = useState({
    totalUsers: 0,
    totalContractors: 0,
    totalProjects: 0,
    totalRevenue: 0,
    pendingVerifications: 0,
  });
  const [loading, setLoading] = useState(true);

  // 1. Fetch live metrics from Supabase database
  useEffect(() => {
    async function fetchDashboardStats() {
      try {
        setLoading(true);
        
        // Fetch users count
        const { count: usersCount, error: userError } = await supabase
          .from('users')
          .select('*', { count: 'exact', head: true });
        
        // Fetch contractors count
        const { count: contractorsCount, error: contractorError } = await supabase
          .from('contractors')
          .select('*', { count: 'exact', head: true });

        // Fetch projects count
        const { count: projectsCount, error: projectError } = await supabase
          .from('projects')
          .select('*', { count: 'exact', head: true });

        // Fetch total revenue from transactions
        const { data: txs, error: txError } = await supabase
          .from('credit_transactions')
          .select('amount_inr')
          .eq('type', 'purchase');

        // Fetch pending verifications
        const { count: pendingCount } = await supabase
          .from('contractors')
          .select('*', { count: 'exact', head: true })
          .or('aadhaar_verified.eq.false,pan_verified.eq.false,gst_verified.eq.false');

        const revenueSum = txs ? txs.reduce((acc, curr) => acc + ((curr.amount_inr ?? 0) / 100), 0) : 0;

        setStats({
          totalUsers: usersCount || 0,
          totalContractors: contractorsCount || 0,
          totalProjects: projectsCount || 0,
          totalRevenue: Math.round(revenueSum),
          pendingVerifications: pendingCount || 0,
        });

      } catch (e) {
        console.error('Error fetching dashboard stats:', e);
      } finally {
        setLoading(false);
      }
    }

    fetchDashboardStats();

    // 2. Set up realtime Supabase subscriptions to append to live activity feed
    const userChannel = supabase
      .channel('schema-db-changes')
      .on(
        'postgres_changes',
        { event: 'INSERT', schema: 'public', table: 'users' },
        (payload) => {
          addActivity({
            user: payload.new.full_name || 'Anonymous User',
            action: 'registered a new profile account',
            type: 'success',
          });
          setStats((prev) => ({ ...prev, totalUsers: prev.totalUsers + 1 }));
        }
      )
      .on(
        'postgres_changes',
        { event: 'INSERT', schema: 'public', table: 'projects' },
        (payload) => {
          addActivity({
            user: payload.new.title || 'Project Lead',
            action: `posted in category: ${payload.new.category}`,
            type: 'info',
          });
          setStats((prev) => ({ ...prev, totalProjects: prev.totalProjects + 1 }));
        }
      )
      .subscribe();

    return () => {
      supabase.removeChannel(userChannel);
    };
  }, [addActivity]);

  const cards = [
    {
      name: 'Total Platform Users',
      value: stats.totalUsers.toString(),
      change: '+14% growth',
      icon: Users,
      color: 'from-blue-500 to-indigo-600',
      shadow: 'shadow-blue-500/10',
    },
    {
      name: 'Verified Contractors',
      value: stats.totalContractors.toString(),
      change: 'Active operating radius',
      icon: Zap,
      color: 'from-amber-500 to-orange-600',
      shadow: 'shadow-amber-500/10',
    },
    {
      name: 'Total Projects Live',
      value: stats.totalProjects.toString(),
      change: 'Bidding is active',
      icon: Construction,
      color: 'from-emerald-500 to-teal-600',
      shadow: 'shadow-emerald-500/10',
    },
    {
      name: 'Transaction Revenue',
      value: `₹${stats.totalRevenue}`,
      change: 'INR via Razorpay',
      icon: Wallet,
      color: 'from-sky-500 to-cyan-600',
      shadow: 'shadow-sky-500/10',
    },
  ];

  return (
    <div className="space-y-8">
      {/* Welcome Title */}
      <div>
        <h1 className="text-3xl font-extrabold text-slate-800 tracking-tight">Executive Dashboard</h1>
        <p className="text-slate-500 mt-1">Real-time marketplace transaction & activity analytics.</p>
      </div>

      {/* Grid Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {cards.map((c, i) => {
          const Icon = c.icon;
          return (
            <div key={i} className={`bg-white rounded-3xl p-6 border border-slate-100 shadow-sm hover:shadow-md transition-shadow duration-200`}>
              <div className="flex items-center justify-between">
                <div className={`w-12 h-12 bg-gradient-to-tr ${c.color} rounded-2xl flex items-center justify-center text-white shadow-lg ${c.shadow}`}>
                  <Icon className="w-6 h-6" />
                </div>
                <span className="text-xs font-semibold text-emerald-600 bg-emerald-50 px-2 py-1 rounded-lg">
                  +12.5%
                </span>
              </div>
              <div className="mt-4">
                <h3 className="text-sm font-semibold text-slate-400 uppercase tracking-wider">{c.name}</h3>
                <p className="text-3xl font-bold text-slate-800 mt-1">{loading ? '...' : c.value}</p>
                <p className="text-xs text-slate-400 mt-2 font-medium">{c.change}</p>
              </div>
            </div>
          );
        })}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        {/* Real-time Activity Feed */}
        <div className="lg:col-span-2 bg-white rounded-3xl border border-slate-100 p-6 shadow-sm">
          <div className="flex items-center justify-between mb-6">
            <div>
              <h2 className="text-lg font-bold text-slate-800">Live Activity Event Log</h2>
              <p className="text-xs text-slate-500">Real-time Supabase database listener channel</p>
            </div>
            <span className="flex items-center gap-1 text-xs text-sky-500 bg-sky-50 px-2 py-1 rounded-lg font-bold">
              <Clock className="w-3.5 h-3.5 animate-pulse" /> Live Stream
            </span>
          </div>

          <div className="space-y-4 max-h-[350px] overflow-y-auto pr-2">
            {recentActivities.map((act, idx) => (
              <div key={act.id || idx} className="flex items-start gap-4 p-3.5 bg-slate-50 rounded-2xl border border-slate-100 hover:border-slate-200 transition-colors">
                <div className="w-8 h-8 rounded-full bg-slate-200 flex items-center justify-center font-bold text-xs shrink-0 text-slate-600">
                  {act.user[0].toUpperCase()}
                </div>
                <div className="flex-1">
                  <p className="text-xs text-slate-400 font-semibold uppercase">{act.timestamp}</p>
                  <p className="text-sm font-medium text-slate-800 mt-0.5">
                    <span className="font-bold text-slate-900">{act.user}</span> {act.action}
                  </p>
                </div>
                <span className={`w-2 h-2 rounded-full mt-2 ${
                  act.type === 'success' ? 'bg-emerald-500' :
                  act.type === 'warning' ? 'bg-amber-500' :
                  act.type === 'error' ? 'bg-rose-500' : 'bg-sky-500'
                }`} />
              </div>
            ))}
          </div>
        </div>

        {/* Warning Metrics / Pending Approvals */}
        <div className="bg-white rounded-3xl border border-slate-100 p-6 shadow-sm flex flex-col justify-between">
          <div>
            <h2 className="text-lg font-bold text-slate-800">Pending Operator Audits</h2>
            <p className="text-xs text-slate-500">Items requiring verification review</p>
          </div>

          <div className="my-6 space-y-4">
            <div className="flex items-center justify-between p-4 bg-amber-50 border border-amber-200/60 rounded-2xl text-amber-800">
              <div className="flex items-center gap-3">
                <AlertCircle className="w-5 h-5 text-amber-500" />
                <span className="font-bold text-sm">Contractor Audits</span>
              </div>
              <span className="bg-amber-100 px-3 py-1 rounded-xl text-xs font-extrabold">
                {stats.pendingVerifications} Pending
              </span>
            </div>
            
            <div className="flex items-center justify-between p-4 bg-sky-50 border border-sky-200/60 rounded-2xl text-sky-800">
              <div className="flex items-center gap-3">
                <Zap className="w-5 h-5 text-sky-500" />
                <span className="font-bold text-sm">Escrow Settlements</span>
              </div>
              <span className="bg-sky-100 px-3 py-1 rounded-xl text-xs font-extrabold">
                0 Active
              </span>
            </div>
          </div>

          <div className="bg-slate-50 rounded-2xl p-4 border border-slate-100 text-center">
            <p className="text-xs text-slate-400 font-bold uppercase tracking-wider">Marketplace Health Score</p>
            <p className="text-3xl font-extrabold text-slate-800 mt-1">98.4%</p>
            <p className="text-[10px] text-emerald-600 font-bold mt-1">▲ Excellent operating condition</p>
          </div>
        </div>
      </div>
    </div>
  );
}
