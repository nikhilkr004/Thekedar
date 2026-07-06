import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:go_router/go_router.dart';
import '../providers/contractor_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/design_system.dart';

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
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update wallet: $e'),
            backgroundColor: AppColors.error,
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
        backgroundColor: AppColors.error,
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
          backgroundColor: AppColors.darkDialog,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.large)),
          title: Text(
            'Buy $_pendingCredits Credits',
            style: AppTypography.subtitle.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Choose a payment method. If you are on an emulator or don\'t have Google Play Services configured, select "Simulate Payment" to add credits instantly.',
            style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _creditWallet();
              },
              child: Text(
                'Simulate Payment (Dev)',
                style: AppTypography.button.copyWith(color: AppColors.primaryLight, fontSize: 13),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _openRazorpayCheckout(title, amount);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.small)),
              ),
              child: Text(
                'Use Razorpay (SDK)',
                style: AppTypography.button.copyWith(color: Colors.white, fontSize: 13),
              ),
            ),
          ],
        );
      },
    );
  }

  void _openRazorpayCheckout(String title, String amount) {
    final options = {
      'key': 'rzp_test_Sw1y7ceIZ6e1Ot',
      'amount': (int.parse(amount.replaceAll(RegExp(r'[^0-9]'), '')) * 100),
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
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isLargeScreen = screenWidth > 840;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkSurface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          'My Wallet',
          style: AppTypography.title.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_outlined, color: AppColors.textPrimary),
            onPressed: () {},
          )
        ],
      ),
      body: Center(
        child: SizedBox(
          width: isLargeScreen ? 840 : double.infinity,
          child: walletAsync.when(
            data: (wallet) {
              final balance = wallet?['balance'] ?? 0;
              final totalEarned = wallet?['total_earned'] ?? 0;

              return txAsync.when(
                data: (transactions) {
                  final lastSpendTx = transactions.firstWhere(
                    (t) => (t['credits'] ?? 0) < 0,
                    orElse: () => <String, dynamic>{'credits': 0},
                  );
                  final lastSpend = lastSpendTx['credits'] ?? 0;

                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Premium Blue Available Balance Card
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: AppGradients.primaryGradient,
                            borderRadius: BorderRadius.circular(AppRadius.xl),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.2),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(AppSpacing.xxl),
                          child: Column(
                            children: [
                              Text(
                                'Available Balance',
                                style: AppTypography.caption.copyWith(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
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
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(AppRadius.medium),
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
                                        borderRadius: BorderRadius.circular(AppRadius.medium),
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
                        const SizedBox(height: AppSpacing.spacing28),

                        // 2. Buy More Credits Section
                        Text(
                          'Buy More Credits',
                          style: AppTypography.smallBody.copyWith(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        _buildCreditPackageCard('50 Credits', '₹ 500', Icons.monetization_on_outlined, false),
                        _buildCreditPackageCard('100 Credits', '₹ 900', Icons.payments_outlined, false),
                        _buildCreditPackageCard('200 Credits', '₹ 1700', Icons.stars_outlined, true),

                        const SizedBox(height: AppSpacing.spacing28),

                        // 3. Recent Activity Section
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Recent Activity',
                              style: AppTypography.smallBody.copyWith(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
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
                                    style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold, color: AppColors.primaryLight),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),

                        if (transactions.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 32),
                            decoration: BoxDecoration(
                              color: AppColors.darkCard,
                              borderRadius: BorderRadius.circular(AppRadius.large),
                              border: Border.all(color: AppColors.darkBorder),
                            ),
                            child: Column(
                              children: [
                                const Icon(Icons.history_toggle_off, size: 48, color: AppColors.textMuted),
                                const SizedBox(height: 8),
                                Text(
                                  'No transactions found',
                                  style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          )
                        else
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.darkCard,
                              borderRadius: BorderRadius.circular(AppRadius.large),
                              border: Border.all(color: AppColors.darkBorder, width: 1.0),
                            ),
                            child: ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _showAllActivity
                                  ? transactions.length
                                  : (transactions.length > 3 ? 3 : transactions.length),
                              separatorBuilder: (context, idx) => const Divider(height: 1, thickness: 1, color: AppColors.darkDivider),
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
                                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.lg),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: isSpend ? AppColors.error.withOpacity(0.12) : AppColors.success.withOpacity(0.12),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          isSpend ? Icons.logout_outlined : Icons.add_circle_outline,
                                          color: isSpend ? AppColors.error : AppColors.success,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.md),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              desc,
                                              style: AppTypography.smallBody.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '$dateStr • $txCode',
                                              style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        isSpend ? '$credits Credits' : '+$credits Credits',
                                        style: AppTypography.smallBody.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: isSpend ? AppColors.error : AppColors.success,
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
                loading: () => const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(color: AppColors.primary))),
                error: (e, st) => Center(child: Padding(padding: const EdgeInsets.all(40), child: Text('Error loading transactions: $e', style: const TextStyle(color: AppColors.error)))),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
            error: (e, st) => Center(child: Text('Error loading wallet: $e', style: const TextStyle(color: AppColors.error))),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 3,
        selectedItemColor: AppColors.primaryLight,
        unselectedItemColor: AppColors.textMuted,
        backgroundColor: AppColors.darkSurface,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Explore'),
          BottomNavigationBarItem(icon: Icon(Icons.request_quote), label: 'Quotes'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        onTap: (index) {
          switch (index) {
            case 0:
              context.go('/leads');
              break;
            case 1:
              context.go('/contractor_quotes');
              break;
            case 2:
              context.go('/chat_list');
              break;
            case 3:
              context.go('/profile_setup');
              break;
          }
        },
      ),
    );
  }

  Widget _buildCreditPackageCard(String title, String price, IconData icon, bool hasBestValueBadge) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(
          color: hasBestValueBadge ? AppColors.secondary.withOpacity(0.3) : AppColors.darkBorder,
          width: hasBestValueBadge ? 2 : 1.0,
        ),
        boxShadow: hasBestValueBadge ? AppShadows.darkCardShadow : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.large - 1.0),
        child: Container(
          decoration: BoxDecoration(
            color: hasBestValueBadge ? AppColors.secondary.withOpacity(0.04) : Colors.transparent,
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.lg),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                ),
                child: Icon(icon, color: AppColors.primaryLight, size: 24),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.smallBody.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      price,
                      style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              if (hasBestValueBadge) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(AppRadius.circular),
                  ),
                  child: const Text(
                    'BEST VALUE',
                    style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              ElevatedButton(
                onPressed: () => _openPurchaseSelection(title, price),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.small)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                child: Text(
                  'Buy',
                  style: AppTypography.button.copyWith(color: Colors.white, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
