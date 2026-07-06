import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/contractor_provider.dart';
import 'contractor_project_details_screen.dart';
import '../../../../core/theme/design_system.dart';

class ContractorQuotesScreen extends ConsumerStatefulWidget {
  const ContractorQuotesScreen({super.key});

  @override
  ConsumerState<ContractorQuotesScreen> createState() => _ContractorQuotesScreenState();
}

class _ContractorQuotesScreenState extends ConsumerState<ContractorQuotesScreen> {
  String _activeTab = 'All Bids';
  final List<String> _tabs = ['All Bids', 'Pending', 'Accepted', 'Rejected'];

  Future<List<Map<String, dynamic>>> _fetchContractorQuotes() async {
    final userId = Supabase.instance.client.auth.currentUser!.id;
    final contractor = await Supabase.instance.client
        .from('contractors')
        .select('id')
        .eq('user_id', userId)
        .single();

    final response = await Supabase.instance.client
        .from('applications')
        .select('*, projects(*)')
        .eq('contractor_id', contractor['id']);

    return List<Map<String, dynamic>>.from(response);
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isLargeScreen = screenWidth > 840;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkSurface,
        elevation: 0,
        title: Text(
          'My Submitted Quotes',
          style: AppTypography.title.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: SizedBox(
          width: isLargeScreen ? 840 : double.infinity,
          child: Column(
            children: [
              // Tab Chip filters
              Container(
                height: 56,
                color: AppColors.darkSurface,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(left: AppSpacing.lg),
                  itemCount: _tabs.length,
                  itemBuilder: (context, index) {
                    final tab = _tabs[index];
                    final isSelected = _activeTab == tab;
                    return Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: ChoiceChip(
                        label: Text(
                          tab,
                          style: AppTypography.caption.copyWith(
                            color: isSelected ? Colors.white : AppColors.textSecondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: AppColors.primary,
                        backgroundColor: AppColors.darkCard,
                        checkmarkColor: Colors.white,
                        side: BorderSide(
                          color: isSelected ? Colors.transparent : AppColors.darkBorder,
                          width: 1.0,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _activeTab = tab;
                            });
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // Main list builder
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _fetchContractorQuotes(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.xxl),
                          child: Text('Error: ${snapshot.error}', style: const TextStyle(color: AppColors.error)),
                        ),
                      );
                    }

                    final quotes = snapshot.data ?? [];
                    final filteredQuotes = quotes.where((q) {
                      final status = (q['status'] ?? 'pending').toString().toLowerCase();
                      if (_activeTab == 'All Bids') return true;
                      if (_activeTab == 'Pending') return status == 'pending';
                      if (_activeTab == 'Accepted') return status == 'accepted' || status == 'hired';
                      if (_activeTab == 'Rejected') return status == 'rejected';
                      return true;
                    }).toList();

                    if (filteredQuotes.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.assignment_turned_in_outlined, size: 56, color: AppColors.textMuted),
                            const SizedBox(height: AppSpacing.lg),
                            Text(
                              'No $_activeTab found',
                              style: AppTypography.smallBody.copyWith(fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      itemCount: filteredQuotes.length,
                      itemBuilder: (context, index) {
                        final quote = filteredQuotes[index];
                        final project = quote['projects'] as Map<String, dynamic>?;
                        if (project == null) return const SizedBox();

                        final title = project['title'] ?? 'Luxury Project Lead';
                        final city = project['city'] ?? 'Location';
                        final category = project['category'] ?? 'General';
                        final status = (quote['status'] ?? 'pending').toString().toLowerCase();

                        final costMin = quote['estimated_cost_min'] ?? 0;
                        final costMax = quote['estimated_cost_max'] ?? 0;
                        final amount = costMin == costMax ? '₹$costMin' : '₹$costMin - ₹$costMax';
                        final timeline = quote['estimated_timeline'] ?? 'Flexible';

                        Color statusColor = AppColors.warning;
                        Color statusBg = AppColors.warning.withOpacity(0.12);
                        if (status == 'accepted' || status == 'hired') {
                          statusColor = AppColors.success;
                          statusBg = AppColors.success.withOpacity(0.12);
                        } else if (status == 'rejected') {
                          statusColor = AppColors.error;
                          statusBg = AppColors.error.withOpacity(0.12);
                        }

                        IconData categoryIcon = Icons.home_repair_service;
                        if (category.toLowerCase() == 'plumber') {
                          categoryIcon = Icons.plumbing;
                        } else if (category.toLowerCase() == 'electrician') {
                          categoryIcon = Icons.electrical_services;
                        } else if (category.toLowerCase() == 'painter') {
                          categoryIcon = Icons.format_paint;
                        } else if (category.toLowerCase() == 'carpenter') {
                          categoryIcon = AppIcons.handyman;
                        } else if (category.toLowerCase() == 'mason') {
                          categoryIcon = Icons.architecture;
                        }

                        return Container(
                          margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                          decoration: BoxDecoration(
                            color: AppColors.darkCard,
                            borderRadius: BorderRadius.circular(AppRadius.large),
                            border: Border.all(color: AppColors.darkBorder, width: 1.0),
                            boxShadow: AppShadows.darkCardShadow,
                          ),
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ContractorProjectDetailsScreen(quote: quote),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(AppRadius.large),
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(AppSpacing.sm),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(AppRadius.small),
                                        ),
                                        child: Icon(categoryIcon, color: AppColors.primaryLight, size: 18),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: statusBg,
                                          borderRadius: BorderRadius.circular(AppRadius.small),
                                        ),
                                        child: Text(
                                          status.toUpperCase(),
                                          style: AppTypography.caption.copyWith(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  Text(
                                    title,
                                    style: AppTypography.smallBody.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textMuted),
                                      const SizedBox(width: 4),
                                      Text('$city, India', style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  const Divider(height: 1, color: AppColors.darkDivider),
                                  const SizedBox(height: AppSpacing.md),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Bid Cost Range', style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
                                          const SizedBox(height: 3),
                                          Text(amount, style: AppTypography.smallBody.copyWith(fontWeight: FontWeight.bold, color: AppColors.success)),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text('Time Estimate', style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
                                          const SizedBox(height: 3),
                                          Text(timeline, style: AppTypography.smallBody.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                                        ],
                                      ),
                                    ],
                                  ),
                                  if (status == 'accepted' || status == 'hired') ...[
                                    const SizedBox(height: AppSpacing.md),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 44,
                                      child: ElevatedButton.icon(
                                        onPressed: () => context.push('/chat', extra: project['id']),
                                        icon: const Icon(Icons.chat_bubble_outline, size: 14, color: Colors.white),
                                        label: const Text('Open Chat Room', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          padding: EdgeInsets.zero,
                                          shape: RoundedRectangleBorder(borderRadius: AppRadius.buttonBorderRadius),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
