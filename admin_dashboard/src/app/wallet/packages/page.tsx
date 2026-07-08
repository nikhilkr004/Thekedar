'use client';

import { useState, useEffect } from 'react';
import { supabase } from '@/core/supabase';
import { useAdminStore } from '@/core/store';
import { hasPermission } from '@/core/rbac';
import { Coins, Plus, Trash2, CheckCircle, AlertTriangle, ToggleLeft, ToggleRight } from 'lucide-react';

interface CoinPackage {
  id: string;
  price_inr: number;
  coins: number;
  bonus_coins: number;
  is_active: boolean;
  created_at: string;
}

export default function CoinPackagesPage() {
  const { user: currentAdmin } = useAdminStore();
  const adminRole = currentAdmin?.role || 'Support';

  const [packages, setPackages] = useState<CoinPackage[]>([]);
  const [loading, setLoading] = useState(true);
  
  // Form fields for new package
  const [priceInr, setPriceInr] = useState('');
  const [coins, setCoins] = useState('');
  const [bonusCoins, setBonusCoins] = useState('0');
  
  const [message, setMessage] = useState<{ text: string; type: 'success' | 'error' } | null>(null);
  const [submitting, setSubmitting] = useState(false);

  // Check edit permission
  const canEdit = hasPermission(adminRole, 'config', 'edit');

  useEffect(() => {
    fetchPackages();
  }, []);

  async function fetchPackages() {
    try {
      setLoading(true);
      const { data, error } = await supabase
        .from('coin_packages')
        .select('*')
        .order('price_inr', { ascending: true });

      if (error) throw error;
      setPackages(data || []);
    } catch (e) {
      console.error('Error fetching coin packages:', e);
    } finally {
      setLoading(false);
    }
  }

  async function handleCreatePackage(e: React.FormEvent) {
    e.preventDefault();
    if (!canEdit) {
      alert('Forbidden: You do not have permission to manage coin packages.');
      return;
    }

    if (!priceInr || !coins) {
      setMessage({ text: 'Please fill in all required fields.', type: 'error' });
      return;
    }

    try {
      setSubmitting(true);
      const newPkg = {
        price_inr: parseFloat(priceInr),
        coins: parseInt(coins),
        bonus_coins: parseInt(bonusCoins || '0'),
        is_active: true
      };

      const { data, error } = await supabase
        .from('coin_packages')
        .insert([newPkg])
        .select();

      if (error) throw error;

      if (data) {
        setPackages((prev) => [...prev, data[0]].sort((a, b) => a.price_inr - b.price_inr));
      }

      setPriceInr('');
      setCoins('');
      setBonusCoins('0');
      setMessage({ text: 'Package created successfully!', type: 'success' });
      setTimeout(() => setMessage(null), 3000);
    } catch (e: any) {
      console.error('Error creating package:', e);
      setMessage({ text: e.message || 'Error creating package.', type: 'error' });
    } finally {
      setSubmitting(false);
    }
  }

  async function handleToggleActive(id: string, currentStatus: boolean) {
    if (!canEdit) return;

    try {
      const { error } = await supabase
        .from('coin_packages')
        .update({ is_active: !currentStatus })
        .eq('id', id);

      if (error) throw error;

      setPackages((prev) =>
        prev.map((pkg) => (pkg.id === id ? { ...pkg, is_active: !currentStatus } : pkg))
      );
    } catch (e) {
      console.error('Error toggling package status:', e);
    }
  }

  async function handleDeletePackage(id: string) {
    if (!canEdit) return;
    if (!confirm('Are you sure you want to delete this coin package?')) return;

    try {
      const { error } = await supabase
        .from('coin_packages')
        .delete()
        .eq('id', id);

      if (error) throw error;

      setPackages((prev) => prev.filter((pkg) => pkg.id !== id));
      setMessage({ text: 'Package deleted successfully.', type: 'success' });
      setTimeout(() => setMessage(null), 3000);
    } catch (e) {
      console.error('Error deleting package:', e);
      setMessage({ text: 'Error deleting package.', type: 'error' });
    }
  }

  return (
    <div className="space-y-8">
      {/* Header */}
      <div>
        <h1 className="text-3xl font-extrabold text-slate-800 tracking-tight flex items-center gap-3">
          <Coins className="w-8 h-8 text-sky-500" />
          Coin Packages Management
        </h1>
        <p className="text-slate-500 mt-1">Configure user-facing recharge packages, prices, and promotional bonus coin tiers.</p>
      </div>

      {message && (
        <div className={`p-4 rounded-2xl flex items-center gap-3 border text-sm max-w-2xl ${
          message.type === 'success' 
            ? 'bg-emerald-50 border-emerald-200 text-emerald-800' 
            : 'bg-rose-50 border-rose-200 text-rose-800'
        }`}>
          {message.type === 'success' ? <CheckCircle className="w-5 h-5" /> : <AlertTriangle className="w-5 h-5" />}
          <span>{message.text}</span>
        </div>
      )}

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        {/* Create Form */}
        {canEdit && (
          <div className="bg-white rounded-3xl border border-slate-100 p-6 shadow-sm h-fit space-y-6">
            <h2 className="text-lg font-bold text-slate-800 flex items-center gap-2">
              <Plus className="w-5 h-5 text-sky-500" />
              Add New Package
            </h2>
            <form onSubmit={handleCreatePackage} className="space-y-4">
              <div>
                <label className="block text-xs font-bold uppercase text-slate-400 mb-2">Price (INR)</label>
                <input
                  type="number"
                  placeholder="e.g. 500"
                  value={priceInr}
                  onChange={(e) => setPriceInr(e.target.value)}
                  className="w-full px-4 py-3 rounded-2xl border border-slate-100 focus:outline-none focus:ring-2 focus:ring-sky-500/20 focus:border-sky-500 text-slate-800 text-sm font-medium"
                />
              </div>
              <div>
                <label className="block text-xs font-bold uppercase text-slate-400 mb-2">Coins Provided</label>
                <input
                  type="number"
                  placeholder="e.g. 500"
                  value={coins}
                  onChange={(e) => setCoins(e.target.value)}
                  className="w-full px-4 py-3 rounded-2xl border border-slate-100 focus:outline-none focus:ring-2 focus:ring-sky-500/20 focus:border-sky-500 text-slate-800 text-sm font-medium"
                />
              </div>
              <div>
                <label className="block text-xs font-bold uppercase text-slate-400 mb-2">Bonus Coins</label>
                <input
                  type="number"
                  placeholder="e.g. 50"
                  value={bonusCoins}
                  onChange={(e) => setBonusCoins(e.target.value)}
                  className="w-full px-4 py-3 rounded-2xl border border-slate-100 focus:outline-none focus:ring-2 focus:ring-sky-500/20 focus:border-sky-500 text-slate-800 text-sm font-medium"
                />
              </div>
              <button
                type="submit"
                disabled={submitting}
                className="w-full bg-slate-900 text-white py-3 rounded-2xl font-semibold hover:bg-slate-850 transition-colors text-sm"
              >
                {submitting ? 'Creating...' : 'Create Package'}
              </button>
            </form>
          </div>
        )}

        {/* Packages List */}
        <div className="lg:col-span-2 bg-white rounded-3xl border border-slate-100 p-6 shadow-sm space-y-6">
          <h2 className="text-lg font-bold text-slate-800">Active Coin Packages</h2>
          {loading ? (
            <div className="flex items-center justify-center p-12">
              <div className="w-10 h-10 border-4 border-sky-500 border-t-transparent rounded-full animate-spin"></div>
            </div>
          ) : packages.length === 0 ? (
            <p className="text-sm text-slate-400 py-6 text-center">No coin packages found. Create one to get started.</p>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-left border-collapse text-sm">
                <thead>
                  <tr className="border-b border-slate-100 text-slate-400 font-semibold">
                    <th className="pb-3 font-semibold">Price</th>
                    <th className="pb-3 font-semibold">Base Coins</th>
                    <th className="pb-3 font-semibold">Bonus</th>
                    <th className="pb-3 font-semibold">Final Value</th>
                    <th className="pb-3 font-semibold">Status</th>
                    {canEdit && <th className="pb-3 text-right font-semibold">Actions</th>}
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100 text-slate-700 font-medium">
                  {packages.map((pkg) => (
                    <tr key={pkg.id}>
                      <td className="py-4 text-slate-800 font-bold">₹{pkg.price_inr}</td>
                      <td className="py-4">{pkg.coins}</td>
                      <td className="py-4 text-emerald-600">+{pkg.bonus_coins}</td>
                      <td className="py-4 text-slate-800 font-bold">{pkg.coins + pkg.bonus_coins} Coins</td>
                      <td className="py-4">
                        <button
                          onClick={() => handleToggleActive(pkg.id, pkg.is_active)}
                          disabled={!canEdit}
                          className="flex items-center gap-1 focus:outline-none"
                        >
                          {pkg.is_active ? (
                            <ToggleRight className="w-6 h-6 text-sky-500 cursor-pointer" />
                          ) : (
                            <ToggleLeft className="w-6 h-6 text-slate-350 cursor-pointer" />
                          )}
                          <span className="text-xs font-semibold">{pkg.is_active ? 'Active' : 'Inactive'}</span>
                        </button>
                      </td>
                      {canEdit && (
                        <td className="py-4 text-right">
                          <button
                            onClick={() => handleDeletePackage(pkg.id)}
                            className="p-2 text-rose-500 hover:bg-rose-50 rounded-xl transition-colors"
                          >
                            <Trash2 className="w-4 h-4" />
                          </button>
                        </td>
                      )}
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
