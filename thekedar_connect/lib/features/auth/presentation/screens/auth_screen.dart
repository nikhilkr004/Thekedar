import 'package:flutter/material.dart';
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
    super.dispose();
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
      width: 60,
      height: 60,
      child: TextField(
        controller: controller,
        focusNode: currentNode,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          counterText: '',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
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
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                const Icon(Icons.handyman, size: 80, color: Colors.blue),
                const SizedBox(height: 24),
                const Text(
                  'Welcome to Thekedar Connect',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Sign in to post projects or find leads',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                
                // Segmented Selector Tab
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
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
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _authMethod == 'phone' ? Colors.white : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: _authMethod == 'phone'
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 5,
                                        offset: const Offset(0, 2),
                                      )
                                    ]
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Phone Login',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _authMethod == 'phone' ? Colors.blue : Colors.grey[600],
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
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _authMethod == 'email' ? Colors.white : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: _authMethod == 'email'
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 5,
                                        offset: const Offset(0, 2),
                                      )
                                    ]
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Email Login',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _authMethod == 'email' ? Colors.blue : Colors.grey[600],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                
                if (_isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else ...[
                  // Dynamic input text field based on selected tab
                  if (_authMethod == 'email')
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email Address',
                        hintText: 'contractor@example.com',
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      enabled: !_otpSent,
                    )
                  else
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                        hintText: '+919999999999',
                        prefixIcon: const Icon(Icons.phone),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      enabled: !_otpSent,
                    ),
                  const SizedBox(height: 16),
                  
                  if (_otpSent) ...[
                    const Text(
                      'Enter 4-Digit Verification Code',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildOtpBox(_otp1Controller, _otp1FocusNode, _otp2FocusNode, null),
                        _buildOtpBox(_otp2Controller, _otp2FocusNode, _otp3FocusNode, _otp1FocusNode),
                        _buildOtpBox(_otp3Controller, _otp3FocusNode, _otp4FocusNode, _otp2FocusNode),
                        _buildOtpBox(_otp4Controller, _otp4FocusNode, null, _otp3FocusNode),
                      ],
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _verifyOtp,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Verify OTP', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ] else ...[
                    ElevatedButton(
                      onPressed: _sendOtp,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Send Verification Code', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                  
                  const SizedBox(height: 24),
                  Row(
                    children: const [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text('OR', style: TextStyle(color: Colors.grey)),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  ElevatedButton.icon(
                    onPressed: _signInWithGoogle,
                    icon: const Icon(Icons.login),
                    label: const Text('Continue with Google'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      elevation: 2,
                      side: const BorderSide(color: Colors.grey, width: 0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
