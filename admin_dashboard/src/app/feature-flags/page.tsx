'use client';

import { useState, useEffect } from 'react';
import { supabase } from '@/core/supabase';
import { useAdminStore } from '@/core/store';
import { hasPermission } from '@/core/rbac';
import { Flag, Plus, Trash2, ToggleLeft, ToggleRight, Sparkles, Check, AlertCircle } from 'lucide-react';

interface FeatureFlag {
  id: string;
  name: string;
  description: string | null;
  is_enabled: boolean;
  updated_at: string;
}

export default function FeatureFlagsPage() {
  const { user: currentAdmin } = useAdminStore();
  const adminRole = currentAdmin?.role || 'Support';

  const [flags, setFlags] = useState<FeatureFlag[]>([]);
  const [loading, setLoading] = useState(true);

  // New flag states
  const [newName, setNewName] = useState('');
  const [newDescription, setNewDescription] = useState('');
  const [newIsEnabled, setNewIsEnabled] = useState(false);
  const [showAddForm, setShowAddForm] = useState(false);
  const [message, setMessage] = useState<{ text: string; type: 'success' | 'error' } | null>(null);

  // Permissions check
  const canEdit = hasPermission(adminRole, 'flags', 'edit');
  const canCreate = hasPermission(adminRole, 'flags', 'create');
  const canDelete = hasPermission(adminRole, 'flags', 'delete');

  useEffect(() => {
    fetchFeatureFlags();
  }, []);

  async function fetchFeatureFlags() {
    try {
      setLoading(true);
      const { data, error } = await supabase
        .from('feature_flags')
        .select('*')
        .order('name');
      
      if (error) throw error;
      setFlags(data || []);
    } catch (e) {
      console.error('Error fetching feature flags:', e);
    } finally {
      setLoading(false);
    }
  }

  async function toggleFlag(id: string, currentStatus: boolean, name: string) {
    if (!canEdit) {
      alert('Forbidden: You do not have permission to toggle feature flags.');
      return;
    }

    try {
      const { error } = await supabase
        .from('feature_flags')
        .update({ is_enabled: !currentStatus, updated_at: new Date().toISOString() })
        .eq('id', id);

      if (error) throw error;

      // Update local state
      setFlags((prev) =>
        prev.map((f) => (f.id === id ? { ...f, is_enabled: !currentStatus, updated_at: new Date().toISOString() } : f))
      );

      // Audit log (locally simulating / calling RPC or inserting audit_logs if table accessible)
      await supabase.from('audit_logs').insert({
        actor_id: currentAdmin?.id ? undefined : null, // If using anonymous admin, we can set actor as null
        action: `Toggle feature flag [${name}] to ${!currentStatus}`,
        target_table: 'feature_flags',
        prev_value: { is_enabled: currentStatus },
        new_value: { is_enabled: !currentStatus }
      });

      setMessage({ text: `Feature flag "${name}" successfully updated!`, type: 'success' });
      setTimeout(() => setMessage(null), 3000);
    } catch (e) {
      console.error('Error toggling feature flag:', e);
      setMessage({ text: 'Error updating feature flag status.', type: 'error' });
    }
  }

  async function handleAddFlag(e: React.FormEvent) {
    e.preventDefault();
    if (!canCreate) {
      alert('Forbidden: You do not have permission to create feature flags.');
      return;
    }
    if (!newName) return;

    try {
      const sanitizedName = newName.toLowerCase().replace(/\s+/g, '_');
      const { data, error } = await supabase
        .from('feature_flags')
        .insert({
          name: sanitizedName,
          description: newDescription || null,
          is_enabled: newIsEnabled
        })
        .select();

      if (error) throw error;

      setFlags((prev) => [...prev, ...data].sort((a, b) => a.name.localeCompare(b.name)));
      setNewName('');
      setNewDescription('');
      setNewIsEnabled(false);
      setShowAddForm(false);
      
      setMessage({ text: `Feature flag "${sanitizedName}" created successfully.`, type: 'success' });
      setTimeout(() => setMessage(null), 3000);
    } catch (e: any) {
      console.error('Error creating feature flag:', e);
      setMessage({ text: e.message || 'Error creating feature flag.', type: 'error' });
    }
  }

  async function handleDeleteFlag(id: string, name: string) {
    if (!canDelete) {
      alert('Forbidden: You do not have permission to delete feature flags.');
      return;
    }
    if (!confirm(`Are you sure you want to permanently delete the feature flag "${name}"?`)) {
      return;
    }

    try {
      const { error } = await supabase
        .from('feature_flags')
        .delete()
        .eq('id', id);

      if (error) throw error;

      setFlags((prev) => prev.filter((f) => f.id !== id));
      setMessage({ text: `Feature flag "${name}" deleted.`, type: 'success' });
      setTimeout(() => setMessage(null), 3000);
    } catch (e) {
      console.error('Error deleting feature flag:', e);
      setMessage({ text: 'Error deleting feature flag.', type: 'error' });
    }
  }

  return (
    <div className="space-y-8">
      {/* Header */}
      <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
        <div>
          <h1 className="text-3xl font-extrabold text-slate-800 tracking-tight">Feature Flags</h1>
          <p className="text-slate-500 mt-1">Control client application functionality remotely in real-time.</p>
        </div>
        {canCreate && (
          <button
            onClick={() => setShowAddForm(!showAddForm)}
            className="bg-sky-500 hover:bg-sky-600 text-white font-bold px-5 py-3 rounded-2xl text-sm transition-all shadow-md shadow-sky-500/10 flex items-center justify-center gap-2 self-start md:self-auto"
          >
            <Plus className="w-5 h-5" />
            {showAddForm ? 'Close panel' : 'New Feature Flag'}
          </button>
        )}
      </div>

      {message && (
        <div className={`p-4 rounded-2xl flex items-center gap-3 border text-sm ${
          message.type === 'success' 
            ? 'bg-emerald-50 border-emerald-200 text-emerald-800' 
            : 'bg-rose-50 border-rose-200 text-rose-800'
        }`}>
          {message.type === 'success' ? <Check className="w-5 h-5" /> : <AlertCircle className="w-5 h-5" />}
          <span>{message.text}</span>
        </div>
      )}

      {/* Add Flag form panel */}
      {showAddForm && (
        <div className="bg-white rounded-3xl border border-slate-100 p-6 shadow-sm max-w-2xl">
          <h2 className="text-lg font-bold text-slate-800 mb-4">Define Remote Feature</h2>
          <form onSubmit={handleAddFlag} className="space-y-4">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label className="block text-xs font-semibold text-slate-400 uppercase tracking-wider mb-2">Feature Name</label>
                <input
                  type="text"
                  value={newName}
                  onChange={(e) => setNewName(e.target.value)}
                  placeholder="e.g. video_calls"
                  required
                  className="w-full bg-slate-50 border border-slate-200/80 text-slate-800 rounded-2xl py-3 px-4 text-sm focus:border-sky-500 focus:outline-none"
                />
              </div>
              <div>
                <label className="block text-xs font-semibold text-slate-400 uppercase tracking-wider mb-2">Initial Status</label>
                <div className="flex items-center h-[50px]">
                  <button
                    type="button"
                    onClick={() => setNewIsEnabled(!newIsEnabled)}
                    className="flex items-center gap-2 text-sm text-slate-700 font-semibold cursor-pointer"
                  >
                    {newIsEnabled ? (
                      <ToggleRight className="w-10 h-10 text-sky-500" />
                    ) : (
                      <ToggleLeft className="w-10 h-10 text-slate-400" />
                    )}
                    <span>{newIsEnabled ? 'Enabled by default' : 'Disabled by default'}</span>
                  </button>
                </div>
              </div>
            </div>
            <div>
              <label className="block text-xs font-semibold text-slate-400 uppercase tracking-wider mb-2">Feature Description</label>
              <textarea
                value={newDescription}
                onChange={(e) => setNewDescription(e.target.value)}
                placeholder="Explain what this flag enables or controls inside the mobile apps..."
                rows={3}
                className="w-full bg-slate-50 border border-slate-200/80 text-slate-800 rounded-2xl py-3 px-4 text-sm focus:border-sky-500 focus:outline-none resize-none"
              />
            </div>
            <div className="flex justify-end gap-3 pt-2">
              <button
                type="button"
                onClick={() => setShowAddForm(false)}
                className="bg-slate-100 hover:bg-slate-200 text-slate-700 font-bold px-5 py-2.5 rounded-2xl text-xs transition-colors"
              >
                Cancel
              </button>
              <button
                type="submit"
                className="bg-sky-500 hover:bg-sky-600 text-white font-bold px-5 py-2.5 rounded-2xl text-xs transition-colors"
              >
                Save & Deploy Flag
              </button>
            </div>
          </form>
        </div>
      )}

      {/* Flags Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {loading ? (
          <div className="col-span-full flex items-center justify-center p-12">
            <div className="w-10 h-10 border-4 border-sky-500 border-t-transparent rounded-full animate-spin"></div>
          </div>
        ) : (
          flags.map((flag) => (
            <div key={flag.id} className="bg-white rounded-3xl border border-slate-100 p-6 shadow-sm flex flex-col justify-between hover:shadow-md transition-shadow">
              <div className="space-y-4">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-3">
                    <div className={`w-10 h-10 rounded-xl flex items-center justify-center ${
                      flag.is_enabled ? 'bg-sky-50 text-sky-500' : 'bg-slate-100 text-slate-400'
                    }`}>
                      <Flag className="w-5 h-5" />
                    </div>
                    <div>
                      <h2 className="font-extrabold text-slate-800 text-base font-mono">{flag.name}</h2>
                      <span className="text-[10px] text-slate-400 font-mono">Updated {new Date(flag.updated_at).toLocaleDateString()}</span>
                    </div>
                  </div>

                  {canEdit ? (
                    <button
                      onClick={() => toggleFlag(flag.id, flag.is_enabled, flag.name)}
                      className="cursor-pointer focus:outline-none transition-transform active:scale-95"
                    >
                      {flag.is_enabled ? (
                        <ToggleRight className="w-12 h-12 text-sky-500" />
                      ) : (
                        <ToggleLeft className="w-12 h-12 text-slate-300" />
                      )}
                    </button>
                  ) : (
                    <span className={`px-2.5 py-1 rounded-xl text-xs font-bold ${
                      flag.is_enabled ? 'bg-emerald-50 text-emerald-600' : 'bg-slate-100 text-slate-400'
                    }`}>
                      {flag.is_enabled ? 'Active' : 'Off'}
                    </span>
                  )}
                </div>

                <p className="text-sm text-slate-500 leading-relaxed min-h-[50px]">
                  {flag.description || 'No description provided for this remote flag control.'}
                </p>
              </div>

              <div className="border-t border-slate-50 pt-4 mt-6 flex justify-between items-center text-xs">
                <div className="flex items-center gap-1.5 text-slate-400 font-medium">
                  <Sparkles className="w-3.5 h-3.5" />
                  <span>Real-time Sync</span>
                </div>

                {canDelete && (
                  <button
                    onClick={() => handleDeleteFlag(flag.id, flag.name)}
                    className="text-slate-300 hover:text-rose-500 p-1 rounded-lg hover:bg-rose-50 transition-colors"
                  >
                    <Trash2 className="w-4 h-4" />
                  </button>
                )}
              </div>
            </div>
          ))
        )}
      </div>
    </div>
  );
}
