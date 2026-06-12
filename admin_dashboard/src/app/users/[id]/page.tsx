'use client';

import { useState, useEffect } from 'react';
import { useParams, useRouter } from 'next/navigation';
import { supabase } from '@/core/supabase';
import { useAdminStore } from '@/core/store';
import { hasPermission } from '@/core/rbac';
import { 
  ArrowLeft, ShieldCheck, ShieldAlert, Award, Calendar, 
  MapPin, Phone, Mail, FileText, CheckCircle2, XCircle, 
  AlertCircle, ExternalLink, HardDrive, RefreshCw, ZoomIn
} from 'lucide-react';

interface UserData {
  id: string;
  phone: string;
  email: string | null;
  full_name: string;
  role: string;
  city: string | null;
  state: string | null;
  profile_photo_url: string | null;
  is_active: boolean;
  created_at: string;
  address: string | null;
}

interface ContractorData {
  id: string;
  business_name: string | null;
  bio: string | null;
  years_experience: number | null;
  categories: string[] | null;
  service_areas: string[] | null;
  cities_covered: string[] | null;
  trust_score: number | null;
  projects_completed: number | null;
  status: string;
  profile_completion_percentage: number;
  aadhaar_doc_url: string | null;
  pan_doc_url: string | null;
  gst_doc_url: string | null;
  portfolio_urls: string[] | null;
  social_links: any | null;
  aadhaar_verified: boolean;
  pan_verified: boolean;
  gst_verified: boolean;
}

