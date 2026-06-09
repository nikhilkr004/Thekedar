'use client';

import { useState, useEffect } from 'react';
import { supabase } from '@/core/supabase';
import { useAdminStore } from '@/core/store';
import { hasPermission } from '@/core/rbac';
import { Settings, Save, AlertTriangle, RefreshCw, CheckCircle } from 'lucide-react';

interface ConfigItem {
  key: string;
  value: string;
  description: string | null;
  updated_at: string;
}

export default function AppConfigPage() {
  const { user: currentAdmin } = useAdminStore();
  const adminRole = currentAdmin?.role || 'Support';

  const [configs, setConfigs] = useState<ConfigItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [editingValues, setEditingValues] = useState<Record<string, string>>({});
  const [savingKey, setSavingKey] = useState<string | null>(null);
  const [message, setMessage] = useState<{ text: string; type: 'success' | 'error' } | null>(null);

  // Check permission
  const canEdit = hasPermission(adminRole, 'config', 'edit');

  useEffect(() => {
    fetchConfigs();
  }, []);

  async function fetchConfigs() {
    try {
      setLoading(true);
      const { data, error } = await supabase
        .from('app_configurations')
        .select('*')
        .order('key');

      if (error) throw error;
      setConfigs(data || []);

      // Initialize edit fields
      const initialEdits: Record<string, string> = {};
      data?.forEach((item) => {
        initialEdits[item.key] = item.value;
      });
      setEditingValues(initialEdits);
    } catch (e) {
      console.error('Error fetching configurations:', e);
    } finally {
      setLoading(false);
    }
  }

  const handleInputChange = (key: string, value: string) => {
    setEditingValues((prev) => ({ ...prev, [key]: value }));
  };

  async function saveConfig(key: string) {
    if (!canEdit) {
      alert('Forbidden: You do not have permission to edit app configuration.');
      return;
    }

    const value = editingValues[key];
    if (value === undefined) return;

    try {
      setSavingKey(key);
      const { error } = await supabase
        .from('app_configurations')
        .update({ value, updated_at: new Date().toISOString() })
        .eq('key', key);

      if (error) throw error;

      setConfigs((prev) =>
        prev.map((c) => (c.key === key ? { ...c, value, updated_at: new Date().toISOString() } : c))
      );

      // Audit Log
      const prevVal = configs.find(c => c.key === key)?.value;
      await supabase.from('audit_logs').insert({
        actor_id: null,
        action: `Modified config [${key}]`,
        target_table: 'app_configurations',
        prev_value: { value: prevVal },
        new_value: { value }
      });

      setMessage({ text: `Configuration key "${key}" saved successfully!`, type: 'success' });
      setTimeout(() => setMessage(null), 3000);
    } catch (e) {
      console.error('Error saving configuration:', e);
      setMessage({ text: 'Error saving config updates.', type: 'error' });
    } finally {
      setSavingKey(null);
    }
  }

  return (
    <div className="space-y-8">
      {/* Header */}
      <div>
        <h1 className="text-3xl font-extrabold text-slate-800 tracking-tight">App Configuration</h1>
        <p className="text-slate-500 mt-1">Configure endpoints, force updates, and toggle maintenance states.</p>
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

      {/* Main Settings Panel */}
      <div className="bg-white rounded-3xl border border-slate-100 p-6 shadow-sm max-w-4xl space-y-6">
        <div className="flex items-center justify-between border-b border-slate-100 pb-4">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-slate-50 rounded-xl flex items-center justify-center text-slate-500">
              <Settings className="w-5 h-5" />
            </div>
            <div>
              <h2 className="text-lg font-bold text-slate-800">Operational Configuration Keys</h2>
              <p className="text-xs text-slate-400">Controls core variables loaded by the client application on bootstrap</p>
            </div>
          </div>
          <button 
            onClick={fetchConfigs}
            className="p-2 text-slate-400 hover:text-slate-600 rounded-xl hover:bg-slate-50 transition-colors"
          >
            <RefreshCw className="w-5 h-5" />
          </button>
        </div>

        {loading ? (
          <div className="flex items-center justify-center p-12">
            <div className="w-10 h-10 border-4 border-sky-500 border-t-transparent rounded-full animate-spin"></div>
          </div>
        ) : (
          <div className="space-y-6 divide-y divide-slate-100">
            {configs.map((config, index) => (
              <div key={config.key} className={`flex flex-col md:flex-row md:items-center justify-between gap-4 ${index > 0 ? 'pt-6' : ''}`}>
                <div className="space-y-1 max-w-md">
                  <span className="text-sm font-bold text-slate-800 font-mono bg-slate-50 border border-slate-100 px-2 py-1 rounded-lg">
                    {config.key}
                  </span>
                  <p className="text-xs text-slate-400 pt-1 leading-relaxed">{config.description}</p>
                </div>

                <div className="flex flex-grow md:max-w-xl items-center gap-4">
                  {config.key.includes('mode') || config.key.includes('force') ? (
                    <select
                      value={editingValues[config.key] || 'false'}
                      onChange={(e) => handleInputChange(config.key, e.target.value)}
                      disabled={!canEdit}
                      className="w-full bg-slate-50 border border-slate-200 text-slate-800 rounded-xl py-2.5 px-4 text-xs font-semibold focus:border-sky-500 focus:outline-none"
                    >
                      <option value="true">TRUE / ENABLED</option>
                      <option value="false">FALSE / DISABLED</option>
                    </select>
                  ) : (
                    <input
                      type="text"
                      value={editingValues[config.key] || ''}
                      onChange={(e) => handleInputChange(config.key, e.target.value)}
                      disabled={!canEdit}
                      placeholder="Enter value"
                      className="w-full bg-slate-50 border border-slate-200 text-slate-800 rounded-xl py-2.5 px-4 text-xs font-mono focus:border-sky-500 focus:outline-none"
                    />
                  )}

                  {canEdit && (
                    <button
                      onClick={() => saveConfig(config.key)}
                      disabled={savingKey === config.key}
                      className="bg-slate-900 hover:bg-slate-800 disabled:bg-slate-400 text-white font-bold px-4 py-2.5 rounded-xl text-xs flex items-center gap-1.5 transition-colors shrink-0"
                    >
                      <Save className="w-4 h-4" />
                      {savingKey === config.key ? 'Saving...' : 'Save'}
                    </button>
                  )}
                </div>
              </div>
            ))}
          </div>
        )}
      </div>

      <div className="bg-rose-50 border border-rose-100 rounded-3xl p-6 max-w-4xl flex items-start gap-4">
        <AlertTriangle className="w-6 h-6 text-rose-500 shrink-0 mt-0.5" />
        <div className="space-y-1">
          <h4 className="text-sm font-bold text-rose-900">Critical Override Warning</h4>
          <p className="text-xs text-rose-700 leading-relaxed">
            Updating the configurations can impact active sessions of mobile app clients immediately. For example, changing the `api_endpoint` will point all incoming client calls to a new backend resource location, or enabling `maintenance_mode` will block clients from browsing project bidding boards.
          </p>
        </div>
      </div>
    </div>
  );
}
