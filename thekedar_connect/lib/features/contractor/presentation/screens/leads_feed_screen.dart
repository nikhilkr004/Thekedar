import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/contractor_provider.dart';
import '../models/contractor_profile.dart';
import '../../../../widgets/shimmer_placeholder.dart';
import '../../../../core/theme/design_system.dart';

class LeadsFeedScreen extends ConsumerWidget {
  const LeadsFeedScreen({super.key});

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(contractorProfileProvider);
    final walletAsync = ref.watch(walletBalanceProvider);
    final bidsAsync = ref.watch(contractorBidsProvider);

    final categoriesList = profileAsync.value?.categories ?? [];
    final categoriesStr = categoriesList.isEmpty
        ? 'Mason,Plumber,Electrician,Painter,Carpenter'
        : categoriesList.join(',');

    final leadsAsync = ref.watch(leadsProvider(categoriesStr));
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isLargeScreen = screenWidth > 840;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: Center(
          child: SizedBox(
            width: isLargeScreen ? 840 : double.infinity,
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                ref.invalidate(leadsProvider);
                ref.invalidate(walletBalanceProvider);
                ref.invalidate(contractorProfileProvider);
                ref.invalidate(contractorBidsProvider);
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Sleek Contractor Header Profile Bar
                    profileAsync.when(
                      data: (profile) {
                        final name = profile?.businessName ?? 'Verified Contractor';
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor: AppColors.primary.withOpacity(0.15),
                                  child: Text(
                                    name[0].toUpperCase(),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primaryLight),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Contractor Workspace',
                                      style: AppTypography.smallBody.copyWith(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                    ),
                                    Text(
                                      'Welcome back, ${name.split(" ").first}',
                                      style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            // Wallet Balance pill and Notification Bell
                            Row(
                              children: [
                                walletAsync.when(
                                  data: (balance) => Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(AppRadius.circular),
                                      border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.stars, color: AppColors.primaryLight, size: 14),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${balance ?? 0} Cr',
                                          style: AppTypography.caption.copyWith(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryLight),
                                        ),
                                      ],
                                    ),
                                  ),
                                  loading: () => const SizedBox(),
                                  error: (_, __) => const SizedBox(),
                                ),
                                const SizedBox(width: 8),
                                Stack(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.notifications_none_outlined, color: AppColors.textPrimary, size: 24),
                                      onPressed: () => context.push('/notifications'),
                                    ),
                                    Positioned(
                                      top: 12,
                                      right: 12,
                                      child: Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: AppColors.error,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                      loading: () => const LinearProgressIndicator(color: AppColors.primary),
                      error: (_, __) => const SizedBox(),
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    // 2. Opportunities Heading
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'New Opportunities',
                              style: AppTypography.subtitle.copyWith(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Recommended leads in Jaipur',
                              style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                        ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.filter_list, size: 14, color: AppColors.primaryLight),
                          label: Text(
                            'Filter',
                            style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold, color: AppColors.primaryLight),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.darkSurface,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.small),
                              side: const BorderSide(color: AppColors.darkBorder),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // 3. Opportunities List Builder
                    leadsAsync.when(
                      data: (leads) {
                        if (leads.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(AppSpacing.xxl),
                            decoration: BoxDecoration(
                              color: AppColors.darkCard,
                              borderRadius: BorderRadius.circular(AppRadius.large),
                              border: Border.all(color: AppColors.darkBorder),
                            ),
                            child: Column(
                              children: [
                                const Icon(Icons.feed_outlined, size: 48, color: AppColors.textMuted),
                                const SizedBox(height: 14),
                                Text(
                                  'No new matching projects found.',
                                  textAlign: TextAlign.center,
                                  style: AppTypography.smallBody.copyWith(fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          );
                        }

                        final bidsMap = bidsAsync.value ?? {};

                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: leads.length,
                          itemBuilder: (context, index) {
                            final lead = leads[index];
                            final id = lead['id'];
                            final category = lead['category'] ?? 'General';
                            final title = lead['title'] ?? 'Untitled Lead';
                            final city = lead['city'] ?? 'Location';
                            final rawDesc = lead['description'] ?? '';
                            final rawAddress = lead['address_text'] ?? '';
                            final timeAgo = _getTimeAgo(lead['created_at']);
                            final budgetMin = lead['budget_min'] ?? 0;
                            final budgetMax = lead['budget_max'] ?? 0;

                            final hasBid = bidsMap.containsKey(id);
                            final bidStatus = bidsMap[id]?.toLowerCase() ?? 'pending';

                            Color? statusBadgeBg;
                            Color? statusBadgeText;
                            String statusLabel = '';
                            if (hasBid) {
                              if (bidStatus == 'accepted' || bidStatus == 'hired') {
                                statusBadgeBg = AppColors.success.withOpacity(0.12);
                                statusBadgeText = AppColors.success;
                                statusLabel = '✓ ACCEPTED';
                              } else if (bidStatus == 'rejected') {
                                statusBadgeBg = AppColors.error.withOpacity(0.12);
                                statusBadgeText = AppColors.error;
                                statusLabel = '✗ DECLINED';
                              } else {
                                statusBadgeBg = AppColors.warning.withOpacity(0.12);
                                statusBadgeText = AppColors.warning;
                                statusLabel = '⚡ SENT';
                              }
                            }

                            final budgetStr = budgetMin == 0 && budgetMax == 0
                                ? 'Est. ₹12,000 - ₹15,000'
                                : budgetMin == budgetMax
                                    ? 'Est. ₹$budgetMin'
                                    : 'Est. ₹$budgetMin - ₹$budgetMax';

                            String cleanDesc = rawDesc;
                            cleanDesc = cleanDesc.replaceAll(RegExp(r'\[Plot Area:[^\]]+\]'), '');
                            cleanDesc = cleanDesc.replaceAll(RegExp(r'\[Drawing Attachment:[^\]]+\]'), '');
                            cleanDesc = cleanDesc.replaceAll(RegExp(r'\[Land Images:[^\]]+\]'), '');
                            cleanDesc = cleanDesc.replaceAll(RegExp(r'\[Drawing PDF URL:[^\]]+\]'), '');
                            cleanDesc = cleanDesc.replaceAll(RegExp(r'\[Land Image URLs:[^\]]+\]'), '');
                            cleanDesc = cleanDesc.trim();
                            if (cleanDesc.isEmpty) {
                              cleanDesc = 'Full requirements analysis and service specifications for site.';
                            }

                            final isPremium = budgetMax >= 50000 || index % 3 == 2;
                            final isUrgent = category.toLowerCase() == 'plumber' || index % 3 == 1;

                            Color badgeBg = AppColors.primary.withOpacity(0.15);
                            Color badgeText = AppColors.primaryLight;
                            String badgeLabel = 'NEW LEAD';
                            if (isPremium) {
                              badgeBg = AppColors.secondary.withOpacity(0.15);
                              badgeText = AppColors.secondary;
                              badgeLabel = '★ PREMIUM';
                            } else if (isUrgent) {
                              badgeBg = AppColors.error.withOpacity(0.12);
                              badgeText = AppColors.error;
                              badgeLabel = 'URGENT';
                            }

                            return Container(
                              margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                              decoration: BoxDecoration(
                                color: AppColors.darkCard,
                                borderRadius: BorderRadius.circular(AppRadius.large),
                                border: Border.all(color: AppColors.darkBorder),
                                boxShadow: AppShadows.darkCardShadow,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(AppSpacing.lg),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: badgeBg,
                                                borderRadius: BorderRadius.circular(AppRadius.small),
                                              ),
                                              child: Text(
                                                badgeLabel,
                                                style: AppTypography.caption.copyWith(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                  color: badgeText,
                                                ),
                                              ),
                                            ),
                                            if (hasBid) ...[
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: statusBadgeBg,
                                                  borderRadius: BorderRadius.circular(AppRadius.small),
                                                ),
                                                child: Text(
                                                  statusLabel,
                                                  style: AppTypography.caption.copyWith(
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.bold,
                                                    color: statusBadgeText,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            const Icon(Icons.access_time, size: 12, color: AppColors.textMuted),
                                            const SizedBox(width: 4),
                                            Text(
                                              timeAgo,
                                              style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: AppSpacing.md),

                                    Text(
                                      title,
                                      style: AppTypography.subtitle.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.sm),

                                    Row(
                                      children: [
                                        const Icon(Icons.location_on, size: 14, color: AppColors.primaryLight),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            rawAddress.startsWith('Lat:')
                                                ? 'Jagatpura, Jaipur (1.5 km away)'
                                                : '$city, India (3.2 km away)',
                                            style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: AppSpacing.xs),

                                    Row(
                                      children: [
                                        const Icon(Icons.wallet, size: 14, color: AppColors.textMuted),
                                        const SizedBox(width: 4),
                                        Text(
                                          budgetStr,
                                          style: AppTypography.smallBody.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: AppSpacing.sm),

                                    Text(
                                      cleanDesc,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTypography.caption.copyWith(
                                        fontStyle: FontStyle.italic,
                                        color: AppColors.textSecondary,
                                        height: 1.4,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.md),

                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: [
                                        _buildTagChip('TOOLS REQUIRED'),
                                        _buildTagChip('SITE VISIT NEEDED'),
                                      ],
                                    ),
                                    const SizedBox(height: AppSpacing.lg),

                                    // Action Button
                                    SizedBox(
                                      width: double.infinity,
                                      height: 48,
                                      child: hasBid
                                          ? (bidStatus == 'accepted' || bidStatus == 'hired'
                                              ? ElevatedButton.icon(
                                                  onPressed: () => context.push('/chat', extra: id),
                                                  icon: const Icon(Icons.chat_bubble_outline, size: 16, color: Colors.white),
                                                  label: const Text('Chat with Customer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: AppColors.success,
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.medium)),
                                                  ),
                                                )
                                              : OutlinedButton(
                                                  onPressed: () {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(content: Text('Your bid request is currently $bidStatus.')),
                                                    );
                                                  },
                                                  style: OutlinedButton.styleFrom(
                                                    foregroundColor: AppColors.textSecondary,
                                                    side: const BorderSide(color: AppColors.darkBorder),
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.medium)),
                                                  ),
                                                  child: Text(
                                                    bidStatus == 'rejected' ? 'Bid Declined' : 'Bid Pending Review',
                                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                                  ),
                                                ))
                                          : (isPremium
                                              ? Container(
                                                  decoration: BoxDecoration(
                                                    gradient: AppGradients.primaryGradient,
                                                    borderRadius: AppRadius.buttonBorderRadius,
                                                  ),
                                                  child: ElevatedButton(
                                                    onPressed: () => context.push('/send_proposal', extra: id),
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: Colors.transparent,
                                                      shadowColor: Colors.transparent,
                                                      shape: RoundedRectangleBorder(borderRadius: AppRadius.buttonBorderRadius),
                                                    ),
                                                    child: const Text('Bid Now', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                                                  ),
                                                )
                                              : ElevatedButton(
                                                  onPressed: () => context.push('/send_proposal', extra: id),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: AppColors.darkSurface,
                                                    foregroundColor: AppColors.primaryLight,
                                                    side: const BorderSide(color: AppColors.darkBorder),
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.medium)),
                                                  ),
                                                  child: const Text('View Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                                )),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                      loading: () => const ProjectListSkeleton(),
                      error: (e, _) => Center(child: Text('Error loading opportunities: $e', style: const TextStyle(color: AppColors.error))),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTagChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(AppRadius.xs),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(fontSize: 8, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
      ),
    );
  }
}
