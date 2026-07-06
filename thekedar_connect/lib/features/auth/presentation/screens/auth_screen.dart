import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/auth_provider.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _isLoading = false;
  bool _otpSent = false;
  String _authMethod = 'phone'; // 'phone' or 'email'
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  
  // 4-digit OTP individual controllers and focus nodes
  final _otp1Controller = TextEditingController();
  final _otp2Controller = TextEditingController();
  final _otp3Controller = TextEditingController();
  final _otp4Controller = TextEditingController();

  final _otp1FocusNode = FocusNode();
  final _otp2FocusNode = FocusNode();
  final _otp3FocusNode = FocusNode();
  final _otp4FocusNode = FocusNode();

  // Resend Countdown Timer State
  int _resendCountdown = 0;
  Timer? _timer;

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _otp1Controller.dispose();
    _otp2Controller.dispose();
    _otp3Controller.dispose();
    _otp4Controller.dispose();
    _otp1FocusNode.dispose();
    _otp2FocusNode.dispose();
    _otp3FocusNode.dispose();
    _otp4FocusNode.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _resendCountdown = 30; // 30 seconds limit
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown == 0) {
        setState(() {
          _timer?.cancel();
        });
      } else {
        setState(() {
          _resendCountdown--;
        });
      }
    });
  }

  Future<void> _sendOtp() async {
    final identifier = _authMethod == 'email' 
        ? _emailController.text.trim()
        : _phoneController.text.trim();
        
    if (identifier.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter your ${_authMethod == 'email' ? 'email address' : 'phone number'}')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      if (_authMethod == 'email') {
        await Supabase.instance.client.auth.signInWithOtp(
          email: identifier,
        );
      } else {
        await Supabase.instance.client.auth.signInWithOtp(
          phone: identifier,
        );
      }
      setState(() {
        _otpSent = true;
      });
      _startTimer();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification code sent!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyOtp() async {
    final identifier = _authMethod == 'email' 
        ? _emailController.text.trim()
        : _phoneController.text.trim();
        
    final code = _otp1Controller.text.trim() +
        _otp2Controller.text.trim() +
        _otp3Controller.text.trim() +
        _otp4Controller.text.trim();

    if (code.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the full 4-digit code')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      if (_authMethod == 'email') {
        await Supabase.instance.client.auth.verifyOTP(
          token: code,
          type: OtpType.email,
          email: identifier,
        );
      } else {
        await Supabase.instance.client.auth.verifyOTP(
          token: code,
          type: OtpType.sms,
          phone: identifier,
        );
      }
      
      if (!mounted) return;
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        final role = session.user.userMetadata?['role'];
        if (role == 'customer') {
          context.go('/customer_home');
        } else if (role == 'contractor') {
          context.go('/leads');
        } else {
          context.go('/role');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Verification failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(authRepositoryProvider).signInWithGoogle();
      
      if (!mounted) return;
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        final role = session.user.userMetadata?['role'];
        if (role == 'customer') {
          context.go('/customer_home');
        } else if (role == 'contractor') {
          context.go('/leads');
        } else {
          context.go('/role');
        }
      }
    } catch (e, stack) {
      debugPrint('GOOGLE SIGN IN ERROR: $e');
      debugPrint('STACK TRACE: $stack');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildOtpBox(
    TextEditingController controller,
    FocusNode currentNode,
    FocusNode? nextNode,
    FocusNode? prevNode,
  ) {
    return SizedBox(
      width: 56,
      height: 56,
      child: TextField(
        controller: controller,
        focusNode: currentNode,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        style: AppTypography.title.copyWith(color: AppColors.textPrimary),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: AppColors.darkSurface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.small),
            borderSide: const BorderSide(color: AppColors.darkBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.small),
            borderSide: const BorderSide(color: AppColors.darkBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.small),
            borderSide: const BorderSide(color: AppColors.primary, width: 2.0),
          ),
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: (value) {
          if (value.isNotEmpty) {
            if (nextNode != null) {
              FocusScope.of(context).requestFocus(nextNode);
            } else {
              currentNode.unfocus();
            }
          } else {
            if (prevNode != null) {
              FocusScope.of(context).requestFocus(prevNode);
            }
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isLargeScreen = screenWidth > 600;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.getResponsiveMargin(context),
                vertical: AppSpacing.xxl,
              ),
              child: Center(
                child: SizedBox(
                  width: isLargeScreen ? 480 : double.infinity,
                  child: Container(
                    decoration: isLargeScreen
                        ? BoxDecoration(
                            color: AppColors.darkSurface,
                            borderRadius: AppRadius.cardBorderRadius,
                            border: Border.all(color: AppColors.darkBorder, width: 1.5),
                            boxShadow: AppShadows.darkCardShadow,
                          )
                        : null,
                    padding: EdgeInsets.all(isLargeScreen ? AppSpacing.spacing32 : 0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: AppSpacing.md),
                        // Premium Gradient Icon Circle
                        Center(
                          child: Container(
                            height: 80,
                            width: 80,
                            decoration: BoxDecoration(
                              gradient: AppGradients.primaryGradient,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                )
                              ],
                            ),
                            child: const Icon(
                              AppIcons.handyman,
                              size: 40,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.spacing32),
                        Text(
                          'Thekedar Connect',
                          style: AppTypography.display.copyWith(
                            color: AppColors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Sign in to post projects or find leads',
                          style: AppTypography.smallBody.copyWith(
                            color: AppColors.textMuted,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.spacing32),
                        
                        // Premium Segmented Selector Tab
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.darkSurface,
                            borderRadius: BorderRadius.circular(AppRadius.medium),
                            border: Border.all(color: AppColors.darkBorder, width: 1.0),
                          ),
                          padding: const EdgeInsets.all(4),
                          child: Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() {
                                    _authMethod = 'phone';
                                    _otpSent = false;
                                  }),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                                    decoration: BoxDecoration(
                                      color: _authMethod == 'phone' ? AppColors.darkCard : Colors.transparent,
                                      borderRadius: BorderRadius.circular(AppRadius.small),
                                      border: _authMethod == 'phone'
                                          ? Border.all(color: AppColors.darkBorder, width: 1.0)
                                          : null,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      'Phone Login',
                                      style: AppTypography.button.copyWith(
                                        color: _authMethod == 'phone' ? AppColors.primaryLight : AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() {
                                    _authMethod = 'email';
                                    _otpSent = false;
                                  }),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                                    decoration: BoxDecoration(
                                      color: _authMethod == 'email' ? AppColors.darkCard : Colors.transparent,
                                      borderRadius: BorderRadius.circular(AppRadius.small),
                                      border: _authMethod == 'email'
                                          ? Border.all(color: AppColors.darkBorder, width: 1.0)
                                          : null,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      'Email Login',
                                      style: AppTypography.button.copyWith(
                                        color: _authMethod == 'email' ? AppColors.primaryLight : AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.spacing32),
                        
                        if (_isLoading)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(AppSpacing.xxl),
                              child: CircularProgressIndicator(color: AppColors.primary),
                            ),
                          )
                        else ...[
                          // Dynamic input text field based on selected tab
                          if (_authMethod == 'email')
                            TextField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              style: AppTypography.body.copyWith(color: AppColors.textPrimary),
                              decoration: InputDecoration(
                                labelText: 'Email Address',
                                labelStyle: TextStyle(color: AppColors.textSecondary),
                                hintText: 'contractor@example.com',
                                hintStyle: TextStyle(color: AppColors.textHint),
                                prefixIcon: const Icon(AppIcons.profile, color: AppColors.iconNormal),
                              ),
                              enabled: !_otpSent,
                            )
                          else
                            TextField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              style: AppTypography.body.copyWith(color: AppColors.textPrimary),
                              decoration: InputDecoration(
                                labelText: 'Phone Number',
                                labelStyle: TextStyle(color: AppColors.textSecondary),
                                hintText: '+919999999999',
                                hintStyle: TextStyle(color: AppColors.textHint),
                                prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.iconNormal),
                              ),
                              enabled: !_otpSent,
                            ),
                          const SizedBox(height: AppSpacing.lg),
                          
                          if (_otpSent) ...[
                            Text(
                              'Enter 4-Digit Verification Code',
                              style: AppTypography.subtitle.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildOtpBox(_otp1Controller, _otp1FocusNode, _otp2FocusNode, null),
                                _buildOtpBox(_otp2Controller, _otp2FocusNode, _otp3FocusNode, _otp1FocusNode),
                                _buildOtpBox(_otp3Controller, _otp3FocusNode, _otp4FocusNode, _otp2FocusNode),
                                _buildOtpBox(_otp4Controller, _otp4FocusNode, null, _otp3FocusNode),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            // Timer & Resend Option row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (_resendCountdown > 0)
                                  Text(
                                    'Resend code in $_resendCountdown seconds',
                                    style: AppTypography.smallBody.copyWith(color: AppColors.textMuted),
                                  )
                                else
                                  TextButton(
                                    onPressed: _sendOtp,
                                    child: Text(
                                      'Resend Code',
                                      style: AppTypography.smallBody.copyWith(
                                        color: AppColors.primaryLight,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            Container(
                              decoration: BoxDecoration(
                                gradient: AppGradients.primaryGradient,
                                borderRadius: AppRadius.buttonBorderRadius,
                              ),
                              child: ElevatedButton(
                                onPressed: _verifyOtp,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  padding: const EdgeInsets.all(AppSpacing.lg),
                                ),
                                child: Text('Verify OTP', style: AppTypography.button.copyWith(color: Colors.white)),
                              ),
                            ),
                          ] else ...[
                            Container(
                              decoration: BoxDecoration(
                                gradient: AppGradients.primaryGradient,
                                borderRadius: AppRadius.buttonBorderRadius,
                              ),
                              child: ElevatedButton(
                                onPressed: _sendOtp,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  padding: const EdgeInsets.all(AppSpacing.lg),
                                ),
                                child: Text('Send Verification Code', style: AppTypography.button.copyWith(color: Colors.white)),
                              ),
                            ),
                          ],
                          
                          const SizedBox(height: AppSpacing.xxl),
                          Row(
                            children: const [
                              Expanded(child: Divider(color: AppColors.darkDivider)),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                                child: Text('OR', style: TextStyle(color: AppColors.textMuted)),
                              ),
                              Expanded(child: Divider(color: AppColors.darkDivider)),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xxl),
                          
                          ElevatedButton.icon(
                            onPressed: _signInWithGoogle,
                            icon: const Icon(Icons.g_mobiledata, size: 28),
                            label: const Text('Continue with Google'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              backgroundColor: AppColors.darkSurface,
                              foregroundColor: AppColors.textPrimary,
                              elevation: 0,
                              side: const BorderSide(color: AppColors.darkBorder, width: 1.0),
                              shape: RoundedRectangleBorder(
                                borderRadius: AppRadius.buttonBorderRadius,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.md),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
