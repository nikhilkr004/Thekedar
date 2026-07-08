'use client';

import { useState, useEffect } from 'react';
import { supabase } from '@/core/supabase';
import { useAdminStore } from '@/core/store';
import { hasPermission } from '@/core/rbac';
import { Coins, Plus, Trash2, CheckCircle, AlertTriangle, ToggleLeft, ToggleRight, DollarSign } from 'lucide-react';

interface ChargeRule {
  id: string;
  rule_name: string;
  min_budget: number;
  max_budget: number | null;
  charge_coins: number;
  is_active: boolean;
  created_at: string;
}

export default function ChargeRulesPage() {
  const { user: currentAdmin } = useAdminStore();
  const adminRole = currentAdmin?.role || 'Support';

  const [rules, setRules] = useState<ChargeRule[]>([]);
  const [loading, setLoading] = useState(true);
  
  // Form fields for new rule
  const [ruleName, setRuleName] = useState('');
  const [minBudget, setMinBudget] = useState('');
  const [maxBudget, setMaxBudget] = useState('');
  const [chargeCoins, setChargeCoins] = useState('');
  
  const [message, setMessage] = useState<{ text: string; type: 'success' | 'error' } | null>(null);
  const [submitting, setSubmitting] = useState(false);

  // Check edit permission
  const canEdit = hasPermission(adminRole, 'config', 'edit');

  useEffect(() => {
    fetchRules();
  }, []);

  async function fetchRules() {
    try {
      setLoading(true);
      const { data, error } = await supabase
        .from('bid_charge_rules')
        .select('*')
        .order('min_budget', { ascending: true });

      if (error) throw error;
      setRules(data || []);
    } catch (e) {
      console.error('Error fetching bid charging rules:', e);
    } finally {
      setLoading(false);
    }
  }

  async function handleCreateRule(e: React.FormEvent) {
    e.preventDefault();
    if (!canEdit) {
      alert('Forbidden: You do not have permission to manage charging rules.');
      return;
    }

    if (!ruleName || !minBudget || !chargeCoins) {
      setMessage({ text: 'Please fill in all required fields.', type: 'error' });
      return;
    }

    try {
      setSubmitting(true);
      const newRule = {
        rule_name: ruleName,
        min_budget: parseFloat(minBudget),
        max_budget: maxBudget ? parseFloat(maxBudget) : null,
        charge_coins: parseInt(chargeCoins),
        is_active: true
      };

      const { data, error } = await supabase
        .from('bid_charge_rules')
        .insert([newRule])
        .select();

      if (error) throw error;

      if (data) {
        setRules((prev) => [...prev, data[0]].sort((a, b) => a.min_budget - b.min_budget));
      }

      setRuleName('');
      setMinBudget('');
      setMaxBudget('');
      setChargeCoins('');
      setMessage({ text: 'Bidding rule created successfully!', type: 'success' });
      setTimeout(() => setMessage(null), 3000);
    } catch (e: any) {
      console.error('Error creating bidding rule:', e);
      setMessage({ text: e.message || 'Error creating rule.', type: 'error' });
    } finally {
      setSubmitting(false);
    }
  }

  async function handleToggleActive(id: string, currentStatus: boolean) {
    if (!canEdit) return;

    try {
      const { error } = await supabase
        .from('bid_charge_rules')
        .update({ is_active: !currentStatus })
        .eq('id', id);

      if (error) throw error;

      setRules((prev) =>
        prev.map((rule) => (rule.id === id ? { ...rule, is_active: !currentStatus } : rule))
      );
    } catch (e) {
      console.error('Error toggling rule status:', e);
    }
  }

  async function handleDeleteRule(id: string) {
    if (!canEdit) return;
    if (!confirm('Are you sure you want to delete this charging rule?')) return;

    try {
      const { error } = await supabase
        .from('bid_charge_rules')
        .delete()
        .eq('id', id);

      if (error) throw error;

      setRules((prev) => prev.filter((rule) => rule.id !== id));
      setMessage({ text: 'Rule deleted successfully.', type: 'success' });
      setTimeout(() => setMessage(null), 3000);
    } catch (e) {
      console.error('Error deleting rule:', e);
      setMessage({ text: 'Error deleting rule.', type: 'error' });
    }
  }

  return (
    <div className="space-y-8">
      {/* Header */}
      <div>
        <h1 className="text-3xl font-extrabold text-slate-800 tracking-tight flex items-center gap-3">
          <DollarSign className="w-8 h-8 text-sky-500" />
          Coin Bidding Rules Management
        </h1>
        <p className="text-slate-500 mt-1">Configure dynamic coin deduction rules based on project budget thresholds.</p>
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
              Add Bidding Rule
            </h2>
            <form onSubmit={handleCreateRule} className="space-y-4">
              <div>
                <label className="block text-xs font-bold uppercase text-slate-400 mb-2">Rule Name</label>
                <input
                  type="text"
                  placeholder="e.g. Medium Budget Tier"
                  value={ruleName}
                  onChange={(e) => setRuleName(e.target.value)}
                  className="w-full px-4 py-3 rounded-2xl border border-slate-100 focus:outline-none focus:ring-2 focus:ring-sky-500/20 focus:border-sky-500 text-slate-800 text-sm font-medium"
                />
              </div>
              <div>
                <label className="block text-xs font-bold uppercase text-slate-400 mb-2">Minimum Project Budget (₹)</label>
                <input
                  type="number"
                  placeholder="e.g. 50000"
                  value={minBudget}
                  onChange={(e) => setMinBudget(e.target.value)}
                  className="w-full px-4 py-3 rounded-2xl border border-slate-100 focus:outline-none focus:ring-2 focus:ring-sky-500/20 focus:border-sky-500 text-slate-800 text-sm font-medium"
                />
              </div>
              <div>
                <label className="block text-xs font-bold uppercase text-slate-400 mb-2">Maximum Project Budget (₹) (Optional)</label>
                <input
                  type="number"
                  placeholder="e.g. 500000 (leave blank for infinity)"
                  value={maxBudget}
                  onChange={(e) => setMaxBudget(e.target.value)}
                  className="w-full px-4 py-3 rounded-2xl border border-slate-100 focus:outline-none focus:ring-2 focus:ring-sky-500/20 focus:border-sky-500 text-slate-800 text-sm font-medium"
                />
              </div>
              <div>
                <label className="block text-xs font-bold uppercase text-slate-400 mb-2">Coins Deducted per Bid</label>
                <input
                  type="number"
                  placeholder="e.g. 20"
                  value={chargeCoins}
                  onChange={(e) => setChargeCoins(e.target.value)}
                  className="w-full px-4 py-3 rounded-2xl border border-slate-100 focus:outline-none focus:ring-2 focus:ring-sky-500/20 focus:border-sky-500 text-slate-800 text-sm font-medium"
                />
              </div>
              <button
                type="submit"
                disabled={submitting}
                className="w-full bg-slate-900 text-white py-3 rounded-2xl font-semibold hover:bg-slate-850 transition-colors text-sm"
              >
                {submitting ? 'Creating...' : 'Create Rule'}
              </button>
            </form>
          </div>
        )}

        {/* Rules List */}
        <div className="lg:col-span-2 bg-white rounded-3xl border border-slate-100 p-6 shadow-sm space-y-6">
          <h2 className="text-lg font-bold text-slate-800">Active Bidding Charge Engine Rules</h2>
          {loading ? (
            <div className="flex items-center justify-center p-12">
              <div className="w-10 h-10 border-4 border-sky-500 border-t-transparent rounded-full animate-spin"></div>
            </div>
          ) : rules.length === 0 ? (
            <p className="text-sm text-slate-400 py-6 text-center">No bidding rules found. Create one to enable dynamic billing.</p>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-left border-collapse text-sm">
                <thead>
                  <tr className="border-b border-slate-100 text-slate-400 font-semibold">
                    <th className="pb-3 font-semibold">Rule Name</th>
                    <th className="pb-3 font-semibold">Budget Range</th>
                    <th className="pb-3 font-semibold">Coins Charged</th>
                    <th className="pb-3 font-semibold">Status</th>
                    {canEdit && <th className="pb-3 text-right font-semibold">Actions</th>}
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100 text-slate-700 font-medium">
                  {rules.map((rule) => (
                    <tr key={rule.id}>
                      <td className="py-4 text-slate-800 font-bold">{rule.rule_name}</td>
                      <td className="py-4 text-slate-600">
                        ₹{rule.min_budget.toLocaleString()} - {rule.max_budget ? `₹${rule.max_budget.toLocaleString()}` : '∞'}
                      </td>
                      <td className="py-4 text-rose-600 font-bold">{rule.charge_coins} Coins</td>
                      <td className="py-4">
                        <button
                          onClick={() => handleToggleActive(rule.id, rule.is_active)}
                          disabled={!canEdit}
                          className="flex items-center gap-1 focus:outline-none"
                        >
                          {rule.is_active ? (
                            <ToggleRight className="w-6 h-6 text-sky-500 cursor-pointer" />
                          ) : (
                            <ToggleLeft className="w-6 h-6 text-slate-350 cursor-pointer" />
                          )}
                          <span className="text-xs font-semibold">{rule.is_active ? 'Active' : 'Inactive'}</span>
                        </button>
                      </td>
                      {canEdit && (
                        <td className="py-4 text-right">
                          <button
                            onClick={() => handleDeleteRule(rule.id)}
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
