'use client';

import { useState, useEffect } from 'react';
import { supabase } from '@/core/supabase';
import { useAdminStore } from '@/core/store';
import { hasPermission } from '@/core/rbac';
import { LifeBuoy, AlertCircle, CheckCircle, MessageSquare, AlertTriangle, ArrowRight } from 'lucide-react';

interface SupportTicket {
  id: string;
  user_id: string | null;
  subject: string;
  description: string;
  status: 'open' | 'in_progress' | 'resolved' | 'closed';
  priority: 'low' | 'medium' | 'high' | 'critical';
  category: string | null;
  created_at: string;
  updated_at: string;
  users?: {
    full_name: string;
    phone: string;
    email: string | null;
  } | null;
}

export default function SupportTicketsPage() {
  const { user: currentAdmin } = useAdminStore();
  const adminRole = currentAdmin?.role || 'Support';

  const [tickets, setTickets] = useState<SupportTicket[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedTicket, setSelectedTicket] = useState<SupportTicket | null>(null);
  const [statusFilter, setStatusFilter] = useState('all');

  // Permission check
  const canEdit = hasPermission(adminRole, 'support', 'edit');

  useEffect(() => {
    fetchTickets();
  }, []);

  async function fetchTickets() {
    try {
      setLoading(true);
      // Fetch tickets and join with users table
      const { data, error } = await supabase
        .from('support_tickets')
        .select(`
          *,
          users:user_id (
            full_name,
            phone,
            email
          )
        `)
        .order('created_at', { ascending: false });

      if (error) throw error;
      setTickets(data || []);
    } catch (e) {
      console.error('Error fetching support tickets:', e);
    } finally {
      setLoading(false);
    }
  }

  async function updateTicketStatus(id: string, newStatus: 'open' | 'in_progress' | 'resolved' | 'closed') {
    if (!canEdit) {
      alert('Forbidden: You do not have permission to update ticket status.');
      return;
    }

    try {
      const prevTicket = tickets.find(t => t.id === id);
      const { error } = await supabase
        .from('support_tickets')
        .update({ status: newStatus, updated_at: new Date().toISOString() })
        .eq('id', id);

      if (error) throw error;

      // Update local state
      setTickets((prev) =>
        prev.map((t) => (t.id === id ? { ...t, status: newStatus, updated_at: new Date().toISOString() } : t))
      );
      if (selectedTicket?.id === id) {
        setSelectedTicket((prev) => prev ? { ...prev, status: newStatus, updated_at: new Date().toISOString() } : null);
      }

      // Audit log
      await supabase.from('audit_logs').insert({
        actor_id: null,
        action: `Updated ticket [${id}] status from ${prevTicket?.status} to ${newStatus}`,
        target_table: 'support_tickets',
        prev_value: { status: prevTicket?.status },
        new_value: { status: newStatus }
      });

    } catch (e) {
      console.error('Error updating ticket status:', e);
    }
  }

  const filteredTickets = tickets.filter((t) => {
    return statusFilter === 'all' ? true : t.status === statusFilter;
  });

  return (
    <div className="space-y-8">
      {/* Header */}
      <div>
        <h1 className="text-3xl font-extrabold text-slate-800 tracking-tight">Support Center</h1>
        <p className="text-slate-500 mt-1">Review feedback, system bugs, and assist users with account queries.</p>
      </div>

      {/* Filter and stats bar */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 bg-white p-5 rounded-3xl border border-slate-100 shadow-sm">
        <div className="flex items-center gap-3">
          <span className="text-xs font-semibold text-slate-400 uppercase tracking-wider">Filter Status:</span>
          <div className="flex gap-2">
            {['all', 'open', 'in_progress', 'resolved', 'closed'].map((status) => (
              <button
                key={status}
                onClick={() => setStatusFilter(status)}
                className={`px-4 py-1.5 rounded-xl text-xs font-bold transition-all border capitalize cursor-pointer ${
                  statusFilter === status
                    ? 'bg-slate-900 border-slate-900 text-white shadow-sm'
                    : 'bg-slate-50 border-slate-200/80 text-slate-600 hover:bg-slate-100'
                }`}
              >
                {status.replace('_', ' ')}
              </button>
            ))}
          </div>
        </div>
        <button
          onClick={fetchTickets}
          className="bg-slate-100 hover:bg-slate-200 text-slate-700 font-bold px-4 py-2 rounded-xl text-xs transition-colors shrink-0"
        >
          Reload Tickets
        </button>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        
        {/* Ticket List */}
        <div className={`bg-white rounded-3xl border border-slate-100 p-6 shadow-sm overflow-hidden ${
          selectedTicket ? 'lg:col-span-2' : 'lg:col-span-3'
        }`}>
          {loading ? (
            <div className="flex items-center justify-center p-12">
              <div className="w-10 h-10 border-4 border-sky-500 border-t-transparent rounded-full animate-spin"></div>
            </div>
          ) : (
            <div className="space-y-4 max-h-[500px] overflow-y-auto pr-2">
              {filteredTickets.map((t) => (
                <div
                  key={t.id}
                  onClick={() => setSelectedTicket(t)}
                  className={`p-4 border rounded-2xl bg-white hover:border-sky-200 cursor-pointer transition-all flex items-start gap-4 ${
                    selectedTicket?.id === t.id ? 'border-sky-300 ring-2 ring-sky-100 bg-slate-50/50' : 'border-slate-100'
                  }`}
                >
                  <div className={`w-10 h-10 rounded-xl flex items-center justify-center shrink-0 ${
                    t.priority === 'critical' ? 'bg-rose-50 text-rose-500' :
                    t.priority === 'high' ? 'bg-amber-50 text-amber-500' :
                    t.priority === 'medium' ? 'bg-sky-50 text-sky-500' : 'bg-slate-100 text-slate-400'
                  }`}>
                    <AlertCircle className="w-5 h-5" />
                  </div>
                  <div className="flex-grow min-w-0 space-y-1">
                    <div className="flex justify-between items-start">
                      <h3 className="text-sm font-bold text-slate-800 truncate">{t.subject}</h3>
                      <span className={`px-2 py-0.5 rounded-lg text-[9px] font-extrabold uppercase font-mono ${
                        t.status === 'open' ? 'bg-rose-50 text-rose-600 border border-rose-200' :
                        t.status === 'in_progress' ? 'bg-amber-50 text-amber-600 border border-amber-200' :
                        t.status === 'resolved' ? 'bg-emerald-50 text-emerald-600 border border-emerald-200' :
                        'bg-slate-100 text-slate-400 border border-slate-200'
                      }`}>
                        {t.status.replace('_', ' ')}
                      </span>
                    </div>
                    <p className="text-xs text-slate-400 truncate leading-relaxed">{t.description}</p>
                    <div className="flex gap-3 pt-2 text-[10px] text-slate-400 font-semibold">
                      <span>By: {t.users?.full_name || 'Guest User'}</span>
                      <span>• Priority: <span className="uppercase">{t.priority}</span></span>
                      {t.category && <span>• Cat: {t.category}</span>}
                    </div>
                  </div>
                </div>
              ))}
              {filteredTickets.length === 0 && (
                <div className="text-center py-12 text-slate-400 font-medium">No tickets match status filters.</div>
              )}
            </div>
          )}
        </div>

        {/* Selected Ticket Drawer / Detail view */}
        {selectedTicket && (
          <div className="bg-white rounded-3xl border border-slate-100 p-6 shadow-sm flex flex-col justify-between h-fit space-y-6">
            <div>
              <div className="flex justify-between items-start">
                <h2 className="text-lg font-bold text-slate-800">Ticket Details</h2>
                <button 
                  onClick={() => setSelectedTicket(null)}
                  className="text-slate-400 hover:text-slate-600 font-bold"
                >
                  ✕
                </button>
              </div>

              <div className="mt-6 space-y-4">
                <div>
                  <span className="text-xs text-slate-400 font-semibold block uppercase">Subject / Request</span>
                  <span className="text-sm font-bold text-slate-800">{selectedTicket.subject}</span>
                </div>

                <div>
                  <span className="text-xs text-slate-400 font-semibold block uppercase">Description Details</span>
                  <p className="text-xs text-slate-600 leading-relaxed bg-slate-50 border border-slate-100 rounded-xl p-3.5 mt-1 font-medium whitespace-pre-wrap">
                    {selectedTicket.description}
                  </p>
                </div>

                <div className="border-t border-slate-100 pt-4 space-y-3">
                  <div>
                    <span className="text-xs text-slate-400 font-semibold block uppercase">Sender Identity</span>
                    <span className="text-xs font-bold text-slate-800">{selectedTicket.users?.full_name || 'Anonymous User'}</span>
                    <span className="block text-[10px] text-slate-400 font-mono">{selectedTicket.users?.phone} {selectedTicket.users?.email ? `| ${selectedTicket.users.email}` : ''}</span>
                  </div>

                  <div>
                    <span className="text-xs text-slate-400 font-semibold block uppercase">Timestamp Created</span>
                    <span className="text-xs text-slate-500 font-mono">{new Date(selectedTicket.created_at).toLocaleString()}</span>
                  </div>
                </div>
              </div>
            </div>

            {/* Action toggles status */}
            <div className="space-y-3 pt-6 border-t border-slate-100">
              <span className="text-xs text-slate-400 font-semibold block uppercase">Set Ticket Status</span>
              <div className="grid grid-cols-2 gap-2">
                {(['open', 'in_progress', 'resolved', 'closed'] as const).map((status) => (
                  <button
                    key={status}
                    onClick={() => updateTicketStatus(selectedTicket.id, status)}
                    disabled={!canEdit || selectedTicket.status === status}
                    className={`py-2 rounded-xl text-[10px] font-bold uppercase transition-all border ${
                      selectedTicket.status === status
                        ? 'bg-slate-900 border-slate-900 text-white font-extrabold shadow-sm'
                        : 'bg-slate-50 border-slate-200 text-slate-600 hover:bg-slate-100 disabled:opacity-50'
                    }`}
                  >
                    {status.replace('_', ' ')}
                  </button>
                ))}
              </div>
            </div>
          </div>
        )}

      </div>
    </div>
  );
}
