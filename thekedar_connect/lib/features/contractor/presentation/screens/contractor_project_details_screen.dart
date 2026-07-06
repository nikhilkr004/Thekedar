import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/design_system.dart';

class ContractorProjectDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> quote;

  const ContractorProjectDetailsScreen({super.key, required this.quote});

  @override
  State<ContractorProjectDetailsScreen> createState() => _ContractorProjectDetailsScreenState();
}

class _ContractorProjectDetailsScreenState extends State<ContractorProjectDetailsScreen> {
  String _readableAddress = '';
  bool _isGeocoding = false;
  Map<String, dynamic>? _clientDetails;
  bool _loadingClient = false;

  @override
  void initState() {
    super.initState();
    _fetchReadableAddress();
    _fetchClientDetails();
  }

  Future<void> _fetchReadableAddress() async {
    final project = widget.quote['projects'] as Map<String, dynamic>?;
    if (project == null) return;
    
    final rawAddress = project['address_text'] ?? '';
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

  Future<void> _fetchClientDetails() async {
    final status = (widget.quote['status'] ?? 'pending').toString().toLowerCase();
    if (status != 'hired' && status != 'accepted') return;

    final project = widget.quote['projects'] as Map<String, dynamic>?;
    if (project == null || project['customer_id'] == null) return;

    setState(() => _loadingClient = true);
    try {
      final response = await Supabase.instance.client
          .from('users')
          .select('full_name, phone, email')
          .eq('id', project['customer_id'])
          .single();
      
      setState(() {
        _clientDetails = response;
      });
    } catch (e) {
      debugPrint('Error fetching client details: $e');
    } finally {
      setState(() => _loadingClient = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final project = widget.quote['projects'] as Map<String, dynamic>?;
    if (project == null) {
      return Scaffold(
        backgroundColor: AppColors.darkBackground,
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('Project details not found.', style: TextStyle(color: AppColors.textPrimary))),
      );
    }

    final title = project['title'] ?? 'Luxury Project';
    final city = project['city'] ?? 'Location';
    final desc = project['description'] ?? '';
    final status = (widget.quote['status'] ?? 'pending').toString().toLowerCase();

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

    final isHired = status == 'hired' || status == 'accepted';
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
          'Project & Client Info',
          style: AppTypography.title.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: SizedBox(
          width: isLargeScreen ? 600 : double.infinity,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Gallery
                if (imageUrls.isNotEmpty)
                  Container(
                    height: 200,
                    color: AppColors.darkSurface,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: imageUrls.length,
                      itemBuilder: (context, index) {
                        return Container(
                          width: 280,
                          margin: const EdgeInsets.only(right: 16),
                          decoration: BoxDecoration(
                            color: AppColors.darkCard,
                            borderRadius: BorderRadius.circular(AppRadius.large),
                            border: Border.all(color: AppColors.darkBorder),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadius.large - 1.0),
                            child: Image.network(
                              imageUrls[index],
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              errorBuilder: (context, error, stackTrace) => const Center(
                                child: Icon(Icons.broken_image, color: AppColors.textMuted, size: 36),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

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
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isHired ? AppColors.success.withOpacity(0.12) : AppColors.warning.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(AppRadius.small),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: AppTypography.caption.copyWith(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isHired ? AppColors.success : AppColors.warning,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
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

                      // Bidding parameters
                      const Divider(color: AppColors.darkDivider),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('My Proposal Price', style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
                              const SizedBox(height: 4),
                              Text(
                                '₹${widget.quote['estimated_cost_min']} - ₹${widget.quote['estimated_cost_max']}',
                                style: AppTypography.smallBody.copyWith(fontWeight: FontWeight.bold, color: AppColors.success),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('Proposed Duration', style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
                              const SizedBox(height: 4),
                              Text(
                                '${widget.quote['estimated_timeline']}',
                                style: AppTypography.smallBody.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      const Divider(color: AppColors.darkDivider),
                      const SizedBox(height: AppSpacing.lg),

                      // Client Contact details section
                      Text(
                        'Client Contact Information',
                        style: AppTypography.smallBody.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 10),

                      if (isHired) ...[
                        if (_loadingClient)
                          const Center(child: CircularProgressIndicator(color: AppColors.primary))
                        else if (_clientDetails != null)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(AppRadius.large),
                              border: Border.all(color: AppColors.success.withOpacity(0.2)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.person, color: AppColors.success, size: 18),
                                    const SizedBox(width: 8),
                                    Text(
                                      _clientDetails!['full_name'] ?? 'Client',
                                      style: AppTypography.smallBody.copyWith(fontWeight: FontWeight.bold, color: AppColors.success),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.phone, color: AppColors.success, size: 16),
                                        const SizedBox(width: 8),
                                        Text(
                                          _clientDetails!['phone'] ?? '',
                                          style: const TextStyle(fontFamily: 'monospace', color: AppColors.success),
                                        ),
                                      ],
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.call, color: AppColors.success, size: 20),
                                      onPressed: () async {
                                        final url = Uri.parse('tel:${_clientDetails!['phone']}');
                                        if (await launchUrl(url)) {}
                                      },
                                    ),
                                  ],
                                ),
                                if (_clientDetails!['email'] != null && _clientDetails!['email'].toString().isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(Icons.email, color: AppColors.success, size: 16),
                                      const SizedBox(width: 8),
                                      Text(
                                        _clientDetails!['email'] ?? '',
                                        style: AppTypography.caption.copyWith(color: AppColors.success),
                                      ),
                                    ],
                                  ),
                                ]
                              ],
                            ),
                          )
                        else
                          const Text('Failed to load shared details.', style: TextStyle(color: AppColors.error, fontSize: 12))
                      ] else ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          decoration: BoxDecoration(
                            color: AppColors.darkCard,
                            borderRadius: BorderRadius.circular(AppRadius.large),
                            border: Border.all(color: AppColors.darkBorder),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.lock_outline, color: AppColors.textMuted, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Client contact and chat room unlock automatically once your bid is accepted!',
                                  style: AppTypography.caption.copyWith(color: AppColors.textSecondary, height: 1.4),
                                ),
                              )
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: AppSpacing.lg),

                      // Attachments Drawing
                      if (pdfUrl != null) ...[
                        Text(
                          'Project drawing',
                          style: AppTypography.smallBody.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 10),
                        InkWell(
                          onTap: () async {
                            try {
                              final uri = Uri.parse(pdfUrl!);
                              await launchUrl(uri, mode: LaunchMode.inAppWebView);
                            } catch (e) {
                              Clipboard.setData(ClipboardData(text: pdfUrl!));
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Drawing link copied to clipboard!')),
                                );
                              }
                            }
                          },
                          borderRadius: BorderRadius.circular(AppRadius.medium),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.darkSurface,
                              borderRadius: BorderRadius.circular(AppRadius.medium),
                              border: Border.all(color: AppColors.darkBorder),
                            ),
                            child: Row(
                              children: const [
                                Icon(Icons.picture_as_pdf, color: AppColors.error, size: 24),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'View drawing specifications (PDF)',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textPrimary),
                                  ),
                                ),
                                Icon(Icons.open_in_new, color: AppColors.primaryLight, size: 16),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                      ],

                      // Action Chat Button
                      if (isHired) ...[
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: AppGradients.primaryGradient,
                              borderRadius: AppRadius.buttonBorderRadius,
                            ),
                            child: ElevatedButton.icon(
                              onPressed: () {
                                context.push('/chat', extra: project['id']);
                              },
                              icon: const Icon(Icons.chat_bubble_outline, size: 18, color: Colors.white),
                              label: const Text('Start Chatting', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(borderRadius: AppRadius.buttonBorderRadius),
                              ),
                            ),
                          ),
                        ),
                      ],
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
}
