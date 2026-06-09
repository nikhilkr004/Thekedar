import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

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

  // Parse GPS coordinates automatically to a human-readable address
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
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('Project details not found.')),
      );
    }

    final title = project['title'] ?? 'Luxury Project';
    final category = project['category'] ?? 'Construction';
    final city = project['city'] ?? 'Location';
    final desc = project['description'] ?? '';
    final status = (widget.quote['status'] ?? 'pending').toString().toLowerCase();

    // Parse drawing/drawing attachments
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
          'Project & Client Info',
          style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gallery
            if (imageUrls.isNotEmpty)
              Container(
                height: 200,
                color: const Color(0xFFF8FAFC),
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
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(19),
                        child: Image.network(
                          imageUrls[index],
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (context, error, stackTrace) => const Center(
                            child: Icon(Icons.broken_image, color: Color(0xFF94A3B8), size: 36),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

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
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isHired ? const Color(0xFFD1FAE5) : const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isHired ? const Color(0xFF065F46) : const Color(0xFFD97706),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
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
                  const SizedBox(height: 16),

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

                  // Bidding parameters
                  const Divider(color: Color(0xFFF1F5F9)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('My Proposal Price', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                          const SizedBox(height: 4),
                          Text(
                            '₹${widget.quote['estimated_cost_min']} - ₹${widget.quote['estimated_cost_max']}',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Proposed Duration', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                          const SizedBox(height: 4),
                          Text(
                            '${widget.quote['estimated_timeline']}',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Color(0xFFF1F5F9)),
                  const SizedBox(height: 16),

                  // Client Contact details section (Conditional)
                  const Text(
                    'Client Contact Information',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 10),

                  if (isHired) ...[
                    if (_loadingClient)
                      const Center(child: CircularProgressIndicator())
                    else if (_clientDetails != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFDCFCE7)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.person, color: Color(0xFF15803D), size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  _clientDetails!['full_name'] ?? 'Client',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF15803D), fontSize: 14),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.phone, color: Color(0xFF15803D), size: 16),
                                    const SizedBox(width: 8),
                                    Text(
                                      _clientDetails!['phone'] ?? '',
                                      style: const TextStyle(fontFamily: 'monospace', color: Color(0xFF15803D)),
                                    ),
                                  ],
                                ),
                                IconButton(
                                  icon: const Icon(Icons.call, color: Color(0xFF15803D), size: 20),
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
                                  const Icon(Icons.email, color: Color(0xFF15803D), size: 16),
                                  const SizedBox(width: 8),
                                  Text(
                                    _clientDetails!['email'] ?? '',
                                    style: const TextStyle(color: Color(0xFF15803D), fontSize: 13),
                                  ),
                                ],
                              ),
                            ]
                          ],
                        ),
                      )
                    else
                      const Text('Failed to load shared details.', style: TextStyle(color: Colors.red, fontSize: 12))
                  ] else ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.lock_outline, color: Color(0xFF94A3B8), size: 20),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Client contact and chat room unlock automatically once your bid is accepted!',
                              style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4),
                            ),
                          )
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Attachments Drawing
                  if (pdfUrl != null) ...[
                    const Text(
                      'Project drawing',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
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
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.picture_as_pdf, color: Colors.redAccent, size: 24),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                'View drawing specifications (PDF)',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF334155)),
                              ),
                            ),
                            const Icon(Icons.open_in_new, color: Color(0xFF0284C7), size: 16),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Action Chat Button
                  if (isHired) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          context.push('/chat', extra: project['id']);
                        },
                        icon: const Icon(Icons.chat_bubble_outline, size: 18, color: Colors.white),
                        label: const Text('Start Chatting', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0284C7),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
    );
  }
}
