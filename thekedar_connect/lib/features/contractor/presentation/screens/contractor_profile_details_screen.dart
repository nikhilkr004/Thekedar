import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lottie/lottie.dart';
import '../models/contractor_profile.dart';

class ContractorProfileDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> contractor;
  final Map<String, dynamic> quote;
  final Map<String, dynamic> project;

  const ContractorProfileDetailsScreen({
    super.key,
    required this.contractor,
    required this.quote,
    required this.project,
  });

  @override
  State<ContractorProfileDetailsScreen> createState() => _ContractorProfileDetailsScreenState();
}

class _ContractorProfileDetailsScreenState extends State<ContractorProfileDetailsScreen> {
  late String _quoteStatus;
  bool _isUpdatingStatus = false;
  ContractorProfile? _profile;
  bool _isLoadingProfile = true;
  String? _profilePhotoUrl;

  @override
  void initState() {
    super.initState();
    _quoteStatus = (widget.quote['status'] ?? 'pending').toString().toLowerCase();
    _loadContractorProfile();
  }

  Future<void> _loadContractorProfile() async {
    try {
      final res = await Supabase.instance.client
          .from('contractors')
          .select(
            'business_name, years_experience, bio, categories, social_links, '
            'aadhaar_verified, pan_verified, gst_verified, '
            'aadhaar_doc_url, pan_doc_url, gst_doc_url, portfolio_urls, '
            'projects_completed, '
            'users:user_id (full_name, phone, address, profile_photo_url)',
          )
          .eq('id', widget.contractor['id'])
          .maybeSingle();

      if (res != null) {
        final userData = res['users'] as Map<String, dynamic>? ?? {};
        setState(() {
          _profile = ContractorProfile(
            fullName: userData['full_name'] ?? '',
            phone: userData['phone'] ?? '',
            address: userData['address'] ?? '',
            businessName: res['business_name'] ?? '',
            yearsExperience: (res['years_experience'] ?? 0) as int,
            bio: res['bio'] ?? '',
            categories: (res['categories'] as List?)?.cast<String>() ?? [],
            socialLinks: res['social_links'] as Map<String, dynamic>? ?? {},
            aadhaarVerified: res['aadhaar_verified'] as bool? ?? false,
            panVerified: res['pan_verified'] as bool? ?? false,
            gstVerified: res['gst_verified'] as bool? ?? false,
            aadhaarDocUrl: res['aadhaar_doc_url'] as String?,
            panDocUrl: res['pan_doc_url'] as String?,
            gstDocUrl: res['gst_doc_url'] as String?,
            portfolioUrls: (res['portfolio_urls'] as List?)?.cast<String>() ?? [],
            projectsCompleted: (res['projects_completed'] ?? 0) as int,
          );
          _profilePhotoUrl = userData['profile_photo_url'];
          _isLoadingProfile = false;
        });
        return;
      }
    } catch (e) {
      debugPrint('Error loading contractor profile: $e');
    }

    // Fallback using widget.contractor
    setState(() {
      final categories = widget.contractor['categories'] as List<dynamic>? ?? [];
      _profile = ContractorProfile(
        fullName: widget.contractor['business_name'] ?? 'Verified Contractor',
        phone: '',
        address: 'Gurgaon, Haryana',
        businessName: widget.contractor['business_name'] ?? 'Verified Contractor',
        yearsExperience: (widget.contractor['years_experience'] ?? 0) as int,
        bio: widget.contractor['bio'] ?? '',
        categories: categories.map((c) => c.toString()).toList(),
        socialLinks: widget.contractor['social_links'] as Map<String, dynamic>? ?? {},
        aadhaarVerified: widget.contractor['aadhaar_verified'] == true,
        panVerified: widget.contractor['pan_verified'] == true,
        gstVerified: widget.contractor['gst_verified'] == true,
        aadhaarDocUrl: widget.contractor['aadhaar_doc_url'] as String?,
        panDocUrl: widget.contractor['pan_doc_url'] as String?,
        gstDocUrl: widget.contractor['gst_doc_url'] as String?,
        portfolioUrls: (widget.contractor['portfolio_urls'] as List?)?.cast<String>() ?? [],
        projectsCompleted: (widget.contractor['projects_completed'] ?? 0) as int,
      );
      _profilePhotoUrl = null;
      _isLoadingProfile = false;
    });
  }

