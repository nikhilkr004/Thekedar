import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/design_system.dart';

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
        final contractorResponse = await supabase
            .from('contractors')
            .select('id')
            .eq('user_id', userId)
            .maybeSingle();
        
        if (contractorResponse != null) {
          final contractorId = contractorResponse['id'];
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
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isLargeScreen = screenWidth > 600;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkSurface,
        elevation: 0,
        title: Text(
          'My Chats',
          style: AppTypography.title.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: SizedBox(
          width: isLargeScreen ? 600 : double.infinity,
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : _chats.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.chat_bubble_outline, size: 56, color: AppColors.textMuted),
                          const SizedBox(height: 16),
                          Text(
                            'No active chats yet',
                            style: AppTypography.smallBody.copyWith(fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 6),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 40),
                            child: Text(
                              _userRole == 'customer'
                                  ? 'Accept a contractor\'s proposal to unlock the chat room and start discussing details.'
                                  : 'Client chats unlock automatically once a project proposal gets accepted.',
                              textAlign: TextAlign.center,
                              style: AppTypography.caption.copyWith(color: AppColors.textMuted, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(AppSpacing.lg),
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
                          categoryIcon = AppIcons.handyman;
                        } else if (category.toLowerCase() == 'mason') {
                          categoryIcon = Icons.architecture;
                        }

                        return Container(
                          margin: const EdgeInsets.only(bottom: AppSpacing.md),
                          decoration: BoxDecoration(
                            color: AppColors.darkCard,
                            borderRadius: BorderRadius.circular(AppRadius.large),
                            border: Border.all(color: AppColors.darkBorder),
                            boxShadow: AppShadows.darkCardShadow,
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primary.withOpacity(0.15),
                              child: Icon(categoryIcon, color: AppColors.primaryLight, size: 20),
                            ),
                            title: Text(
                              chat['partner_name'],
                              style: AppTypography.smallBody.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                'Project: ${chat['title']}',
                                style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
                            onTap: () {
                              context.push('/chat', extra: chat['project_id']);
                            },
                          ),
                        );
                      },
                    ),
        ),
      ),
    );
  }
}
