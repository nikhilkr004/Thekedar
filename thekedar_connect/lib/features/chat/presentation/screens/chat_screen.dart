import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/chat_provider.dart';
import '../../../../core/theme/design_system.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String projectId;
  const ChatScreen({super.key, required this.projectId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageController = TextEditingController();
  String? _resolvedReceiverId;
  String _chatPartnerName = 'Chat';
  String? _partnerPhone;
  String? _partnerEmail;
  bool _isResolving = true;

  @override
  void initState() {
    super.initState();
    _resolveChatParticipants();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _resolveChatParticipants() async {
    try {
      final supabase = Supabase.instance.client;
      final currentUserId = supabase.auth.currentUser!.id;

      final project = await supabase
          .from('projects')
          .select('title, customer_id')
          .eq('id', widget.projectId)
          .single();

      final customerId = project['customer_id'];
      final projectTitle = project['title'] ?? 'Project';

      if (currentUserId == customerId) {
        final acceptedApp = await supabase
            .from('applications')
            .select('contractor_id, contractors(user_id, business_name, users(phone, email))')
            .eq('project_id', widget.projectId)
            .eq('status', 'hired')
            .maybeSingle();

        if (acceptedApp != null && acceptedApp['contractors'] != null) {
          final contractorData = acceptedApp['contractors'] as Map<String, dynamic>;
          final userData = contractorData['users'];
          
          String? phone;
          String? email;
          if (userData is Map) {
            phone = userData['phone']?.toString();
            email = userData['email']?.toString();
          } else if (userData is List && userData.isNotEmpty) {
            phone = userData[0]['phone']?.toString();
            email = userData[0]['email']?.toString();
          }

          setState(() {
            _resolvedReceiverId = contractorData['user_id'];
            _chatPartnerName = contractorData['business_name'] ?? 'Contractor';
            _partnerPhone = phone;
            _partnerEmail = email;
            _isResolving = false;
          });
        } else {
          setState(() {
            _resolvedReceiverId = null;
            _chatPartnerName = 'Waiting for Bid Accept';
            _isResolving = false;
          });
        }
      } else {
        final projectData = await supabase
            .from('projects')
            .select('customer_id, users:customer_id(phone, email, full_name)')
            .eq('id', widget.projectId)
            .single();

        final customerData = projectData['users'];
        String? phone;
        String? email;
        String name = 'Client';

        if (customerData is Map) {
          phone = customerData['phone']?.toString();
          email = customerData['email']?.toString();
          name = customerData['full_name'] ?? 'Client';
        } else if (customerData is List && customerData.isNotEmpty) {
          phone = customerData[0]['phone']?.toString();
          email = customerData[0]['email']?.toString();
          name = customerData[0]['full_name'] ?? 'Client';
        }

        setState(() {
          _resolvedReceiverId = projectData['customer_id'];
          _chatPartnerName = '$name (${projectTitle})';
          _partnerPhone = phone;
          _partnerEmail = email;
          _isResolving = false;
        });
      }
    } catch (e) {
      setState(() {
        _resolvedReceiverId = null;
        _chatPartnerName = 'Chat Room';
        _isResolving = false;
      });
    }
  }

  Future<void> _send() async {
    if (_messageController.text.trim().isEmpty) return;
    if (_resolvedReceiverId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot send message. Chat partner is not accepted yet!')),
      );
      return;
    }

    try {
      await ref.read(chatRepositoryProvider).sendMessage(
            projectId: widget.projectId,
            receiverId: _resolvedReceiverId!,
            content: _messageController.text.trim(),
          );
      _messageController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(chatMessagesProvider(widget.projectId));
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              _chatPartnerName,
              style: AppTypography.smallBody.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
            ),
            if (!_isResolving && _resolvedReceiverId != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 4),
                  Text('Active Now', style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontSize: 10)),
                ],
              ),
          ],
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
          width: isLargeScreen ? 600 : double.infinity,
          child: _isResolving
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : Column(
                  children: [
                    if (_partnerPhone != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.08),
                          border: const Border(bottom: BorderSide(color: AppColors.darkDivider)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.shield_outlined, color: AppColors.success, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Shared Details: Phone: $_partnerPhone ${_partnerEmail != null && _partnerEmail!.isNotEmpty ? "• Email: $_partnerEmail" : ""}',
                                style: AppTypography.caption.copyWith(color: AppColors.success, fontWeight: FontWeight.bold),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.phone, color: AppColors.success, size: 16),
                              constraints: const BoxConstraints(),
                              padding: EdgeInsets.zero,
                              onPressed: () async {
                                final url = Uri.parse('tel:$_partnerPhone');
                                if (await launchUrl(url)) {}
                              },
                            ),
                          ],
                        ),
                      ),
                    Expanded(
                      child: messagesAsync.when(
                        data: (messages) {
                          if (messages.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.chat_bubble_outline, size: 48, color: AppColors.textMuted),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No messages yet',
                                    style: AppTypography.smallBody.copyWith(fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Start the conversation now!',
                                    style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                            );
                          }

                          return ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.lg),
                            reverse: true,
                            itemCount: messages.length,
                            itemBuilder: (context, index) {
                              final m = messages[messages.length - 1 - index];
                              final isMe = m['sender_id'] == currentUserId;

                              return Align(
                                alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  constraints: BoxConstraints(
                                    maxWidth: screenWidth * (isLargeScreen ? 0.6 : 0.75),
                                  ),
                                  decoration: BoxDecoration(
                                    color: isMe ? AppColors.primary : AppColors.darkCard,
                                    borderRadius: BorderRadius.only(
                                      topLeft: const Radius.circular(20),
                                      topRight: const Radius.circular(20),
                                      bottomLeft: Radius.circular(isMe ? 20 : 4),
                                      bottomRight: Radius.circular(isMe ? 4 : 20),
                                    ),
                                    border: isMe ? null : Border.all(color: AppColors.darkBorder),
                                    boxShadow: AppShadows.darkCardShadow,
                                  ),
                                  child: Text(
                                    m['content'] ?? '',
                                    style: AppTypography.body.copyWith(
                                      color: isMe ? Colors.white : AppColors.textPrimary,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                        error: (e, st) => Center(child: Text('Error loading messages: $e', style: const TextStyle(color: AppColors.error))),
                      ),
                    ),
                    
                    // Message Composer Box
                    Container(
                      padding: const EdgeInsets.only(left: 12, right: 12, bottom: 24, top: 12),
                      decoration: const BoxDecoration(
                        color: AppColors.darkSurface,
                        border: Border(top: BorderSide(color: AppColors.darkDivider)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.darkCard,
                              borderRadius: BorderRadius.circular(AppRadius.medium),
                              border: Border.all(color: AppColors.darkBorder),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.add, color: AppColors.textSecondary),
                              onPressed: () {},
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              style: AppTypography.body.copyWith(color: AppColors.textPrimary),
                              decoration: InputDecoration(
                                hintText: 'Type a message...',
                                hintStyle: AppTypography.caption.copyWith(color: AppColors.textMuted),
                                fillColor: AppColors.darkCard,
                                filled: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(AppRadius.circular),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              onSubmitted: (_) => _send(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              boxShadow: AppShadows.darkCardShadow,
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.send, color: Colors.white, size: 18),
                              onPressed: _send,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
