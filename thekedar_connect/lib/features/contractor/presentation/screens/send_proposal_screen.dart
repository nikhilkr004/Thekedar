import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/contractor_provider.dart';

class SendProposalScreen extends ConsumerStatefulWidget {
  final String projectId;
  const SendProposalScreen({super.key, required this.projectId});

  @override
  ConsumerState<SendProposalScreen> createState() => _SendProposalScreenState();
}

class _SendProposalScreenState extends ConsumerState<SendProposalScreen> {
  final _timelineController = TextEditingController();
  final _coverMessageController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _timelineController.dispose();
    _coverMessageController.dispose();
    super.dispose();
  }

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

  Future<void> _submit(int budgetMin, int budgetMax) async {
    if (_timelineController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter estimated completion time')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Submit proposal details
      await ref.read(contractorRepositoryProvider).submitProposal(
            projectId: widget.projectId,
            estimatedCostMin: budgetMin > 0 ? budgetMin : 12000,
            estimatedCostMax: budgetMax > 0 ? budgetMax : 15000,
            estimatedTimeline: _timelineController.text,
            coverMessage: _coverMessageController.text,
          );

      if (mounted) {
        ref.invalidate(walletBalanceProvider);
        ref.invalidate(contractorBidsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Service Request Sent successfully!')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending request: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF0F172A), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Lead Details',
          style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Color(0xFF0F172A)),
            onPressed: () {},
          ),
          CircleAvatar(
            radius: 14,
            backgroundColor: const Color(0xFFE2E8F0),
            child: ClipOval(
              child: Container(color: const Color(0xFF0284C7), width: 28, height: 28),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: Supabase.instance.client
            .from('projects')
            .select('*')
            .eq('id', widget.projectId)
            .single(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
          }

          final project = snapshot.data ?? {};
          final title = project['title'] ?? 'Luxury Construction Lead';
          final category = project['category'] ?? 'General';
          final city = project['city'] ?? 'Jaipur';
          final desc = project['description'] ?? '';
          final rawAddress = project['address_text'] ?? '';
          final timeAgo = _getTimeAgo(project['created_at']);
          final budgetMin = project['budget_min'] ?? 0;
          final budgetMax = project['budget_max'] ?? 0;

          // Parse blueprint and photo URLs from description metadata
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

          // Clean description string
          String cleanDesc = desc;
          cleanDesc = cleanDesc.replaceAll(RegExp(r'\[Plot Area:[^\]]+\]'), '');
          cleanDesc = cleanDesc.replaceAll(RegExp(r'\[Drawing Attachment:[^\]]+\]'), '');
          cleanDesc = cleanDesc.replaceAll(RegExp(r'\[Land Images:[^\]]+\]'), '');
          cleanDesc = cleanDesc.replaceAll(RegExp(r'\[Drawing PDF URL:[^\]]+\]'), '');
          cleanDesc = cleanDesc.replaceAll(RegExp(r'\[Land Image URLs:[^\]]+\]'), '');
          cleanDesc = cleanDesc.trim();
          if (cleanDesc.isEmpty) {
            cleanDesc = 'Complete specification analysis for this premium project. Highly optimized space utilization and high-quality standard fitting requirements.';
          }

          final isPremium = budgetMax >= 50000;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Premium Lead Blue Banner (Matches Right Screen Layout)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0284C7),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        radius: 18,
                        child: const Icon(Icons.star, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isPremium ? 'PREMIUM LEAD' : 'VERIFIED PARTNER LEAD',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                            ),
                            Text(
                              isPremium ? 'Priority access for top-rated partners' : 'Direct access to verified customer requirements',
                              style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.9)),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.check_circle, color: Color(0xFF0284C7), size: 12),
                            SizedBox(width: 4),
                            Text(
                              'Verified',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Color(0xFF0284C7)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 2. Main Lead Specification Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Time ago
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 14, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 6),
                          Text(
                            timeAgo,
                            style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Location & Map Link
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 16, color: Color(0xFF0284C7)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              rawAddress.startsWith('Lat:') ? 'Jagatpura, Jaipur (1.5 km away)' : '$city, India (3.2 km away)',
                              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                            ),
                          ),
                          InkWell(
                            onTap: () {},
                            child: Row(
                              children: const [
                                Text(
                                  'View on Map',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                                ),
                                SizedBox(width: 3),
                                Icon(Icons.open_in_new, size: 10, color: Color(0xFF0284C7)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Description
                      const Text(
                        'Description',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        cleanDesc,
                        style: const TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.5),
                      ),
                      const SizedBox(height: 20),

                      // Specification tags wrap
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildSpecTag('Tools Required'),
                          _buildSpecTag('Site Visit Needed'),
                          _buildSpecTag('Material Provided'),
                          _buildSpecTag('Urgent Fix'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 3. Site Photos & Blueprints Section (Horizontal Scrollview)
                const Text(
                  'Site Photos & Blueprints',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 160,
                  child: imageUrls.isNotEmpty
                      ? ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: imageUrls.length,
                          itemBuilder: (context, index) {
                            return Container(
                              width: 220,
                              margin: const EdgeInsets.only(right: 14),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(15),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.network(imageUrls[index], fit: BoxFit.cover),
                                    Positioned(
                                      bottom: 10,
                                      left: 10,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.5),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          'Site Photo ${index + 1}.jpg',
                                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        )
                      : ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            _buildMockPhotoCard('Architectural Frame', 'assets/mock1.jpg'),
                            _buildMockPhotoCard('Internal Layout', 'assets/mock2.jpg'),
                          ],
                        ),
                ),
                const SizedBox(height: 28),

                // 4. Send Service Request Card (Matches Right Screen Form Card!)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.01),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.mail_outline, color: Color(0xFF0284C7), size: 20),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Send Service Request',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Completion Time Input
                      const Text(
                        'Estimated Completion Time',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _timelineController,
                        decoration: InputDecoration(
                          hintText: 'e.g., 15 Days',
                          prefixIcon: const Icon(Icons.timer_outlined, color: Color(0xFF64748B)),
                          fillColor: Colors.white,
                          filled: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          enabledBorder: inputBorder,
                          focusedBorder: inputBorder.copyWith(borderSide: const BorderSide(color: Color(0xFF0284C7), width: 2)),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Proposal Note Input
                      const Text(
                        'Proposal Note',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _coverMessageController,
                        maxLines: 5,
                        decoration: InputDecoration(
                          hintText: 'I have 10+ years of experience in villa projects. We can ensure the highest safety standards and use grade-A materials as requested...',
                          fillColor: Colors.white,
                          filled: true,
                          contentPadding: const EdgeInsets.all(20),
                          enabledBorder: inputBorder,
                          focusedBorder: inputBorder.copyWith(borderSide: const BorderSide(color: Color(0xFF0284C7), width: 2)),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Info Tag
                      const Text(
                        'Your profile, including project history and experience, will be shared with the user.',
                        style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), height: 1.4),
                      ),
                      const SizedBox(height: 24),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : ElevatedButton.icon(
                                onPressed: () => _submit(budgetMin, budgetMax),
                                icon: const Icon(Icons.send, size: 16, color: Colors.white),
                                label: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Text('Send Request ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                    Icon(Icons.arrow_forward, size: 14, color: Colors.white),
                                  ],
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0284C7),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
      ),
    );
  }

  Widget _buildSpecTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
      ),
    );
  }

  Widget _buildMockPhotoCard(String name, String assetPath) {
    return Container(
      width: 220,
      margin: const EdgeInsets.only(right: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const Icon(Icons.landscape, size: 48, color: Color(0xFF94A3B8)),
          Positioned(
            bottom: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                name,
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
