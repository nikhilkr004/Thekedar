import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thekedar_connect/l10n/app_localizations.dart';
import '../../../../core/theme/design_system.dart';
import '../../../contractor/presentation/providers/contractor_provider.dart';
import '../../../contractor/presentation/models/contractor_profile.dart';

class CustomerHomeScreen extends ConsumerWidget {
  const CustomerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isLargeScreen = screenWidth > 840;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkSurface,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: AppColors.textPrimary),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text(
          'Thekedar Connect',
          style: AppTypography.title.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: AppColors.textPrimary),
            onPressed: () {},
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primary.withOpacity(0.15),
              child: const Icon(AppIcons.profile, size: 20, color: AppColors.primaryLight),
            ),
          ),
        ],
      ),
      drawer: const Drawer(),
      body: Center(
        child: SizedBox(
          width: isLargeScreen ? 1024 : double.infinity,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Dream Project Hero Banner
                Container(
                  margin: const EdgeInsets.all(AppSpacing.lg),
                  padding: const EdgeInsets.all(AppSpacing.xxl),
                  decoration: BoxDecoration(
                    gradient: AppGradients.primaryGradient,
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.2),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      )
                    ],
                  ),
                  child: Stack(
                    children: [
                      const Positioned(
                        right: -20,
                        bottom: -20,
                        child: Opacity(
                          opacity: 0.08,
                          child: Icon(
                            Icons.architecture,
                            size: 150,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Build Your Dream Project Today',
                            style: AppTypography.display.copyWith(
                              color: Colors.white,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Connect with India\'s most trusted contractors and specialists.',
                            style: AppTypography.body.copyWith(
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxl),
                          ElevatedButton(
                            onPressed: () => context.push('/post_project'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.primaryDark,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl, vertical: AppSpacing.md),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppRadius.circular),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Text(
                                  'Post a Project',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(Icons.arrow_forward, size: 16),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // 2. Our Services Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                  child: Row(
                    children: [
                      Text(
                        'Our Services',
                        style: AppTypography.subtitle.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {},
                        child: Text(
                          'View All',
                          style: AppTypography.smallBody.copyWith(
                            color: AppColors.primaryLight,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Service Grid
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: isLargeScreen ? 4 : 2,
                    crossAxisSpacing: AppSpacing.lg,
                    mainAxisSpacing: AppSpacing.lg,
                    childAspectRatio: isLargeScreen ? 1.6 : 1.3,
                    children: [
                      _buildServiceCard('Plumber', Icons.plumbing),
                      _buildServiceCard('Electrician', Icons.electrical_services),
                      _buildServiceCard('Painter', Icons.format_paint),
                      _buildServiceCard('Carpenter', AppIcons.handyman),
                    ],
                  ),
                ),
                
                // Full Width Service Card for Civil Work
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.darkCard,
                      borderRadius: BorderRadius.circular(AppRadius.large),
                      border: Border.all(color: AppColors.darkBorder, width: 1.0),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: AppColors.electricBlue.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.home_work_outlined,
                            color: AppColors.electricBlue,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.lg),
                        Text(
                          'Civil Work',
                          style: AppTypography.body.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.chevron_right, color: AppColors.textMuted),
                      ],
                    ),
                  ),
                ),

                // 3. How It Works Block
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                  padding: const EdgeInsets.all(AppSpacing.xxl),
                  decoration: BoxDecoration(
                    color: AppColors.darkSurface,
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    border: Border.all(color: AppColors.darkBorder, width: 1.0),
                  ),
                  child: Column(
                    children: [
                      Text(
                        l10n.howItWorks,
                        style: AppTypography.subtitle.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.spacing32),
                      _buildStepItem('1', l10n.postProject, l10n.postProjectDesc),
                      const SizedBox(height: 20),
                      _buildStepItem('2', l10n.connect, l10n.connectDesc),
                      const SizedBox(height: 20),
                      _buildStepItem('3', l10n.build, l10n.buildDesc),
                    ],
                  ),
                ),

                // 4. Top Rated Experts
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.lg),
                  child: Row(
                    children: [
                      Text(
                        l10n.topRatedExperts,
                        style: AppTypography.subtitle.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {},
                        child: Text(
                          l10n.seeExperts,
                          style: AppTypography.smallBody.copyWith(
                            color: AppColors.primaryLight,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Experts horizontal list
                ref.watch(topContractorsProvider).when(
                  data: (contractors) {
                    if (contractors.isEmpty) {
                      return const SizedBox(
                        height: 280,
                        child: Center(
                          child: Text(
                            'No verified experts found yet.',
                            style: TextStyle(color: AppColors.textMuted),
                          ),
                        ),
                      );
                    }
                    return SizedBox(
                      height: 280,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.only(left: AppSpacing.lg),
                        itemCount: contractors.length,
                        itemBuilder: (context, index) {
                          final c = contractors[index];
                          final exp = '${c.yearsExperience} years';
                          final primaryCategory = c.categories.isNotEmpty ? c.categories.first : 'Contractor';
                          return _buildExpertCard(
                            context,
                            c,
                            exp,
                            5.0, // Initial 5-star rating as requested
                          );
                        },
                      ),
                    );
                  },
                  loading: () => const SizedBox(
                    height: 280,
                    child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                  ),
                  error: (e, s) => const SizedBox(
                    height: 280,
                    child: Center(
                      child: Text(
                        'Failed to load experts.',
                        style: TextStyle(color: AppColors.error),
                      ),
                    ),
                  ),
                ),

                 // 5. Customer Stories
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.spacing32, AppSpacing.lg, AppSpacing.md),
                  child: Text(
                    l10n.customerStories,
                    style: AppTypography.subtitle.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                
                SizedBox(
                  height: 165,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.only(left: AppSpacing.lg),
                    children: [
                      _buildStoryCard(l10n.story1, 'Ananya R.'),
                      _buildStoryCard(l10n.story2, 'Samir K.'),
                    ],
                  ),
                ),

                // 6. Why Choose Us
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.spacing32, AppSpacing.lg, AppSpacing.lg),
                  child: Center(
                    child: Text(
                      l10n.whyChooseUs,
                      style: AppTypography.subtitle.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
                
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: isLargeScreen ? 4 : 2,
                    crossAxisSpacing: AppSpacing.lg,
                    mainAxisSpacing: AppSpacing.lg,
                    childAspectRatio: isLargeScreen ? 1.6 : 1.4,
                    children: [
                      _buildFeatureItem(AppIcons.verify, 'Background\nChecked', AppColors.success),
                      _buildFeatureItem(Icons.payments_outlined, 'Upfront Pricing', AppColors.electricBlue),
                      _buildFeatureItem(Icons.shield_outlined, 'Quality Guarantee', AppColors.secondary),
                      _buildFeatureItem(Icons.support_agent_outlined, '24/7 Support', AppColors.warning),
                    ],
                  ),
                ),

                // 7. Bottom Shield Banner
                Container(
                  margin: const EdgeInsets.all(AppSpacing.lg),
                  padding: const EdgeInsets.all(AppSpacing.xxl),
                  decoration: BoxDecoration(
                    color: AppColors.darkSurface,
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    border: Border.all(color: AppColors.darkBorder, width: 1.0),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          AppIcons.check,
                          color: AppColors.success,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Professional Shield Protection',
                        style: AppTypography.subtitle.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Every booking is insured. We guarantee quality workmanship or your money back.',
                        textAlign: TextAlign.center,
                        style: AppTypography.smallBody.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.darkCard,
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: AppColors.darkBorder),
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl, vertical: AppSpacing.md),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.circular),
                          ),
                        ),
                        child: const Text('Learn More'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.spacing80),
              ],
            ),
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/post_project'),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildServiceCard(String title, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: AppColors.darkBorder, width: 1.0),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: AppColors.primaryLight,
              size: 24,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            title,
            style: AppTypography.caption.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem(String step, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            step,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.smallBody.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                description,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showContractorDetails(BuildContext context, ContractorProfile c) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: AppColors.darkSurface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 48,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textMuted.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.expertProfile,
                      style: AppTypography.title.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textPrimary),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(color: AppColors.darkBorder),
              
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 36,
                            backgroundColor: AppColors.primary.withOpacity(0.15),
                            child: const Icon(Icons.person, size: 40, color: AppColors.primaryLight),
                          ),
                          const SizedBox(width: AppSpacing.lg),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  c.fullName,
                                  style: AppTypography.subtitle.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                if (c.businessName.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    c.businessName,
                                    style: AppTypography.smallBody.copyWith(
                                      color: AppColors.primaryLight,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.star, color: AppColors.warning, size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      '5.0 (${l10n.topRatedExperts})',
                                      style: AppTypography.caption.copyWith(
                                        color: AppColors.warning,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (c.aadhaarVerified)
                            _buildDocBadge('Aadhaar ${l10n.verified}', AppColors.success),
                          if (c.panVerified)
                            _buildDocBadge('PAN ${l10n.verified}', AppColors.success),
                          if (c.gstVerified)
                            _buildDocBadge('GST ${l10n.verified}', AppColors.success),
                          _buildDocBadge('${c.yearsExperience} Years Exp', AppColors.electricBlue),
                          _buildDocBadge('${c.projectsCompleted} Projects Done', AppColors.secondary),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      
                      Text(
                        l10n.about,
                        style: AppTypography.smallBody.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        c.bio.isNotEmpty ? c.bio : 'No profile description provided.',
                        style: AppTypography.smallBody.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      
                      Text(
                        l10n.specialties,
                        style: AppTypography.smallBody.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: c.categories.map((cat) {
                          return Chip(
                            label: Text(cat, style: const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
                            backgroundColor: AppColors.darkCard,
                            side: const BorderSide(color: AppColors.darkBorder),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      if (c.portfolioUrls.isNotEmpty) ...[
                        Text(
                          l10n.portfolioGallery,
                          style: AppTypography.smallBody.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 120,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: c.portfolioUrls.length,
                            itemBuilder: (context, i) {
                              return Container(
                                width: 160,
                                margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.darkBorder),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    c.portfolioUrls[i],
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, _, __) => const Center(
                                      child: Icon(Icons.image, color: AppColors.textMuted),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                      ],
                    ],
                  ),
                ),
              ),
              
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: const BoxDecoration(
                  color: AppColors.darkCard,
                  border: Border(top: BorderSide(color: AppColors.darkBorder)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.phone, color: AppColors.textPrimary),
                        label: Text(c.phone.isNotEmpty ? c.phone : 'No Phone', style: const TextStyle(color: AppColors.textPrimary)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.darkBorder),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          context.go('/chat_list');
                        },
                        icon: const Icon(Icons.chat_bubble_outline),
                        label: Text(l10n.chatNow),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
    );
  }

  Widget _buildDocBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildExpertCard(BuildContext context, ContractorProfile contractor, String exp, double rating) {
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: () => _showContractorDetails(context, contractor),
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: AppSpacing.lg, bottom: AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(AppRadius.large),
          border: Border.all(color: AppColors.darkBorder, width: 1.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.large)),
              child: Container(
                height: 120,
                width: double.infinity,
                color: AppColors.darkSurface,
                child: const Icon(AppIcons.profile, size: 50, color: AppColors.textMuted),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(AppRadius.small),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star, color: AppColors.warning, size: 12),
                            const SizedBox(width: 2),
                            Text(
                              rating.toString(),
                              style: AppTypography.caption.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.warning,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    contractor.fullName,
                    style: AppTypography.smallBody.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${contractor.categories.isNotEmpty ? contractor.categories.first : "Contractor"} • $exp',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(AppRadius.small),
                        ),
                        child: Text(
                          l10n.verified,
                          style: AppTypography.caption.copyWith(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.electricBlue.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(AppRadius.small),
                        ),
                        child: Text(
                          l10n.available,
                          style: AppTypography.caption.copyWith(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: AppColors.electricBlue,
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStoryCard(String quote, String author) {
    return Container(
      width: 270,
      margin: const EdgeInsets.only(right: AppSpacing.lg, bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: AppColors.darkBorder, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(
              5,
              (index) => const Icon(Icons.star, color: AppColors.warning, size: 14),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: Text(
              '"$quote"',
              style: AppTypography.caption.copyWith(
                fontStyle: FontStyle.italic,
                color: AppColors.textSecondary,
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '— $author',
            style: AppTypography.caption.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: AppColors.darkBorder, width: 1.0),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: AppSpacing.sm),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTypography.caption.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
