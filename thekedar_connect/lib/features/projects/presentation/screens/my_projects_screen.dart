import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import '../providers/project_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../contractor/presentation/screens/contractor_profile_details_screen.dart';
import '../../../../widgets/shimmer_placeholder.dart';
import '../../../../core/theme/design_system.dart';

class MyProjectsScreen extends ConsumerStatefulWidget {
  const MyProjectsScreen({super.key});

  @override
  ConsumerState<MyProjectsScreen> createState() => _MyProjectsScreenState();
}

class _MyProjectsScreenState extends ConsumerState<MyProjectsScreen> {
  String _activeFilter = 'All Projects';
  final List<String> _filters = ['All Projects', 'Active', 'Pending', 'Completed'];

  @override
  Widget build(BuildContext context) {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      return const Scaffold(
        backgroundColor: AppColors.darkBackground,
        body: Center(
          child: Text('Not logged in', style: TextStyle(color: AppColors.textPrimary)),
        ),
      );
    }

    final projectsAsync = ref.watch(customerProjectsProvider(userId));
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isLargeScreen = screenWidth > 840;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkSurface,
        elevation: 0,
        title: Text(
          'My Projects',
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
          IconButton(
            icon: const Icon(Icons.more_vert, color: AppColors.textPrimary),
            onPressed: () {},
          ),
        ],
      ),
      body: Center(
        child: SizedBox(
          width: isLargeScreen ? 1024 : double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Horizontal Status Filters
              Container(
                height: 56,
                color: AppColors.darkSurface,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(left: AppSpacing.lg),
                  itemCount: _filters.length,
                  itemBuilder: (context, index) {
                    final filter = _filters[index];
                    final isSelected = _activeFilter == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: ChoiceChip(
                        label: Text(
                          filter,
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
                              _activeFilter = filter;
                            });
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // 2. Projects List builder
              Expanded(
                child: projectsAsync.when(
                  data: (projects) {
                    final filteredProjects = projects.where((p) {
                      final status = (p['status'] ?? 'active').toString().toLowerCase();
                      if (_activeFilter == 'All Projects') return true;
                      if (_activeFilter == 'Active') return status == 'active';
                      if (_activeFilter == 'Pending') return status == 'pending';
                      if (_activeFilter == 'Completed') return status == 'completed';
                      return true;
                    }).toList();

                    if (filteredProjects.isEmpty) {
                      return RefreshIndicator(
                        onRefresh: () async {
                          ref.invalidate(customerProjectsProvider(userId));
                        },
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Container(
                            height: MediaQuery.of(context).size.height * 0.6,
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.assignment_late_outlined, size: 64, color: AppColors.textMuted),
                                const SizedBox(height: AppSpacing.lg),
                                Text(
                                  'No $_activeFilter found',
                                  style: AppTypography.subtitle.copyWith(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () async {
                        ref.invalidate(customerProjectsProvider(userId));
                      },
                      child: ListView.builder(
                        itemCount: filteredProjects.length,
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        itemBuilder: (context, index) {
                          final p = filteredProjects[index];
                          final status = (p['status'] ?? 'active').toString();
                          final category = p['category'] ?? 'General';
                          final city = p['city'] ?? 'Unknown';
                          final title = p['title'] ?? 'Untitled Project';

                          Color statusColor = AppColors.primaryLight;
                          Color statusBg = AppColors.primary.withOpacity(0.12);
                          if (status.toLowerCase() == 'completed') {
                            statusColor = AppColors.success;
                            statusBg = AppColors.success.withOpacity(0.12);
                          } else if (status.toLowerCase() == 'pending') {
                            statusColor = AppColors.warning;
                            statusBg = AppColors.warning.withOpacity(0.12);
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
                                    builder: (context) => ProjectDetailsScreen(project: p),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(AppRadius.large),
                              child: Padding(
                                padding: const EdgeInsets.all(AppSpacing.xxl),
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
                                          child: Icon(categoryIcon, color: AppColors.primaryLight, size: 20),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: statusBg,
                                            borderRadius: BorderRadius.circular(AppRadius.small),
                                          ),
                                          child: Text(
                                            status.toUpperCase(),
                                            style: AppTypography.caption.copyWith(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: statusColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: AppSpacing.lg),
                                    Text(
                                      title,
                                      style: AppTypography.subtitle.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.xs),
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textMuted),
                                        const SizedBox(width: 4),
                                        Text(
                                          '$city, India',
                                          style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: AppSpacing.lg),
                                    const Divider(height: 1, thickness: 1, color: AppColors.darkDivider),
                                    const SizedBox(height: AppSpacing.md),
                                    Row(
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Budget',
                                              style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Est. Standard',
                                              style: AppTypography.body.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const Spacer(),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              'Quotes',
                                              style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                                            ),
                                            const SizedBox(height: 4),
                                            FutureBuilder<int>(
                                              future: Supabase.instance.client
                                                  .from('applications')
                                                  .select('id')
                                                  .eq('project_id', p['id'])
                                                  .then((value) => value.length),
                                              builder: (context, snapshot) {
                                                final count = snapshot.data ?? 0;
                                                final countStr = count < 10 ? '0$count' : '$count';
                                                return Text(
                                                  '$countStr Received',
                                                  style: AppTypography.body.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                    color: AppColors.textPrimary,
                                                  ),
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                  loading: () => const ProjectListSkeleton(),
                  error: (e, st) => Center(child: Text('Error: $e', style: const TextStyle(color: AppColors.error))),
                ),
              ),
            ],
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
}

// -------------------------------------------------------------
// Pixel-Perfect Project Details Screen
// -------------------------------------------------------------
class ProjectDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> project;

  const ProjectDetailsScreen({super.key, required this.project});

  @override
  State<ProjectDetailsScreen> createState() => _ProjectDetailsScreenState();
}

class _ProjectDetailsScreenState extends State<ProjectDetailsScreen> {
  String _readableAddress = '';
  bool _isGeocoding = false;

  @override
  void initState() {
    super.initState();
    _fetchReadableAddress();
  }

  Future<void> _fetchReadableAddress() async {
    final rawAddress = widget.project['address_text'] ?? '';
    if (rawAddress.startsWith('Lat:')) {
      setState(() => _isGeocoding = true);
      try {
        final cleanString = rawAddress.replaceAll('Lat:', '').replaceAll('Lon:', '').trim();
        final parts = cleanString.split(',');
        if (parts.length == 2) {
          final lat = double.parse(parts[0].trim());
          final lon = double.parse(parts[1].trim());

          final placemarks = await geocoding.placemarkFromCoordinates(lat, lon);
          if (placemarks.isNotEmpty) {
            final pm = placemarks.first;
            setState(() {
              _readableAddress = "${pm.name ?? ''}, ${pm.locality ?? ''}, ${pm.subAdministrativeArea ?? ''}, ${pm.administrativeArea ?? ''}";
            });
          }
        }
      } catch (e) {
        setState(() {
          _readableAddress = rawAddress;
        });
      } finally {
        setState(() => _isGeocoding = false);
      }
    } else {
      setState(() {
        _readableAddress = rawAddress;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.project['title'] ?? 'Luxury Project';
    final category = widget.project['category'] ?? 'Construction';
    final city = widget.project['city'] ?? 'Location';
    final desc = widget.project['description'] ?? '';

    // Parse drawing PDF
    String? pdfUrl;
    final pdfMatch = RegExp(r'\[Drawing PDF URL:\s*(https?://[^\s\]]+)').firstMatch(desc);
    if (pdfMatch != null) {
      pdfUrl = pdfMatch.group(1);
    }

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

    String? plotArea;
    final plotMatch = RegExp(r'\[Plot Area:\s*([^\s\]]+)\s*(?:sq\.ft|Sq\.ft)?\]').firstMatch(desc);
    if (plotMatch != null) {
      plotArea = plotMatch.group(1);
    }

    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isLargeScreen = screenWidth > 840;

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
          'Project Details',
          style: AppTypography.title.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: AppColors.textPrimary),
            onPressed: () {},
          ),
        ],
      ),
      body: Center(
        child: SizedBox(
          width: isLargeScreen ? 840 : double.infinity,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Photo Gallery
                if (imageUrls.isNotEmpty)
                  Container(
                    height: 240,
                    color: AppColors.darkSurface,
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      itemCount: imageUrls.length,
                      itemBuilder: (context, index) {
                        return Container(
                          width: 320,
                          margin: const EdgeInsets.only(right: AppSpacing.lg),
                          decoration: BoxDecoration(
                            color: AppColors.darkCard,
                            borderRadius: BorderRadius.circular(AppRadius.large),
                            border: Border.all(color: AppColors.darkBorder),
                            boxShadow: AppShadows.darkCardShadow,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadius.large - 1.0),
                            child: Image.network(
                              imageUrls[index],
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              errorBuilder: (context, error, stackTrace) => const Center(
                                child: Icon(Icons.broken_image, color: AppColors.textMuted, size: 40),
                              ),
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                // 2. Specifications Detail Card
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: AppTypography.subtitle.copyWith(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(AppRadius.small),
                            ),
                            child: Text(
                              'EST. VALUE',
                              style: AppTypography.caption.copyWith(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryLight,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, color: AppColors.primaryLight, size: 16),
                          const SizedBox(width: 4),
                          Expanded(
                            child: _isGeocoding
                                ? const LinearProgressIndicator(minHeight: 2, color: AppColors.primary)
                                : Text(
                                    _readableAddress.isEmpty ? '$city, India' : _readableAddress,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                                  ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      
                      if (cleanDesc.isNotEmpty) ...[
                        Text(
                          cleanDesc,
                          style: AppTypography.body.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                      ],

                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildDetailTag(category),
                          if (plotArea != null) _buildDetailTag('$plotArea Sq.ft'),
                          _buildDetailTag('Site Work'),
                          _buildDetailTag('Verified Details'),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      
                      // Drawing pdf attachment link
                      if (pdfUrl != null) ...[
                        Text(
                          'Attachments',
                          style: AppTypography.subtitle.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        InkWell(
                          onTap: () async {
                            try {
                              final uri = Uri.parse(pdfUrl!);
                              final success = await launchUrl(uri, mode: LaunchMode.inAppWebView);
                              if (!success) {
                                Clipboard.setData(ClipboardData(text: pdfUrl!));
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Copied drawing URL to clipboard!')),
                                  );
                                }
                              }
                            } catch (e) {
                              Clipboard.setData(ClipboardData(text: pdfUrl!));
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Copied link to clipboard!')),
                                );
                              }
                            }
                          },
                          borderRadius: BorderRadius.circular(AppRadius.medium),
                          child: Container(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            decoration: BoxDecoration(
                              color: AppColors.darkCard,
                              borderRadius: BorderRadius.circular(AppRadius.medium),
                              border: Border.all(color: AppColors.darkBorder),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.picture_as_pdf, color: AppColors.error, size: 28),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Text(
                                    pdfUrl!.split('/').last,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                  ),
                                ),
                                const Icon(Icons.open_in_new, color: AppColors.primaryLight, size: 20),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                      ],

                      Text(
                        'Quotes Received',
                        style: AppTypography.subtitle.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      FutureBuilder<List<Map<String, dynamic>>>(
                        future: Supabase.instance.client
                            .from('applications')
                            .select('*, contractors(*)')
                            .eq('project_id', widget.project['id']),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                          }
                          if (snapshot.hasError) {
                            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: AppColors.error)));
                          }
                          final quotes = snapshot.data ?? [];
                          if (quotes.isEmpty) {
                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(AppSpacing.xxl),
                              decoration: BoxDecoration(
                                color: AppColors.darkCard,
                                borderRadius: BorderRadius.circular(AppRadius.large),
                                border: Border.all(color: AppColors.darkBorder),
                              ),
                              child: Column(
                                children: [
                                  const Icon(Icons.assignment_outlined, size: 48, color: AppColors.textMuted),
                                  const SizedBox(height: AppSpacing.md),
                                  Text(
                                    'No quotes received yet',
                                    style: AppTypography.smallBody.copyWith(fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    'Contractors will review your project and bid shortly.',
                                    textAlign: TextAlign.center,
                                    style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                            );
                          }

                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: quotes.length,
                            itemBuilder: (context, index) {
                              return _buildRealQuoteCard(context, quotes[index]);
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(AppRadius.circular),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildRealQuoteCard(BuildContext context, Map<String, dynamic> quote) {
    final contractor = quote['contractors'] as Map<String, dynamic>?;
    final businessName = contractor?['business_name'] ?? 'Verified Contractor';
    final exp = contractor?['years_experience'] != null ? '${contractor!['years_experience']} years exp' : 'New Contractor';
    final rating = contractor?['average_rating'] != null ? contractor!['average_rating'].toString() : '5.0';
    
    final costMin = quote['estimated_cost_min'] ?? 0;
    final costMax = quote['estimated_cost_max'] ?? 0;
    final amount = costMin == costMax ? '₹$costMin' : '₹$costMin - ₹$costMax';
    final timeline = quote['estimated_timeline'] ?? 'Flexible';
    final coverMessage = quote['cover_message'] ?? '';
    final quoteId = quote['id'];
    final quoteStatus = (quote['status'] ?? 'pending').toString().toLowerCase();
    final contractorId = quote['contractor_id'];

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: AppColors.darkBorder, width: 1.0),
      ),
      child: InkWell(
        onTap: () async {
          if (contractor != null) {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ContractorProfileDetailsScreen(
                  contractor: contractor,
                  quote: quote,
                  project: widget.project,
                ),
              ),
            );
            if (result == true) {
              setState(() {});
            }
          }
        },
        borderRadius: BorderRadius.circular(AppRadius.large),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primary.withOpacity(0.15),
                    child: Text(businessName[0].toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryLight)),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          businessName,
                          style: AppTypography.smallBody.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '$exp • Rating $rating ★',
                          style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        amount,
                        style: AppTypography.smallBody.copyWith(fontWeight: FontWeight.bold, color: AppColors.success),
                      ),
                      Text(
                        timeline,
                        style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  )
                ],
              ),
              if (coverMessage.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.darkSurface,
                    borderRadius: BorderRadius.circular(AppRadius.medium),
                  ),
                  child: Text(
                    coverMessage,
                    style: AppTypography.caption.copyWith(color: AppColors.textSecondary, height: 1.4),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              if (quoteStatus == 'pending')
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: AppGradients.primaryGradient,
                          borderRadius: AppRadius.buttonBorderRadius,
                        ),
                        child: ElevatedButton(
                          onPressed: () async {
                            try {
                              await Supabase.instance.client
                                  .from('applications')
                                  .update({'status': 'hired'}).eq('id', quoteId);

                              await Supabase.instance.client
                                  .from('projects')
                                  .update({'hired_contractor_id': contractorId}).eq('id', widget.project['id']);

                              setState(() {});
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Quote accepted!')));
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(borderRadius: AppRadius.buttonBorderRadius),
                          ),
                          child: const Text('Accept', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          try {
                            await Supabase.instance.client
                                .from('applications')
                                .update({'status': 'rejected'}).eq('id', quoteId);
                            setState(() {});
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Quote rejected!')));
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.darkBorder),
                          foregroundColor: AppColors.textSecondary,
                          shape: RoundedRectangleBorder(borderRadius: AppRadius.buttonBorderRadius),
                        ),
                        child: const Text('Reject'),
                      ),
                    ),
                  ],
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: quoteStatus == 'hired' ? AppColors.success.withOpacity(0.12) : AppColors.error.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(AppRadius.small),
                        ),
                        child: Text(
                          quoteStatus.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: quoteStatus == 'hired' ? AppColors.success : AppColors.error,
                          ),
                        ),
                      ),
                    ),
                    if (quoteStatus == 'hired') ...[
                      const SizedBox(height: AppSpacing.md),
                      SizedBox(
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            context.push('/chat', extra: widget.project['id']);
                          },
                          icon: const Icon(Icons.chat_bubble_outline, size: 16, color: Colors.white),
                          label: const Text('Chat with Contractor', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: AppRadius.buttonBorderRadius),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
