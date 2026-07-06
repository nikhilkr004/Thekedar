import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/design_system.dart';

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() => _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _receipts = [];
  String _activeTab = 'all';
  String _typeFilter = 'all';

  final List<String> _filters = ['all', 'attendance', 'leave', 'payroll', 'site', 'system'];

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
    _subscribeToRealtimeNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() => _isLoading = true);
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      final response = await _supabase
          .from('notification_recipients')
          .select('*, notifications(*)')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      if (response != null) {
        setState(() {
          _receipts = List<Map<String, dynamic>>.from(response);
        });
      }
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _subscribeToRealtimeNotifications() {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    _supabase
        .channel('public:notification_recipients')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notification_recipients',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: user.id,
          ),
          callback: (payload) async {
            try {
              final newId = payload.newRecord['id'];
              final details = await _supabase
                  .from('notification_recipients')
                  .select('*, notifications(*)')
                  .eq('id', newId)
                  .single();

              if (details != null && mounted) {
                setState(() {
                  _receipts.insert(0, details);
                });
              }
            } catch (e) {
              debugPrint('Error handling realtime notification sync: $e');
            }
          },
        )
        .subscribe();
  }

  Future<void> _markAsRead(String receiptId) async {
    try {
      await _supabase
          .from('notification_recipients')
          .update({'is_read': true, 'read_at': DateTime.now().toUtc().toIso8601String()})
          .eq('id', receiptId);

      setState(() {
        _receipts = _receipts.map((r) {
          if (r['id'] == receiptId) {
            return {
              ...r,
              'is_read': true,
              'read_at': DateTime.now().toUtc().toIso8601String(),
            };
          }
          return r;
        }).toList();
      });
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  Future<void> _markAllAsRead() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      await _supabase
          .from('notification_recipients')
          .update({'is_read': true, 'read_at': DateTime.now().toUtc().toIso8601String()})
          .eq('user_id', user.id)
          .eq('is_read', false);

      setState(() {
        _receipts = _receipts.map((r) {
          return {
            ...r,
            'is_read': true,
            'read_at': DateTime.now().toUtc().toIso8601String(),
          };
        }).toList();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All notifications marked as read')),
        );
      }
    } catch (e) {
      debugPrint('Error marking all as read: $e');
    }
  }

  Future<void> _deleteNotification(String receiptId) async {
    try {
      await _supabase.from('notification_recipients').delete().eq('id', receiptId);

      setState(() {
        _receipts.removeWhere((r) => r['id'] == receiptId);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification deleted')),
        );
      }
    } catch (e) {
      debugPrint('Error deleting notification: $e');
    }
  }

  List<Map<String, dynamic>> _getFilteredReceipts() {
    return _receipts.where((r) {
      final notification = r['notifications'] as Map<String, dynamic>?;
      if (notification == null) return false;

      final isRead = r['is_read'] == true;
      if (_activeTab == 'unread' && isRead) return false;
      if (_activeTab == 'read' && !isRead) return false;

      final type = (notification['notification_type'] ?? 'system').toString().toLowerCase();
      if (_typeFilter != 'all' && type != _typeFilter) return false;

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = _getFilteredReceipts();
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
          'Notification Center',
          style: AppTypography.title.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all, color: AppColors.primaryLight),
            tooltip: 'Mark all as read',
            onPressed: _markAllAsRead,
          ),
        ],
      ),
      body: Center(
        child: SizedBox(
          width: isLargeScreen ? 600 : double.infinity,
          child: Column(
            children: [
              // 1. Status Filter Tabs
              Container(
                color: AppColors.darkSurface,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildTabButton('All', 'all'),
                    _buildTabButton('Unread', 'unread'),
                    _buildTabButton('Read', 'read'),
                  ],
                ),
              ),
              
              // 2. Category Filters List
              SizedBox(
                height: 54,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                  itemCount: _filters.length,
                  itemBuilder: (context, index) {
                    final filterName = _filters[index];
                    final isSelected = _typeFilter == filterName;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _typeFilter = filterName;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : AppColors.darkCard,
                          borderRadius: BorderRadius.circular(AppRadius.circular),
                          border: Border.all(
                            color: isSelected ? Colors.transparent : AppColors.darkBorder,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            filterName.toUpperCase(),
                            style: AppTypography.caption.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // 3. Main Inbox Notification List
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                    : filteredList.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            itemCount: filteredList.length,
                            itemBuilder: (context, index) {
                              final receipt = filteredList[index];
                              return _buildNotificationCard(receipt);
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton(String label, String tabKey) {
    final isSelected = _activeTab == tabKey;
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeTab = tabKey;
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTypography.smallBody.copyWith(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? AppColors.primaryLight : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 2.5,
            width: 40,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primaryLight : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.circular),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> receipt) {
    final notification = receipt['notifications'] as Map<String, dynamic>?;
    if (notification == null) return const SizedBox.shrink();

    final isRead = receipt['is_read'] == true;
    final title = notification['title'] ?? 'Notification Alert';
    final message = notification['message'] ?? '';
    final type = (notification['notification_type'] ?? 'system').toString().toLowerCase();
    final priority = (notification['priority'] ?? 'medium').toString().toLowerCase();

    Color priorityColor;
    if (priority == 'critical') {
      priorityColor = AppColors.error;
    } else if (priority == 'high') {
      priorityColor = AppColors.warning;
    } else {
      priorityColor = AppColors.textMuted;
    }

    IconData typeIcon;
    Color iconBgColor;
    Color iconColor;
    if (type == 'attendance') {
      typeIcon = Icons.fingerprint;
      iconBgColor = AppColors.success.withOpacity(0.12);
      iconColor = AppColors.success;
    } else if (type == 'leave') {
      typeIcon = Icons.calendar_today;
      iconBgColor = AppColors.primary.withOpacity(0.12);
      iconColor = AppColors.primaryLight;
    } else if (type == 'payroll') {
      typeIcon = Icons.account_balance_wallet;
      iconBgColor = AppColors.success.withOpacity(0.12);
      iconColor = AppColors.success;
    } else if (type == 'site') {
      typeIcon = Icons.location_on;
      iconBgColor = AppColors.secondary.withOpacity(0.12);
      iconColor = AppColors.secondary;
    } else {
      typeIcon = Icons.notifications_none;
      iconBgColor = AppColors.darkSurface;
      iconColor = AppColors.textSecondary;
    }

    return Dismissible(
      key: Key(receipt['id']),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) => _deleteNotification(receipt['id']),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.12),
          borderRadius: BorderRadius.circular(AppRadius.large),
        ),
        child: const Icon(Icons.delete_outline, color: AppColors.error),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        decoration: BoxDecoration(
          color: isRead ? AppColors.darkCard : AppColors.darkCard.withOpacity(0.85),
          borderRadius: BorderRadius.circular(AppRadius.large),
          border: Border.all(
            color: isRead ? AppColors.darkBorder : AppColors.primary.withOpacity(0.4),
            width: 1,
          ),
          boxShadow: isRead ? null : [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: InkWell(
          onTap: () {
            if (!isRead) {
              _markAsRead(receipt['id']);
            }
          },
          borderRadius: BorderRadius.circular(AppRadius.large),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(AppRadius.medium),
                  ),
                  child: Icon(typeIcon, color: iconColor, size: 20),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: AppTypography.smallBody.copyWith(
                                fontWeight: isRead ? FontWeight.bold : FontWeight.w900,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: priorityColor,
                              shape: BoxShape.circle,
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        message,
                        style: AppTypography.caption.copyWith(color: AppColors.textSecondary, height: 1.4),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        DateTime.parse(receipt['created_at'].toString()).toLocal().toString().split(' ')[0],
                        style: AppTypography.caption.copyWith(color: AppColors.textMuted, fontWeight: FontWeight.bold),
                      )
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.notifications_off_outlined, size: 48, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Text(
            'All Caught Up!',
            style: AppTypography.smallBody.copyWith(fontWeight: FontWeight.bold, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            'You have no notifications in this category.',
            style: AppTypography.caption.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