export default function ContractorReviewPage() {
  const { id: userId } = useParams() as { id: string };
  const router = useRouter();
  const { user: currentAdmin } = useAdminStore();
  const adminRole = currentAdmin?.role || 'Support';

  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [userData, setUserData] = useState<UserData | null>(null);
  const [contractorData, setContractorData] = useState<ContractorData | null>(null);
  
  // Local state for actions
  const [currentStatus, setCurrentStatus] = useState('DRAFT');
  const [rejectionReason, setRejectionReason] = useState('');
  const [zoomDocument, setZoomDocument] = useState<string | null>(null);
  const [reviewNotes, setReviewNotes] = useState({
    aadhaar: '',
    pan: '',
    gst: ''
  });

  const canEdit = hasPermission(adminRole, 'users', 'edit');

  useEffect(() => {
    fetchData();
  }, [userId]);

  async function fetchData() {
    try {
      setLoading(true);
      // 1. Fetch main user profile
      const { data: user, error: userError } = await supabase
        .from('users')
        .select('*')
        .eq('id', userId)
        .single();

      if (userError) throw userError;
      setUserData(user);

      // 2. Fetch contractor details
      const { data: contractor, error: contractorError } = await supabase
        .from('contractors')
        .select('*')
        .eq('user_id', userId)
        .maybeSingle();

      if (contractorError) throw contractorError;
      setContractorData(contractor);

      if (contractor) {
        setCurrentStatus(contractor.status || 'DRAFT');
      }
    } catch (e) {
      console.error('Error fetching contractor data:', e);
    } finally {
      setLoading(false);
    }
  }

  async function handleStatusChange(statusValue: string) {
    if (!canEdit) {
      alert('Forbidden: You do not have permission to verify contractors.');
      return;
    }
    if (!contractorData) return;

    if ((statusValue === 'REJECTED' || statusValue === 'BLOCKED') && !rejectionReason.trim()) {
      alert('Please provide a reason or note for rejecting/blocking this account.');
      return;
    }

    try {
      setSaving(true);

      // 1. Update contractor status in DB
      const { error: contractorUpdateError } = await supabase
        .from('contractors')
        .update({ status: statusValue })
        .eq('id', contractorData.id);

      if (contractorUpdateError) throw contractorUpdateError;

      // 2. Map contractor status to main user is_active boolean
      const isActiveStatus = !['SUSPENDED', 'BLOCKED', 'REJECTED'].includes(statusValue);
      const { error: userUpdateError } = await supabase
        .from('users')
        .update({ is_active: isActiveStatus })
        .eq('id', userId);

      if (userUpdateError) throw userUpdateError;

      // 3. Write immutable verification audit log
      const { error: logError } = await supabase
        .from('contractor_verification_logs')
        .insert({
          contractor_id: contractorData.id,
          admin_id: currentAdmin?.id || userId, // Fallback if admin ID missing
          action: 'STATUS_CHANGE',
          previous_status: contractorData.status,
          new_status: statusValue,
          reason: rejectionReason || `Status updated to ${statusValue} by admin`
        });

      if (logError) console.error('Failed to write audit log:', logError);

      // 4. Automatically initialize credit wallet if approved
      if (statusValue === 'APPROVED' || statusValue === 'ACTIVE') {
        const { data: wallet } = await supabase
          .from('credit_wallets')
          .select('id')
          .eq('contractor_id', contractorData.id)
          .maybeSingle();

        if (!wallet) {
          await supabase.from('credit_wallets').insert({
            contractor_id: contractorData.id,
            balance: 50, // Welcome credits allocation
            total_purchased: 0,
            total_spent: 0,
            total_earned: 0
          });
        }
      }

      alert('Contractor verification status updated successfully.');
      fetchData(); // Reload latest data
      setRejectionReason('');
    } catch (e) {
      console.error('Error updating status:', e);
      alert('Error updating status. Please try again.');
    } finally {
      setSaving(false);
    }
  }

  async function toggleDocumentVerify(docType: 'aadhaar' | 'pan' | 'gst', isVerified: boolean) {
    if (!canEdit || !contractorData) return;

    try {
      setSaving(true);
      const updatePayload: any = {};
      updatePayload[`${docType}_verified`] = isVerified;

      const { error } = await supabase
        .from('contractors')
        .update(updatePayload)
        .eq('id', contractorData.id);

      if (error) throw error;

      setContractorData(prev => prev ? { ...prev, ...updatePayload } : null);
    } catch (e) {
      console.error('Error toggling document verification:', e);
    } finally {
      setSaving(false);
    }
  }

  if (loading) {
    return (
      <div className="flex flex-col items-center justify-center min-h-[50vh] space-y-4">
        <div className="w-12 h-12 border-4 border-sky-500 border-t-transparent rounded-full animate-spin"></div>
        <p className="text-slate-500 text-sm font-semibold">Loading verification details...</p>
      </div>
    );
  }

  if (!userData) {
    return (
      <div className="bg-rose-50 border border-rose-100 rounded-3xl p-8 text-center text-rose-600 max-w-xl mx-auto mt-12">
        <AlertCircle className="w-12 h-12 mx-auto mb-4" />
        <h3 className="text-lg font-bold">User Profile Not Found</h3>
        <p className="text-sm mt-1">The user session or profile identifier is invalid or does not exist in the database.</p>
        <button onClick={() => router.push('/users')} className="mt-6 bg-rose-600 hover:bg-rose-700 text-white font-bold px-6 py-2.5 rounded-2xl text-sm transition-colors">
          Return to Users list
        </button>
      </div>
    );
  }

  return (
    <div className="space-y-8 max-w-7xl mx-auto pb-12">
      {/* Navigation Header */}
      <div className="flex flex-col md:flex-row gap-4 items-start md:items-center justify-between">
        <div className="flex items-center gap-4">
          <button 
            onClick={() => router.push('/users')}
            className="p-3 bg-white border border-slate-100 hover:bg-slate-50 rounded-2xl shadow-sm transition-colors text-slate-600"
          >
            <ArrowLeft className="w-5 h-5" />
          </button>
          <div>
            <div className="flex items-center gap-2">
              <h1 className="text-2xl font-extrabold text-slate-800 tracking-tight">{userData.full_name}</h1>
              <span className={`text-[10px] font-extrabold uppercase px-2.5 py-1 rounded-full border ${
                userData.role === 'contractor' 
                  ? 'bg-amber-50 text-amber-700 border-amber-200' 
                  : 'bg-blue-50 text-blue-700 border-blue-200'
              }`}>
                {userData.role}
              </span>
            </div>
            <p className="text-slate-400 text-sm mt-0.5">Verification Workspace & Security Audit</p>
          </div>
        </div>

        {/* Global status banner */}
        {contractorData && (
          <div className={`px-5 py-3 rounded-2xl border flex items-center gap-3 ${
            contractorData.status === 'APPROVED' || contractorData.status === 'ACTIVE'
              ? 'bg-emerald-50 border-emerald-100 text-emerald-700'
              : contractorData.status === 'REJECTED' || contractorData.status === 'BLOCKED'
              ? 'bg-rose-50 border-rose-100 text-rose-700'
              : 'bg-amber-50 border-amber-100 text-amber-700'
          }`}>
            {contractorData.status === 'APPROVED' || contractorData.status === 'ACTIVE' ? (
              <ShieldCheck className="w-5 h-5" />
            ) : (
              <ShieldAlert className="w-5 h-5" />
            )}
            <div>
              <span className="text-xs font-bold uppercase block tracking-wider leading-none">Marketplace Status</span>
              <span className="text-sm font-extrabold">{contractorData.status}</span>
            </div>
          </div>
        )}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        
        {/* Profile Details (Left 2 cols) */}
        <div className="lg:col-span-2 space-y-8">
          
          {/* Main profile card info */}
          <div className="bg-white rounded-3xl border border-slate-100 p-6 shadow-sm space-y-6">
            <div className="flex items-center gap-6">
              <div className="w-20 h-20 bg-gradient-to-tr from-sky-400 to-sky-600 rounded-3xl flex items-center justify-center text-white text-3xl font-extrabold shadow-md">
                {userData.full_name[0].toUpperCase()}
              </div>
              <div className="space-y-1">
                <h3 className="text-lg font-bold text-slate-800">{contractorData?.business_name || 'No Business Name'}</h3>
                <p className="text-slate-500 text-sm flex items-center gap-1.5">
                  <MapPin className="w-4 h-4 text-slate-400" />
                  {userData.city || 'No operating city'}, {userData.state || ''}
                </p>
                {contractorData && (
                  <div className="flex items-center gap-2 mt-1">
                    <div className="w-28 bg-slate-100 rounded-full h-2 overflow-hidden">
                      <div className="bg-sky-500 h-2" style={{ width: `${contractorData.profile_completion_percentage}%` }}></div>
                    </div>
                    <span className="text-xs font-bold text-slate-500">{contractorData.profile_completion_percentage}% Profile Complete</span>
                  </div>
                )}
              </div>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-6 pt-6 border-t border-slate-50">
              <div className="flex items-center gap-3">
                <div className="p-3 bg-slate-50 rounded-2xl text-slate-500"><Phone className="w-5 h-5" /></div>
                <div>
                  <span className="text-xs text-slate-400 font-semibold block">Phone Number</span>
                  <span className="text-sm font-mono font-bold text-slate-700">{userData.phone}</span>
                </div>
              </div>
              <div className="flex items-center gap-3">
                <div className="p-3 bg-slate-50 rounded-2xl text-slate-500"><Mail className="w-5 h-5" /></div>
                <div>
                  <span className="text-xs text-slate-400 font-semibold block">Email Address</span>
                  <span className="text-sm font-semibold text-slate-700">{userData.email || 'None'}</span>
                </div>
              </div>
              <div className="flex items-center gap-3">
                <div className="p-3 bg-slate-50 rounded-2xl text-slate-500"><Award className="w-5 h-5" /></div>
                <div>
                  <span className="text-xs text-slate-400 font-semibold block">Years of Experience</span>
                  <span className="text-sm font-bold text-slate-700">{contractorData?.years_experience ?? 0} Years</span>
                </div>
              </div>
              <div className="flex items-center gap-3">
                <div className="p-3 bg-slate-50 rounded-2xl text-slate-500"><Calendar className="w-5 h-5" /></div>
                <div>
                  <span className="text-xs text-slate-400 font-semibold block">Registered Since</span>
                  <span className="text-sm font-mono text-slate-700">{new Date(userData.created_at).toLocaleDateString()}</span>
                </div>
              </div>
            </div>

            {contractorData?.bio && (
              <div className="pt-6 border-t border-slate-50 space-y-2">
                <span className="text-xs text-slate-400 font-bold uppercase tracking-wider block">Bio / Description</span>
                <p className="text-sm text-slate-600 leading-relaxed bg-slate-50/50 p-4 rounded-2xl border border-slate-100">{contractorData.bio}</p>
              </div>
            )}

            {/* Specialties & Areas */}
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6 pt-6 border-t border-slate-50">
              <div>
                <span className="text-xs text-slate-400 font-bold uppercase tracking-wider block mb-2">Service Categories</span>
                <div className="flex flex-wrap gap-2">
                  {contractorData?.categories && contractorData.categories.length > 0 ? (
                    contractorData.categories.map((c, i) => (
                      <span key={i} className="px-3 py-1 bg-slate-100 text-slate-600 rounded-lg text-xs font-bold">{c}</span>
                    ))
                  ) : (
                    <span className="text-xs text-slate-400 italic">None defined</span>
                  )}
                </div>
              </div>
              <div>
                <span className="text-xs text-slate-400 font-bold uppercase tracking-wider block mb-2">Service Areas</span>
                <div className="flex flex-wrap gap-2">
                  {contractorData?.service_areas && contractorData.service_areas.length > 0 ? (
                    contractorData.service_areas.map((a, i) => (
                      <span key={i} className="px-3 py-1 bg-sky-50 text-sky-700 rounded-lg text-xs font-bold">{a}</span>
                    ))
                  ) : (
                    <span className="text-xs text-slate-400 italic">None defined</span>
                  )}
                </div>
              </div>
            </div>
          </div>

          {/* Verification documents review Workspace */}
          <div className="space-y-6">
            <h3 className="text-lg font-bold text-slate-800 flex items-center gap-2">
              <FileText className="w-5 h-5 text-slate-500" />
              Uploaded KYC Documents
            </h3>

            {contractorData ? (
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                
                {/* Aadhaar Card */}
                <div className="bg-white rounded-3xl border border-slate-100 p-6 shadow-sm space-y-4 flex flex-col justify-between">
                  <div className="space-y-2">
                    <div className="flex justify-between items-center">
                      <span className="text-sm font-bold text-slate-800">Aadhaar Document</span>
                      <span className={`text-xs font-bold px-2 py-0.5 rounded-lg border ${
                        contractorData.aadhaar_verified 
                          ? 'bg-emerald-50 text-emerald-700 border-emerald-200' 
                          : 'bg-rose-50 text-rose-700 border-rose-200'
                      }`}>
                        {contractorData.aadhaar_verified ? 'Verified' : 'Unverified'}
                      </span>
                    </div>
                    <p className="text-xs text-slate-400 font-medium">Verify Aadhaar number matching identity proof.</p>
                  </div>

                  {contractorData.aadhaar_doc_url ? (
                    <div className="space-y-3">
                      <div className="relative group aspect-video bg-slate-50 border border-slate-100 rounded-2xl overflow-hidden flex items-center justify-center">
                        <img 
                          src={contractorData.aadhaar_doc_url} 
                          alt="Aadhaar doc" 
                          className="object-cover w-full h-full"
                        />
                        <button 
                          onClick={() => setZoomDocument(contractorData.aadhaar_doc_url)}
                          className="absolute inset-0 bg-black/40 opacity-0 group-hover:opacity-100 flex items-center justify-center gap-2 text-white font-semibold text-xs transition-opacity duration-200 rounded-2xl"
                        >
                          <ZoomIn className="w-5 h-5" /> Zoom Document
                        </button>
                      </div>

                      <div className="flex gap-2">
                        <button 
                          onClick={() => toggleDocumentVerify('aadhaar', true)}
                          disabled={saving}
                          className="flex-1 bg-emerald-50 border border-emerald-200 hover:bg-emerald-100 text-emerald-700 text-xs font-bold py-2 rounded-xl transition-colors"
                        >
                          Verify Doc
                        </button>
                        <button 
                          onClick={() => toggleDocumentVerify('aadhaar', false)}
                          disabled={saving}
                          className="flex-1 bg-rose-50 border border-rose-200 hover:bg-rose-100 text-rose-700 text-xs font-bold py-2 rounded-xl transition-colors"
                        >
                          Reject Doc
                        </button>
                      </div>
                    </div>
                  ) : (
                    <div className="border border-dashed border-slate-200/80 rounded-2xl p-6 text-center text-slate-400 text-xs font-semibold">
                      Not uploaded yet
                    </div>
                  )}
                </div>

                {/* PAN Card */}
                <div className="bg-white rounded-3xl border border-slate-100 p-6 shadow-sm space-y-4 flex flex-col justify-between">
                  <div className="space-y-2">
                    <div className="flex justify-between items-center">
                      <span className="text-sm font-bold text-slate-800">PAN Document</span>
                      <span className={`text-xs font-bold px-2 py-0.5 rounded-lg border ${
                        contractorData.pan_verified 
                          ? 'bg-emerald-50 text-emerald-700 border-emerald-200' 
                          : 'bg-rose-50 text-rose-700 border-rose-200'
                      }`}>
                        {contractorData.pan_verified ? 'Verified' : 'Unverified'}
                      </span>
                    </div>
                    <p className="text-xs text-slate-400 font-medium">Verify Permanent Account Number validation.</p>
                  </div>

                  {contractorData.pan_doc_url ? (
                    <div className="space-y-3">
                      <div className="relative group aspect-video bg-slate-50 border border-slate-100 rounded-2xl overflow-hidden flex items-center justify-center">
                        <img 
                          src={contractorData.pan_doc_url} 
                          alt="PAN doc" 
                          className="object-cover w-full h-full"
                        />
                        <button 
                          onClick={() => setZoomDocument(contractorData.pan_doc_url)}
                          className="absolute inset-0 bg-black/40 opacity-0 group-hover:opacity-100 flex items-center justify-center gap-2 text-white font-semibold text-xs transition-opacity duration-200 rounded-2xl"
                        >
                          <ZoomIn className="w-5 h-5" /> Zoom Document
                        </button>
                      </div>

                      <div className="flex gap-2">
                        <button 
                          onClick={() => toggleDocumentVerify('pan', true)}
                          disabled={saving}
                          className="flex-1 bg-emerald-50 border border-emerald-200 hover:bg-emerald-100 text-emerald-700 text-xs font-bold py-2 rounded-xl transition-colors"
                        >
                          Verify Doc
                        </button>
                        <button 
                          onClick={() => toggleDocumentVerify('pan', false)}
                          disabled={saving}
                          className="flex-1 bg-rose-50 border border-rose-200 hover:bg-rose-100 text-rose-700 text-xs font-bold py-2 rounded-xl transition-colors"
                        >
                          Reject Doc
                        </button>
                      </div>
                    </div>
                  ) : (
                    <div className="border border-dashed border-slate-200/80 rounded-2xl p-6 text-center text-slate-400 text-xs font-semibold">
                      Not uploaded yet
                    </div>
                  )}
                </div>

                {/* GST Invoice */}
                <div className="bg-white rounded-3xl border border-slate-100 p-6 shadow-sm space-y-4 flex flex-col justify-between">
                  <div className="space-y-2">
                    <div className="flex justify-between items-center">
                      <span className="text-sm font-bold text-slate-800">GST Registration</span>
                      <span className={`text-xs font-bold px-2 py-0.5 rounded-lg border ${
                        contractorData.gst_verified 
                          ? 'bg-emerald-50 text-emerald-700 border-emerald-200' 
                          : 'bg-rose-50 text-rose-700 border-rose-200'
                      }`}>
                        {contractorData.gst_verified ? 'Verified' : 'Unverified'}
                      </span>
                    </div>
                    <p className="text-xs text-slate-400 font-medium">Verify Goods and Services Tax credentials.</p>
                  </div>

                  {contractorData.gst_doc_url ? (
                    <div className="space-y-3">
                      <div className="relative group aspect-video bg-slate-50 border border-slate-100 rounded-2xl overflow-hidden flex items-center justify-center">
                        <img 
                          src={contractorData.gst_doc_url} 
                          alt="GST doc" 
                          className="object-cover w-full h-full"
                        />
                        <button 
                          onClick={() => setZoomDocument(contractorData.gst_doc_url)}
                          className="absolute inset-0 bg-black/40 opacity-0 group-hover:opacity-100 flex items-center justify-center gap-2 text-white font-semibold text-xs transition-opacity duration-200 rounded-2xl"
                        >
                          <ZoomIn className="w-5 h-5" /> Zoom Document
                        </button>
                      </div>

                      <div className="flex gap-2">
                        <button 
                          onClick={() => toggleDocumentVerify('gst', true)}
                          disabled={saving}
                          className="flex-1 bg-emerald-50 border border-emerald-200 hover:bg-emerald-100 text-emerald-700 text-xs font-bold py-2 rounded-xl transition-colors"
                        >
                          Verify Doc
                        </button>
                        <button 
                          onClick={() => toggleDocumentVerify('gst', false)}
                          disabled={saving}
                          className="flex-1 bg-rose-50 border border-rose-200 hover:bg-rose-100 text-rose-700 text-xs font-bold py-2 rounded-xl transition-colors"
                        >
                          Reject Doc
                        </button>
                      </div>
                    </div>
                  ) : (
                    <div className="border border-dashed border-slate-200/80 rounded-2xl p-6 text-center text-slate-400 text-xs font-semibold">
                      Not uploaded yet
                    </div>
                  )}
                </div>

                {/* Portfolio Project Images */}
                <div className="bg-white rounded-3xl border border-slate-100 p-6 shadow-sm space-y-4 flex flex-col justify-between">
                  <div className="space-y-2">
                    <span className="text-sm font-bold text-slate-800">Featured Portfolios</span>
                    <p className="text-xs text-slate-400 font-medium">Verify completed project images uploaded by user.</p>
                  </div>

                  {contractorData.portfolio_urls && contractorData.portfolio_urls.length > 0 ? (
                    <div className="grid grid-cols-3 gap-2">
                      {contractorData.portfolio_urls.slice(0, 6).map((url, index) => (
                        <div 
                          key={index}
                          onClick={() => setZoomDocument(url)}
                          className="aspect-square bg-slate-50 border border-slate-100 rounded-xl overflow-hidden cursor-pointer hover:opacity-85 transition-opacity"
                        >
                          <img src={url} alt={`Portfolio ${index}`} className="object-cover w-full h-full" />
                        </div>
                      ))}
                    </div>
                  ) : (
                    <div className="border border-dashed border-slate-200/80 rounded-2xl p-6 text-center text-slate-400 text-xs font-semibold">
                      No projects added yet
                    </div>
                  )}
                </div>
              </div>
            ) : (
              <p className="text-sm text-slate-500 italic">No contractor data details found.</p>
            )}
          </div>
        </div>

        {/* Verification Status Control Sidebar Panel */}
        <div className="space-y-8">
          
          {/* Main action selector status */}
          <div className="bg-white rounded-3xl border border-slate-100 p-6 shadow-sm space-y-6">
            <h3 className="text-md font-bold text-slate-800 uppercase tracking-wider">Update Account Status</h3>

            <div className="space-y-4">
              <div>
                <label className="text-xs text-slate-400 font-semibold block uppercase mb-1.5">Verification Status</label>
                <select 
                  value={currentStatus}
                  onChange={(e) => setCurrentStatus(e.target.value)}
                  className="w-full bg-slate-50 border border-slate-200/80 rounded-xl px-4 py-2.5 text-sm outline-none text-slate-700 font-semibold focus:border-sky-500 transition-colors cursor-pointer"
                >
                  <option value="DRAFT">DRAFT</option>
                  <option value="PROFILE_INCOMPLETE">PROFILE_INCOMPLETE</option>
                  <option value="READY_FOR_SUBMISSION">READY_FOR_SUBMISSION</option>
                  <option value="PENDING_VERIFICATION">PENDING_VERIFICATION</option>
                  <option value="UNDER_REVIEW">UNDER_REVIEW</option>
                  <option value="APPROVED">APPROVED (Active Marketplace)</option>
                  <option value="ACTIVE">ACTIVE</option>
                  <option value="REJECTED">REJECTED</option>
                  <option value="SUSPENDED">SUSPENDED</option>
                  <option value="BLOCKED">BLOCKED</option>
                </select>
              </div>

              <div>
                <label className="text-xs text-slate-400 font-semibold block uppercase mb-1.5">Rejection / Suspended Reason</label>
                <textarea 
                  rows={4}
                  value={rejectionReason}
                  onChange={(e) => setRejectionReason(e.target.value)}
                  placeholder="Provide precise review notes or reasons for rejection..."
                  className="w-full bg-slate-50 border border-slate-200/80 rounded-xl p-4 text-xs outline-none text-slate-700 focus:border-sky-500 transition-colors resize-none leading-relaxed"
                />
              </div>

              <button 
                onClick={() => handleStatusChange(currentStatus)}
                disabled={saving || !contractorData}
                className="w-full bg-gradient-to-tr from-sky-500 to-sky-600 hover:from-sky-600 hover:to-sky-700 text-white font-extrabold text-sm py-3 rounded-xl shadow-sm transition-all flex items-center justify-center gap-2 cursor-pointer disabled:opacity-50"
              >
                {saving ? (
                  <RefreshCw className="w-4 h-4 animate-spin" />
                ) : (
                  'Apply Verification State'
                )}
              </button>
            </div>
          </div>

          {/* Verification requirements checklist summary */}
          <div className="bg-white rounded-3xl border border-slate-100 p-6 shadow-sm space-y-4">
            <h3 className="text-xs font-extrabold text-slate-500 uppercase tracking-wider">Verification Checklist</h3>
            
            {contractorData ? (
              <div className="space-y-3.5">
                <div className="flex items-center justify-between text-xs">
                  <span className="text-slate-500">Profile Completion Percentage</span>
                  <span className={`font-bold ${contractorData.profile_completion_percentage >= 80 ? 'text-emerald-600' : 'text-rose-500'}`}>
                    {contractorData.profile_completion_percentage}%
                  </span>
                </div>
                <div className="flex items-center justify-between text-xs border-t border-slate-50 pt-2.5">
                  <span className="text-slate-500">Aadhaar Document Status</span>
                  <span className="font-bold flex items-center gap-1">
                    {contractorData.aadhaar_doc_url ? (
                      contractorData.aadhaar_verified ? (
                        <span className="text-emerald-600 flex items-center gap-1"><CheckCircle2 className="w-3.5 h-3.5" /> Verified</span>
                      ) : (
                        <span className="text-amber-500 flex items-center gap-1"><AlertCircle className="w-3.5 h-3.5" /> Pending</span>
                      )
                    ) : (
                      <span className="text-rose-500 flex items-center gap-1"><XCircle className="w-3.5 h-3.5" /> Missing</span>
                    )}
                  </span>
                </div>
                <div className="flex items-center justify-between text-xs border-t border-slate-50 pt-2.5">
                  <span className="text-slate-500">PAN Document Status</span>
                  <span className="font-bold flex items-center gap-1">
                    {contractorData.pan_doc_url ? (
                      contractorData.pan_verified ? (
                        <span className="text-emerald-600 flex items-center gap-1"><CheckCircle2 className="w-3.5 h-3.5" /> Verified</span>
                      ) : (
                        <span className="text-amber-500 flex items-center gap-1"><AlertCircle className="w-3.5 h-3.5" /> Pending</span>
                      )
                    ) : (
                      <span className="text-rose-500 flex items-center gap-1"><XCircle className="w-3.5 h-3.5" /> Missing</span>
                    )}
                  </span>
                </div>
                <div className="flex items-center justify-between text-xs border-t border-slate-50 pt-2.5">
                  <span className="text-slate-500">GST Registration Status</span>
                  <span className="font-bold flex items-center gap-1">
                    {contractorData.gst_doc_url ? (
                      contractorData.gst_verified ? (
                        <span className="text-emerald-600 flex items-center gap-1"><CheckCircle2 className="w-3.5 h-3.5" /> Verified</span>
                      ) : (
                        <span className="text-amber-500 flex items-center gap-1"><AlertCircle className="w-3.5 h-3.5" /> Pending</span>
                      )
                    ) : (
                      <span className="text-slate-400 flex items-center gap-1 italic">Optional</span>
                    )}
                  </span>
                </div>
              </div>
            ) : (
              <p className="text-xs text-slate-400 italic">No contractor checklists available.</p>
            )}
          </div>
        </div>
      </div>

      {/* Full-size document preview Modal */}
      {zoomDocument && (
        <div className="fixed inset-0 z-50 bg-black/75 backdrop-blur-sm flex items-center justify-center p-8">
          <div className="relative max-w-4xl max-h-[85vh] bg-white rounded-3xl p-4 shadow-2xl flex flex-col items-center">
            <button 
              onClick={() => setZoomDocument(null)}
              className="absolute -top-4 -right-4 bg-white border border-slate-200 text-slate-800 p-2.5 rounded-full shadow-lg hover:bg-slate-100 font-bold transition-transform hover:scale-105"
            >
              ✕
            </button>
            <div className="overflow-auto max-h-[75vh] flex justify-center w-full">
              <img src={zoomDocument} alt="Zoomed doc" className="object-contain max-h-[70vh] rounded-2xl" />
            </div>
            <div className="mt-4 flex gap-4">
              <a 
                href={zoomDocument} 
                target="_blank" 
                rel="noreferrer"
                className="bg-sky-500 hover:bg-sky-600 text-white font-bold text-xs px-5 py-2.5 rounded-xl shadow-sm transition-colors flex items-center gap-2"
              >
                <ExternalLink className="w-4 h-4" /> Open In New Tab
              </a>
              <a 
                href={zoomDocument}
                download
                className="bg-slate-100 hover:bg-slate-200 text-slate-700 font-bold text-xs px-5 py-2.5 rounded-xl shadow-sm transition-colors flex items-center gap-2"
              >
                <HardDrive className="w-4 h-4" /> Download File
              </a>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
