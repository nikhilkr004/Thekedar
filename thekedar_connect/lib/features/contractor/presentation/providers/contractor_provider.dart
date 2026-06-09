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
