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
    debugPrint('MyProjectsScreen debug: userId = $userId');
    if (userId == null) {
      return const Scaffold(body: Center(child: Text('Not logged in')));
    }

    final projectsAsync = ref.watch(customerProjectsProvider(userId));
    debugPrint('MyProjectsScreen debug: projectsAsync = $projectsAsync');

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'My Projects',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Color(0xFF64748B)),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Color(0xFF64748B)),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Horizontal Status Filters
          Container(
            height: 48,
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: 16),
              itemCount: _filters.length,
              itemBuilder: (context, index) {
                final filter = _filters[index];
                final isSelected = _activeFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(
                      filter,
                      style: TextStyle(
                        color: isSelected ? Colors.white : const Color(0xFF64748B),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: const Color(0xFF0284C7),
                    backgroundColor: const Color(0xFFF1F5F9),
                    checkmarkColor: Colors.white,
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
          const SizedBox(height: 8),

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
                            Icon(Icons.assignment_late_outlined, size: 64, color: Colors.blueGrey.shade300),
                            const SizedBox(height: 16),
                            Text(
                              'No $_activeFilter found',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
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
                    padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final p = filteredProjects[index];
                    final status = (p['status'] ?? 'active').toString();
                    final category = p['category'] ?? 'General';
                    final city = p['city'] ?? 'Unknown';
                    final title = p['title'] ?? 'Untitled Project';

                    Color statusColor = const Color(0xFF0284C7);
                    Color statusBg = const Color(0xFFE0F2FE);
                    if (status.toLowerCase() == 'completed') {
                      statusColor = const Color(0xFF059669);
                      statusBg = const Color(0xFFD1FAE5);
                    } else if (status.toLowerCase() == 'pending') {
                      statusColor = const Color(0xFFD97706);
                      statusBg = const Color(0xFFFEF3C7);
                    }

                    IconData categoryIcon = Icons.home_repair_service;
                    if (category.toLowerCase() == 'plumber') {
                      categoryIcon = Icons.plumbing;
                    } else if (category.toLowerCase() == 'electrician') {
                      categoryIcon = Icons.electrical_services;
                    } else if (category.toLowerCase() == 'painter') {
                      categoryIcon = Icons.format_paint;
                    } else if (category.toLowerCase() == 'carpenter') {
                      categoryIcon = Icons.handyman;
                    } else if (category.toLowerCase() == 'mason') {
                      categoryIcon = Icons.architecture;
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.015),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          )
                        ],
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
                        borderRadius: BorderRadius.circular(24),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEFF6FF),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(categoryIcon, color: const Color(0xFF0284C7), size: 20),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: statusBg,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      status.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: statusColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF94A3B8)),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$city, India',
                                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: const [
                                      Text(
                                        'Budget',
                                        style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Est. Standard',
                                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      const Text(
                                        'Quotes',
                                        style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
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
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF0F172A),
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
              error: (e, st) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/post_project'),
        backgroundColor: const Color(0xFF0284C7),
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

  // Parse GPS coordinates automatically to a human-readable city address
  Future<void> _fetchReadableAddress() async {
    final rawAddress = widget.project['address_text'] ?? '';
    if (rawAddress.startsWith('Lat:')) {
      setState(() => _isGeocoding = true);
      try {
        // Parse "Lat: 28.594001, Lon: 76.974694"
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
        // Fallback to coordinates if geocoding yields an error
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
    final status = (widget.project['status'] ?? 'active').toString().toUpperCase();

    // 1. Parse PDF and Image URLs dynamically from description metadata
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

    final hasPdf = pdfUrl != null || desc.contains('[Drawing Attachment: Selected]') || desc.contains('[Drawing Attachment: ');
    final hasImages = imageUrls.isNotEmpty || desc.contains('photos selected');
    int imageCount = imageUrls.isNotEmpty ? imageUrls.length : 0;
    if (imageCount == 0 && hasImages) {
      try {
        final matches = RegExp(r'\[Land Images:\s*(\d+)\s*photos').firstMatch(desc);
        if (matches != null) {
          imageCount = int.parse(matches.group(1)!);
        }
      } catch (_) {}
    }

    // 2. Clean up raw metadata blocks from description for a premium UI
    String? plotArea;
    final plotMatch = RegExp(r'\[Plot Area:\s*([^\s\]]+)\s*(?:sq\.ft|Sq\.ft)?\]').firstMatch(desc);
    if (plotMatch != null) {
      plotArea = plotMatch.group(1);
    }

    String cleanDesc = desc;
    cleanDesc = cleanDesc.replaceAll(RegExp(r'\[Plot Area:[^\]]+\]'), '');
    cleanDesc = cleanDesc.replaceAll(RegExp(r'\[Drawing Attachment:[^\]]+\]'), '');
    cleanDesc = cleanDesc.replaceAll(RegExp(r'\[Land Images:[^\]]+\]'), '');
    cleanDesc = cleanDesc.replaceAll(RegExp(r'\[Drawing PDF URL:[^\]]+\]'), '');
    cleanDesc = cleanDesc.replaceAll(RegExp(r'\[Land Image URLs:[^\]]+\]'), '');
    cleanDesc = cleanDesc.trim();

    return Scaffold(
      backgroundColor: const Color(0xFFFCFDFF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF0F172A), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Project Details',
          style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Color(0xFF0F172A)),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. HORIZONTAL SWIPABLE PHOTO GALLERY (Scrollview instead of grid!)
            if (imageUrls.isNotEmpty)
              Container(
                height: 240,
                color: const Color(0xFFF8FAFC),
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: imageUrls.length,
                  itemBuilder: (context, index) {
                    return Container(
                      width: 320,
                      margin: const EdgeInsets.only(right: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(23),
                        child: Image.network(
                          imageUrls[index],
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (context, error, stackTrace) => const Center(
                            child: Icon(Icons.broken_image, color: Color(0xFF94A3B8), size: 40),
                          ),
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(child: CircularProgressIndicator(strokeWidth: 3));
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),

            // 2. Primary project specification details
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'EST. VALUE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0284C7),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // GPS-to-Human-Address text widget (fixed text overflow layouts)
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, color: Color(0xFF0284C7), size: 16),
                      const SizedBox(width: 4),
                      Expanded(
                        child: _isGeocoding
                            ? const LinearProgressIndicator(minHeight: 2)
                            : Text(
                                _readableAddress.isEmpty ? '$city, India' : _readableAddress,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  
                  // Description
                  if (cleanDesc.isNotEmpty) ...[
                    Text(
                      cleanDesc,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF475569),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Tag categories chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildDetailTag(category),
                      if (plotArea != null) _buildDetailTag('$plotArea Sq.ft'),
                      _buildDetailTag('Site Work'),
                      _buildDetailTag('Verification Done'),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // PDF at the bottom if PDF drawing is attached
                  if (pdfUrl != null) ...[
                    const Text(
                      'Attachments',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () async {
                        try {
                          final uri = Uri.parse(pdfUrl!);
                          final success = await launchUrl(uri, mode: LaunchMode.inAppWebView);
                          if (!success) {
                            Clipboard.setData(ClipboardData(text: pdfUrl!));
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Unable to launch PDF. Copied to clipboard!')),
                              );
                            }
                          }
                        } catch (e) {
                          Clipboard.setData(ClipboardData(text: pdfUrl!));
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('PDF link copied to clipboard!')),
                            );
                          }
                        }
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.picture_as_pdf, color: Colors.redAccent, size: 28),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                pdfUrl!.split('/').last, // Show parsed filename from Supabase URL
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155)),
                              ),
                            ),
                            const Icon(Icons.open_in_new, color: Color(0xFF0284C7), size: 20),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Quotes Received
                  const Text(
                    'Quotes Received',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 12),

                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: Supabase.instance.client
                        .from('applications')
                        .select('*, contractors(*)')
                        .eq('project_id', widget.project['id']),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
                      }
                      final quotes = snapshot.data ?? [];
                      if (quotes.isEmpty) {
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            children: const [
                              Icon(Icons.assignment_outlined, size: 48, color: Color(0xFF94A3B8)),
                              SizedBox(height: 12),
                              Text(
                                'No quotes received yet',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF475569)),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Contractors will review your project and bid shortly.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
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
    );
  }

  Widget _buildDetailTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, color: Color(0xFF475569), fontWeight: FontWeight.w600),
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
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
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
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xFFE0F2FE),
                    child: Text(businessName[0].toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0284C7))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          businessName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$exp • Star Rating $rating ★',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        amount,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF059669)),
                      ),
                      Text(
                        timeline,
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                    ],
                  )
                ],
              ),
              if (coverMessage.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    coverMessage,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.4),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              if (quoteStatus == 'pending')
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          try {
                            // 1. Update application status
                            await Supabase.instance.client
                                .from('applications')
                                .update({'status': 'hired'})
                                .eq('id', quoteId);

                            // 2. Update projects table
                            await Supabase.instance.client
                                .from('projects')
                                .update({'hired_contractor_id': contractorId})
                                .eq('id', widget.project['id']);

                            setState(() {});
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Quote accepted!')));
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0284C7),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                        child: const Text('Accept', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          try {
                            await Supabase.instance.client
                                .from('applications')
                                .update({'status': 'rejected'})
                                .eq('id', quoteId);
                            setState(() {});
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Quote rejected!')));
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Reject', style: TextStyle(color: Color(0xFF64748B))),
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
                          color: quoteStatus == 'hired' ? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          quoteStatus.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: quoteStatus == 'hired' ? const Color(0xFF065F46) : const Color(0xFF991B1B),
                          ),
                        ),
                      ),
                    ),
                    if (quoteStatus == 'hired') ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 40,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            context.push('/chat', extra: widget.project['id']);
                          },
                          icon: const Icon(Icons.chat_bubble_outline, size: 16, color: Colors.white),
                          label: const Text('Chat with Contractor', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0284C7),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
