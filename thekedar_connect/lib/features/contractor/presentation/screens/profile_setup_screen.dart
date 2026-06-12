import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lottie/lottie.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image/image.dart' as img;
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
  final _projectsCompletedController = TextEditingController();
  final _bioController = TextEditingController();

  // Customer/Contractor profile state variables
  bool _showUpdateForm = false;
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _propertyNotesController = TextEditingController();
  String _selectedPropertyType = 'homeowner';
  String _selectedContactMethod = 'Phone Call';
  String? _profilePhotoUrl;

  // Social Links controllers
  final _whatsappController = TextEditingController();
  final _instagramController = TextEditingController();
  final _facebookController = TextEditingController();
  final _websiteController = TextEditingController();

  // Document Upload statuses
  String _aadhaarStatus = 'PENDING';
  String _panStatus = 'PENDING';
  String _gstStatus = 'OPTIONAL';

  // Selected work category (from dropdown list matching mockup)
  String _selectedWorkCategory = 'General Contractor';

  final List<String> _categories = [
    'Mason',
    'Plumber',
    'Electrician',
    'Painter',
    'Carpenter',
    'General Contractor',
  ];
  final Set<String> _selectedCategories = {};
  bool _isLoading = false;
  bool _isEditing = false;
  
  String? _userRole;
  bool _loadingRole = true;

  // Newly Picked document files
  File? _profilePhotoFile;
  File? _aadhaarFile;
  File? _panFile;
  File? _gstFile;
  List<File> _portfolioFiles = [];



  // Existing document URLs
  String? _aadhaarDocUrl;
  String? _panDocUrl;
  String? _gstDocUrl;
  List<String> _portfolioUrls = [];

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    _loadCustomerData();
  }

  Future<File?> _compressImageFile(File file) async {
    try {
      final originalBytes = await file.readAsBytes();
      final decoded = img.decodeImage(originalBytes);
      if (decoded == null) return file;
      
      img.Image resized = decoded;
      if (decoded.width > 800 || decoded.height > 800) {
        if (decoded.width > decoded.height) {
          resized = img.copyResize(decoded, width: 800);
        } else {
          resized = img.copyResize(decoded, height: 800);
        }
      }
      
      final compressedBytes = img.encodeJpg(resized, quality: 15);
      final tempDir = Directory.systemTemp;
      final tempFile = File('${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}_${file.uri.pathSegments.last}');
      await tempFile.writeAsBytes(compressedBytes);
      return tempFile;
    } catch (e) {
      print('Compression error: $e');
      return file;
    }
  }

  Future<void> _pickProfilePhoto() async {
    try {
      final picked = await _picker.pickImage(source: ImageSource.gallery);
      if (picked == null) return;
      setState(() => _isLoading = true);
      final file = File(picked.path);
      final compressed = await _compressImageFile(file);
      setState(() {
        _profilePhotoFile = compressed;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking profile photo: $e')),
      );
    }
  }

  Future<void> _pickDocument(String docType) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      );
      if (result == null || result.files.single.path == null) return;
      setState(() => _isLoading = true);
      final file = File(result.files.single.path!);
      final isPdf = file.path.toLowerCase().endsWith('.pdf');
      
      if (isPdf) {
        setState(() {
          if (docType == 'aadhaar') {
            _aadhaarFile = file;
            _aadhaarStatus = 'SELECTED';
          } else if (docType == 'pan') {
            _panFile = file;
            _panStatus = 'SELECTED';
          } else if (docType == 'gst') {
            _gstFile = file;
            _gstStatus = 'SELECTED';
          }
          _isLoading = false;
        });
      } else {
        final compressed = await _compressImageFile(file);
        setState(() {
          if (docType == 'aadhaar') {
            _aadhaarFile = compressed;
            _aadhaarStatus = 'SELECTED';
          } else if (docType == 'pan') {
            _panFile = compressed;
            _panStatus = 'SELECTED';
          } else if (docType == 'gst') {
            _gstFile = compressed;
            _gstStatus = 'SELECTED';
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking document: $e')),
      );
    }
  }

  Future<void> _pickPortfolioImages() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.image,
      );
      if (result == null) return;
      setState(() => _isLoading = true);
      for (final fileInfo in result.files) {
        if (fileInfo.path != null) {
          final file = File(fileInfo.path!);
          final compressed = await _compressImageFile(file);
          if (compressed != null) {
            setState(() {
              _portfolioFiles.add(compressed);
            });
          }
        }
      }
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking portfolio images: $e')),
      );
    }
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
    _projectsCompletedController.dispose();
    _bioController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _propertyNotesController.dispose();
    _whatsappController.dispose();
    _instagramController.dispose();
    _facebookController.dispose();
    _websiteController.dispose();
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

      // 1. Upload Profile Photo if changed
      String? profilePhotoUrl = _profilePhotoUrl;
      if (_profilePhotoFile != null) {
        final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final fileBytes = await _profilePhotoFile!.readAsBytes();
        await Supabase.instance.client.storage.from('project_photos').uploadBinary(
          '$userId/$fileName',
          fileBytes,
          fileOptions: const FileOptions(contentType: 'image/jpeg'),
        );
        profilePhotoUrl = Supabase.instance.client.storage.from('project_photos').getPublicUrl('$userId/$fileName');
      }

      // 2. Upload Aadhaar Doc if changed
      String? aadhaarDocUrl = _aadhaarDocUrl;
      if (_aadhaarFile != null) {
        final isPdf = _aadhaarFile!.path.toLowerCase().endsWith('.pdf');
        final ext = isPdf ? 'pdf' : 'jpg';
        final fileName = 'aadhaar_${DateTime.now().millisecondsSinceEpoch}.$ext';
        final fileBytes = await _aadhaarFile!.readAsBytes();
        await Supabase.instance.client.storage.from('project_drawings').uploadBinary(
          '$userId/$fileName',
          fileBytes,
          fileOptions: FileOptions(contentType: isPdf ? 'application/pdf' : 'image/jpeg'),
        );
        aadhaarDocUrl = Supabase.instance.client.storage.from('project_drawings').getPublicUrl('$userId/$fileName');
      }

      // 3. Upload PAN Doc if changed
      String? panDocUrl = _panDocUrl;
      if (_panFile != null) {
        final isPdf = _panFile!.path.toLowerCase().endsWith('.pdf');
        final ext = isPdf ? 'pdf' : 'jpg';
        final fileName = 'pan_${DateTime.now().millisecondsSinceEpoch}.$ext';
        final fileBytes = await _panFile!.readAsBytes();
        await Supabase.instance.client.storage.from('project_drawings').uploadBinary(
          '$userId/$fileName',
          fileBytes,
          fileOptions: FileOptions(contentType: isPdf ? 'application/pdf' : 'image/jpeg'),
        );
        panDocUrl = Supabase.instance.client.storage.from('project_drawings').getPublicUrl('$userId/$fileName');
      }

      // 4. Upload GST Doc if changed
      String? gstDocUrl = _gstDocUrl;
      if (_gstFile != null) {
        final isPdf = _gstFile!.path.toLowerCase().endsWith('.pdf');
        final ext = isPdf ? 'pdf' : 'jpg';
        final fileName = 'gst_${DateTime.now().millisecondsSinceEpoch}.$ext';
        final fileBytes = await _gstFile!.readAsBytes();
        await Supabase.instance.client.storage.from('project_drawings').uploadBinary(
          '$userId/$fileName',
          fileBytes,
          fileOptions: FileOptions(contentType: isPdf ? 'application/pdf' : 'image/jpeg'),
        );
        gstDocUrl = Supabase.instance.client.storage.from('project_drawings').getPublicUrl('$userId/$fileName');
      }

      // 5. Upload new Portfolio/Project photos
      List<String> portfolioUrls = List.from(_portfolioUrls);
      if (_portfolioFiles.isNotEmpty) {
        for (int i = 0; i < _portfolioFiles.length; i++) {
          final fileName = 'portfolio_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
          final fileBytes = await _portfolioFiles[i].readAsBytes();
          await Supabase.instance.client.storage.from('project_photos').uploadBinary(
            '$userId/$fileName',
            fileBytes,
            fileOptions: const FileOptions(contentType: 'image/jpeg'),
          );
          final url = Supabase.instance.client.storage.from('project_photos').getPublicUrl('$userId/$fileName');
          portfolioUrls.add(url);
        }
      }

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
          'projects_completed': int.tryParse(_projectsCompletedController.text) ?? 0,
          'bio': _bioController.text,
          'categories': _selectedCategories.isNotEmpty 
              ? _selectedCategories.toList() 
              : [_selectedWorkCategory],
          'social_links': {
            'whatsapp': _whatsappController.text,
            'instagram': _instagramController.text,
            'facebook': _facebookController.text,
            'website': _websiteController.text,
          },
          'aadhaar_verified': _aadhaarStatus == 'VERIFIED' || _aadhaarStatus == 'SELECTED',
          'pan_verified': _panStatus == 'VERIFIED' || _panStatus == 'SELECTED',
          'gst_verified': _gstStatus == 'VERIFIED' || _gstStatus == 'SELECTED',
          'aadhaar_doc_url': aadhaarDocUrl,
          'pan_doc_url': panDocUrl,
          'gst_doc_url': gstDocUrl,
          'portfolio_urls': portfolioUrls,
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
          'projects_completed': int.tryParse(_projectsCompletedController.text) ?? 0,
          'bio': _bioController.text,
          'categories': _selectedCategories.isNotEmpty 
              ? _selectedCategories.toList() 
              : [_selectedWorkCategory],
          'social_links': {
            'whatsapp': _whatsappController.text,
            'instagram': _instagramController.text,
            'facebook': _facebookController.text,
            'website': _websiteController.text,
          },
          'aadhaar_verified': _aadhaarStatus == 'VERIFIED' || _aadhaarStatus == 'SELECTED',
          'pan_verified': _panStatus == 'VERIFIED' || _panStatus == 'SELECTED',
          'gst_verified': _gstStatus == 'VERIFIED' || _gstStatus == 'SELECTED',
          'aadhaar_doc_url': aadhaarDocUrl,
          'pan_doc_url': panDocUrl,
          'gst_doc_url': gstDocUrl,
          'portfolio_urls': portfolioUrls,
        }).eq('user_id', userId);
      }

      // Update personal info in users table
      await Supabase.instance.client.from('users').update({
        'full_name': _fullNameController.text,
        'phone': _phoneController.text,
        'address': _addressController.text,
        'profile_photo_url': profilePhotoUrl,
      }).eq('id', userId);

      ref.invalidate(contractorProfileProvider);
      ref.invalidate(walletBalanceProvider);
      setState(() {
        _isEditing = false;
        _profilePhotoFile = null;
        _aadhaarFile = null;
        _panFile = null;
        _gstFile = null;
        _portfolioFiles = [];
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
        if (profile != null && !_isEditing && _businessNameController.text.isEmpty && _fullNameController.text.isEmpty) {
          // Pre-fill controllers on startup if profile exists
          _fullNameController.text = profile.fullName;
          _phoneController.text = profile.phone;
          _addressController.text = profile.address;
          _businessNameController.text = profile.businessName;
          _experienceController.text = profile.yearsExperience.toString();
          _projectsCompletedController.text = profile.projectsCompleted.toString();
          _bioController.text = profile.bio;
          _whatsappController.text = profile.socialLinks['whatsapp'] ?? '';
          _instagramController.text = profile.socialLinks['instagram'] ?? '';
          _facebookController.text = profile.socialLinks['facebook'] ?? '';
          _websiteController.text = profile.socialLinks['website'] ?? '';
          _aadhaarStatus = profile.aadhaarVerified ? 'VERIFIED' : 'PENDING';
          _panStatus = profile.panVerified ? 'VERIFIED' : 'PENDING';
          _gstStatus = profile.gstVerified ? 'VERIFIED' : 'OPTIONAL';
          _aadhaarDocUrl = profile.aadhaarDocUrl;
          _panDocUrl = profile.panDocUrl;
          _gstDocUrl = profile.gstDocUrl;
          _portfolioUrls = profile.portfolioUrls;
          if (profile.categories.isNotEmpty) {
            _selectedWorkCategory = profile.categories.first;
            _selectedCategories.clear();
            _selectedCategories.addAll(profile.categories);
          }
        }
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
        elevation: 0.5,
        leading: const Icon(Icons.menu, color: Color(0xFF0F172A)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text(
              'aThekedar',
              style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Color(0xFF0284C7)),
            onPressed: () {
              // Pre-fill controllers to edit
              _fullNameController.text = profile.fullName;
              _phoneController.text = profile.phone;
              _addressController.text = profile.address;
              _businessNameController.text = profile.businessName;
              _experienceController.text = profile.yearsExperience.toString();
              _projectsCompletedController.text = profile.projectsCompleted.toString();
              _bioController.text = profile.bio;
              _whatsappController.text = profile.socialLinks['whatsapp'] ?? '';
              _instagramController.text = profile.socialLinks['instagram'] ?? '';
              _facebookController.text = profile.socialLinks['facebook'] ?? '';
              _websiteController.text = profile.socialLinks['website'] ?? '';
              _aadhaarStatus = profile.aadhaarVerified ? 'VERIFIED' : 'PENDING';
              _panStatus = profile.panVerified ? 'VERIFIED' : 'PENDING';
              _gstStatus = profile.gstVerified ? 'VERIFIED' : 'OPTIONAL';
              _aadhaarDocUrl = profile.aadhaarDocUrl;
              _panDocUrl = profile.panDocUrl;
              _gstDocUrl = profile.gstDocUrl;
              _portfolioUrls = profile.portfolioUrls;
              setState(() {
                if (profile.categories.isNotEmpty) {
                  _selectedWorkCategory = profile.categories.first;
                }
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
            // 1. Profile Hero Section
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                children: [
                  // Banner Image Container
                  Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      Container(
                        height: 180,
                        margin: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0284C7), Color(0xFF5B21B6)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              top: 16,
                              right: 16,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF22C55E),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    CircleAvatar(radius: 3, backgroundColor: Colors.white),
                                    SizedBox(width: 5),
                                    Text(
                                      'ACTIVE',
                                      style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                      // Profile Avatar
                      Transform.translate(
                        offset: const Offset(0, 32),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF3B82F6), width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 46,
                            backgroundColor: Colors.white,
                            backgroundImage: _profilePhotoUrl != null
                                ? NetworkImage(_profilePhotoUrl!)
                                : const AssetImage('assets/images/placeholder_profile.png') as ImageProvider,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),

                  // Contractor Name
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        profile.fullName.isNotEmpty ? profile.fullName : 'Nikhil Kumar',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          border: Border.all(color: const Color(0xFFDCFCE7)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.verified_user_outlined, color: Color(0xFF16A34A), size: 10),
                            SizedBox(width: 3),
                            Text('KYC', style: TextStyle(color: Color(0xFF16A34A), fontSize: 9, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Location Tag
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_on, color: Color(0xFF0284C7), size: 14),
                        const SizedBox(width: 6),
                        Text(
                          profile.address.isNotEmpty ? profile.address : 'Gurgaon, Haryana',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Radius Tag
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.navigation, color: Color(0xFF0284C7), size: 12),
                        SizedBox(width: 6),
                        Text(
                          '25km Radius',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Wallet balance and Topup section
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0369A1), Color(0xFF0284C7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0284C7).withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.white24,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.account_balance_wallet_outlined, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'WALLET BALANCE',
                            style: TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                          ),
                          const SizedBox(height: 2),
                          Consumer(
                            builder: (context, ref, _) {
                              final balanceAsync = ref.watch(walletBalanceProvider);
                              return balanceAsync.when(
                                data: (balance) => Text(
                                  '${balance ?? 0} Credits',
                                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                loading: () => const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                ),
                                error: (_, __) => const Text('0 Credits', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: () => context.push('/wallet'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF0284C7),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: const Text(
                      'Topup',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2. Social Links Grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 2.8,
                children: [
                  _buildMockupSocialBtn(
                    label: 'WhatsApp',
                    icon: Icons.chat_bubble_outline,
                    iconColor: const Color(0xFF22C55E),
                    bgColor: const Color(0xFFDCFCE7),
                    onTap: () => _launchSocialLink('whatsapp', profile.socialLinks['whatsapp'] ?? ''),
                  ),
                  _buildMockupSocialBtn(
                    label: 'Instagram',
                    icon: Icons.camera_alt_outlined,
                    iconColor: const Color(0xFFEC4899),
                    bgColor: const Color(0xFFFCE7F3),
                    onTap: () => _launchSocialLink('instagram', profile.socialLinks['instagram'] ?? ''),
                  ),
                  _buildMockupSocialBtn(
                    label: 'Facebook',
                    icon: Icons.public_outlined,
                    iconColor: const Color(0xFF3B82F6),
                    bgColor: const Color(0xFFDBEAFE),
                    onTap: () => _launchSocialLink('facebook', profile.socialLinks['facebook'] ?? ''),
                  ),
                  _buildMockupSocialBtn(
                    label: 'Website',
                    icon: Icons.language_outlined,
                    iconColor: const Color(0xFF0F172A),
                    bgColor: const Color(0xFFE2E8F0),
                    onTap: () => _launchSocialLink('website', profile.socialLinks['website'] ?? ''),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 3. Quick Stats Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: _buildMockupStatCard(
                      value: '${profile.yearsExperience}',
                      label: 'YEARS\nEXP.',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildMockupStatCard(
                      value: '4.8',
                      label: 'AVG\nRATING',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildMockupStatCard(
                      value: '${profile.projectsCompleted}+',
                      label: 'PROJECTS',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 4. Service Excellence & Core Specialties Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'SERVICE EXCELLENCE',
                    style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0369A1), fontSize: 11, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    profile.categories.isNotEmpty ? profile.categories.first : 'Civil Construction',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A), fontSize: 20),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    profile.bio.isNotEmpty ? profile.bio : 'With over a decade of dedicated service in the civil construction industry, I specialize in delivering high-quality residential and commercial projects. My approach combines traditional craftsmanship with modern project management.',
                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, height: 1.5),
                  ),
                  const SizedBox(height: 24),

                  // Project Budget Inner Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'PROJECT BUDGET',
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8), letterSpacing: 0.5),
                        ),
                        SizedBox(height: 6),
                        Text(
                          '₹ 50k - ₹ 50L',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Core Specialties row
                  const Text(
                    'CORE SPECIALTIES',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8), letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildChipText('Renovation'),
                      _buildChipText('Modular Kitchen'),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Expertise list
                  const Text(
                    'Expertise & Skills',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildChipText('Waterproofing'),
                      _buildChipText('Foundation Work'),
                      _buildChipText('Interior Finishes'),
                      _buildChipText('Plumbing Services'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 5. Featured Work
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Featured Work',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F172A)),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Recent architectural milestones in NCR',
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                      ),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: () {},
                    icon: const Text('Explore All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0284C7))),
                    label: const Icon(Icons.arrow_forward, size: 14, color: Color(0xFF0284C7)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 180,
              child: profile.portfolioUrls.isNotEmpty
                  ? ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: profile.portfolioUrls.length,
                      itemBuilder: (context, index) {
                        return Container(
                          width: 260,
                          margin: const EdgeInsets.only(right: 14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            image: DecorationImage(
                              image: NetworkImage(profile.portfolioUrls[index]),
                              fit: BoxFit.cover,
                            ),
                          ),
                        );
                      },
                    )
                  : ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        _buildMockupFeaturedCard(
                          title: 'Skyline Residency',
                          category: 'RENOVATION • 2023',
                          price: '₹ 24L',
                          imageUrl: 'https://images.unsplash.com/photo-1589939705384-5185137a7f0f?q=80&w=300&auto=format&fit=crop',
                        ),
                        _buildMockupFeaturedCard(
                          title: 'Modern Villa Extension',
                          category: 'FOUNDATION • 2024',
                          price: '₹ 45L',
                          imageUrl: 'https://images.unsplash.com/photo-1621905251189-08b45d6a269e?q=80&w=300&auto=format&fit=crop',
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 24),

            // 6. Verified Trust Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Color(0xFFDCFCE7),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check, color: Color(0xFF16A34A), size: 14),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Verified Trust',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A), fontSize: 15),
                          ),
                          Text(
                            'PLATFORM AUTHENTICATED',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF94A3B8), fontSize: 9),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  _buildVerifiedTrustRow(
                    title: 'Aadhaar ID',
                    subtitle: 'CONFIRMED IDENTITY',
                    isVerified: profile.aadhaarVerified,
                  ),
                  const Divider(height: 24, color: Color(0xFFF1F5F9)),

                  _buildVerifiedTrustRow(
                    title: 'PAN Card',
                    subtitle: 'TAX COMPLIANCE VERIFIED',
                    isVerified: profile.panVerified,
                  ),
                  const Divider(height: 24, color: Color(0xFFF1F5F9)),

                  _buildVerifiedTrustRow(
                    title: 'GST Registry',
                    subtitle: 'GST-OTA1...A56',
                    isVerified: profile.gstVerified,
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      'PARTNERING SINCE MAY 2012',
                      style: TextStyle(fontSize: 10, color: const Color(0xFF94A3B8), fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            // 7. Client Reviews Section (Empty state with Lottie)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.star_outline, color: Color(0xFF0284C7), size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Client Reviews',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          height: 120,
                          child: Lottie.network(
                            'https://lottie.host/575e9e04-d5cf-4df5-b98a-76192d19b6eb/s8U5YkR8eK.json',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.rate_review_outlined,
                                size: 60,
                                color: Color(0xFF94A3B8),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'No reviews yet',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF475569),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Feedback from completed projects will appear here.',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF94A3B8),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Share & Report Bottom Row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildCircularActionBtn(Icons.share_outlined, 'SHARE'),
                const SizedBox(width: 24),
                _buildCircularActionBtn(Icons.info_outline, 'REPORT'),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Future<void> _launchSocialLink(String platform, String value) async {
    if (value.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No $platform link is provided.')),
        );
      }
      return;
    }

    Uri uri;
    if (value.startsWith('http://') || value.startsWith('https://')) {
      uri = Uri.parse(value);
    } else {
      switch (platform.toLowerCase()) {
        case 'whatsapp':
          final clean = value.replaceAll(RegExp(r'[^0-9]'), '');
          uri = Uri.parse('https://wa.me/$clean');
          break;
        case 'instagram':
          uri = Uri.parse('https://instagram.com/$value');
          break;
        case 'facebook':
          uri = Uri.parse('https://facebook.com/$value');
          break;
        default:
          uri = Uri.parse('https://$value');
      }
    }

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch URL';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open link: $value')),
        );
      }
    }
  }

  Widget _buildMockupSocialBtn({
    required String label,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: bgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 16),
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569), fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMockupStatCard({required String value, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8), height: 1.2),
          ),
        ],
      ),
    );
  }

  Widget _buildChipText(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0369A1)),
      ),
    );
  }

  Widget _buildMockupFeaturedCard({
    required String title,
    required String category,
    required String price,
    required String imageUrl,
  }) {
    return Container(
      width: 260,
      margin: const EdgeInsets.only(right: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        image: DecorationImage(
          image: NetworkImage(imageUrl),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
          ),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  category,
                  style: const TextStyle(color: Colors.white70, fontSize: 8, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                price,
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerifiedTrustRow({
    required String title,
    required String subtitle,
    required bool isVerified,
  }) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.shield_outlined, color: Color(0xFF64748B), size: 18),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A), fontSize: 13),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(color: isVerified ? const Color(0xFF16A34A) : const Color(0xFF94A3B8), fontSize: 9, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const Spacer(),
        if (isVerified)
          const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 20)
        else
          const Icon(Icons.radio_button_unchecked, color: Color(0xFFCBD5E1), size: 20),
      ],
    );
  }

  Widget _buildCircularActionBtn(IconData icon, String label) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Icon(icon, color: const Color(0xFF64748B), size: 18),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8), letterSpacing: 0.5),
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
  // Calculate dynamic profile visibility percentage based on fields filled
  int _calculateVisibility() {
    int percentage = 20;
    if (_fullNameController.text.trim().isNotEmpty) percentage += 10;
    if (_phoneController.text.trim().isNotEmpty) percentage += 10;
    if (_addressController.text.trim().isNotEmpty) percentage += 10;
    if (_experienceController.text.trim().isNotEmpty) percentage += 10;
    if (_bioController.text.trim().isNotEmpty) percentage += 15;
    if (_whatsappController.text.trim().isNotEmpty) percentage += 5;
    if (_instagramController.text.trim().isNotEmpty) percentage += 5;
    if (_facebookController.text.trim().isNotEmpty) percentage += 5;
    if (_websiteController.text.trim().isNotEmpty) percentage += 5;
    if (_aadhaarStatus == 'VERIFIED') percentage += 10;
    if (_panStatus == 'VERIFIED') percentage += 5;
    return percentage > 100 ? 100 : percentage;
  }

  Widget _buildProfileSetupForm() {
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () {
            setState(() {
              _isEditing = false;
            });
          },
        ),
        title: const Text(
          'Thekedar Connect',
          style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(left: 20, right: 20, top: 24, bottom: 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Header Text
                const Text(
                  'Professional Verification',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Complete your profile to unlock high-value contracts. Verified professionals receive 3x more project invitations.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // 2. Personal Information Card
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
                        children: const [
                          Icon(Icons.person_outline, color: Color(0xFF0284C7), size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Personal Information',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

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
                                    backgroundImage: _profilePhotoFile != null
                                        ? FileImage(_profilePhotoFile!)
                                        : (_profilePhotoUrl != null && _profilePhotoUrl!.isNotEmpty
                                            ? NetworkImage(_profilePhotoUrl!)
                                            : null) as ImageProvider?,
                                    child: _profilePhotoFile == null && (_profilePhotoUrl == null || _profilePhotoUrl!.isEmpty)
                                        ? const Icon(Icons.person, size: 40, color: Color(0xFF0284C7))
                                        : null,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: _pickProfilePhoto,
                                  child: const CircleAvatar(
                                    radius: 14,
                                    backgroundColor: Color(0xFF0284C7),
                                    child: Icon(Icons.camera_alt, color: Colors.white, size: 12),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),

                      const Text(
                        'FULL NAME',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _fullNameController,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'John Doe',
                          fillColor: const Color(0xFFF8FAFC),
                          filled: true,
                          prefixIcon: const Icon(Icons.person_outline, size: 18),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          enabledBorder: inputBorder,
                          focusedBorder: inputBorder.copyWith(borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.8)),
                        ),
                      ),
                      const SizedBox(height: 16),

                      const Text(
                        'CONTACT NUMBER',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _phoneController,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: '+91 98765 43210',
                          fillColor: const Color(0xFFF8FAFC),
                          filled: true,
                          prefixIcon: const Icon(Icons.phone_outlined, size: 18),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          enabledBorder: inputBorder,
                          focusedBorder: inputBorder.copyWith(borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.8)),
                        ),
                      ),
                      const SizedBox(height: 16),

                      const Text(
                        'PERMANENT ADDRESS',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _addressController,
                        onChanged: (_) => setState(() {}),
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Building, Street, Area, City, PIN Code',
                          fillColor: const Color(0xFFF8FAFC),
                          filled: true,
                          prefixIcon: const Padding(
                            padding: EdgeInsets.only(bottom: 30),
                            child: Icon(Icons.location_on_outlined, size: 18),
                          ),
                          contentPadding: const EdgeInsets.all(16),
                          enabledBorder: inputBorder,
                          focusedBorder: inputBorder.copyWith(borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.8)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 3. Professional Details Card
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
                        children: const [
                          Icon(Icons.work_outline, color: Color(0xFF0284C7), size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Professional Details',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      const Text(
                        'BUSINESS NAME',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _businessNameController,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'e.g. Apex Constructions',
                          fillColor: const Color(0xFFF8FAFC),
                          filled: true,
                          prefixIcon: const Icon(Icons.business_outlined, size: 18),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          enabledBorder: inputBorder,
                          focusedBorder: inputBorder.copyWith(borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.8)),
                        ),
                      ),
                      const SizedBox(height: 16),

                      const Text(
                        'WORK CATEGORY',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: _selectedWorkCategory,
                        dropdownColor: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        decoration: InputDecoration(
                          fillColor: const Color(0xFFF8FAFC),
                          filled: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          enabledBorder: inputBorder,
                          focusedBorder: inputBorder,
                        ),
                        items: _categories.map((c) {
                          return DropdownMenuItem<String>(
                            value: c,
                            child: Text(c, style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A))),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedWorkCategory = val;
                              _selectedCategories.clear();
                              _selectedCategories.add(val);
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      const Text(
                        'YEARS OF EXPERIENCE',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _experienceController,
                        onChanged: (_) => setState(() {}),
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'e.g. 10',
                          fillColor: const Color(0xFFF8FAFC),
                          filled: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          enabledBorder: inputBorder,
                          focusedBorder: inputBorder.copyWith(borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.8)),
                        ),
                      ),
                      const SizedBox(height: 16),

                      const Text(
                        'PROJECTS COMPLETED',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _projectsCompletedController,
                        onChanged: (_) => setState(() {}),
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'e.g. 25',
                          fillColor: const Color(0xFFF8FAFC),
                          filled: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          enabledBorder: inputBorder,
                          focusedBorder: inputBorder.copyWith(borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.8)),
                        ),
                      ),
                      const SizedBox(height: 16),

                      const Text(
                        'PROFESSIONAL BIO',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _bioController,
                        onChanged: (_) => setState(() {}),
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'Describe your expertise and major projects completed...',
                          fillColor: const Color(0xFFF8FAFC),
                          filled: true,
                          contentPadding: const EdgeInsets.all(16),
                          enabledBorder: inputBorder,
                          focusedBorder: inputBorder.copyWith(borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.8)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 4. Social Links Card
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
                        children: const [
                          Icon(Icons.share_outlined, color: Color(0xFF0284C7), size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Social Links',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      const Text(
                        'WHATSAPP NUMBER',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _whatsappController,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: '+91 98765 43210',
                          fillColor: const Color(0xFFF8FAFC),
                          filled: true,
                          prefixIcon: const Icon(Icons.chat_bubble_outline, size: 18),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          enabledBorder: inputBorder,
                          focusedBorder: inputBorder.copyWith(borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.8)),
                        ),
                      ),
                      const SizedBox(height: 16),

                      const Text(
                        'INSTAGRAM PROFILE',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _instagramController,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: '@username',
                          fillColor: const Color(0xFFF8FAFC),
                          filled: true,
                          prefixIcon: const Icon(Icons.camera_alt_outlined, size: 18),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          enabledBorder: inputBorder,
                          focusedBorder: inputBorder.copyWith(borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.8)),
                        ),
                      ),
                      const SizedBox(height: 16),

                      const Text(
                        'FACEBOOK PROFILE',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _facebookController,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'facebook.com/profile',
                          fillColor: const Color(0xFFF8FAFC),
                          filled: true,
                          prefixIcon: const Icon(Icons.public_outlined, size: 18),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          enabledBorder: inputBorder,
                          focusedBorder: inputBorder.copyWith(borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.8)),
                        ),
                      ),
                      const SizedBox(height: 16),

                      const Text(
                        'WEBSITE URL',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _websiteController,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'www.yourwebsite.com',
                          fillColor: const Color(0xFFF8FAFC),
                          filled: true,
                          prefixIcon: const Icon(Icons.language_outlined, size: 18),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          enabledBorder: inputBorder,
                          focusedBorder: inputBorder.copyWith(borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.8)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // 5. Document Upload Card
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
                        children: const [
                          Icon(Icons.upload_file_outlined, color: Color(0xFF0284C7), size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Document Upload',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // PAN Card upload row
                      _buildMockupUploadRow(
                        title: 'PAN Card',
                        formatInfo: 'FORMAT: JPG, PDF (MAX 2MB)',
                        status: _panStatus,
                        onUploadTap: () => _pickDocument('pan'),
                      ),
                      if (_panFile == null && _panDocUrl != null && _panDocUrl!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.link, size: 14, color: Color(0xFF0284C7)),
                            const SizedBox(width: 4),
                            const Text(
                              'Uploaded document: ',
                              style: TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                            ),
                            Expanded(
                              child: Text(
                                _panDocUrl!.split('/').last,
                                style: const TextStyle(fontSize: 10, color: Color(0xFF0284C7), fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const Divider(height: 32, color: Color(0xFFF1F5F9)),

                      // GST upload row
                      _buildMockupUploadRow(
                        title: 'GST Certificate (Optional)',
                        formatInfo: 'FORMAT: PDF (MAX 5MB)',
                        status: _gstStatus,
                        onUploadTap: () => _pickDocument('gst'),
                      ),
                      if (_gstFile == null && _gstDocUrl != null && _gstDocUrl!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.link, size: 14, color: Color(0xFF0284C7)),
                            const SizedBox(width: 4),
                            const Text(
                              'Uploaded document: ',
                              style: TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                            ),
                            Expanded(
                              child: Text(
                                _gstDocUrl!.split('/').last,
                                style: const TextStyle(fontSize: 10, color: Color(0xFF0284C7), fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const Divider(height: 32, color: Color(0xFFF1F5F9)),

                      // Aadhaar upload row
                      _buildMockupUploadRow(
                        title: 'Aadhaar Card (Front & Back)',
                        formatInfo: 'FORMAT: JPG, PDF (MAX 2MB)',
                        status: _aadhaarStatus,
                        onUploadTap: () => _pickDocument('aadhaar'),
                      ),
                      if (_aadhaarFile == null && _aadhaarDocUrl != null && _aadhaarDocUrl!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.link, size: 14, color: Color(0xFF0284C7)),
                            const SizedBox(width: 4),
                            const Text(
                              'Uploaded document: ',
                              style: TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                            ),
                            Expanded(
                              child: Text(
                                _aadhaarDocUrl!.split('/').last,
                                style: const TextStyle(fontSize: 10, color: Color(0xFF0284C7), fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Project Portfolio Card
                Container(
                  padding: const EdgeInsets.all(20),
                  margin: const EdgeInsets.only(top: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.photo_library_outlined, color: Color(0xFF0284C7), size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Project Portfolio',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      // Render existing portfolio images
                      if (_portfolioUrls.isNotEmpty) ...[
                        const Text(
                          'EXISTING WORK PHOTOS',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.5),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 80,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _portfolioUrls.length,
                            itemBuilder: (context, index) {
                              return Stack(
                                children: [
                                  Container(
                                    width: 80,
                                    height: 80,
                                    margin: const EdgeInsets.only(right: 8),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      image: DecorationImage(
                                        image: NetworkImage(_portfolioUrls[index]),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 2,
                                    right: 10,
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _portfolioUrls.removeAt(index);
                                        });
                                      },
                                      child: const CircleAvatar(
                                        radius: 10,
                                        backgroundColor: Colors.red,
                                        child: Icon(Icons.close, size: 12, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Render newly selected/compressed portfolio files
                      if (_portfolioFiles.isNotEmpty) ...[
                        const Text(
                          'NEWLY SELECTED PHOTOS',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.5),
                        ),
                        const SizedBox(height: 8),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _portfolioFiles.length,
                          itemBuilder: (context, index) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      _portfolioFiles[index],
                                      width: 40,
                                      height: 40,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Project Image ${index + 1}',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                    onPressed: () {
                                      setState(() {
                                        _portfolioFiles.removeAt(index);
                                      });
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Add photos button
                      OutlinedButton.icon(
                        onPressed: _pickPortfolioImages,
                        icon: const Icon(Icons.add_photo_alternate_outlined),
                        label: const Text('Add Project Images', style: TextStyle(fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF0284C7),
                          side: const BorderSide(color: Color(0xFF0284C7)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 6. Submit Button
                SizedBox(
                  height: 54,
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton.icon(
                          onPressed: _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0369A1), // Royal Blue
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          icon: const Icon(Icons.verified_user_outlined, size: 20),
                          label: const Text(
                            'Submit for Verification',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'BY SUBMITTING, YOU AGREE TO OUR VERIFICATION TERMS & CONDITIONS.',
                  style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // 7. Why Verify Card
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
                      const Text(
                        'WHY VERIFY?',
                        style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0369A1), fontSize: 13, letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 16),
                      _buildCheckBullet('Priority listing in "Top Professionals" section'),
                      const SizedBox(height: 12),
                      _buildCheckBullet('Eligible for high-budget commercial projects'),
                      const SizedBox(height: 12),
                      _buildCheckBullet('Direct "Book Now" feature enabled on profile'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 8. Need Assistance Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'NEED ASSISTANCE?',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A), fontSize: 12, letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Our onboarding team is available 24/7 to help you with documentation.',
                        style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Starting chat support...')),
                          );
                        },
                        icon: const Icon(Icons.headset_mic_outlined, size: 16),
                        label: const Text('Chat with Support', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF0369A1),
                          side: const BorderSide(color: Color(0xFF0369A1), width: 1.2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

          // 9. Premium Floating Sticky Footer Overlay Visibility Badge
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  )
                ],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: const Color(0xFFF1F5F9),
                      child: ClipOval(
                        child: _profilePhotoUrl != null
                            ? Image.network(_profilePhotoUrl!, width: 44, height: 44, fit: BoxFit.cover)
                            : const Icon(Icons.person, color: Color(0xFF64748B)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Verification in Progress',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A), fontSize: 14),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'PROFILE VISIBILITY: ${_calculateVisibility()}%',
                            style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0284C7), fontSize: 11, letterSpacing: 0.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckBullet(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.check_circle_outline, color: Color(0xFF10B981), size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Color(0xFF475569), fontSize: 13, height: 1.3, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget _buildMockupUploadRow({
    required String title,
    required String formatInfo,
    required String status,
    required VoidCallback onUploadTap,
  }) {
    Color statusColor = const Color(0xFF94A3B8);
    Color statusBg = const Color(0xFFF1F5F9);
    if (status == 'VERIFIED') {
      statusColor = const Color(0xFF10B981);
      statusBg = const Color(0xFFD1FAE5);
    } else if (status == 'OPTIONAL') {
      statusColor = const Color(0xFF64748B);
      statusBg = const Color(0xFFF1F5F9);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.credit_card_outlined, color: Color(0xFF3B82F6), size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A), fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formatInfo,
                    style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 9, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: statusBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                status,
                style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
            const Spacer(),
            SizedBox(
              height: 32,
              child: ElevatedButton(
                onPressed: onUploadTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                child: Text(status == 'VERIFIED' ? 'Change' : 'Upload', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ],
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
