import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:go_router/go_router.dart';
import '../providers/contractor_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  late Razorpay _razorpay;
  int _pendingCredits = 0;
  bool _showAllActivity = false;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  Future<void> _creditWallet() async {
    try {
      await ref.read(contractorRepositoryProvider).addCredits(_pendingCredits);
      ref.invalidate(walletProvider);
      ref.invalidate(walletBalanceProvider);
      ref.invalidate(walletTransactionsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Wallet credited with $_pendingCredits credits successfully!'),
            backgroundColor: const Color(0xFF059669),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update wallet: $e'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    _creditWallet();
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment failed: ${response.message}'),
        backgroundColor: const Color(0xFFDC2626),
      ),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('External wallet: ${response.walletName}')),
    );
  }

  void _openPurchaseSelection(String title, String amount) {
    try {
      _pendingCredits = int.parse(title.replaceAll(RegExp(r'[^0-9]'), ''));
    } catch (_) {
      _pendingCredits = 50;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Buy $_pendingCredits Credits'),
          content: const Text(
            'Choose a payment method. If you are on an emulator or don\'t have Google Play Services configured, select "Simulate Payment" to add credits instantly.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _creditWallet();
              },
              child: const Text('Simulate Payment (Dev)'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _openRazorpayCheckout(title, amount);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Use Razorpay (SDK)'),
            ),
          ],
        );
      },
    );
  }

  void _openRazorpayCheckout(String title, String amount) {
    final options = {
      'key': 'rzp_test_Sw1y7ceIZ6e1Ot',
      'amount': (int.parse(amount.replaceAll(RegExp(r'[^0-9]'), '')) * 100), // in paise
      'name': 'Thekedar Connect',
      'description': title,
      'prefill': {
        'contact': '9876543210',
        'email': 'contractor@thekedar.com',
      },
    };
    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Razorpay error: $e');
    }
  }

  String _formatDateTime(String? isoString) {
    if (isoString == null) return '';
    try {
      final dt = DateTime.parse(isoString).toLocal();
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return "${months[dt.month - 1]} ${dt.day}, ${dt.year}";
    } catch (_) {
      return isoString;
    }
  }

  @override
  Widget build(BuildContext context) {
    final walletAsync = ref.watch(walletProvider);
    final txAsync = ref.watch(walletTransactionsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF0284C7), size: 20),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
          'My Wallet',
          style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_outlined, color: Color(0xFF0F172A)),
            onPressed: () {},
          )
        ],
      ),
      body: walletAsync.when(
        data: (wallet) {
          final balance = wallet?['balance'] ?? 0;
          final totalEarned = wallet?['total_earned'] ?? 0;

          return txAsync.when(
            data: (transactions) {
              // Get last spend amount
              final lastSpendTx = transactions.firstWhere(
                (t) => (t['credits'] ?? 0) < 0,
                orElse: () => <String, dynamic>{'credits': 0},
              );
              final lastSpend = lastSpendTx['credits'] ?? 0;

              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Premium Blue Available Balance Card
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF025CAB), Color(0xFF0E70C7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF025CAB).withOpacity(0.25),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          const Text(
                            'Available Balance',
                            style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.wallet, color: Colors.white, size: 36),
                              const SizedBox(width: 8),
                              Text(
                                '$balance',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 42,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Credits',
                            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 24),
                          // Stats row
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    children: [
                                      const Text(
                                        'Lifetime Earned',
                                        style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w500),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '$totalEarned Cr',
                                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    children: [
                                      const Text(
                                        'Last Spend',
                                        style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w500),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '$lastSpend Cr',
                                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // 2. Buy More Credits Section
                    const Text(
                      'Buy More Credits',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 14),

                    // Packages List
                    _buildCreditPackageCard('50 Credits', '₹ 500', Icons.monetization_on_outlined, false),
                    _buildCreditPackageCard('100 Credits', '₹ 900', Icons.payments_outlined, false),
                    _buildCreditPackageCard('200 Credits', '₹ 1700', Icons.stars_outlined, true),

                    const SizedBox(height: 24),

                    // 3. Recent Activity Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Recent Activity',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                        if (transactions.isNotEmpty)
                          InkWell(
                            onTap: () {
                              setState(() {
                                _showAllActivity = !_showAllActivity;
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Text(
                                _showAllActivity ? 'Show Less' : 'View All',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (transactions.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          children: const [
                            Icon(Icons.history_toggle_off, size: 48, color: Color(0xFF94A3B8)),
                            SizedBox(height: 8),
                            Text(
                              'No transactions found',
                              style: TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _showAllActivity
                              ? transactions.length
                              : (transactions.length > 3 ? 3 : transactions.length),
                          separatorBuilder: (context, idx) => const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
                          itemBuilder: (context, index) {
                            final tx = transactions[index];
                            final txId = tx['id']?.toString() ?? '';
                            final txCode = txId.isNotEmpty
                                ? (tx['type'] == 'spend' ? '#LAD-${txId.substring(0, 4).toUpperCase()}' : 'TXN-${txId.substring(0, 4).toUpperCase()}')
                                : 'TXN-REF';

                            final type = tx['type'] ?? 'purchase';
                            final credits = tx['credits'] ?? 0;
                            final desc = tx['description'] ?? 'Wallet Update';
                            final dateStr = _formatDateTime(tx['created_at']?.toString());

                            final isSpend = type == 'spend' || credits < 0;

                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              child: Row(
                                children: [
                                  // Circle Icon
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: isSpend ? const Color(0xFFFEF2F2) : const Color(0xFFECFDF5),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      isSpend ? Icons.logout_outlined : Icons.add_circle_outline,
                                      color: isSpend ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  // Details Text
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          desc,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '$dateStr • $txCode',
                                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Amount
                                  Text(
                                    isSpend ? '$credits Credits' : '+$credits Credits',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: isSpend ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              );
            },
            loading: () => const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator())),
            error: (e, st) => Center(child: Padding(padding: const EdgeInsets.all(40), child: Text('Error loading transactions: $e'))),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error loading wallet: $e')),
      ),
    );
  }

  Widget _buildCreditPackageCard(String title, String price, IconData icon, bool hasBestValueBadge) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasBestValueBadge ? const Color(0xFF025CAB).withOpacity(0.15) : const Color(0xFFF1F5F9),
          width: hasBestValueBadge ? 2 : 1.5,
        ),
        boxShadow: hasBestValueBadge
            ? [
                BoxShadow(
                  color: const Color(0xFF025CAB).withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19),
        child: Container(
          decoration: BoxDecoration(
            color: hasBestValueBadge ? const Color(0xFF025CAB).withOpacity(0.02) : Colors.white,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              // Icon container
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: const Color(0xFF0284C7), size: 24),
              ),
              const SizedBox(width: 14),
              // Package details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      price,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              // Best Value badge
              if (hasBestValueBadge) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF025CAB),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'BEST VALUE',
                    style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              // Buy button
              ElevatedButton(
                onPressed: () => _openPurchaseSelection(title, price),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF025CAB),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                child: const Text(
                  'Buy',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
