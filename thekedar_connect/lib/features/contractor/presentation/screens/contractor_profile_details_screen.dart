import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

class ContractorProfileDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> contractor;
  final Map<String, dynamic> quote;
  final Map<String, dynamic> project;

  const ContractorProfileDetailsScreen({
    super.key,
    required this.contractor,
    required this.quote,
    required this.project,
  });

  @override
  State<ContractorProfileDetailsScreen> createState() => _ContractorProfileDetailsScreenState();
}

class _ContractorProfileDetailsScreenState extends State<ContractorProfileDetailsScreen> {
  late String _quoteStatus;
  bool _isUpdatingStatus = false;

  @override
  void initState() {
    super.initState();
    _quoteStatus = (widget.quote['status'] ?? 'pending').toString().toLowerCase();
  }

  Future<void> _updateQuoteStatus(String status) async {
    setState(() => _isUpdatingStatus = true);
    try {
      // 1. Update applications status
      await Supabase.instance.client
          .from('applications')
          .update({'status': status})
          .eq('id', widget.quote['id']);

      if (status == 'hired') {
        // 2. Update projects table
        await Supabase.instance.client
            .from('projects')
            .update({'hired_contractor_id': widget.contractor['id']})
            .eq('id', widget.project['id']);
      }

      setState(() {
        _quoteStatus = status;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(status == 'hired' ? 'Quote accepted!' : 'Quote rejected!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating status: $e')),
        );
      }
    } finally {
      setState(() => _isUpdatingStatus = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final businessName = widget.contractor['business_name'] ?? 'Verified Contractor';
    final exp = widget.contractor['years_experience'] ?? 0;
    final rating = widget.contractor['average_rating'] != null
        ? double.tryParse(widget.contractor['average_rating'].toString()) ?? 5.0
        : 5.0;
    final bio = widget.contractor['bio'] ?? 'Professional contractor providing premium renovation and construction services.';
    final completedCount = widget.contractor['projects_completed'] ?? 0;
    final trustScore = widget.contractor['trust_score'] != null
        ? double.tryParse(widget.contractor['trust_score'].toString()) ?? 95.0
        : 95.0;

    final aadhaar = widget.contractor['aadhaar_verified'] == true;
    final pan = widget.contractor['pan_verified'] == true;
    final gst = widget.contractor['gst_verified'] == true;
    final selfie = widget.contractor['selfie_verified'] == true;

    final categories = widget.contractor['categories'] as List<dynamic>? ?? [];
    final serviceRadius = widget.contractor['service_radius_km'] ?? 25;
    final serviceAreas = widget.contractor['service_areas'] as List<dynamic>? ?? [];

    final coverMessage = widget.quote['cover_message'] ?? '';
    final costMin = widget.quote['estimated_cost_min'] ?? 0;
    final costMax = widget.quote['estimated_cost_max'] ?? 0;
    final priceStr = costMin == costMax ? '₹$costMin' : '₹$costMin - ₹$costMax';
    final timeline = widget.quote['estimated_timeline'] ?? 'Flexible';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF0F172A), size: 20),
          onPressed: () => Navigator.pop(context, true),
        ),
        title: const Text(
          'Contractor Profile',
          style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Premium Header Profile Summary
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: const Color(0xFFE0F2FE),
                        child: Text(
                          businessName.isNotEmpty ? businessName[0].toUpperCase() : 'C',
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    businessName,
                                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                  ),
                                ),
                                if (aadhaar || pan || gst)
                                  const Icon(Icons.verified, color: Color(0xFF0284C7), size: 22),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                if (categories.isNotEmpty)
                                  ...categories.map((c) => Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF1F5F9),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          c.toString(),
                                          style: const TextStyle(fontSize: 10, color: Color(0xFF475569), fontWeight: FontWeight.w600),
                                        ),
                                      ))
                                else
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      widget.project['category'] ?? 'Contractor',
                                      style: const TextStyle(fontSize: 10, color: Color(0xFF475569), fontWeight: FontWeight.w600),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.star, color: Colors.amber, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  rating.toStringAsFixed(1),
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  '(12 Reviews)',
                                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                ),
                              ],
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
                  const SizedBox(height: 20),
                  // Stats Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem('$exp Years', 'Experience'),
                      _buildStatItem('$completedCount Projects', 'Completed'),
                      _buildStatItem('${trustScore.toInt()}%', 'Trust Score'),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 2. Proposal Bid Details
            Container(
              color: Colors.white,
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bid Proposal',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Estimated Cost', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                          const SizedBox(height: 4),
                          Text(priceStr, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF059669))),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Timeline', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                          const SizedBox(height: 4),
                          Text(timeline, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                        ],
                      )
                    ],
                  ),
                  if (coverMessage.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text('Cover Message', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Text(
                        coverMessage,
                        style: const TextStyle(fontSize: 13, color: Color(0xFF334155), height: 1.4),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 3. Document Verification Checklist
            Container(
              color: Colors.white,
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Verification Badges',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildVerificationBadge('Aadhaar', aadhaar)),
                      Expanded(child: _buildVerificationBadge('PAN Card', pan)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildVerificationBadge('GST Reg', gst)),
                      Expanded(child: _buildVerificationBadge('Selfie Match', selfie)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 4. Bio Description
            Container(
              color: Colors.white,
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'About Contractor',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    bio,
                    style: const TextStyle(fontSize: 14, color: Color(0xFF475569), height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 5. Service Area info
            Container(
              color: Colors.white,
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Service Area',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.map_outlined, color: Color(0xFF64748B), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          serviceAreas.isNotEmpty
                              ? serviceAreas.join(', ')
                              : 'Najafgarh and surrounding regions of Delhi',
                          style: const TextStyle(fontSize: 13, color: Color(0xFF334155)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.radar_outlined, color: Color(0xFF64748B), size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Operational Radius: Up to $serviceRadius km',
                        style: const TextStyle(fontSize: 13, color: Color(0xFF334155)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 6. Work Gallery
            Container(
              color: Colors.white,
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Work Showcase & Portfolio',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 16),
                  if (widget.quote['portfolio_photo_urls'] != null &&
                      widget.quote['portfolio_photo_urls'] is List &&
                      (widget.quote['portfolio_photo_urls'] as List).isNotEmpty)
                    SizedBox(
                      height: 160,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: (widget.quote['portfolio_photo_urls'] as List).length,
                        itemBuilder: (context, index) {
                          final imageUrl = (widget.quote['portfolio_photo_urls'] as List)[index].toString();
                          return GestureDetector(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) => Dialog(
                                  backgroundColor: Colors.transparent,
                                  child: Stack(
                                    alignment: Alignment.topRight,
                                    children: [
                                      InteractiveViewer(
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(16),
                                          child: Image.network(imageUrl, fit: BoxFit.contain),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.close, color: Colors.white, size: 30),
                                        onPressed: () => Navigator.pop(context),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              width: 200,
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(15),
                                child: Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: const Color(0xFFF1F5F9),
                                    child: const Icon(Icons.broken_image_outlined, color: Colors.grey),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    )
                  else ...[
                    const Text(
                      'No specific images uploaded for this bid. Showing references:',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontStyle: FontStyle.italic),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 140,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _buildPortfolioCard(
                            'Interior Painting Reference',
                            'Standard 3 BHK flat paint finishing reference.',
                            'https://images.unsplash.com/photo-1589939705384-5185137a7f0f?q=80&w=300&auto=format&fit=crop',
                          ),
                          _buildPortfolioCard(
                            'Living Room Reference',
                            'Standard lighting layout and smart home electrical reference.',
                            'https://images.unsplash.com/photo-1621905251189-08b45d6a269e?q=80&w=300&auto=format&fit=crop',
                          ),
                          _buildPortfolioCard(
                            'Bathroom Plumbing Reference',
                            'Premium CP fittings installation and drainage work.',
                            'https://images.unsplash.com/photo-1584622650111-993a426fbf0a?q=80&w=300&auto=format&fit=crop',
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 7. Mock Contractor Reviews section
            Container(
              color: Colors.white,
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Customer Reviews',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 16),
                  _buildReviewItem('Rajesh Kumar', 5.0, 'Very professional work. Completed the wiring layout on time and within budget. Recommended!'),
                  _buildReviewItem('Amit Sharma', 4.5, 'Satisfactory services. Handled structural changes nicely and verified everything step by step.'),
                  _buildReviewItem('Sandeep Singh', 5.0, 'Honest billing and top quality materials used for the construction. Very satisfied.'),
                ],
              ),
            ),
            const SizedBox(height: 100), // Spacing for floating buttons
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: const Color(0xFFE2E8F0), width: 1)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4)),
          ],
        ),
        child: SafeArea(
          child: _isUpdatingStatus
              ? const Center(child: CircularProgressIndicator())
              : _buildFooterActions(),
        ),
      ),
    );
  }

  Widget _buildStatItem(String val, String label) {
    return Column(
      children: [
        Text(val, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
      ],
    );
  }

  Widget _buildVerificationBadge(String title, bool isVerified) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: isVerified ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isVerified ? const Color(0xFFA7F3D0) : const Color(0xFFFCA5A5), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isVerified ? Icons.check_circle : Icons.cancel,
            color: isVerified ? const Color(0xFF059669) : const Color(0xFFDC2626),
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isVerified ? const Color(0xFF065F46) : const Color(0xFF991B1B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPortfolioCard(String title, String desc, String imageUrl) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(13), topRight: Radius.circular(13)),
            child: Image.network(
              imageUrl,
              height: 70,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: const Color(0xFFF1F5F9), height: 70, child: const Icon(Icons.image_outlined)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF0F172A)), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(desc, style: const TextStyle(fontSize: 9, color: Color(0xFF64748B)), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildReviewItem(String name, double stars, String comment) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0F172A))),
              const Spacer(),
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < stars.floor() ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 12,
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(comment, style: const TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.3)),
          const SizedBox(height: 8),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
        ],
      ),
    );
  }

  Widget _buildFooterActions() {
    if (_quoteStatus == 'pending') {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () => _updateQuoteStatus('hired'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text('Accept Quote', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton(
              onPressed: () => _updateQuoteStatus('rejected'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFE2E8F0)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Reject Bid', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ),
        ],
      );
    } else if (_quoteStatus == 'hired') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () {
            context.push('/chat', extra: widget.project['id']);
          },
          icon: const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 18),
          label: const Text('Chat with Contractor', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0284C7),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
        ),
      );
    } else {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(8)),
        child: const Center(
          child: Text(
            'BID REJECTED',
            style: TextStyle(color: Color(0xFF991B1B), fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
      );
    }
  }
}
