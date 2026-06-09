import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  List<Map<String, dynamic>> _chats = [];
  bool _loading = true;
  String _userRole = 'customer';

  @override
  void initState() {
    super.initState();
    _fetchActiveChats();
  }

  Future<void> _fetchActiveChats() async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser!.id;

      // 1. Fetch user role
      final profile = await supabase
          .from('users')
          .select('role')
          .eq('id', userId)
          .single();
      
      final role = profile['role'] ?? 'customer';
      setState(() {
        _userRole = role;
      });

      List<Map<String, dynamic>> loadedChats = [];

      if (role == 'customer') {
        // Fetch projects where customer is the owner and contractor is hired
        final response = await supabase
            .from('projects')
            .select('id, title, category, status, hired_contractor_id, contractors(business_name)')
            .eq('customer_id', userId)
            .not('hired_contractor_id', 'is', null);
        
        if (response != null) {
          for (var item in response) {
            final contractor = item['contractors'] as Map<String, dynamic>?;
            loadedChats.add({
              'project_id': item['id'],
              'title': item['title'],
              'category': item['category'],
              'partner_name': contractor?['business_name'] ?? 'Contractor',
            });
          }
        }
      } else {
        // Current user is contractor -> find contractor id
        final contractorResponse = await supabase
            .from('contractors')
            .select('id')
            .eq('user_id', userId)
            .maybeSingle();
        
        if (contractorResponse != null) {
          final contractorId = contractorResponse['id'];
          // Fetch projects where contractor is hired
          final response = await supabase
              .from('projects')
              .select('id, title, category, status, customer_id, users:customer_id(full_name)')
              .eq('hired_contractor_id', contractorId);
          
          if (response != null) {
            for (var item in response) {
              final customer = item['users'] as Map<String, dynamic>?;
              loadedChats.add({
                'project_id': item['id'],
                'title': item['title'],
                'category': item['category'],
                'partner_name': customer?['full_name'] ?? 'Client',
              });
            }
          }
        }
      }

      setState(() {
        _chats = loadedChats;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Error fetching active chats: $e');
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          'My Chats',
          style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _chats.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.chat_bubble_outline, size: 56, color: Color(0xFF94A3B8)),
                      const SizedBox(height: 16),
                      const Text(
                        'No active chats yet',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B), fontSize: 15),
                      ),
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Text(
                          _userRole == 'customer'
                              ? 'Accept a contractor\'s proposal to unlock the chat room and start discussing details.'
                              : 'Client chats unlock automatically once a project proposal gets accepted.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8), height: 1.4),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _chats.length,
                  itemBuilder: (context, index) {
                    final chat = _chats[index];
                    final category = (chat['category'] ?? 'General').toString();

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
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFFEFF6FF),
                          child: Icon(categoryIcon, color: const Color(0xFF0284C7), size: 20),
                        ),
                        title: Text(
                          chat['partner_name'],
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A), fontSize: 15),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            'Project: ${chat['title']}',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
                        onTap: () {
                          context.push('/chat', extra: chat['project_id']);
                        },
                      ),
                    );
                  },
                ),

    );
  }
}
