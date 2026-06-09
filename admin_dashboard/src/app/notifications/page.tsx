'use client';

import { useState, useEffect } from 'react';
import { supabase } from '@/core/supabase';
import { useAdminStore } from '@/core/store';
import { hasPermission } from '@/core/rbac';
import { 
  Send, Bell, Filter, BarChart2, CheckCircle, AlertTriangle, 
  Eye, RefreshCw, SendIcon, ShieldAlert, Award, Sliders, Users, 
  MapPin, Settings, History, CheckCheck, Trash2
} from 'lucide-react';
import { 
  AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, 
  ResponsiveContainer, BarChart, Bar, Legend, PieChart, Pie, Cell 
} from 'recharts';

interface NotificationMetadata {
  id: string;
  company_id: string | null;
  title: string;
  message: string;
  image_url: string | null;
  notification_type: string;
  priority: string;
  target_type: string;
  created_by: string | null;
  created_at: string;
}

interface RecipientStat {
  id: string;
  notification_id: string;
  is_read: boolean;
  delivered_at: string | null;
  opened_at: string | null;
}

interface UserRecord {
  id: string;
  full_name: string;
  role: string | null;
  email: string | null;
}

interface SiteRecord {
  id: string;
  name: string;
}

export default function NotificationsPage() {
  const { user: currentAdmin } = useAdminStore();
  const adminRole = currentAdmin?.role || 'Support';

  // State arrays
  const [notifications, setNotifications] = useState<NotificationMetadata[]>([]);
  const [recipientsStats, setRecipientsStats] = useState<Record<string, { sent: number; read: number; opened: number; delivered: number }>>({});
  const [users, setUsers] = useState<UserRecord[]>([]);
  const [sites, setSites] = useState<SiteRecord[]>([]);
  const [loading, setLoading] = useState(true);

  // Form compose fields
  const [title, setTitle] = useState('');
  const [messageText, setMessageText] = useState('');
  const [imageUrl, setImageUrl] = useState('');
  const [notificationType, setNotificationType] = useState('broadcast');
  const [priority, setPriority] = useState('medium');
  const [targetType, setTargetType] = useState('all');
  
  // Dynamic Target values
  const [targetCompanyId, setTargetCompanyId] = useState('');
  const [targetSiteId, setTargetSiteId] = useState('');
  const [targetRole, setTargetRole] = useState('Worker');
  const [targetUserId, setTargetUserId] = useState('');

  const [isSending, setIsSending] = useState(false);
  const [feedback, setFeedback] = useState<{ text: string; type: 'success' | 'error' } | null>(null);

  // Stats summaries
  const [totalNotifications, setTotalNotifications] = useState(0);
  const [totalDelivered, setTotalDelivered] = useState(0);
  const [totalOpened, setTotalOpened] = useState(0);
  const [totalRead, setTotalRead] = useState(0);
  const [totalUnread, setTotalUnread] = useState(0);

  // Permission check
  const canSend = hasPermission(adminRole, 'notifications', 'create');

  useEffect(() => {
    fetchInitialData();
  }, []);

  async function fetchInitialData() {
    try {
      setLoading(true);
      
      // 1. Fetch notifications
      const { data: notifs, error: notifError } = await supabase
        .from('notifications')
        .select('*')
        .order('created_at', { ascending: false });

      if (notifError) throw notifError;
      const loadedNotifs = notifs || [];
      setNotifications(loadedNotifs);
      setTotalNotifications(loadedNotifs.length);

      // 2. Fetch recipients logs for metrics
      const { data: recips, error: recipError } = await supabase
        .from('notification_recipients')
        .select('notification_id, is_read, delivered_at, opened_at');

      if (recipError) throw recipError;
      const loadedRecips = recips || [];

      // Calculate totals
      let readCount = 0;
      let unreadCount = 0;
      let deliveredCount = 0;
      let openedCount = 0;

      // Group statistics by notification id
      const statsMap: Record<string, { sent: number; read: number; opened: number; delivered: number }> = {};
      
      loadedRecips.forEach((r) => {
        if (r.is_read) readCount++;
        else unreadCount++;
        if (r.delivered_at) deliveredCount++;
        if (r.opened_at) openedCount++;

        if (!statsMap[r.notification_id]) {
          statsMap[r.notification_id] = { sent: 0, read: 0, opened: 0, delivered: 0 };
        }
        statsMap[r.notification_id].sent++;
        if (r.is_read) statsMap[r.notification_id].read++;
        if (r.opened_at) statsMap[r.notification_id].opened++;
        if (r.delivered_at) statsMap[r.notification_id].delivered++;
      });

      setTotalRead(readCount);
      setTotalUnread(unreadCount);
      setTotalDelivered(deliveredCount);
      setTotalOpened(openedCount);
      setRecipientsStats(statsMap);

      // 3. Fetch users for individual targeting
      const { data: usersData } = await supabase
        .from('users')
        .select('id, full_name, role, email')
        .order('full_name');
      setUsers(usersData || []);

      // 4. Fetch sites from placeholders
      const { data: sitesData } = await supabase
        .from('placeholder_sites')
        .select('id, name')
        .order('name');
      setSites(sitesData || []);

    } catch (e) {
      console.error('Error fetching dashboard telemetry:', e);
    } finally {
      setLoading(false);
    }
  }

  async function handleSendNotification(e: React.FormEvent) {
    e.preventDefault();
    if (!canSend) {
      alert('Forbidden: You do not have permission to send notifications.');
      return;
    }
    if (!title || !messageText) return;

    try {
      setIsSending(true);
      setFeedback(null);

      // Resolve targets and fetch matching user IDs
      let targetedUserIds: string[] = [];

      if (targetType === 'all') {
        targetedUserIds = users.map((u) => u.id);
      } else if (targetType === 'company') {
        // If users table lacks company_id, we check user_devices for company mappings
        if (!targetCompanyId) {
          throw new Error('Please enter a target Company ID.');
        }
        const { data: deviceUsers } = await supabase
          .from('user_devices')
          .select('user_id')
          .eq('company_id', targetCompanyId);
        
        targetedUserIds = Array.from(new Set((deviceUsers || []).map((d) => d.user_id)));
      } else if (targetType === 'site') {
        if (!targetSiteId) {
          throw new Error('Please select a target work site.');
        }
        const { data: siteUsers } = await supabase
          .from('placeholder_site_assignments')
          .select('user_id')
          .eq('site_id', targetSiteId)
          .eq('is_active', true);
        
        targetedUserIds = (siteUsers || []).map((s) => s.user_id);
      } else if (targetType === 'role') {
        targetedUserIds = users
          .filter((u) => u.role?.toLowerCase() === targetRole.toLowerCase())
          .map((u) => u.id);
      } else if (targetType === 'individual') {
        if (!targetUserId) {
          throw new Error('Please select an individual recipient.');
        }
        targetedUserIds = [targetUserId];
      }

      if (targetedUserIds.length === 0) {
        throw new Error('Target selection resolved to 0 matching active users.');
      }

      // 1. Create notifications entry
      const { data: notifData, error: notifError } = await supabase
        .from('notifications')
        .insert({
          title,
          message: messageText,
          image_url: imageUrl || null,
          notification_type: notificationType,
          priority: priority as any,
          target_type: targetType as any,
          created_by: currentAdmin?.id || null,
        })
        .select()
        .single();

      if (notifError) throw notifError;

      // 2. Create recipient rows in batch
      const recipientRows = targetedUserIds.map((uid) => ({
        notification_id: notifData.id,
        user_id: uid,
        is_read: false,
      }));

      const { error: batchError } = await supabase
        .from('notification_recipients')
        .insert(recipientRows);

      if (batchError) throw batchError;

      // 3. Log action to audits
      await supabase.from('audit_logs').insert({
        actor_id: currentAdmin?.id || null,
        action: `Created notification broadcast: "${title}"`,
        target_table: 'notifications',
        new_value: { id: notifData.id, targets: targetedUserIds.length }
      });

      setFeedback({ text: `Broadcast successfully queued and dispatched to ${targetedUserIds.length} users.`, type: 'success' });
      
      // Clean form fields
      setTitle('');
      setMessageText('');
      setImageUrl('');
      
      // Refresh statistics data
      fetchInitialData();
      
      setTimeout(() => setFeedback(null), 5000);
    } catch (err: any) {
      console.error('Error dispatching notifications:', err);
      setFeedback({ text: err.message || 'Failed to dispatch notifications.', type: 'error' });
    } finally {
      setIsSending(false);
    }
  }

  async function handleDeleteNotification(id: string) {
    if (!confirm('Are you sure you want to delete this notification record? This will remove history logs for all recipients.')) return;
    try {
      const { error } = await supabase.from('notifications').delete().eq('id', id);
      if (error) throw error;
      setNotifications((prev) => prev.filter((n) => n.id !== id));
      setFeedback({ text: 'Notification history record deleted successfully.', type: 'success' });
      setTimeout(() => setFeedback(null), 3000);
    } catch (err: any) {
      console.error(err);
      setFeedback({ text: 'Failed to delete notification record.', type: 'error' });
    }
  }

  // Aggregate Chart data (Group by day)
  const getChartData = () => {
    const dailyMap: Record<string, number> = {};
    notifications.forEach((n) => {
      const dateStr = new Date(n.created_at).toLocaleDateString(undefined, { month: 'short', day: 'numeric' });
      dailyMap[dateStr] = (dailyMap[dateStr] || 0) + 1;
    });

    return Object.entries(dailyMap).reverse().map(([date, count]) => ({
      date,
      Alerts: count
    }));
  };

  const chartData = getChartData().slice(-7); // Show last 7 active days

  const readRate = totalNotifications > 0 ? Math.round((totalRead / (totalRead + totalUnread || 1)) * 100) : 0;
  const openRate = totalNotifications > 0 ? Math.round((totalOpened / (totalDelivered || 1)) * 100) : 0;

  return (
    <div className="space-y-8 pb-12">
      {/* Header */}
      <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
        <div>
          <h1 className="text-3xl font-extrabold text-slate-800 tracking-tight">Notification Center</h1>
          <p className="text-slate-500 mt-1">Multi-tenant, real-time push notification console.</p>
        </div>
        <button 
          onClick={fetchInitialData}
          className="flex items-center gap-2 text-xs font-semibold text-slate-600 bg-white hover:bg-slate-50 border border-slate-200/80 px-4 py-2.5 rounded-2xl shadow-sm transition-all duration-200 active:scale-[0.98]"
        >
          <RefreshCw className="w-4 h-4 animate-spin-slow" />
          Refresh Stats & Logs
        </button>
      </div>

      {feedback && (
        <div className={`p-4 rounded-2xl flex items-center gap-3 border text-sm max-w-4xl shadow-sm ${
          feedback.type === 'success' 
            ? 'bg-emerald-50 border-emerald-200 text-emerald-800' 
            : 'bg-rose-50 border-rose-200 text-rose-800'
        }`}>
          {feedback.type === 'success' ? <CheckCircle className="w-5 h-5 text-emerald-600" /> : <AlertTriangle className="w-5 h-5 text-rose-600" />}
          <span className="font-medium">{feedback.text}</span>
        </div>
      )}

      {/* KPI Stats Grid */}
      <div className="grid grid-cols-2 lg:grid-cols-5 gap-4">
        <div className="bg-white rounded-2xl border border-slate-100 p-5 shadow-sm space-y-1">
          <span className="block text-xs font-semibold text-slate-400 uppercase tracking-wider">Total Alerts</span>
          <div className="flex items-baseline gap-2">
            <span className="text-2xl font-black text-slate-800">{totalNotifications}</span>
            <span className="text-[10px] text-slate-400">broadcasts</span>
          </div>
        </div>
        <div className="bg-white rounded-2xl border border-slate-100 p-5 shadow-sm space-y-1">
          <span className="block text-xs font-semibold text-slate-400 uppercase tracking-wider">Delivered</span>
          <div className="flex items-baseline gap-2">
            <span className="text-2xl font-black text-slate-800">{totalDelivered}</span>
            <span className="text-[10px] text-slate-400">devices</span>
          </div>
        </div>
        <div className="bg-white rounded-2xl border border-slate-100 p-5 shadow-sm space-y-1">
          <span className="block text-xs font-semibold text-slate-400 uppercase tracking-wider">Opened</span>
          <div className="flex items-baseline gap-2">
            <span className="text-2xl font-black text-slate-800">{totalOpened}</span>
            <span className="text-[10px] text-sky-500 font-bold font-mono">{openRate}% rate</span>
          </div>
        </div>
        <div className="bg-white rounded-2xl border border-slate-100 p-5 shadow-sm space-y-1">
          <span className="block text-xs font-semibold text-slate-400 uppercase tracking-wider">Read Receipts</span>
          <div className="flex items-baseline gap-2">
            <span className="text-2xl font-black text-slate-800">{totalRead}</span>
            <span className="text-[10px] text-emerald-500 font-bold font-mono">{readRate}% rate</span>
          </div>
        </div>
        <div className="bg-white rounded-2xl border border-slate-100 p-5 shadow-sm space-y-1 col-span-2 lg:col-span-1">
          <span className="block text-xs font-semibold text-slate-400 uppercase tracking-wider">Unread Tray</span>
          <div className="flex items-baseline gap-2">
            <span className="text-2xl font-black text-slate-800">{totalUnread}</span>
            <span className="text-[10px] text-slate-400">pending action</span>
          </div>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        
        {/* Compose Panel */}
        <div className="bg-white rounded-3xl border border-slate-100 p-6 shadow-sm space-y-6 self-start">
          <div className="flex items-center gap-3 border-b border-slate-50 pb-4">
            <div className="w-10 h-10 bg-sky-50 rounded-xl flex items-center justify-center text-sky-500">
              <Bell className="w-5 h-5" />
            </div>
            <div>
              <h2 className="text-lg font-bold text-slate-800">Compose Push</h2>
              <p className="text-xs text-slate-400 font-medium">Trigger serverless multi-tenant broadcasts</p>
            </div>
          </div>

          <form onSubmit={handleSendNotification} className="space-y-4">
            <div>
              <label className="block text-xs font-bold text-slate-500 uppercase mb-2">Notification Title</label>
              <input
                type="text"
                value={title}
                onChange={(e) => setTitle(e.target.value)}
                placeholder="Alert title headline..."
                required
                disabled={!canSend || isSending}
                className="w-full bg-slate-50 border border-slate-200/80 text-slate-800 rounded-2xl py-3 px-4 text-xs focus:border-sky-500 focus:outline-none focus:ring-1 focus:ring-sky-500 transition-all"
              />
            </div>

            <div>
              <label className="block text-xs font-bold text-slate-500 uppercase mb-2">Message Body</label>
              <textarea
                value={messageText}
                onChange={(e) => setMessageText(e.target.value)}
                placeholder="Enter alert message details..."
                required
                rows={3}
                disabled={!canSend || isSending}
                className="w-full bg-slate-50 border border-slate-200/80 text-slate-800 rounded-2xl py-3 px-4 text-xs focus:border-sky-500 focus:outline-none focus:ring-1 focus:ring-sky-500 resize-none transition-all"
              />
            </div>

            <div>
              <label className="block text-xs font-bold text-slate-500 uppercase mb-2">Image URL (Optional)</label>
              <input
                type="url"
                value={imageUrl}
                onChange={(e) => setImageUrl(e.target.value)}
                placeholder="https://example.com/banner.png"
                disabled={!canSend || isSending}
                className="w-full bg-slate-50 border border-slate-200/80 text-slate-800 rounded-2xl py-3 px-4 text-xs focus:border-sky-500 focus:outline-none focus:ring-1 focus:ring-sky-500 transition-all"
              />
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-xs font-bold text-slate-500 uppercase mb-2">Type Category</label>
                <select
                  value={notificationType}
                  onChange={(e) => setNotificationType(e.target.value)}
                  disabled={!canSend || isSending}
                  className="w-full bg-slate-50 border border-slate-200/80 text-slate-800 rounded-2xl py-3 px-4 text-xs focus:border-sky-500 focus:outline-none cursor-pointer"
                >
                  <option value="broadcast">Admin Broadcast</option>
                  <option value="attendance">Attendance</option>
                  <option value="leave">Leave Request</option>
                  <option value="payroll">Payroll Alert</option>
                  <option value="site">Site Assignment</option>
                  <option value="system">System Maintenance</option>
                </select>
              </div>

              <div>
                <label className="block text-xs font-bold text-slate-500 uppercase mb-2">Priority Level</label>
                <select
                  value={priority}
                  onChange={(e) => setPriority(e.target.value)}
                  disabled={!canSend || isSending}
                  className="w-full bg-slate-50 border border-slate-200/80 text-slate-800 rounded-2xl py-3 px-4 text-xs focus:border-sky-500 focus:outline-none cursor-pointer"
                >
                  <option value="low">Low</option>
                  <option value="medium">Medium</option>
                  <option value="high">High</option>
                  <option value="critical">Critical</option>
                </select>
              </div>
            </div>

            <div className="border-t border-slate-100 pt-4 space-y-4">
              <div>
                <label className="block text-xs font-bold text-slate-500 uppercase mb-2">Target Filters</label>
                <select
                  value={targetType}
                  onChange={(e) => setTargetType(e.target.value)}
                  disabled={!canSend || isSending}
                  className="w-full bg-slate-50 border border-slate-200/80 text-slate-800 rounded-2xl py-3 px-4 text-xs focus:border-sky-500 focus:outline-none cursor-pointer"
                >
                  <option value="all">Everyone (All users)</option>
                  <option value="company">Specific Company</option>
                  <option value="site">Workers Assigned to Site</option>
                  <option value="role">Users with Role</option>
                  <option value="individual">Individual Selected User</option>
                </select>
              </div>

              {/* Dynamic Sub-filters based on type */}
              {targetType === 'company' && (
                <div>
                  <label className="block text-xs font-bold text-slate-500 uppercase mb-2">Company ID (UUID)</label>
                  <input
                    type="text"
                    value={targetCompanyId}
                    onChange={(e) => setTargetCompanyId(e.target.value)}
                    placeholder="Enter company UUID..."
                    required
                    className="w-full bg-slate-50 border border-slate-200/80 text-slate-800 rounded-2xl py-3 px-4 text-xs focus:border-sky-500 focus:outline-none"
                  />
                </div>
              )}

              {targetType === 'site' && (
                <div>
                  <label className="block text-xs font-bold text-slate-500 uppercase mb-2">Select Active Site</label>
                  <select
                    value={targetSiteId}
                    onChange={(e) => setTargetSiteId(e.target.value)}
                    required
                    className="w-full bg-slate-50 border border-slate-200/80 text-slate-800 rounded-2xl py-3 px-4 text-xs focus:border-sky-500 focus:outline-none cursor-pointer"
                  >
                    <option value="">-- Choose Site --</option>
                    {sites.map((s) => (
                      <option key={s.id} value={s.id}>{s.name}</option>
                    ))}
                  </select>
                </div>
              )}

              {targetType === 'role' && (
                <div>
                  <label className="block text-xs font-bold text-slate-500 uppercase mb-2">Select Target Role</label>
                  <select
                    value={targetRole}
                    onChange={(e) => setTargetRole(e.target.value)}
                    className="w-full bg-slate-50 border border-slate-200/80 text-slate-800 rounded-2xl py-3 px-4 text-xs focus:border-sky-500 focus:outline-none cursor-pointer"
                  >
                    <option value="Worker">Worker</option>
                    <option value="Supervisor">Supervisor</option>
                    <option value="Accountant">Accountant</option>
                    <option value="Company Admin">Company Admin</option>
                    <option value="Super Admin">Super Admin</option>
                    <option value="contractor">Contractor (Client)</option>
                    <option value="customer">Customer (Homeowner)</option>
                  </select>
                </div>
              )}

              {targetType === 'individual' && (
                <div>
                  <label className="block text-xs font-bold text-slate-500 uppercase mb-2">Select Recipient User</label>
                  <select
                    value={targetUserId}
                    onChange={(e) => setTargetUserId(e.target.value)}
                    required
                    className="w-full bg-slate-50 border border-slate-200/80 text-slate-800 rounded-2xl py-3 px-4 text-xs focus:border-sky-500 focus:outline-none cursor-pointer"
                  >
                    <option value="">-- Choose User --</option>
                    {users.map((u) => (
                      <option key={u.id} value={u.id}>
                        {u.full_name} ({u.role || 'No Role'})
                      </option>
                    ))}
                  </select>
                </div>
              )}
            </div>

            {canSend ? (
              <button
                type="submit"
                disabled={isSending}
                className="w-full bg-sky-500 hover:bg-sky-600 text-white font-bold py-3.5 rounded-2xl text-xs flex items-center justify-center gap-2 transition-all shadow-md shadow-sky-500/10 active:scale-[0.98] disabled:opacity-50"
              >
                <Send className="w-4 h-4" />
                {isSending ? 'Sending notifications...' : 'Dispatch Notification Broadcast'}
              </button>
            ) : (
              <div className="bg-rose-500/10 border border-rose-500/20 text-rose-700 text-center font-bold p-3 rounded-2xl text-xs flex items-center justify-center gap-2">
                <ShieldAlert className="w-4 h-4" />
                <span>No Permission to Broadcast</span>
              </div>
            )}
          </form>
        </div>

        {/* Analytics Chart & History Table List */}
        <div className="lg:col-span-2 space-y-8">
          
          {/* Charts stats panel */}
          <div className="bg-white rounded-3xl border border-slate-100 p-6 shadow-sm space-y-4">
            <h3 className="text-base font-bold text-slate-800 flex items-center gap-2">
              <BarChart2 className="w-5 h-5 text-slate-500" />
              Daily Dispatches Activity
            </h3>
            {chartData.length > 0 ? (
              <div className="h-64 w-full">
                <ResponsiveContainer width="100%" height="100%">
                  <AreaChart data={chartData}>
                    <defs>
                      <linearGradient id="colorAlerts" x1="0" y1="0" x2="0" y2="1">
                        <stop offset="5%" stopColor="#0284c7" stopOpacity={0.4}/>
                        <stop offset="95%" stopColor="#0284c7" stopOpacity={0.0}/>
                      </linearGradient>
                    </defs>
                    <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#f1f5f9" />
                    <XAxis dataKey="date" stroke="#94a3b8" fontSize={10} tickLine={false} />
                    <YAxis stroke="#94a3b8" fontSize={10} tickLine={false} />
                    <Tooltip contentStyle={{ background: '#0f172a', borderRadius: '12px', border: 'none', color: '#fff', fontSize: '12px' }} />
                    <Area type="monotone" dataKey="Alerts" stroke="#0284c7" strokeWidth={2.5} fillOpacity={1} fill="url(#colorAlerts)" />
                  </AreaChart>
                </ResponsiveContainer>
              </div>
            ) : (
              <div className="h-64 flex items-center justify-center text-xs text-slate-400 font-medium border border-dashed border-slate-100 rounded-2xl">
                No notification activity data in the last 7 days.
              </div>
            )}
          </div>

          {/* History log list */}
          <div className="bg-white rounded-3xl border border-slate-100 p-6 shadow-sm space-y-6">
            <div className="flex items-center justify-between border-b border-slate-50 pb-4">
              <h3 className="text-base font-bold text-slate-800 flex items-center gap-2">
                <History className="w-5 h-5 text-slate-500" />
                Notification History Logs
              </h3>
              <span className="text-[10px] text-slate-400 font-bold font-mono">
                {notifications.length} entries
              </span>
            </div>

            {loading ? (
              <div className="flex items-center justify-center p-12">
                <div className="w-8 h-8 border-3 border-sky-500 border-t-transparent rounded-full animate-spin"></div>
              </div>
            ) : (
              <div className="space-y-4 max-h-[460px] overflow-y-auto pr-2 scrollbar-thin">
                {notifications.map((n) => {
                  const stat = recipientsStats[n.id] || { sent: 0, read: 0, opened: 0, delivered: 0 };
                  const readPercent = stat.sent > 0 ? Math.round((stat.read / stat.sent) * 100) : 0;
                  const openPercent = stat.sent > 0 ? Math.round((stat.opened / stat.sent) * 100) : 0;
                  
                  return (
                    <div key={n.id} className="p-4 border border-slate-100 rounded-2xl bg-white hover:border-slate-200/80 transition-all shadow-xs relative group">
                      <div className="flex justify-between items-start gap-4">
                        <div className="space-y-1 pr-6">
                          <div className="flex items-center gap-2 flex-wrap">
                            <h4 className="text-sm font-extrabold text-slate-800">{n.title}</h4>
                            <span className={`text-[9px] font-bold px-2 py-0.5 rounded-full uppercase ${
                              n.priority === 'critical' ? 'bg-rose-50 text-rose-600' :
                              n.priority === 'high' ? 'bg-orange-50 text-orange-600' :
                              'bg-slate-50 text-slate-600'
                            }`}>
                              {n.priority}
                            </span>
                            <span className="bg-slate-100 text-[9px] text-slate-500 font-semibold px-2 py-0.5 rounded-md capitalize">
                              {n.notification_type}
                            </span>
                          </div>
                          <p className="text-xs text-slate-500 leading-normal">{n.message}</p>
                        </div>
                        
                        {/* Delete action */}
                        {canSend && (
                          <button
                            onClick={() => handleDeleteNotification(n.id)}
                            className="absolute right-3 top-3 text-slate-300 hover:text-rose-500 p-1.5 rounded-lg hover:bg-rose-50/50 transition-colors opacity-0 group-hover:opacity-100"
                            title="Delete record"
                          >
                            <Trash2 className="w-4 h-4" />
                          </button>
                        )}
                        
                        <span className="shrink-0 text-[10px] text-slate-400 font-bold font-mono">
                          {new Date(n.created_at).toLocaleDateString()}
                        </span>
                      </div>

                      <div className="grid grid-cols-2 sm:grid-cols-4 gap-2 pt-3 mt-3 border-t border-slate-50 text-[10px] font-semibold text-slate-500">
                        <div>
                          <span className="block text-slate-400 text-[9px] uppercase tracking-wide">Target Mode</span>
                          <span className="capitalize">{n.target_type}</span>
                        </div>
                        <div>
                          <span className="block text-slate-400 text-[9px] uppercase tracking-wide">Sent Recipients</span>
                          <span className="text-slate-800 font-bold font-mono">{stat.sent}</span>
                        </div>
                        <div>
                          <span className="block text-slate-400 text-[9px] uppercase tracking-wide">FCM Delivery</span>
                          <span className="text-sky-600 font-bold font-mono">{stat.delivered} ({stat.sent > 0 ? Math.round((stat.delivered/stat.sent)*100) : 0}%)</span>
                        </div>
                        <div>
                          <span className="block text-slate-400 text-[9px] uppercase tracking-wide">Read Rate</span>
                          <span className="text-emerald-600 font-bold font-mono">
                            {stat.read} ({readPercent}%)
                          </span>
                        </div>
                      </div>
                    </div>
                  );
                })}
                {notifications.length === 0 && (
                  <div className="text-center py-12 text-slate-400 text-xs font-semibold">
                    No notification history available.
                  </div>
                )}
              </div>
            )}
          </div>

        </div>

      </div>
    </div>
  );
}
