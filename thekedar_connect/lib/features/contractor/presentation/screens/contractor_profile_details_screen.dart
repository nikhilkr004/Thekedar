import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lottie/lottie.dart';
import '../models/contractor_profile.dart';
import '../../../../core/theme/design_system.dart';

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
      await Supabase.instance.client
          .from('applications')
          .update({'status': status})
          .eq('id', widget.quote['id']);

      if (status == 'hired') {
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
        backgroundColor: AppColors.darkBackground,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
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

    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isLargeScreen = screenWidth > 600;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkSurface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context, true),
        ),
        title: Text(
          'aThekedar',
          style: AppTypography.title.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: SizedBox(
          width: isLargeScreen ? 600 : double.infinity,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Profile Hero Section
                Container(
                  decoration: const BoxDecoration(
                    color: AppColors.darkSurface,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(32),
                      bottomRight: Radius.circular(32),
                    ),
                  ),
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          Container(
                            height: 180,
                            margin: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: AppGradients.primaryGradient,
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
                                      color: AppColors.success,
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
                          Transform.translate(
                            offset: const Offset(0, 32),
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.primary, width: 3),
                                boxShadow: AppShadows.darkCardShadow,
                              ),
                              child: CircleAvatar(
                                radius: 46,
                                backgroundColor: AppColors.darkSurface,
                                backgroundImage: _profilePhotoUrl != null
                                    ? NetworkImage(_profilePhotoUrl!)
                                    : null,
                                child: _profilePhotoUrl == null
                                    ? Text(
                                        profile.fullName.isNotEmpty
                                            ? profile.fullName[0].toUpperCase()
                                            : 'C',
                                        style: AppTypography.title.copyWith(
                                            fontSize: 32,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primaryLight),
                                      )
                                    : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 48),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            profile.fullName.isNotEmpty ? profile.fullName : 'Nikhil Kumar',
                            style: AppTypography.title.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.12),
                              border: Border.all(color: AppColors.success.withOpacity(0.2)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.verified_user_outlined, color: AppColors.success, size: 10),
                                SizedBox(width: 3),
                                Text('KYC', style: TextStyle(color: AppColors.success, fontSize: 9, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.darkBackground,
                          borderRadius: BorderRadius.circular(AppRadius.circular),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.location_on, color: AppColors.primaryLight, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              profile.address.isNotEmpty ? profile.address : 'Gurgaon, Haryana',
                              style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.darkBackground,
                          borderRadius: BorderRadius.circular(AppRadius.circular),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.navigation, color: AppColors.primaryLight, size: 12),
                            const SizedBox(width: 6),
                            Text(
                              '${widget.contractor[\'service_radius_km\'] ?? 25}km Radius',
                              style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // 2. Social Links Grid
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
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
                        bgColor: const Color(0xFF22C55E).withOpacity(0.12),
                        onTap: () => _launchSocialLink('whatsapp', profile.socialLinks['whatsapp'] ?? ''),
                      ),
                      _buildMockupSocialBtn(
                        label: 'Instagram',
                        icon: Icons.camera_alt_outlined,
                        iconColor: const Color(0xFFEC4899),
                        bgColor: const Color(0xFFEC4899).withOpacity(0.12),
                        onTap: () => _launchSocialLink('instagram', profile.socialLinks['instagram'] ?? ''),
                      ),
                      _buildMockupSocialBtn(
                        label: 'Facebook',
                        icon: Icons.public_outlined,
                        iconColor: const Color(0xFF3B82F6),
                        bgColor: const Color(0xFF3B82F6).withOpacity(0.12),
                        onTap: () => _launchSocialLink('facebook', profile.socialLinks['facebook'] ?? ''),
                      ),
                      _buildMockupSocialBtn(
                        label: 'Website',
                        icon: Icons.language_outlined,
                        iconColor: AppColors.textPrimary,
                        bgColor: AppColors.darkSurface,
                        onTap: () => _launchSocialLink('website', profile.socialLinks['website'] ?? ''),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // 3. Quick Stats Row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
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
                const SizedBox(height: AppSpacing.lg),

                // 4. Bid Proposal & Cover Message Details
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  padding: const EdgeInsets.all(AppSpacing.xxl),
                  decoration: BoxDecoration(
                    color: AppColors.darkCard,
                    borderRadius: BorderRadius.circular(AppRadius.large),
                    border: Border.all(color: AppColors.darkBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'BID PROPOSAL',
                        style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.primaryLight, fontSize: 11, letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Estimated Cost', style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
                              const SizedBox(height: 4),
                              Text(priceStr, style: AppTypography.smallBody.copyWith(fontWeight: FontWeight.bold, color: AppColors.success)),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('Timeline', style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
                              const SizedBox(height: 4),
                              Text(timeline, style: AppTypography.smallBody.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                            ],
                          ),
                        ],
                      ),
                      if (coverMessage.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Text('Cover Message', style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          decoration: BoxDecoration(
                            color: AppColors.darkSurface,
                            borderRadius: BorderRadius.circular(AppRadius.medium),
                            border: Border.all(color: AppColors.darkBorder),
                          ),
                          child: Text(
                            coverMessage,
                            style: AppTypography.caption.copyWith(color: AppColors.textSecondary, height: 1.5),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // 5. Service Excellence & Core Specialties Card
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  padding: const EdgeInsets.all(AppSpacing.xxl),
                  decoration: BoxDecoration(
                    color: AppColors.darkCard,
                    borderRadius: BorderRadius.circular(AppRadius.large),
                    border: Border.all(color: AppColors.darkBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'SERVICE EXCELLENCE',
                        style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.primaryLight, fontSize: 11, letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        profile.categories.isNotEmpty ? profile.categories.first : 'Civil Construction',
                        style: AppTypography.smallBody.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        profile.bio.isNotEmpty ? profile.bio : 'With over a decade of dedicated service in the civil construction industry, I specialize in delivering high-quality residential and commercial projects. My approach combines traditional craftsmanship with modern project management.',
                        style: AppTypography.caption.copyWith(color: AppColors.textSecondary, height: 1.5),
                      ),
                      const SizedBox(height: 24),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.darkSurface,
                          borderRadius: BorderRadius.circular(AppRadius.medium),
                          border: Border.all(color: AppColors.darkBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PROJECT BUDGET',
                              style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold, color: AppColors.textMuted),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '₹ 50k - ₹ 50L',
                              style: AppTypography.smallBody.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      Text(
                        'CORE SPECIALTIES',
                        style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold, color: AppColors.textMuted),
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

                      Text(
                        'Expertise & Skills',
                        style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold, color: AppColors.textSecondary),
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
                const SizedBox(height: AppSpacing.lg),

                // 6. Featured Work
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Featured Work',
                            style: AppTypography.smallBody.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Recent architectural milestones in NCR',
                            style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                          ),
                        ],
                      ),
                      TextButton.icon(
                        onPressed: () {},
                        icon: Text('Explore All', style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold, color: AppColors.primaryLight)),
                        label: const Icon(Icons.arrow_forward, size: 14, color: AppColors.primaryLight),
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
                const SizedBox(height: AppSpacing.lg),

                // 7. Verified Trust Card
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  padding: const EdgeInsets.all(AppSpacing.xxl),
                  decoration: BoxDecoration(
                    color: AppColors.darkCard,
                    borderRadius: BorderRadius.circular(AppRadius.large),
                    border: Border.all(color: AppColors.darkBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check, color: AppColors.success, size: 14),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Verified Trust',
                                style: AppTypography.smallBody.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                              ),
                              Text(
                                'PLATFORM AUTHENTICATED',
                                style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold, color: AppColors.textMuted),
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
                      const Divider(height: 24, color: AppColors.darkDivider),

                      _buildVerifiedTrustRow(
                        title: 'PAN Card',
                        subtitle: 'TAX COMPLIANCE VERIFIED',
                        isVerified: profile.panVerified,
                      ),
                      const Divider(height: 24, color: AppColors.darkDivider),

                      _buildVerifiedTrustRow(
                        title: 'GST Registry',
                        subtitle: 'GST-OTA1...A56',
                        isVerified: profile.gstVerified,
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Text(
                          'PARTNERING SINCE MAY 2012',
                          style: AppTypography.caption.copyWith(color: AppColors.textMuted, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // 7. Client Reviews Section
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 16),
                  padding: const EdgeInsets.all(AppSpacing.xxl),
                  decoration: BoxDecoration(
                    color: AppColors.darkCard,
                    borderRadius: BorderRadius.circular(AppRadius.large),
                    border: Border.all(color: AppColors.darkBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.star_outline, color: AppColors.primaryLight, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Client Reviews',
                            style: AppTypography.smallBody.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
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
                                    color: AppColors.textMuted,
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No reviews yet',
                              style: AppTypography.smallBody.copyWith(fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Feedback from completed projects will appear here.',
                              style: AppTypography.caption.copyWith(color: AppColors.textMuted),
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
                const SizedBox(height: 120),
              ],
            ),
          ),
        ),
      ),
      bottomSheet: Container(
        color: AppColors.darkSurface,
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: SafeArea(
          child: SizedBox(
            width: isLargeScreen ? 600 : double.infinity,
            child: _isUpdatingStatus
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _buildFooterActions(),
          ),
        ),
      ),
    );
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
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.medium),
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
                  style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold, color: AppColors.textSecondary),
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
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: AppTypography.title.copyWith(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTypography.caption.copyWith(color: AppColors.textMuted, height: 1.2),
          ),
        ],
      ),
    );
  }

  Widget _buildChipText(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold, color: AppColors.primaryLight),
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
        border: Border.all(color: AppColors.darkBorder),
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
                color: AppColors.darkSurface,
                child: const Icon(Icons.image_outlined, color: AppColors.textMuted),
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
                  color: Colors.black.withOpacity(0.4),
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
            color: isVerified ? AppColors.success.withOpacity(0.12) : AppColors.error.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isVerified ? Icons.assignment_turned_in_outlined : Icons.assignment_late_outlined,
            color: isVerified ? AppColors.success : AppColors.error,
            size: 18,
          ),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.bold,
                color: isVerified ? AppColors.success : AppColors.error,
                fontSize: 8,
              ),
            ),
          ],
        ),
        const Spacer(),
        if (isVerified)
          const Icon(Icons.check_circle, color: AppColors.success, size: 18)
        else
          const Icon(Icons.pending, color: AppColors.textMuted, size: 18)
      ],
    );
  }

  Widget _buildCircularActionBtn(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.darkSurface,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.darkBorder),
          ),
          child: Icon(icon, color: AppColors.textSecondary, size: 18),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: AppTypography.caption.copyWith(fontSize: 8, fontWeight: FontWeight.bold, color: AppColors.textMuted),
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
                gradient: AppGradients.primaryGradient,
                borderRadius: AppRadius.buttonBorderRadius,
              ),
              child: ElevatedButton(
                onPressed: () => _updateQuoteStatus('hired'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.buttonBorderRadius),
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
                foregroundColor: AppColors.textSecondary,
                side: const BorderSide(color: AppColors.darkBorder),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.large)),
              ),
              child: const Text('Reject Bid', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ),
        ],
      );
    } else if (_quoteStatus == 'hired') {
      return Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          gradient: AppGradients.primaryGradient,
          borderRadius: AppRadius.buttonBorderRadius,
        ),
        child: ElevatedButton.icon(
          onPressed: () {
            context.push('/chat', extra: widget.project['id']);
          },
          icon: const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 18),
          label: const Text('MESSAGE CONTRACTOR', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: AppRadius.buttonBorderRadius),
          ),
        ),
      );
    } else {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(color: AppColors.error.withOpacity(0.12), borderRadius: BorderRadius.circular(AppRadius.large)),
        child: const Center(
          child: Text(
            'BID REJECTED',
            style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
      );
    }
  }
}
