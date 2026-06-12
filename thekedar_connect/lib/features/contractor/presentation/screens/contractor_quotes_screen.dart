import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/contractor_provider.dart';
import 'contractor_project_details_screen.dart';

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
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'My Submitted Quotes',
          style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Tab Chip filters
          Container(
            height: 48,
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: 16),
              itemCount: _tabs.length,
              itemBuilder: (context, index) {
                final tab = _tabs[index];
                final isSelected = _activeTab == tab;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(
                      tab,
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
                          _activeTab = tab;
                        });
                      }
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // Main list builder
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchContractorQuotes(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
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
                        const Icon(Icons.assignment_turned_in_outlined, size: 56, color: Color(0xFF94A3B8)),
                        const SizedBox(height: 14),
                        Text(
                          'No $_activeTab found',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
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

                    Color statusColor = const Color(0xFFD97706);
                    Color statusBg = const Color(0xFFFEF3C7);
                    if (status == 'accepted' || status == 'hired') {
                      statusColor = const Color(0xFF059669);
                      statusBg = const Color(0xFFD1FAE5);
                    } else if (status == 'rejected') {
                      statusColor = const Color(0xFFDC2626);
                      statusBg = const Color(0xFFFEE2E2);
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
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.01),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
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
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEFF6FF),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(categoryIcon, color: const Color(0xFF0284C7), size: 18),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: statusBg,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      status.toUpperCase(),
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Text(
                                title,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF94A3B8)),
                                  const SizedBox(width: 4),
                                  Text('$city, India', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Divider(height: 1, color: Color(0xFFF1F5F9)),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Bid Cost Range', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                                      const SizedBox(height: 3),
                                      Text(amount, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF059669))),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      const Text('Time Estimate', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                                      const SizedBox(height: 3),
                                      Text(timeline, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
                                    ],
                                  ),
                                ],
                              ),
                              if (status == 'accepted' || status == 'hired') ...[
                                const SizedBox(height: 14),
                                SizedBox(
                                  width: double.infinity,
                                  height: 42,
                                  child: ElevatedButton.icon(
                                    onPressed: () => context.push('/chat', extra: project['id']),
                                    icon: const Icon(Icons.chat_bubble_outline, size: 14, color: Colors.white),
                                    label: const Text('Open Chat Room', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF0284C7),
                                      padding: EdgeInsets.zero,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

    );
  }
}