  Future<void> _updateQuoteStatus(String status) async {
    setState(() => _isUpdatingStatus = true);
    try {
      // 1. Update applications status
      await Supabase.instance.client
          .from('applications')
          .update({'status': status})
          .eq('id', widget.quote['id']);

      if (status == 'hired') {
        // 2. Update projects table
        await Supabase.instance.client
            .from('projects')
            .update({'hired_contractor_id': widget.contractor['id']})
            .eq('id', widget.project['id']);
      }

      setState(() {
        _quoteStatus = status;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(status == 'hired' ? 'Quote accepted!' : 'Quote rejected!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating status: $e')),
        );
      }
    } finally {
      setState(() => _isUpdatingStatus = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingProfile || _profile == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final profile = _profile!;
    final rating = widget.contractor['average_rating'] != null
        ? double.tryParse(widget.contractor['average_rating'].toString()) ?? 4.8
        : 4.8;
    final completedCount = profile.projectsCompleted;

    final costMin = widget.quote['estimated_cost_min'] ?? 0;
    final costMax = widget.quote['estimated_cost_max'] ?? 0;
    final priceStr = costMin == costMax ? '₹$costMin' : '₹$costMin - ₹$costMax';
    final timeline = widget.quote['estimated_timeline'] ?? 'Flexible';
    final coverMessage = widget.quote['cover_message'] ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF0F172A), size: 20),
          onPressed: () => Navigator.pop(context, true),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text(
              'aThekedar',
              style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Profile Hero Section
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                children: [
                  // Banner Image Container
                  Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      Container(
                        height: 180,
                        margin: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0284C7), Color(0xFF5B21B6)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              top: 16,
                              right: 16,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF22C55E),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    CircleAvatar(radius: 3, backgroundColor: Colors.white),
                                    SizedBox(width: 5),
                                    Text(
                                      'ACTIVE',
                                      style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                      // Profile Avatar
                      Transform.translate(
                        offset: const Offset(0, 32),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF3B82F6), width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 46,
                            backgroundColor: const Color(0xFFEFF6FF),
                            backgroundImage: _profilePhotoUrl != null
                                ? NetworkImage(_profilePhotoUrl!)
                                : null,
                            child: _profilePhotoUrl == null
                                ? Text(
                                    profile.fullName.isNotEmpty
                                        ? profile.fullName[0].toUpperCase()
                                        : 'C',
                                    style: const TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0284C7)),
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),

