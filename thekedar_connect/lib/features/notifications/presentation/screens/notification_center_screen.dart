import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() => _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _receipts = [];
  String _activeTab = 'all'; // 'all' | 'unread' | 'read'
  String _typeFilter = 'all'; // 'all' | 'attendance' | 'leave' | 'payroll' | 'site' | 'system'

  final List<String> _filters = ['all', 'attendance', 'leave', 'payroll', 'site', 'system'];

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
    _subscribeToRealtimeNotifications();
  }

  // Fetch receipts joined with notifications details
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

  // Subscribe to real-time notification recipient inserts
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
            // Fetch the fully populated details for the new notification
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

  // Mark single notification as read
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

  // Mark all notifications as read
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

  // Delete notification receipt
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

  // Filter receipts locally based on tabs & dropdowns
  List<Map<String, dynamic>> _getFilteredReceipts() {
    return _receipts.where((r) {
      final notification = r['notifications'] as Map<String, dynamic>?;
      if (notification == null) return false;

      // Status Filter
      final isRead = r['is_read'] == true;
      if (_activeTab == 'unread' && isRead) return false;
      if (_activeTab == 'read' && !isRead) return false;

      // Type Category Filter
      final type = (notification['notification_type'] ?? 'system').toString().toLowerCase();
      if (_typeFilter != 'all' && type != _typeFilter) return false;

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = _getFilteredReceipts();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          'Notification Center',
          style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all, color: Color(0xFF0284C7)),
            tooltip: 'Mark all as read',
            onPressed: _markAllAsRead,
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Status Filter Tabs (All, Unread, Read)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 8),
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
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                      color: isSelected ? const Color(0xFF0284C7) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF0284C7) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        filterName.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : const Color(0xFF475569),
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
                ? const Center(child: CircularProgressIndicator())
                : filteredList.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredList.length,
                        itemBuilder: (context, index) {
                          final receipt = filteredList[index];
                          return _buildNotificationCard(receipt);
                        },
                      ),
          ),
        ],
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
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? const Color(0xFF0284C7) : const Color(0xFF64748B),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 2.5,
            width: 40,
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF0284C7) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
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

    // Map priority colors
    Color priorityColor;
    if (priority == 'critical') {
      priorityColor = const Color(0xFFEF4444);
    } else if (priority == 'high') {
      priorityColor = const Color(0xFFF97316);
    } else {
      priorityColor = const Color(0xFF64748B);
    }

    // Map type icons
    IconData typeIcon;
    Color iconBgColor;
    if (type == 'attendance') {
      typeIcon = Icons.fingerprint;
      iconBgColor = const Color(0xFFECFDF5);
    } else if (type == 'leave') {
      typeIcon = Icons.calendar_today;
      iconBgColor = const Color(0xFFEFF6FF);
    } else if (type == 'payroll') {
      typeIcon = Icons.account_balance_wallet;
      iconBgColor = const Color(0xFFFDF2F8);
    } else if (type == 'site') {
      typeIcon = Icons.location_on;
      iconBgColor = const Color(0xFFFFF7ED);
    } else {
      typeIcon = Icons.notifications_none;
      iconBgColor = const Color(0xFFF1F5F9);
    }

    return Dismissible(
      key: Key(receipt['id']),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) => _deleteNotification(receipt['id']),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isRead ? Colors.white : const Color(0xFFF0F9FF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isRead ? const Color(0xFFE2E8F0) : const Color(0xFFBAE6FD),
            width: 1,
          ),
        ),
        child: InkWell(
          onTap: () {
            if (!isRead) {
              _markAsRead(receipt['id']);
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon column
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(typeIcon, color: const Color(0xFF475569), size: 20),
                ),
                const SizedBox(width: 12),
                // Text column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontWeight: isRead ? FontWeight.bold : FontWeight.w900,
                                fontSize: 14,
                                color: const Color(0xFF0F172A),
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
                        style: const TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.4),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        DateTime.parse(receipt['created_at'].toString()).toLocal().toString().split(' ')[0],
                        style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold),
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
          Icon(Icons.notifications_off_outlined, size: 48, color: Colors.slate[300]),
          const SizedBox(height: 12),
          const Text(
            'All Caught Up!',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 4),
          const Text(
            'You have no notifications in this category.',
            style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }
}
