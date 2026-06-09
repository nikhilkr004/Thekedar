'use client';

import { useState, useEffect } from 'react';
import { supabase } from '@/core/supabase';
import { useAdminStore } from '@/core/store';
import { hasPermission } from '@/core/rbac';
import { Plus, Trash2, Megaphone, Image as ImageIcon, Eye, CheckCircle2 } from 'lucide-react';

interface Banner {
  id: string;
  image_url: string;
  redirect_url: string | null;
  position: number;
  is_active: boolean;
}

interface Announcement {
  id: string;
  title: string;
  message: string;
  is_active: boolean;
}

export default function CMSPage() {
  const { user: currentAdmin } = useAdminStore();
  const adminRole = currentAdmin?.role || 'Support';

  const [banners, setBanners] = useState<Banner[]>([]);
  const [announcements, setAnnouncements] = useState<Announcement[]>([]);
  const [loading, setLoading] = useState(true);

  // Form states
  const [bannerUrl, setBannerUrl] = useState('');
  const [redirectUrl, setRedirectUrl] = useState('');
  const [announcementTitle, setAnnouncementTitle] = useState('');
  const [announcementMsg, setAnnouncementMsg] = useState('');

  const canEdit = hasPermission(adminRole, 'cms', 'edit');

  useEffect(() => {
    fetchCMSContent();
  }, []);

  async function fetchCMSContent() {
    try {
      setLoading(true);
      const { data: bannerData } = await supabase.from('app_banners').select('*').order('position');
      const { data: announceData } = await supabase.from('app_announcements').select('*').order('created_at', { ascending: false });

      setBanners(bannerData || []);
      setAnnouncements(announceData || []);
    } catch (e) {
      console.error('Error fetching CMS content:', e);
    } finally {
      setLoading(false);
    }
  }

  async function handleAddBanner(e: React.FormEvent) {
    e.preventDefault();
    if (!canEdit) {
      alert('Forbidden: Insufficient privileges.');
      return;
    }
    if (!bannerUrl) return;

    try {
      const { data, error } = await supabase
        .from('app_banners')
        .insert({
          image_url: bannerUrl,
          redirect_url: redirectUrl || null,
          position: banners.length,
          is_active: true,
        })
        .select();

      if (error) throw error;
      setBanners((prev) => [...prev, ...data]);
      setBannerUrl('');
      setRedirectUrl('');
    } catch (e) {
      console.error('Error adding banner:', e);
    }
  }

  async function handleDeleteBanner(id: string) {
    if (!canEdit) return;
    try {
      const { error } = await supabase.from('app_banners').delete().eq('id', id);
      if (error) throw error;
      setBanners((prev) => prev.filter((b) => b.id !== id));
    } catch (e) {
      console.error('Error deleting banner:', e);
    }
  }

  async function handleAddAnnouncement(e: React.FormEvent) {
    e.preventDefault();
    if (!canEdit) return;
    if (!announcementTitle || !announcementMsg) return;

    try {
      const { data, error } = await supabase
        .from('app_announcements')
        .insert({
          title: announcementTitle,
          message: announcementMsg,
          is_active: true,
        })
        .select();

      if (error) throw error;
      setAnnouncements((prev) => [data[0], ...prev]);
      setAnnouncementTitle('');
      setAnnouncementMsg('');
    } catch (e) {
      console.error('Error adding announcement:', e);
    }
  }

  async function toggleAnnouncement(id: string, currentStatus: boolean) {
    if (!canEdit) return;
    try {
      const { error } = await supabase
        .from('app_announcements')
        .update({ is_active: !currentStatus })
        .eq('id', id);

      if (error) throw error;
      setAnnouncements((prev) =>
        prev.map((a) => (a.id === id ? { ...a, is_active: !currentStatus } : a))
      );
    } catch (e) {
      console.error('Error updating announcement status:', e);
    }
  }

  return (
    <div className="space-y-8">
      {/* Header */}
      <div>
        <h1 className="text-3xl font-extrabold text-slate-800 tracking-tight">App Content CMS</h1>
        <p className="text-slate-500 mt-1">Configure layout banners, announce alerts, and adjust promotional features.</p>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
        
        {/* Banners CMS Card */}
        <div className="bg-white rounded-3xl border border-slate-100 p-6 shadow-sm space-y-6">
          <div className="flex items-center justify-between border-b border-slate-50 pb-4">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 bg-sky-50 rounded-xl flex items-center justify-center text-sky-500">
                <ImageIcon className="w-5 h-5" />
              </div>
              <div>
                <h2 className="text-lg font-bold text-slate-800 font-sans">Layout Promo Banners</h2>
                <p className="text-xs text-slate-400">Carousel banners at Mobile Home screen</p>
              </div>
            </div>
          </div>

          {/* Form */}
          {canEdit && (
            <form onSubmit={handleAddBanner} className="space-y-4 bg-slate-50 p-4 rounded-2xl border border-slate-100">
              <h3 className="text-xs font-bold text-slate-400 uppercase tracking-wider">Publish New Banner</h3>
              <div>
                <input
                  type="text"
                  value={bannerUrl}
                  onChange={(e) => setBannerUrl(e.target.value)}
                  placeholder="Image URL (e.g. https://supabase.co/storage/...)"
                  className="w-full bg-white border border-slate-200 text-slate-800 rounded-xl px-4 py-2.5 text-xs focus:border-sky-500 focus:outline-none"
                />
              </div>
              <div>
                <input
                  type="text"
                  value={redirectUrl}
                  onChange={(e) => setRedirectUrl(e.target.value)}
                  placeholder="Redirect Action Link (Deep link or HTTPS / Optional)"
                  className="w-full bg-white border border-slate-200 text-slate-800 rounded-xl px-4 py-2.5 text-xs focus:border-sky-500 focus:outline-none"
                />
              </div>
              <button 
                type="submit"
                className="w-full bg-sky-500 hover:bg-sky-600 text-white font-bold py-2 rounded-xl text-xs flex items-center justify-center gap-1.5 transition-colors"
              >
                <Plus className="w-4 h-4" /> Publish Banner
              </button>
            </form>
          )}

          {/* List */}
          <div className="space-y-4 max-h-[300px] overflow-y-auto">
            {banners.map((b) => (
              <div key={b.id} className="flex items-center gap-4 p-3 border border-slate-100 rounded-2xl bg-white hover:border-slate-200 transition-colors">
                <div className="w-20 h-12 bg-slate-100 rounded-lg overflow-hidden flex items-center justify-center shrink-0 border border-slate-200">
                  {/* eslint-disable-next-line @next/next/no-img-element */}
                  <img src={b.image_url} alt="Promo" className="object-cover w-full h-full" onError={(e) => {
                    (e.target as HTMLElement).style.display = 'none';
                  }} />
                </div>
                <div className="flex-1 min-w-0">
                  <p className="text-xs font-bold text-slate-800 truncate">{b.image_url.split('/').pop() || 'Banners Promo'}</p>
                  <p className="text-[10px] text-slate-400 truncate">{b.redirect_url || 'No redirect action'}</p>
                </div>
                {canEdit && (
                  <button 
                    onClick={() => handleDeleteBanner(b.id)}
                    className="p-2 text-slate-400 hover:text-rose-500 rounded-xl hover:bg-rose-50 transition-colors shrink-0"
                  >
                    <Trash2 className="w-4 h-4" />
                  </button>
                )}
              </div>
            ))}
            {banners.length === 0 && (
              <div className="text-center py-8 text-slate-400 text-xs font-medium">No live promotional banners.</div>
            )}
          </div>
        </div>

        {/* Announcements CMS Card */}
        <div className="bg-white rounded-3xl border border-slate-100 p-6 shadow-sm space-y-6">
          <div className="flex items-center justify-between border-b border-slate-50 pb-4">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 bg-amber-50 rounded-xl flex items-center justify-center text-amber-500">
                <Megaphone className="w-5 h-5" />
              </div>
              <div>
                <h2 className="text-lg font-bold text-slate-800 font-sans">App Announcements</h2>
                <p className="text-xs text-slate-400">Broadcast updates shown in in-app alerts</p>
              </div>
            </div>
          </div>

          {/* Form */}
          {canEdit && (
            <form onSubmit={handleAddAnnouncement} className="space-y-4 bg-slate-50 p-4 rounded-2xl border border-slate-100">
              <h3 className="text-xs font-bold text-slate-400 uppercase tracking-wider">Create Announcement</h3>
              <div>
                <input
                  type="text"
                  value={announcementTitle}
                  onChange={(e) => setAnnouncementTitle(e.target.value)}
                  placeholder="Alert Title (e.g. Diwali Holiday Notice)"
                  className="w-full bg-white border border-slate-200 text-slate-800 rounded-xl px-4 py-2.5 text-xs focus:border-sky-500 focus:outline-none"
                />
              </div>
              <div>
                <textarea
                  value={announcementMsg}
                  onChange={(e) => setAnnouncementMsg(e.target.value)}
                  placeholder="Announcement message description details..."
                  rows={2}
                  className="w-full bg-white border border-slate-200 text-slate-800 rounded-xl px-4 py-2.5 text-xs focus:border-sky-500 focus:outline-none resize-none"
                />
              </div>
              <button 
                type="submit"
                className="w-full bg-amber-500 hover:bg-amber-600 text-white font-bold py-2 rounded-xl text-xs flex items-center justify-center gap-1.5 transition-colors"
              >
                <Plus className="w-4 h-4" /> Broadcast Notice
              </button>
            </form>
          )}

          {/* List */}
          <div className="space-y-4 max-h-[300px] overflow-y-auto">
            {announcements.map((a) => (
              <div key={a.id} className="p-4 border border-slate-100 rounded-2xl bg-white hover:border-slate-200 transition-colors space-y-2">
                <div className="flex justify-between items-start">
                  <h4 className="text-sm font-bold text-slate-800">{a.title}</h4>
                  <button 
                    onClick={() => toggleAnnouncement(a.id, a.is_active)}
                    className={`px-2 py-0.5 rounded-lg text-[9px] font-extrabold transition-colors border ${
                      a.is_active 
                        ? 'bg-emerald-50 border-emerald-200 text-emerald-600 hover:bg-emerald-100' 
                        : 'bg-slate-50 border-slate-200 text-slate-400 hover:bg-slate-100'
                    }`}
                  >
                    {a.is_active ? '✓ ACTIVE' : '✕ INACTIVE'}
                  </button>
                </div>
                <p className="text-xs text-slate-500 leading-normal">{a.message}</p>
              </div>
            ))}
            {announcements.length === 0 && (
              <div className="text-center py-8 text-slate-400 text-xs font-medium">No system-wide announcements broadcasted.</div>
            )}
          </div>
        </div>

      </div>
    </div>
  );
}
