'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { supabase } from '@/core/supabase';
import { useAdminStore } from '@/core/store';
import { hasPermission } from '@/core/rbac';
import { Search, Filter, Ban, CheckCircle, Trash2, ShieldAlert } from 'lucide-react';

interface UserItem {
  id: string;
  phone: string;
  email: string | null;
  full_name: string;
  role: 'customer' | 'contractor';
  city: string | null;
  state: string | null;
  property_type: string | null;
  is_active: boolean;
  created_at: string;
}

export default function UsersPage() {
  const router = useRouter();
  const { user: currentAdmin } = useAdminStore();
  const adminRole = currentAdmin?.role || 'Support';

  const [users, setUsers] = useState<UserItem[]>([]);
  const [searchTerm, setSearchTerm] = useState('');
  const [roleFilter, setRoleFilter] = useState('all');
  const [loading, setLoading] = useState(true);
  const [selectedUser, setSelectedUser] = useState<UserItem | null>(null);

  // Check permissions
  const canEdit = hasPermission(adminRole, 'users', 'edit');
  const canDelete = hasPermission(adminRole, 'users', 'delete');

  useEffect(() => {
    fetchUsers();
  }, []);

  async function fetchUsers() {
    try {
      setLoading(true);
      const { data, error } = await supabase
        .from('users')
        .select('*')
        .order('created_at', { ascending: false });

      if (error) throw error;
      setUsers(data || []);
    } catch (e) {
      console.error('Error fetching users:', e);
    } finally {
      setLoading(false);
    }
  }

  async function toggleUserActive(userId: string, currentStatus: boolean) {
    if (!canEdit) {
      alert('Forbidden: You do not have permission to edit users.');
      return;
    }
    try {
      const { error } = await supabase
        .from('users')
        .update({ is_active: !currentStatus })
        .eq('id', userId);

      if (error) throw error;

      // Update local state
      setUsers((prev) =>
        prev.map((u) => (u.id === userId ? { ...u, is_active: !currentStatus } : u))
      );
      if (selectedUser?.id === userId) {
        setSelectedUser((prev) => prev ? { ...prev, is_active: !currentStatus } : null);
      }
    } catch (e) {
      console.error('Error updating user status:', e);
    }
  }

  async function deleteUser(userId: string) {
    if (!canDelete) {
      alert('Forbidden: You do not have permission to delete users.');
      return;
    }
    if (!confirm('Are you sure you want to permanently delete this user? This action is irreversible.')) {
      return;
    }
    try {
      const { error } = await supabase
        .from('users')
        .delete()
        .eq('id', userId);

      if (error) throw error;

      setUsers((prev) => prev.filter((u) => u.id !== userId));
      setSelectedUser(null);
    } catch (e) {
      console.error('Error deleting user:', e);
    }
  }

  const filteredUsers = users.filter((u) => {
    const matchesSearch =
      u.full_name.toLowerCase().includes(searchTerm.toLowerCase()) ||
      u.phone.includes(searchTerm) ||
      (u.email?.toLowerCase().includes(searchTerm.toLowerCase()) ?? false);
    
    const matchesRole = roleFilter === 'all' ? true : u.role === roleFilter;

    return matchesSearch && matchesRole;
  });

  return (
    <div className="space-y-8">
      {/* Page Header */}
      <div>
        <h1 className="text-3xl font-extrabold text-slate-800 tracking-tight">User Management</h1>
        <p className="text-slate-500 mt-1">Suspend, activate, verify, or review platform user registration details.</p>
      </div>

      {/* Action Filters Bar */}
      <div className="flex flex-col md:flex-row gap-4 bg-white p-5 rounded-3xl border border-slate-100 shadow-sm justify-between">
        <div className="flex flex-1 gap-4">
          <div className="relative flex-1 max-w-md">
            <Search className="absolute left-4 top-3 w-5 h-5 text-slate-400" />
            <input
              type="text"
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              placeholder="Search by name, email, or phone number..."
              className="w-full bg-slate-50 border border-slate-200/80 text-slate-800 rounded-2xl py-2.5 pl-12 pr-4 text-sm focus:border-sky-500 focus:outline-none transition-colors"
            />
          </div>
          
          <div className="relative max-w-xs flex items-center bg-slate-50 border border-slate-200/80 rounded-2xl px-4 py-2.5 text-sm gap-2">
            <Filter className="w-4 h-4 text-slate-400" />
            <select
              value={roleFilter}
              onChange={(e) => setRoleFilter(e.target.value)}
              className="bg-transparent text-slate-700 outline-none font-medium cursor-pointer"
            >
              <option value="all">All Roles</option>
              <option value="customer">Customers</option>
              <option value="contractor">Contractors</option>
            </select>
          </div>
        </div>

        <button 
          onClick={fetchUsers} 
          className="bg-slate-100 hover:bg-slate-200 text-slate-700 font-bold px-5 py-2.5 rounded-2xl text-sm transition-colors"
        >
          Refresh List
        </button>
      </div>

      {/* Main UI layout (split when user selected) */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        <div className={`bg-white rounded-3xl border border-slate-100 p-6 shadow-sm overflow-hidden ${
          selectedUser ? 'lg:col-span-2' : 'lg:col-span-3'
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
                    <th className="p-4 rounded-l-2xl">Name</th>
                    <th className="p-4">Contact</th>
                    <th className="p-4">Role</th>
                    <th className="p-4">Status</th>
                    <th className="p-4 rounded-r-2xl">Registered</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100">
                  {filteredUsers.map((u) => (
                    <tr 
                      key={u.id} 
                      onClick={() => setSelectedUser(u)}
                      className={`hover:bg-slate-50/80 cursor-pointer transition-colors ${
                        selectedUser?.id === u.id ? 'bg-slate-50 font-bold' : ''
                      }`}
                    >
                      <td className="p-4">
                        <div className="font-bold text-slate-800">{u.full_name}</div>
                        <div className="text-xs text-slate-400">{u.email || 'No email associated'}</div>
                      </td>
                      <td className="p-4 font-mono text-slate-700">{u.phone}</td>
                      <td className="p-4 uppercase tracking-wider text-xs">
                        <span className={`px-2 py-1 rounded-lg font-extrabold ${
                          u.role === 'contractor' 
                            ? 'bg-amber-50 text-amber-700 border border-amber-200' 
                            : 'bg-blue-50 text-blue-700 border border-blue-200'
                        }`}>
                          {u.role}
                        </span>
                      </td>
                      <td className="p-4">
                        <span className={`inline-flex items-center gap-1 text-xs font-bold ${
                          u.is_active ? 'text-emerald-600' : 'text-rose-500'
                        }`}>
                          <span className={`w-2 h-2 rounded-full ${u.is_active ? 'bg-emerald-500' : 'bg-rose-500'}`} />
                          {u.is_active ? 'Active' : 'Suspended'}
                        </span>
                      </td>
                      <td className="p-4 text-slate-400 font-mono text-xs">
                        {new Date(u.created_at).toLocaleDateString()}
                      </td>
                    </tr>
                  ))}
                  {filteredUsers.length === 0 && (
                    <tr>
                      <td colSpan={5} className="p-8 text-center text-slate-400">
                        No registered users match your criteria.
                      </td>
                    </tr>
                  )}
                </tbody>
              </table>
            </div>
          )}
        </div>

        {/* Selected Profile View Drawer Panel */}
        {selectedUser && (
          <div className="bg-white rounded-3xl border border-slate-100 p-6 shadow-sm flex flex-col justify-between h-fit space-y-6">
            <div>
              <div className="flex justify-between items-start">
                <h2 className="text-lg font-bold text-slate-800">User Profile Context</h2>
                <button 
                  onClick={() => setSelectedUser(null)}
                  className="text-slate-400 hover:text-slate-600 font-bold"
                >
                  ✕
                </button>
              </div>
              
              <div className="mt-6 space-y-4">
                <div className="flex items-center gap-4">
                  <div className="w-14 h-14 bg-gradient-to-tr from-sky-400 to-sky-600 text-white rounded-2xl flex items-center justify-center font-extrabold text-lg">
                    {selectedUser.full_name[0].toUpperCase()}
                  </div>
                  <div>
                    <h3 className="font-bold text-slate-800">{selectedUser.full_name}</h3>
                    <p className="text-xs text-sky-600 font-bold uppercase tracking-wider">{selectedUser.role}</p>
                  </div>
                </div>

                <div className="border-t border-slate-100 pt-4 space-y-3">
                  <div>
                    <span className="text-xs text-slate-400 font-semibold block uppercase">Phone Number</span>
                    <span className="text-sm font-mono text-slate-700">{selectedUser.phone}</span>
                  </div>
                  <div>
                    <span className="text-xs text-slate-400 font-semibold block uppercase">Operating City</span>
                    <span className="text-sm text-slate-700">{selectedUser.city || 'Not provided'}, {selectedUser.state || ''}</span>
                  </div>
                  {selectedUser.role === 'customer' && (
                    <div>
                      <span className="text-xs text-slate-400 font-semibold block uppercase">Property Segment</span>
                      <span className="text-sm text-slate-700 capitalize">{selectedUser.property_type || 'Individual'}</span>
                    </div>
                  )}
                  <div>
                    <span className="text-xs text-slate-400 font-semibold block uppercase">Internal UUID Key</span>
                    <span className="text-[10px] font-mono text-slate-400 select-all">{selectedUser.id}</span>
                  </div>
                </div>
              </div>
            </div>

            {/* Action buttons wrapper */}
            <div className="space-y-3 pt-6 border-t border-slate-100">
              {selectedUser.role === 'contractor' && (
                <button
                  onClick={() => router.push(`/users/${selectedUser.id}`)}
                  className="w-full bg-gradient-to-tr from-sky-500 to-sky-600 hover:from-sky-600 hover:to-sky-700 text-white py-2.5 rounded-xl font-extrabold text-sm transition-all flex items-center justify-center gap-2 shadow-sm mb-3"
                >
                  <ShieldAlert className="w-4 h-4" /> Review & Verify Profile
                </button>
              )}
              <button
                onClick={() => toggleUserActive(selectedUser.id, selectedUser.is_active)}
                className={`w-full py-2.5 rounded-xl font-bold text-sm transition-colors flex items-center justify-center gap-2 border ${
                  selectedUser.is_active
                    ? 'bg-rose-50 border-rose-200 text-rose-600 hover:bg-rose-100'
                    : 'bg-emerald-50 border-emerald-200 text-emerald-600 hover:bg-emerald-100'
                }`}
              >
                {selectedUser.is_active ? (
                  <>
                    <Ban className="w-4 h-4" /> Suspend Account
                  </>
                ) : (
                  <>
                    <CheckCircle className="w-4 h-4" /> Activate Account
                  </>
                )}
              </button>

              <button
                onClick={() => deleteUser(selectedUser.id)}
                className="w-full bg-slate-50 hover:bg-rose-50 border border-slate-200 hover:border-rose-200 text-slate-500 hover:text-rose-600 py-2.5 rounded-xl font-bold text-sm transition-colors flex items-center justify-center gap-2"
              >
                <Trash2 className="w-4 h-4" /> Delete Profile
              </button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
