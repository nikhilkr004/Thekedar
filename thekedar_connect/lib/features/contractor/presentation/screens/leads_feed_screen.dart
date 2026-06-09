import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/contractor_provider.dart';
import '../models/contractor_profile.dart';
import '../../../../widgets/shimmer_placeholder.dart';

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
    final leadsAsync = ref.watch(
      leadsProvider('Mason,Plumber,Electrician,Painter,Carpenter'),
    );
    final profileAsync = ref.watch(contractorProfileProvider);
    final walletAsync = ref.watch(walletBalanceProvider);
    final bidsAsync = ref.watch(contractorBidsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F7FA), // Soft blue-grey background matching screenshot
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(leadsProvider);
            ref.invalidate(walletBalanceProvider);
            ref.invalidate(contractorProfileProvider);
            ref.invalidate(contractorBidsProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Sleek Contractor Header Profile Bar (Matches Left Screen)
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
                              backgroundColor: const Color(0xFF0284C7),
                              child: Text(
                                name[0].toUpperCase(),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Contractor Workspace',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                ),
                                Text(
                                  'Welcome back, ${name.split(" ").first}',
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
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
                                  color: const Color(0xFFE0F2FE),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: const Color(0xFFBAE6FD)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.stars, color: Color(0xFF0284C7), size: 14),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${balance ?? 0} Cr',
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0369A1)),
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
                                  icon: const Icon(Icons.notifications_none_outlined, color: Color(0xFF0F172A), size: 24),
                                  onPressed: () {},
                                ),
                                Positioned(
                                  top: 12,
                                  right: 12,
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Colors.redAccent,
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
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => const SizedBox(),
                ),
                const SizedBox(height: 24),

                // 2. Opportunities Heading (Matches Left Screen)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'New Opportunities',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Recommended leads in Jaipur',
                          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.filter_list, size: 14, color: Color(0xFF0284C7)),
                      label: const Text(
                        'Filter',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEFF6FF),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Color(0xFFDBEAFE)),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 3. Opportunities List Builder (Sleek card redesign)
                leadsAsync.when(
                  data: (leads) {
                    if (leads.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          children: const [
                            Icon(Icons.feed_outlined, size: 48, color: Color(0xFF94A3B8)),
                            SizedBox(height: 14),
                            Text(
                              'No new matching projects found.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF475569)),
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

                        // Check bid status
                        final hasBid = bidsMap.containsKey(id);
                        final bidStatus = bidsMap[id]?.toLowerCase() ?? 'pending';

                        Color? statusBadgeBg;
                        Color? statusBadgeText;
                        String statusLabel = '';
                        if (hasBid) {
                          if (bidStatus == 'accepted' || bidStatus == 'hired') {
                            statusBadgeBg = const Color(0xFFD1FAE5);
                            statusBadgeText = const Color(0xFF059669);
                            statusLabel = '✓ ACCEPTED';
                          } else if (bidStatus == 'rejected') {
                            statusBadgeBg = const Color(0xFFFEE2E2);
                            statusBadgeText = const Color(0xFFDC2626);
                            statusLabel = '✗ DECLINED';
                          } else {
                            statusBadgeBg = const Color(0xFFFEF3C7);
                            statusBadgeText = const Color(0xFFD97706);
                            statusLabel = '⚡ SENT';
                          }
                        }

                        // Budget string styling
                        final budgetStr = budgetMin == 0 && budgetMax == 0
                            ? 'Est. ₹12,000 - ₹15,000' // fallback placeholder matching screen
                            : budgetMin == budgetMax
                                ? 'Est. ₹$budgetMin'
                                : 'Est. ₹$budgetMin - ₹$budgetMax';

                        // Deduce clean description
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

                        // Determine badging category matching Left Screen
                        final isPremium = budgetMax >= 50000 || index % 3 == 2;
                        final isUrgent = category.toLowerCase() == 'plumber' || index % 3 == 1;

                        Color badgeBg = const Color(0xFFEFF6FF);
                        Color badgeText = const Color(0xFF0284C7);
                        String badgeLabel = 'NEW LEAD';
                        if (isPremium) {
                          badgeBg = const Color(0xFF0F172A);
                          badgeText = Colors.white;
                          badgeLabel = '★ PREMIUM';
                        } else if (isUrgent) {
                          badgeBg = const Color(0xFFFEE2E2);
                          badgeText = const Color(0xFFEF4444);
                          badgeLabel = 'URGENT';
                        }

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Top Badging & Time Row
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: badgeBg,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            badgeLabel,
                                            style: TextStyle(
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
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              statusLabel,
                                              style: TextStyle(
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
                                        const Icon(Icons.access_time, size: 12, color: Color(0xFF94A3B8)),
                                        const SizedBox(width: 4),
                                        Text(
                                          timeAgo,
                                          style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // Title
                                Text(
                                  title,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 10),

                                // Location
                                Row(
                                  children: [
                                    const Icon(Icons.location_on, size: 14, color: Color(0xFF0284C7)),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        rawAddress.startsWith('Lat:')
                                            ? 'Jagatpura, Jaipur (1.5 km away)' // Simulated coordinates distance
                                            : '$city, India (3.2 km away)',
                                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                // Budget
                                Row(
                                  children: [
                                    const Icon(Icons.wallet, size: 14, color: Color(0xFF64748B)),
                                    const SizedBox(width: 4),
                                    Text(
                                      budgetStr,
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),

                                // Description snippet
                                Text(
                                  cleanDesc,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                    color: Color(0xFF64748B),
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 14),

                                // Bottom tag pills wrap
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: [
                                    _buildTagChip('TOOLS REQUIRED'),
                                    _buildTagChip('SITE VISIT NEEDED'),
                                  ],
                                ),
                                const SizedBox(height: 18),

                                // Action Button
                                SizedBox(
                                  width: double.infinity,
                                  height: 48,
                                  child: hasBid
                                      ? (bidStatus == 'accepted' || bidStatus == 'hired'
                                          ? ElevatedButton.icon(
                                              onPressed: () => context.push('/chat', extra: id),
                                              icon: const Icon(Icons.chat_bubble_outline, size: 16),
                                              label: const Text('Chat with Customer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFF059669),
                                                foregroundColor: Colors.white,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                                elevation: 0,
                                              ),
                                            )
                                          : OutlinedButton(
                                              onPressed: () {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text('Your bid request is currently $bidStatus.')),
                                                );
                                              },
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: const Color(0xFF64748B),
                                                side: const BorderSide(color: Color(0xFFCBD5E1)),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                              ),
                                              child: Text(
                                                bidStatus == 'rejected' ? 'Bid Declined' : 'Bid Pending Review',
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                              ),
                                            ))
                                      : (isPremium
                                          ? ElevatedButton(
                                              onPressed: () => context.push('/send_proposal', extra: id),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFF0369A1),
                                                foregroundColor: Colors.white,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                                elevation: 0,
                                              ),
                                              child: const Text('Bid Now', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                            )
                                          : ElevatedButton(
                                              onPressed: () => context.push('/send_proposal', extra: id),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFFE0F2FE),
                                                foregroundColor: const Color(0xFF0369A1),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                                elevation: 0,
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
                  error: (e, _) => Center(child: Text('Error loading opportunities: $e')),
                ),
              ],
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
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
      ),
    );
  }
}
