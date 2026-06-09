'use client';

import { useState, useEffect } from 'react';
import { supabase } from '@/core/supabase';
import { useAdminStore } from '@/core/store';
import { hasPermission } from '@/core/rbac';
import { History, ShieldAlert, ArrowRight, RefreshCw, ZoomIn } from 'lucide-react';

interface AuditLog {
  id: string;
  actor_id: string | null;
  action: string;
  target_table: string;
  prev_value: Record<string, any> | null;
  new_value: Record<string, any> | null;
  timestamp: string;
  users?: {
    full_name: string;
    role: string;
  } | null;
}

export default function AuditLogsPage() {
  const { user: currentAdmin } = useAdminStore();
  const adminRole = currentAdmin?.role || 'Support';

  const [logs, setLogs] = useState<AuditLog[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedLog, setSelectedLog] = useState<AuditLog | null>(null);

  // Permission check
  const canView = hasPermission(adminRole, 'audits', 'view');

  useEffect(() => {
    if (canView) {
      fetchAuditLogs();
    }
  }, [canView]);

  async function fetchAuditLogs() {
    try {
      setLoading(true);
      const { data, error } = await supabase
        .from('audit_logs')
        .select(`
          *,
          users:actor_id (
            full_name,
            role
          )
        `)
        .order('timestamp', { ascending: false });

      if (error) throw error;
      setLogs(data || []);
    } catch (e) {
      console.error('Error fetching audit logs:', e);
    } finally {
      setLoading(false);
    }
  }

  if (!canView) {
    return (
      <div className="bg-rose-50 border border-rose-100 rounded-3xl p-8 flex items-center gap-4 text-rose-800 max-w-2xl">
        <ShieldAlert className="w-8 h-8 text-rose-500 shrink-0" />
        <div>
          <h2 className="text-lg font-bold">Access Denied</h2>
          <p className="text-xs text-rose-600 mt-1">Your administrator role group ({adminRole}) does not have permission to view system audit logs.</p>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-8">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-extrabold text-slate-800 tracking-tight">System Audit Logs</h1>
          <p className="text-slate-500 mt-1">Chronological history logs of dashboard actions and database configuration overrides.</p>
        </div>
        <button
          onClick={fetchAuditLogs}
          className="bg-white hover:bg-slate-50 text-slate-700 font-bold px-4 py-2.5 rounded-2xl text-xs border border-slate-200 transition-colors flex items-center gap-1.5"
        >
          <RefreshCw className="w-4 h-4" /> Reload Logs
        </button>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        
        {/* Logs Table */}
        <div className={`bg-white rounded-3xl border border-slate-100 p-6 shadow-sm overflow-hidden ${
          selectedLog ? 'lg:col-span-2' : 'lg:col-span-3'
        }`}>
          {loading ? (
            <div className="flex items-center justify-center p-12">
              <div className="w-10 h-10 border-4 border-sky-500 border-t-transparent rounded-full animate-spin"></div>
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-left text-sm text-slate-600">
                <thead className="bg-slate-50 text-xs text-slate-400 uppercase font-bold tracking-wider">
                  <tr>
                    <th className="p-4 rounded-l-2xl">Action & Details</th>
                    <th className="p-4">Table</th>
                    <th className="p-4">Operator</th>
                    <th className="p-4 rounded-r-2xl">Timestamp</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100">
                  {logs.map((log) => (
                    <tr
                      key={log.id}
                      onClick={() => setSelectedLog(log)}
                      className={`hover:bg-slate-50/80 cursor-pointer transition-colors ${
                        selectedLog?.id === log.id ? 'bg-slate-50 font-bold' : ''
                      }`}
                    >
                      <td className="p-4">
                        <div className="font-bold text-slate-800 flex items-center gap-1.5">
                          {log.action}
                        </div>
                      </td>
                      <td className="p-4">
                        <span className="font-mono text-xs bg-slate-50 border border-slate-100 px-2 py-0.5 rounded text-slate-500">
                          {log.target_table}
                        </span>
                      </td>
                      <td className="p-4 text-xs font-semibold text-slate-700">
                        {log.users?.full_name || 'System Operator'}
                        <span className="block text-[9px] text-slate-400 font-normal">{log.users?.role || 'Anon Web Admin'}</span>
                      </td>
                      <td className="p-4 text-slate-400 font-mono text-xs">
                        {new Date(log.timestamp).toLocaleString()}
                      </td>
                    </tr>
                  ))}
                  {logs.length === 0 && (
                    <tr>
                      <td colSpan={4} className="p-8 text-center text-slate-400">
                        No audit records have been generated yet.
                      </td>
                    </tr>
                  )}
                </tbody>
              </table>
            </div>
          )}
        </div>

        {/* Selected Log Drawer View */}
        {selectedLog && (
          <div className="bg-white rounded-3xl border border-slate-100 p-6 shadow-sm flex flex-col h-fit space-y-6">
            <div className="flex justify-between items-start">
              <h2 className="text-lg font-bold text-slate-800">Change Details</h2>
              <button 
                onClick={() => setSelectedLog(null)}
                className="text-slate-400 hover:text-slate-600 font-bold"
              >
                ✕
              </button>
            </div>

            <div className="space-y-4">
              <div>
                <span className="text-xs text-slate-400 font-semibold block uppercase">Action Logged</span>
                <span className="text-xs font-bold text-slate-800 font-mono bg-slate-50 border border-slate-100 p-2.5 rounded-xl block mt-1">
                  {selectedLog.action}
                </span>
              </div>

              {selectedLog.prev_value && (
                <div>
                  <span className="text-xs text-slate-400 font-semibold block uppercase">Previous Value</span>
                  <pre className="text-[10px] text-slate-600 font-mono bg-rose-50/50 border border-rose-100/60 rounded-xl p-3.5 mt-1 overflow-x-auto whitespace-pre-wrap">
                    {JSON.stringify(selectedLog.prev_value, null, 2)}
                  </pre>
                </div>
              )}

              {selectedLog.new_value && (
                <div>
                  <span className="text-xs text-slate-400 font-semibold block uppercase">New Value</span>
                  <pre className="text-[10px] text-slate-600 font-mono bg-emerald-50/50 border border-emerald-100/60 rounded-xl p-3.5 mt-1 overflow-x-auto whitespace-pre-wrap">
                    {JSON.stringify(selectedLog.new_value, null, 2)}
                  </pre>
                </div>
              )}

              <div className="border-t border-slate-100 pt-4 text-[11px] text-slate-400 space-y-1">
                <div>UUID: <span className="font-mono text-[9px]">{selectedLog.id}</span></div>
                <div>Target Object Schema: <span className="font-mono font-bold text-slate-500">{selectedLog.target_table}</span></div>
              </div>
            </div>
          </div>
        )}

      </div>
    </div>
  );
}
