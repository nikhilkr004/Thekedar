import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/contractor_provider.dart';
import '../../../../core/theme/design_system.dart';

class SendProposalScreen extends ConsumerStatefulWidget {
  final String projectId;
  const SendProposalScreen({super.key, required this.projectId});

  @override
  ConsumerState<SendProposalScreen> createState() => _SendProposalScreenState();
}

class _SendProposalScreenState extends ConsumerState<SendProposalScreen> {
  final _timelineController = TextEditingController();
  final _coverMessageController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _timelineController.dispose();
    _coverMessageController.dispose();
    super.dispose();
  }

  String _getTimeAgo(String? timestamp) {
    if (timestamp == null) return 'Just now';
    try {
      final created = DateTime.parse(timestamp);
      final diff = DateTime.now().difference(created);
      if (diff.inDays > 0) return '${diff.inDays}d ago';
      if (diff.inHours > 0) return '${diff.inHours}h ago';
      if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
      return 'Just now';
    } catch (_) {
      return 'Just now';
    }
  }

  Future<void> _submit(int budgetMin, int budgetMax) async {
    if (_timelineController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter estimated completion time')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref.read(contractorRepositoryProvider).submitProposal(
            projectId: widget.projectId,
            estimatedCostMin: budgetMin > 0 ? budgetMin : 12000,
            estimatedCostMax: budgetMax > 0 ? budgetMax : 15000,
            estimatedTimeline: _timelineController.text,
            coverMessage: _coverMessageController.text,
          );

      if (mounted) {
        ref.invalidate(walletBalanceProvider);
        ref.invalidate(contractorBidsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Service Request Sent successfully!')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending request: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isLargeScreen = screenWidth > 600;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkSurface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Lead Details',
          style: AppTypography.title.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: AppColors.textPrimary),
            onPressed: () {},
          ),
          CircleAvatar(
            radius: 14,
            backgroundColor: AppColors.primary.withOpacity(0.15),
            child: const Icon(AppIcons.profile, size: 16, color: AppColors.primaryLight),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Center(
        child: SizedBox(
          width: isLargeScreen ? 600 : double.infinity,
          child: FutureBuilder<Map<String, dynamic>>(
            future: Supabase.instance.client
                .from('projects')
                .select('*')
                .eq('id', widget.projectId)
                .single(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppColors.primary));
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: AppColors.error)));
              }

              final project = snapshot.data ?? {};
              final title = project['title'] ?? 'Luxury Construction Lead';
              final city = project['city'] ?? 'Jaipur';
              final desc = project['description'] ?? '';
              final rawAddress = project['address_text'] ?? '';
              final timeAgo = _getTimeAgo(project['created_at']);
              final budgetMin = project['budget_min'] ?? 0;
              final budgetMax = project['budget_max'] ?? 0;

              List<String> imageUrls = [];
              final imagesMatch = RegExp(r'\[Land Image URLs:\s*([^\s\]]+(?:,\s*[^\s\]]+)*)\]').firstMatch(desc);
              if (imagesMatch != null) {
                final rawUrls = imagesMatch.group(1) ?? '';
                imageUrls = rawUrls.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
              }

              String cleanDesc = desc;
              cleanDesc = cleanDesc.replaceAll(RegExp(r'\[Plot Area:[^\]]+\]'), '');
              cleanDesc = cleanDesc.replaceAll(RegExp(r'\[Drawing Attachment:[^\]]+\]'), '');
              cleanDesc = cleanDesc.replaceAll(RegExp(r'\[Land Images:[^\]]+\]'), '');
              cleanDesc = cleanDesc.replaceAll(RegExp(r'\[Drawing PDF URL:[^\]]+\]'), '');
              cleanDesc = cleanDesc.replaceAll(RegExp(r'\[Land Image URLs:[^\]]+\]'), '');
              cleanDesc = cleanDesc.trim();
              if (cleanDesc.isEmpty) {
                cleanDesc = 'Complete specification analysis for this premium project. Highly optimized space utilization and high-quality standard fitting requirements.';
              }

              final isPremium = budgetMax >= 50000;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Premium Lead Blue Banner
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        borderRadius: BorderRadius.circular(AppRadius.large),
                        boxShadow: AppShadows.darkCardShadow,
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.white.withOpacity(0.2),
                            radius: 18,
                            child: const Icon(Icons.star, color: Colors.white, size: 18),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isPremium ? 'PREMIUM LEAD' : 'VERIFIED PARTNER LEAD',
                                  style: AppTypography.smallBody.copyWith(fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                                Text(
                                  isPremium ? 'Priority access for top-rated partners' : 'Direct access to verified customer requirements',
                                  style: AppTypography.caption.copyWith(color: Colors.white.withOpacity(0.9)),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(AppRadius.circular),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.check_circle, color: AppColors.secondary, size: 12),
                                SizedBox(width: 4),
                                Text(
                                  'Verified',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: AppColors.secondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // 2. Main Lead Specification Card
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.xxl),
                      decoration: BoxDecoration(
                        color: AppColors.darkCard,
                        borderRadius: BorderRadius.circular(AppRadius.large),
                        border: Border.all(color: AppColors.darkBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: AppTypography.subtitle.copyWith(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: AppSpacing.sm),

                          Row(
                            children: [
                              const Icon(Icons.access_time, size: 14, color: AppColors.textMuted),
                              const SizedBox(width: 6),
                              Text(
                                timeAgo,
                                style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),

                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 16, color: AppColors.primaryLight),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  rawAddress.startsWith('Lat:') ? 'Jagatpura, Jaipur (1.5 km away)' : '$city, India (3.2 km away)',
                                  style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.lg),

                          Text(
                            'Description',
                            style: AppTypography.smallBody.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            cleanDesc,
                            style: AppTypography.caption.copyWith(color: AppColors.textSecondary, height: 1.5),
                          ),
                          const SizedBox(height: AppSpacing.lg),

                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildSpecTag('Tools Required'),
                              _buildSpecTag('Site Visit Needed'),
                              _buildSpecTag('Material Provided'),
                              _buildSpecTag('Urgent Fix'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // 3. Site Photos
                    Text(
                      'Site Photos & Blueprints',
                      style: AppTypography.subtitle.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      height: 160,
                      child: imageUrls.isNotEmpty
                          ? ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: imageUrls.length,
                              itemBuilder: (context, index) {
                                return Container(
                                  width: 220,
                                  margin: const EdgeInsets.only(right: 14),
                                  decoration: BoxDecoration(
                                    color: AppColors.darkCard,
                                    borderRadius: BorderRadius.circular(AppRadius.large),
                                    border: Border.all(color: AppColors.darkBorder),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(AppRadius.large - 1.0),
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        Image.network(imageUrls[index], fit: BoxFit.cover),
                                        Positioned(
                                          bottom: 10,
                                          left: 10,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withOpacity(0.5),
                                              borderRadius: BorderRadius.circular(AppRadius.small),
                                            ),
                                            child: Text(
                                              'Site Photo ${index + 1}.jpg',
                                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            )
                          : ListView(
                              scrollDirection: Axis.horizontal,
                              children: [
                                _buildMockPhotoCard('Architectural Frame'),
                                _buildMockPhotoCard('Internal Layout'),
                              ],
                            ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    // 4. Send Service Request Card
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.xxl),
                      decoration: BoxDecoration(
                        color: AppColors.darkCard,
                        borderRadius: BorderRadius.circular(AppRadius.large),
                        border: Border.all(color: AppColors.darkBorder),
                        boxShadow: AppShadows.darkCardShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(AppSpacing.sm),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(AppRadius.small),
                                ),
                                child: const Icon(Icons.mail_outline, color: AppColors.primaryLight, size: 20),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Text(
                                'Send Service Request',
                                style: AppTypography.smallBody.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.lg),

                          Text(
                            'Estimated Completion Time',
                            style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          TextField(
                            controller: _timelineController,
                            style: AppTypography.body.copyWith(color: AppColors.textPrimary),
                            decoration: const InputDecoration(
                              hintText: 'e.g., 15 Days',
                              prefixIcon: Icon(Icons.timer_outlined, color: AppColors.iconNormal),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),

                          Text(
                            'Proposal Note',
                            style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          TextField(
                            controller: _coverMessageController,
                            maxLines: 5,
                            style: AppTypography.body.copyWith(color: AppColors.textPrimary),
                            decoration: const InputDecoration(
                              hintText: 'I have 10+ years of experience in villa projects. We can ensure the highest safety standards...',
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),

                          Text(
                            'Your profile, including project history and experience, will be shared with the user.',
                            style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                          ),
                          const SizedBox(height: AppSpacing.lg),

                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: _isLoading
                                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                                : Container(
                                    decoration: BoxDecoration(
                                      gradient: AppGradients.primaryGradient,
                                      borderRadius: AppRadius.buttonBorderRadius,
                                    ),
                                    child: ElevatedButton.icon(
                                      onPressed: () => _submit(budgetMin, budgetMax),
                                      icon: const Icon(Icons.send, size: 16, color: Colors.white),
                                      label: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: const [
                                          Text('Send Request ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                                          Icon(Icons.arrow_forward, size: 14, color: Colors.white),
                                        ],
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        shape: RoundedRectangleBorder(borderRadius: AppRadius.buttonBorderRadius),
                                      ),
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSpecTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(AppRadius.small),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600, color: AppColors.textSecondary),
      ),
    );
  }

  Widget _buildMockPhotoCard(String name) {
    return Container(
      width: 220,
      margin: const EdgeInsets.only(right: 14),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const Icon(Icons.landscape, size: 48, color: AppColors.textMuted),
          Positioned(
            bottom: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(AppRadius.small),
              ),
              child: Text(
                name,
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
