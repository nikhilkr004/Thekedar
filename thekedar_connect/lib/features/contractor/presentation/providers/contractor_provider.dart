import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repositories/contractor_repository.dart';
import '../../data/repositories/contractor_repository_impl.dart';
import '../../presentation/models/contractor_profile.dart';

final contractorRepositoryProvider = Provider<ContractorRepository>((ref) {
  return ContractorRepositoryImpl(Supabase.instance.client);
});

final leadsProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>((ref, categoriesStr) async {
  final repo = ref.watch(contractorRepositoryProvider);
  final categories = categoriesStr.split(',').map((c) => c.trim()).toList();
  return await repo.getLeads(categories);
});

final walletProvider = StreamProvider.autoDispose<Map<String, dynamic>?>(
  (ref) {
    final repo = ref.watch(contractorRepositoryProvider);
    return repo.getWalletBalance();
  },
);


final walletBalanceProvider = FutureProvider.autoDispose<int?>(
  (ref) async {
    final repo = ref.watch(contractorRepositoryProvider);
    return repo.getWalletCredits();
  },
);


// Provider for Contractor Profile
final contractorProfileProvider = FutureProvider.autoDispose<ContractorProfile?>((ref) async {
  final repo = ref.watch(contractorRepositoryProvider);
  return await repo.getProfile();
});

// Map of project_id -> status for all bids/applications by the current contractor
final contractorBidsProvider = FutureProvider.autoDispose<Map<String, String>>((ref) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return {};
  
  try {
    final contractor = await Supabase.instance.client
        .from('contractors')
        .select('id')
        .eq('user_id', userId)
        .maybeSingle();
        
    if (contractor == null) return {};
    
    final response = await Supabase.instance.client
        .from('applications')
        .select('project_id, status')
        .eq('contractor_id', contractor['id']);
        
    final bidsMap = <String, String>{};
    for (final app in response) {
      final projectId = app['project_id']?.toString() ?? '';
      final status = app['status']?.toString() ?? 'pending';
      if (projectId.isNotEmpty) {
        bidsMap[projectId] = status;
      }
    }
    return bidsMap;
  } catch (e) {
    return {};
  }
});

final walletTransactionsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(contractorRepositoryProvider);
  return await repo.getTransactions();
});

// Provider to fetch all actual contractors for customer home screen
final topContractorsProvider = FutureProvider.autoDispose<List<ContractorProfile>>((ref) async {
  try {
    final response = await Supabase.instance.client
        .from('contractors')
        .select(
          'business_name, years_experience, bio, categories, social_links, '
          'aadhaar_verified, pan_verified, gst_verified, '
          'aadhaar_doc_url, pan_doc_url, gst_doc_url, portfolio_urls, '
          'projects_completed, status, '
          'users:user_id (full_name, phone, address)',
        );

    final list = <ContractorProfile>[];
    for (final res in response) {
      final userData = res['users'] as Map<String, dynamic>? ?? {};
      list.add(ContractorProfile(
        fullName: userData['full_name'] ?? 'Contractor',
        phone: userData['phone'] ?? '',
        address: userData['address'] ?? '',
        businessName: res['business_name'] ?? 'Thekedar',
        yearsExperience: (res['years_experience'] ?? 0) as int,
        bio: res['bio'] ?? '',
        categories: (res['categories'] as List?)?.cast<String>() ?? [],
        socialLinks: res['social_links'] as Map<String, dynamic>? ?? {},
        aadhaarVerified: res['aadhaar_verified'] as bool? ?? false,
        panVerified: res['pan_verified'] as bool? ?? false,
        gstVerified: res['gst_verified'] as bool? ?? false,
        aadhaarDocUrl: res['aadhaar_doc_url'] as String?,
        panDocUrl: res['pan_doc_url'] as String?,
        gstDocUrl: res['gst_doc_url'] as String?,
        portfolioUrls: (res['portfolio_urls'] as List?)?.cast<String>() ?? [],
        projectsCompleted: (res['projects_completed'] ?? 0) as int,
        status: res['status'] ?? 'DRAFT',
      ));
    }
    return list;
  } catch (e) {
    return [];
  }
});

