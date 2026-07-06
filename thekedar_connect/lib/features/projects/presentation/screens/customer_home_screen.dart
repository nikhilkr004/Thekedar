import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/design_system.dart';

class CustomerHomeScreen extends ConsumerWidget {
  const CustomerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isLargeScreen = screenWidth > 840;

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
                            'Build Your Dream\nProject Today',
                            style: AppTypography.display.copyWith(
                              color: Colors.white,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Connect with India\'s most trusted\ncontractors and specialists.',
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
                    childAspectRatio: 1.3,
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
                        'How It Works',
                        style: AppTypography.subtitle.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.spacing32),
                      _buildStepItem('1', 'Post Project', 'Describe your needs and budget in minutes.'),
                      const SizedBox(height: 20),
                      _buildStepItem('2', 'Connect', 'Get matched with verified local experts.'),
                      const SizedBox(height: 20),
                      _buildStepItem('3', 'Build', 'Review quotes and hire the best professional.'),
                    ],
                  ),
                ),

                // 4. Top Rated Experts
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.lg),
                  child: Row(
                    children: [
                      Text(
                        'Top Rated Experts',
                        style: AppTypography.subtitle.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {},
                        child: Text(
                          'See Experts',
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
                SizedBox(
                  height: 280,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.only(left: AppSpacing.lg),
                    children: [
                      _buildExpertCard(
                        'Rajesh Kumar',
                        'Master Electrician',
                        '12 years',
                        4.9,
                      ),
                      _buildExpertCard(
                        'Amit Singh',
                        'Expert Painter',
                        '8 years',
                        4.8,
                      ),
                    ],
                  ),
                ),

                // 5. Customer Stories
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.spacing32, AppSpacing.lg, AppSpacing.md),
                  child: Text(
                    'Customer Stories',
                    style: AppTypography.subtitle.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                
                SizedBox(
                  height: 140,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.only(left: AppSpacing.lg),
                    children: [
                      _buildStoryCard('Found a great plumber in 10 minutes. Job done perfectly!', 'Ananya R.'),
                      _buildStoryCard('Transparent pricing and very highly professional work!', 'Samir K.'),
                    ],
                  ),
                ),

                // 6. Why Choose Us
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.spacing32, AppSpacing.lg, AppSpacing.lg),
                  child: Center(
                    child: Text(
                      'Why Choose Us',
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
                    childAspectRatio: 1.4,
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

  Widget _buildExpertCard(String name, String role, String exp, double rating) {
    String imagePath = '';
    if (name.contains('Rajesh')) {
      imagePath = 'assets/images/expert_rajesh.png';
    } else if (name.contains('Amit')) {
      imagePath = 'assets/images/expert_amit.png';
    }

    return Container(
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
              child: imagePath.isNotEmpty
                  ? Image.asset(imagePath, fit: BoxFit.cover)
                  : const Icon(AppIcons.profile, size: 50, color: AppColors.textMuted),
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
                  name,
                  style: AppTypography.smallBody.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '$role • $exp',
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
                        'VERIFIED',
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
                        'AVAILABLE',
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
    );
  }

  Widget _buildStoryCard(String quote, String author) {
    return Container(
      width: 240,
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
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
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
