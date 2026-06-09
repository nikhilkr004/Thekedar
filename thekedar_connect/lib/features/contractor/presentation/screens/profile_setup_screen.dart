import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/contractor_provider.dart';
import '../models/contractor_profile.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _businessNameController = TextEditingController();
  final _experienceController = TextEditingController();
  final _bioController = TextEditingController();

  // Customer profile state variables
  bool _showUpdateForm = false;
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _propertyNotesController = TextEditingController();
  String _selectedPropertyType = 'homeowner';
  String _selectedContactMethod = 'Phone Call';
  String? _profilePhotoUrl;

  final List<String> _categories = [
    'Mason',
    'Plumber',
    'Electrician',
    'Painter',
    'Carpenter',
  ];
  final Set<String> _selectedCategories = {};
  bool _isLoading = false;
  bool _isEditing = false;
  
  String? _userRole;
  bool _loadingRole = true;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    _loadCustomerData();
  }

  Future<void> _loadUserRole() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;
      final profile = await Supabase.instance.client
          .from('users')
          .select('role')
          .eq('id', userId)
          .single();
      setState(() {
        _userRole = profile['role'];
        _loadingRole = false;
      });
    } catch (e) {
      setState(() {
        _userRole = 'customer';
        _loadingRole = false;
      });
    }
  }

  Future<void> _loadCustomerData() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;
      final profile = await Supabase.instance.client
          .from('users')
          .select('*')
          .eq('id', userId)
          .single();
      setState(() {
        _fullNameController.text = profile['full_name'] ?? '';
        _phoneController.text = profile['phone'] ?? '';
        _emailController.text = profile['email'] ?? '';
        _addressController.text = profile['address'] ?? '';
        _propertyNotesController.text = profile['property_notes'] ?? '';
        _selectedPropertyType = profile['property_type'] ?? 'homeowner';
        _selectedContactMethod = profile['preferred_contact_method'] ?? 'Phone Call';
        _profilePhotoUrl = profile['profile_photo_url'];
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _experienceController.dispose();
    _bioController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _propertyNotesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_businessNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter business name')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;

      // Check if contractor profile exists
      final existing = await Supabase.instance.client
          .from('contractors')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();

      if (existing == null) {
        // Insert profile
        final contractorRes = await Supabase.instance.client.from('contractors').insert({
          'user_id': userId,
          'business_name': _businessNameController.text,
          'years_experience': int.tryParse(_experienceController.text) ?? 0,
          'bio': _bioController.text,
          'categories': _selectedCategories.toList(),
          'average_rating': 5.0,
        }).select().single();

        // Initialize wallet for new contractor
        await Supabase.instance.client.from('credit_wallets').insert({
          'contractor_id': contractorRes['id'],
          'balance': 100, // Pre-load 100 credits for testing
        });
      } else {
        // Update profile
        await Supabase.instance.client.from('contractors').update({
          'business_name': _businessNameController.text,
          'years_experience': int.tryParse(_experienceController.text) ?? 0,
          'bio': _bioController.text,
          'categories': _selectedCategories.toList(),
        }).eq('user_id', userId);
      }

      ref.invalidate(contractorProfileProvider);
      ref.invalidate(walletBalanceProvider);
      setState(() {
        _isEditing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile saved successfully!')),
        );
        context.go('/leads');
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

  @override
  Widget build(BuildContext context) {
    if (_loadingRole) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_userRole == 'customer') {
      return _buildCustomerProfileView();
    }

    final profileAsync = ref.watch(contractorProfileProvider);

    return profileAsync.when(
      data: (profile) {
        if (profile == null || _isEditing) {
          return _buildProfileSetupForm();
        }
        return _buildPremiumProfileView(profile);
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, st) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error loading profile: $e', style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.invalidate(contractorProfileProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------------
  // A. REDESIGNED PREMIUM CONTRACTOR PROFILE VIEW (Mockup Left Screen layout)
  // -------------------------------------------------------------------
  Widget _buildPremiumProfileView(ContractorProfile profile) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'My Profile',
          style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Color(0xFF0284C7)),
            onPressed: () {
              // Pre-fill controllers to edit
              _businessNameController.text = profile.businessName;
              _experienceController.text = profile.yearsExperience.toString();
              _bioController.text = profile.bio;
              setState(() {
                _selectedCategories.clear();
                _selectedCategories.addAll(profile.categories);
                _isEditing = true;
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Premium Blue-Slate Gradient Header Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0284C7), Color(0xFF0F172A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        child: Text(
                          profile.businessName[0].toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 36, color: Colors.white),
                        ),
                      ),
                      const CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.verified, color: Colors.blue, size: 18),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    profile.businessName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Service Partner ID: #${Supabase.instance.client.auth.currentUser?.id.substring(0, 8).toUpperCase()}',
                    style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
                  ),
                  const SizedBox(height: 24),
                  // Trust & Experience Stats
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildHeaderStat('4.9 ★', 'Avg Rating'),
                      Container(width: 1, height: 28, color: Colors.white24),
                      _buildHeaderStat('${profile.yearsExperience}+ Years', 'Experience'),
                      Container(width: 1, height: 28, color: Colors.white24),
                      _buildHeaderStat('98%', 'Trust Score'),
                    ],
                  ),
                ],
              ),
            ),

            // 2. Profile details card
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // About card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Business Biography',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          profile.bio.isNotEmpty ? profile.bio : 'No bio specifications added yet.',
                          style: const TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.4),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Primary Services Offered',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: profile.categories.map((cat) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFDBEAFE)),
                              ),
                              child: Text(
                                cat,
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Wallet & Credits card for Contractor to check/buy credits
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0284C7), Color(0xFF38BDF8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'My Wallet Balance',
                              style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            ref.watch(walletBalanceProvider).when(
                              data: (balance) => Text(
                                '${balance ?? 0} Credits',
                                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              loading: () => const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              ),
                              error: (_, __) => const Text('Error', style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                        ElevatedButton.icon(
                          onPressed: () => context.push('/wallet'),
                          icon: const Icon(Icons.account_balance_wallet, size: 16, color: Color(0xFF0284C7)),
                          label: const Text('Add Credits', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0284C7))),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 3. Contractor's Submitted Quotes & Live Projects Status Section (Real-time Supabase)
                  const Text(
                    'Requested Projects & Status',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 12),

                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: _fetchContractorQuotes(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Error loading quotes: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
                      }

                      final quotes = snapshot.data ?? [];
                      if (quotes.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            children: const [
                              Icon(Icons.assignment_turned_in_outlined, size: 40, color: Color(0xFF94A3B8)),
                              SizedBox(height: 10),
                              Text(
                                'No requests submitted yet',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569)),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: quotes.length,
                        itemBuilder: (context, index) {
                          final quote = quotes[index];
                          final project = quote['projects'] as Map<String, dynamic>?;
                          if (project == null) return const SizedBox();

                          final title = project['title'] ?? 'Luxury Project Lead';
                          final city = project['city'] ?? 'Location';
                          final category = project['category'] ?? 'General';
                          final status = (quote['status'] ?? 'pending').toString().toLowerCase();

                          Color statusColor = const Color(0xFFD97706);
                          Color statusBg = const Color(0xFFFEF3C7);
                          if (status == 'accepted') {
                            statusColor = const Color(0xFF059669);
                            statusBg = const Color(0xFFD1FAE5);
                          } else if (status == 'rejected') {
                            statusColor = const Color(0xFFDC2626);
                            statusBg = const Color(0xFFFEE2E2);
                          }

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              onTap: () {
                                if (status == 'accepted') {
                                  // 4. If accepted, automatically redirect to the chat activity!
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Quote accepted! Redirecting to chat...')),
                                  );
                                  context.push('/chat', extra: project['id']);
                                } else if (status == 'rejected') {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('This bid was declined by the user.')),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Bid pending review. Chat will open once accepted!')),
                                  );
                                }
                              },
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.architecture, color: Color(0xFF0284C7), size: 20),
                              ),
                              title: Text(
                                title,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  '$category • $city',
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                ),
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: statusBg,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  status.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: statusColor,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11),
        ),
      ],
    );
  }

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

  // -------------------------------------------------------------------
  // B. ORIGINAL CONTRACTOR PROFILE SETUP FORM (For New Contractors)
  // -------------------------------------------------------------------
  Widget _buildProfileSetupForm() {
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFFCFDFF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          'Contractor Profile Setup',
          style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Complete your Business Profile',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 6),
            const Text(
              'Help clients understand your skills and experience details.',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 24),

            TextField(
              controller: _businessNameController,
              decoration: InputDecoration(
                labelText: 'Business Name',
                fillColor: Colors.white,
                filled: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                enabledBorder: inputBorder,
                focusedBorder: inputBorder.copyWith(borderSide: const BorderSide(color: Color(0xFF0284C7), width: 2)),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _experienceController,
              decoration: InputDecoration(
                labelText: 'Years of Experience',
                fillColor: Colors.white,
                filled: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                enabledBorder: inputBorder,
                focusedBorder: inputBorder.copyWith(borderSide: const BorderSide(color: Color(0xFF0284C7), width: 2)),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _bioController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Bio / Business Scope description...',
                fillColor: Colors.white,
                filled: true,
                contentPadding: const EdgeInsets.all(20),
                enabledBorder: inputBorder,
                focusedBorder: inputBorder.copyWith(borderSide: const BorderSide(color: Color(0xFF0284C7), width: 2)),
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'Service Categories Offered',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((c) {
                final isSelected = _selectedCategories.contains(c);
                return FilterChip(
                  label: Text(c),
                  selected: isSelected,
                  selectedColor: const Color(0xFFE0F2FE),
                  checkmarkColor: const Color(0xFF0284C7),
                  backgroundColor: const Color(0xFFF1F5F9),
                  labelStyle: TextStyle(
                    color: isSelected ? const Color(0xFF0369A1) : const Color(0xFF475569),
                    fontWeight: FontWeight.bold,
                  ),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedCategories.add(c);
                      } else {
                        _selectedCategories.remove(c);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 28),

            const Text(
              'KYC Verification Documents',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildUploadButton('Aadhaar')),
                const SizedBox(width: 10),
                Expanded(child: _buildUploadButton('PAN')),
                const SizedBox(width: 10),
                Expanded(child: _buildUploadButton('GST')),
              ],
            ),
            const SizedBox(height: 36),

            SizedBox(
              height: 52,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0284C7),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Submit Profile Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadButton(String label) {
    return OutlinedButton.icon(
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$label uploaded successfully (Demo Verification!)')),
        );
      },
      icon: const Icon(Icons.cloud_upload_outlined, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 11)),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF475569),
        side: const BorderSide(color: Color(0xFFCBD5E1)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }

  Future<Map<String, dynamic>> _fetchCustomerInfo() async {
    final userId = Supabase.instance.client.auth.currentUser!.id;
    return await Supabase.instance.client
        .from('users')
        .select('*')
        .eq('id', userId)
        .single();
  }

  Future<List<Map<String, dynamic>>> _fetchCustomerProjects() async {
    final userId = Supabase.instance.client.auth.currentUser!.id;
    final response = await Supabase.instance.client
        .from('projects')
        .select('*')
        .eq('customer_id', userId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Widget _buildCustomerProfileView() {
    if (_showUpdateForm) {
      return _buildCustomerUpdateProfileForm();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () => context.go('/customer_home'),
        ),
        title: const Text(
          'Profile',
          style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Color(0xFF0F172A)),
            onPressed: () {},
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchCustomerInfo(),
        builder: (context, infoSnapshot) {
          if (infoSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (infoSnapshot.hasError) {
            return Center(child: Text('Error loading profile: ${infoSnapshot.error}'));
          }

          final userMap = infoSnapshot.data!;
          final fullName = userMap['full_name'] ?? 'Homeowner';
          final phone = userMap['phone'] ?? '';
          final email = userMap['email'] ?? 'No email associated';
          final propertyTypeDb = userMap['property_type'] ?? 'homeowner';
          String propertyType = propertyTypeDb.toString();
          if (propertyType == 'homeowner') {
            propertyType = 'Homeowner';
          } else if (propertyType == 'builder') {
            propertyType = 'Builder';
          } else if (propertyType == 'developer') {
            propertyType = 'Developer';
          } else if (propertyType == 'tenant') {
            propertyType = 'Tenant';
          }
          final address = userMap['address'] ?? 'No address registered';
          final notes = userMap['property_notes'] ?? '';
          final photoUrl = userMap['profile_photo_url'] ?? '';
          final memberSinceStr = _formatMemberSince(userMap['created_at']?.toString());

          return FutureBuilder<List<Map<String, dynamic>>>(
            future: _fetchCustomerProjects(),
            builder: (context, projectsSnapshot) {
              final projects = projectsSnapshot.data ?? [];
              final projectsPosted = projects.length;
              final activeProjects = projects.where((p) => (p['status'] ?? 'active').toString().toLowerCase() == 'active').length;

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Profile Avatar & Basic Info Card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: [
                          Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF0284C7),
                                  shape: BoxShape.circle,
                                ),
                                child: CircleAvatar(
                                  radius: 46,
                                  backgroundColor: const Color(0xFFEFF6FF),
                                  backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                                  child: photoUrl.isEmpty
                                      ? Text(
                                          fullName[0].toUpperCase(),
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 32, color: Color(0xFF0284C7)),
                                        )
                                      : null,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => setState(() => _showUpdateForm = true),
                                child: const CircleAvatar(
                                  radius: 16,
                                  backgroundColor: Color(0xFF0284C7),
                                  child: Icon(Icons.edit, color: Colors.white, size: 14),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            fullName,
                            style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 22),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFDBEAFE)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.verified, color: Color(0xFF0284C7), size: 12),
                                SizedBox(width: 4),
                                Text(
                                  'Verified Member',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            notes.isNotEmpty
                                ? notes
                                : 'Dedicated craftsman specialized in modern home renovations and structural repairs.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 2. Metrics Block Grid
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            icon: Icons.assignment_outlined,
                            title: 'PROJECTS POSTED',
                            value: '$projectsPosted',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMetricCard(
                            icon: Icons.pending_actions_outlined,
                            title: 'ONGOING',
                            value: '$activeProjects Active',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildMetricCard(
                      icon: Icons.calendar_today_outlined,
                      title: 'MEMBER SINCE',
                      value: memberSinceStr,
                    ),
                    const SizedBox(height: 16),

                    // 3. Personal Info Box
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Text(
                                'Personal Info',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                              ),
                              Icon(Icons.info_outline, color: Color(0xFF94A3B8), size: 18),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildInfoRow(Icons.phone_outlined, 'Phone', phone),
                          const Divider(height: 24, color: Color(0xFFF1F5F9)),
                          _buildInfoRow(Icons.email_outlined, 'Email', email),
                          const Divider(height: 24, color: Color(0xFFF1F5F9)),
                          _buildInfoRow(Icons.location_on_outlined, 'Address', address),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 4. Options List
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: [
                          _buildMenuTile(Icons.payment_outlined, 'Payment Methods'),
                          const Divider(height: 1, color: Color(0xFFF1F5F9)),
                          _buildMenuTile(Icons.security_outlined, 'Security & Privacy'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 5. Sign Out Box
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF1F2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFFFE4E6)),
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.logout, color: Colors.red),
                        title: const Text(
                          'Sign Out',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                        ),
                        onTap: () async {
                          await Supabase.instance.client.auth.signOut();
                          if (context.mounted) {
                            context.go('/auth');
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 6. Action Button
                    SizedBox(
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: () => setState(() => _showUpdateForm = true),
                        icon: const Icon(Icons.cached, size: 16),
                        label: const Text('Update Profile', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0284C7),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildCustomerUpdateProfileForm() {
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () => setState(() => _showUpdateForm = false),
        ),
        title: const Text(
          'Update Profile',
          style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Color(0xFF0F172A)),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Photo section
            Center(
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFF0284C7),
                          shape: BoxShape.circle,
                        ),
                        child: CircleAvatar(
                          radius: 46,
                          backgroundColor: const Color(0xFFEFF6FF),
                          backgroundImage: _profilePhotoUrl != null && _profilePhotoUrl!.isNotEmpty
                              ? NetworkImage(_profilePhotoUrl!)
                              : null,
                          child: _profilePhotoUrl == null || _profilePhotoUrl!.isEmpty
                              ? const Icon(Icons.person, size: 40, color: Color(0xFF0284C7))
                              : null,
                        ),
                      ),
                      GestureDetector(
                        onTap: _showAvatarSelectionDialog,
                        child: const CircleAvatar(
                          radius: 14,
                          backgroundColor: Color(0xFF0284C7),
                          child: Icon(Icons.camera_alt, color: Colors.white, size: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _showAvatarSelectionDialog,
                    child: const Text(
                      'Upload Profile Photo',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Form inputs
            _buildFieldLabel('Full Name'),
            TextField(
              controller: _fullNameController,
              decoration: InputDecoration(
                hintText: 'e.g. Rajesh Kumar',
                fillColor: Colors.white,
                filled: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                enabledBorder: inputBorder,
                focusedBorder: inputBorder.copyWith(borderSide: const BorderSide(color: Color(0xFF0284C7), width: 2)),
              ),
            ),
            const SizedBox(height: 16),

            _buildFieldLabel('Phone Number'),
            TextField(
              controller: _phoneController,
              decoration: InputDecoration(
                hintText: '+91 98765 43210',
                fillColor: Colors.white,
                filled: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                enabledBorder: inputBorder,
                focusedBorder: inputBorder.copyWith(borderSide: const BorderSide(color: Color(0xFF0284C7), width: 2)),
              ),
            ),
            const SizedBox(height: 16),

            _buildFieldLabel('Email Address'),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                hintText: 'rajesh@thekedarconnect.com',
                fillColor: Colors.white,
                filled: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                enabledBorder: inputBorder,
                focusedBorder: inputBorder.copyWith(borderSide: const BorderSide(color: Color(0xFF0284C7), width: 2)),
              ),
            ),
            const SizedBox(height: 16),

            _buildFieldLabel('Primary Property Type'),
            DropdownButtonFormField<String>(
              value: _selectedPropertyType,
              items: const [
                DropdownMenuItem(value: 'homeowner', child: Text('Homeowner')),
                DropdownMenuItem(value: 'builder', child: Text('Builder')),
                DropdownMenuItem(value: 'developer', child: Text('Developer')),
                DropdownMenuItem(value: 'tenant', child: Text('Tenant')),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedPropertyType = val);
                }
              },
              decoration: InputDecoration(
                fillColor: Colors.white,
                filled: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                enabledBorder: inputBorder,
                focusedBorder: inputBorder.copyWith(borderSide: const BorderSide(color: Color(0xFF0284C7), width: 2)),
              ),
            ),
            const SizedBox(height: 16),

            _buildFieldLabel('Residential Address'),
            TextField(
              controller: _addressController,
              decoration: InputDecoration(
                hintText: 'Enter your full address',
                suffixIcon: const Icon(Icons.location_on_outlined, color: Color(0xFF0284C7)),
                fillColor: Colors.white,
                filled: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                enabledBorder: inputBorder,
                focusedBorder: inputBorder.copyWith(borderSide: const BorderSide(color: Color(0xFF0284C7), width: 2)),
              ),
            ),
            const SizedBox(height: 16),

            _buildFieldLabel('Preferred Contact Method'),
            DropdownButtonFormField<String>(
              value: _selectedContactMethod,
              items: ['Phone Call', 'SMS', 'Email', 'WhatsApp']
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedContactMethod = val);
                }
              },
              decoration: InputDecoration(
                fillColor: Colors.white,
                filled: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                enabledBorder: inputBorder,
                focusedBorder: inputBorder.copyWith(borderSide: const BorderSide(color: Color(0xFF0284C7), width: 2)),
              ),
            ),
            const SizedBox(height: 16),

            _buildFieldLabel('Property Details / Notes'),
            TextField(
              controller: _propertyNotesController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Mention any specific requirements or property details...',
                fillColor: Colors.white,
                filled: true,
                contentPadding: const EdgeInsets.all(20),
                enabledBorder: inputBorder,
                focusedBorder: inputBorder.copyWith(borderSide: const BorderSide(color: Color(0xFF0284C7), width: 2)),
              ),
            ),
            const SizedBox(height: 24),

            // Verification Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFDBEAFE)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Icon(Icons.shield_outlined, color: Color(0xFF0284C7), size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Verification Status',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A), fontSize: 14),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Completing your profile increases your profile visibility to potential clients by 45%.',
                          style: TextStyle(color: Color(0xFF64748B), fontSize: 12, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Buttons row
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: OutlinedButton(
                      onPressed: () => setState(() => _showUpdateForm = false),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _saveCustomerProfile,
                      icon: const Icon(Icons.check_circle_outline, size: 16),
                      label: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0284C7),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A), fontSize: 13),
      ),
    );
  }

  Widget _buildMetricCard({required IconData icon, required String title, required String value}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFFEFF6FF),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF0284C7), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String value) {
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: const Color(0xFFEFF6FF),
          child: Icon(icon, color: const Color(0xFF0284C7), size: 18),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMenuTile(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF475569)),
      title: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
      ),
      trailing: const Icon(Icons.chevron_right, color: Color(0xFF94A3B8), size: 20),
      onTap: () {},
    );
  }

  String _formatMemberSince(String? timestamp) {
    if (timestamp == null) return 'October 2023';
    try {
      final dt = DateTime.parse(timestamp);
      final months = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ];
      return '${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return 'October 2023';
    }
  }

  Future<void> _saveCustomerProfile() async {
    setState(() => _isLoading = true);
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      await Supabase.instance.client.from('users').update({
        'full_name': _fullNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'property_type': _selectedPropertyType,
        'address': _addressController.text.trim(),
        'preferred_contact_method': _selectedContactMethod,
        'property_notes': _propertyNotesController.text.trim(),
        'profile_photo_url': _profilePhotoUrl,
      }).eq('id', userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
        setState(() {
          _showUpdateForm = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving profile details: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  void _showAvatarSelectionDialog() {
    final urls = [
      'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80&w=200',
      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&q=80&w=200',
      'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&q=80&w=200',
      'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&q=80&w=200',
    ];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Profile Picture'),
          content: SizedBox(
            height: 100,
            width: 300,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: urls.map((u) {
                return GestureDetector(
                  onTap: () {
                    setState(() => _profilePhotoUrl = u);
                    Navigator.pop(context);
                  },
                  child: CircleAvatar(
                    radius: 28,
                    backgroundImage: NetworkImage(u),
                  ),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
}