                  // Contractor Name
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        profile.fullName.isNotEmpty ? profile.fullName : 'Nikhil Kumar',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          border: Border.all(color: const Color(0xFFDCFCE7)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.verified_user_outlined, color: Color(0xFF16A34A), size: 10),
                            SizedBox(width: 3),
                            Text('KYC', style: TextStyle(color: Color(0xFF16A34A), fontSize: 9, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Location Tag
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_on, color: Color(0xFF0284C7), size: 14),
                        const SizedBox(width: 6),
                        Text(
                          profile.address.isNotEmpty ? profile.address : 'Gurgaon, Haryana',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Radius Tag
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.navigation, color: Color(0xFF0284C7), size: 12),
                        const SizedBox(width: 6),
                        Text(
                          '${widget.contractor['service_radius_km'] ?? 25}km Radius',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2. Social Links Grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 2.8,
                children: [
                  _buildMockupSocialBtn(
                    label: 'WhatsApp',
                    icon: Icons.chat_bubble_outline,
                    iconColor: const Color(0xFF22C55E),
                    bgColor: const Color(0xFFDCFCE7),
                    onTap: () => _launchSocialLink('whatsapp', profile.socialLinks['whatsapp'] ?? ''),
                  ),
                  _buildMockupSocialBtn(
                    label: 'Instagram',
                    icon: Icons.camera_alt_outlined,
                    iconColor: const Color(0xFFEC4899),
                    bgColor: const Color(0xFFFCE7F3),
                    onTap: () => _launchSocialLink('instagram', profile.socialLinks['instagram'] ?? ''),
                  ),
                  _buildMockupSocialBtn(
                    label: 'Facebook',
                    icon: Icons.public_outlined,
                    iconColor: const Color(0xFF3B82F6),
                    bgColor: const Color(0xFFDBEAFE),
                    onTap: () => _launchSocialLink('facebook', profile.socialLinks['facebook'] ?? ''),
                  ),
                  _buildMockupSocialBtn(
                    label: 'Website',
                    icon: Icons.language_outlined,
                    iconColor: const Color(0xFF0F172A),
                    bgColor: const Color(0xFFE2E8F0),
                    onTap: () => _launchSocialLink('website', profile.socialLinks['website'] ?? ''),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 3. Quick Stats Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: _buildMockupStatCard(
                      value: '${profile.yearsExperience}',
                      label: 'YEARS\nEXP.',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildMockupStatCard(
                      value: rating.toStringAsFixed(1),
                      label: 'AVG\nRATING',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildMockupStatCard(
                      value: '${completedCount}+',
                      label: 'PROJECTS',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 4. Bid Proposal & Cover Message Details (Premium Card style)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'BID PROPOSAL',
                    style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0369A1), fontSize: 11, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Estimated Cost', style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                          const SizedBox(height: 4),
                          Text(priceStr, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Timeline', style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                          const SizedBox(height: 4),
                          Text(timeline, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                        ],
                      ),
                    ],
                  ),
                  if (coverMessage.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Text('Cover Message', style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Text(
                        coverMessage,
                        style: const TextStyle(fontSize: 13, color: Color(0xFF334155), height: 1.5),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 5. Service Excellence & Core Specialties Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'SERVICE EXCELLENCE',
                    style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0369A1), fontSize: 11, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    profile.categories.isNotEmpty ? profile.categories.first : 'Civil Construction',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A), fontSize: 20),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    profile.bio.isNotEmpty ? profile.bio : 'With over a decade of dedicated service in the civil construction industry, I specialize in delivering high-quality residential and commercial projects. My approach combines traditional craftsmanship with modern project management.',
                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, height: 1.5),
                  ),
                  const SizedBox(height: 24),

                  // Project Budget Inner Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'PROJECT BUDGET',
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8), letterSpacing: 0.5),
                        ),
                        SizedBox(height: 6),
                        Text(
                          '₹ 50k - ₹ 50L',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Core Specialties row
                  const Text(
                    'CORE SPECIALTIES',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8), letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildChipText('Renovation'),
                      _buildChipText('Modular Kitchen'),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Expertise list
                  const Text(
                    'Expertise & Skills',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildChipText('Waterproofing'),
                      _buildChipText('Foundation Work'),
                      _buildChipText('Interior Finishes'),
                      _buildChipText('Plumbing Services'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 6. Featured Work / Portfolio
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Featured Work',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F172A)),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Recent architectural milestones in NCR',
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                      ),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: () {},
                    icon: const Text('Explore All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0284C7))),
                    label: const Icon(Icons.arrow_forward, size: 14, color: Color(0xFF0284C7)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 180,
              child: widget.quote['portfolio_photo_urls'] != null &&
                      widget.quote['portfolio_photo_urls'] is List &&
                      (widget.quote['portfolio_photo_urls'] as List).isNotEmpty
                  ? ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: (widget.quote['portfolio_photo_urls'] as List).length,
                      itemBuilder: (context, index) {
                        final imageUrl = (widget.quote['portfolio_photo_urls'] as List)[index].toString();
                        return GestureDetector(
                          onTap: () => _showFullImageDialog(imageUrl),
                          child: _buildMockupFeaturedCard(
                            title: 'Project Reference ${index + 1}',
                            category: 'PORTFOLIO • REFER',
                            price: priceStr,
                            imageUrl: imageUrl,
                          ),
                        );
                      },
                    )
                  : ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        _buildMockupFeaturedCard(
                          title: 'Skyline Residency',
                          category: 'RENOVATION • 2023',
                          price: '₹ 24L',
                          imageUrl: 'https://images.unsplash.com/photo-1589939705384-5185137a7f0f?q=80&w=300&auto=format&fit=crop',
                        ),
                        _buildMockupFeaturedCard(
                          title: 'Modern Villa Extension',
                          category: 'FOUNDATION • 2024',
                          price: '₹ 45L',
                          imageUrl: 'https://images.unsplash.com/photo-1621905251189-08b45d6a269e?q=80&w=300&auto=format&fit=crop',
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 24),

            // 7. Verified Trust Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Color(0xFFDCFCE7),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check, color: Color(0xFF16A34A), size: 14),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Verified Trust',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A), fontSize: 15),
                          ),
                          Text(
                            'PLATFORM AUTHENTICATED',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF94A3B8), fontSize: 9),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  _buildVerifiedTrustRow(
                    title: 'Aadhaar ID',
                    subtitle: 'CONFIRMED IDENTITY',
                    isVerified: profile.aadhaarVerified,
                  ),
                  const Divider(height: 24, color: Color(0xFFF1F5F9)),

                  _buildVerifiedTrustRow(
                    title: 'PAN Card',
                    subtitle: 'TAX COMPLIANCE VERIFIED',
                    isVerified: profile.panVerified,
                  ),
                  const Divider(height: 24, color: Color(0xFFF1F5F9)),

                  _buildVerifiedTrustRow(
                    title: 'GST Registry',
                    subtitle: 'GST-OTA1...A56',
                    isVerified: profile.gstVerified,
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      'PARTNERING SINCE MAY 2012',
                      style: TextStyle(fontSize: 10, color: const Color(0xFF94A3B8), fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            // 7. Client Reviews Section (Empty state with Lottie)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.star_outline, color: Color(0xFF0284C7), size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Client Reviews',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          height: 120,
                          child: Lottie.network(
                            'https://lottie.host/575e9e04-d5cf-4df5-b98a-76192d19b6eb/s8U5YkR8eK.json',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.rate_review_outlined,
                                size: 60,
                                color: Color(0xFF94A3B8),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'No reviews yet',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF475569),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Feedback from completed projects will appear here.',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF94A3B8),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Share & Report Bottom Row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildCircularActionBtn(Icons.share_outlined, 'SHARE'),
                const SizedBox(width: 24),
                _buildCircularActionBtn(Icons.info_outline, 'REPORT'),
              ],
            ),
            const SizedBox(height: 120), // Extra space for bottom actions
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: const Color(0xFFE2E8F0), width: 1)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4)),
          ],
        ),
        child: SafeArea(
          child: _isUpdatingStatus
              ? const Center(child: CircularProgressIndicator())
              : _buildFooterActions(),
        ),
      ),
    );
  }

  Future<void> _launchSocialLink(String platform, String value) async {
    if (value.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No $platform link is provided by this contractor.')),
        );
      }
      return;
    }

    Uri uri;
    if (value.startsWith('http://') || value.startsWith('https://')) {
      uri = Uri.parse(value);
    } else {
      switch (platform.toLowerCase()) {
        case 'whatsapp':
          final clean = value.replaceAll(RegExp(r'[^0-9]'), '');
          uri = Uri.parse('https://wa.me/$clean');
          break;
        case 'instagram':
          uri = Uri.parse('https://instagram.com/$value');
          break;
        case 'facebook':
          uri = Uri.parse('https://facebook.com/$value');
          break;
        default:
          uri = Uri.parse('https://$value');
      }
    }

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch URL';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open link: $value')),
        );
      }
    }
  }

  Widget _buildMockupSocialBtn({
    required String label,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: bgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 16),
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMockupStatCard({required String value, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8), height: 1.2),
          ),
        ],
      ),
    );
  }

  Widget _buildChipText(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0369A1)),
      ),
    );
  }

  Widget _buildMockupFeaturedCard({
    required String title,
    required String category,
    required String price,
    required String imageUrl,
  }) {
    return Container(
      width: 260,
      margin: const EdgeInsets.only(right: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(23),
        child: Stack(
          children: [
            Image.network(
              imageUrl,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: const Color(0xFFF1F5F9),
                child: const Icon(Icons.image_outlined, color: Colors.grey),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Colors.black.withOpacity(0.65)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  price,
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category,
                    style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerifiedTrustRow({
    required String title,
    required String subtitle,
    required bool isVerified,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isVerified ? const Color(0xFFDCFCE7) : const Color(0xFFFEF2F2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isVerified ? Icons.assignment_turned_in_outlined : Icons.assignment_late_outlined,
            color: isVerified ? const Color(0xFF16A34A) : const Color(0xFFEF4444),
            size: 18,
          ),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A), fontSize: 13),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isVerified ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                fontSize: 8,
              ),
            ),
          ],
        ),
        const Spacer(),
        if (isVerified)
          const Icon(Icons.check_circle, color: Color(0xFF22C55E), size: 18)
        else
          const Icon(Icons.pending, color: Color(0xFF94A3B8), size: 18)
      ],
    );
  }

  Widget _buildCircularActionBtn(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Icon(icon, color: const Color(0xFF475569), size: 18),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)),
        ),
      ],
    );
  }

  void _showFullImageDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            InteractiveViewer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(imageUrl, fit: BoxFit.contain),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooterActions() {
    if (_quoteStatus == 'pending') {
      return Row(
        children: [
          Expanded(
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0284C7), Color(0xFF3B82F6)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: ElevatedButton(
                onPressed: () => _updateQuoteStatus('hired'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.send, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text('Accept Quote', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton(
              onPressed: () => _updateQuoteStatus('rejected'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFE2E8F0)),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Reject Bid', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ),
        ],
      );
    } else if (_quoteStatus == 'hired') {
      return Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0284C7), Color(0xFF3B82F6)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: ElevatedButton.icon(
          onPressed: () {
            context.push('/chat', extra: widget.project['id']);
          },
          icon: const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 18),
          label: const Text('MESSAGE CONTRACTOR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      );
    } else {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(16)),
        child: const Center(
          child: Text(
            'BID REJECTED',
            style: TextStyle(color: Color(0xFF991B1B), fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
      );
    }
  }
}

