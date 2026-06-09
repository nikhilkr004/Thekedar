import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repositories/contractor_repository.dart';
import '../../presentation/models/contractor_profile.dart';

class ContractorRepositoryImpl implements ContractorRepository {
  final SupabaseClient _supabase;

  ContractorRepositoryImpl(this._supabase);

  String get _userId => _supabase.auth.currentUser!.id;

  @override
  Future<List<Map<String, dynamic>>> getLeads(List<String> categories) async {
    final response = await _supabase
        .from('projects')
        .select(
          'id, title, category, city, budget_min, budget_max, status, description, address_text, created_at',
        )
        .eq('status', 'active')
        .order('created_at', ascending: false);
    // response is a List<dynamic>
    final List<dynamic> data = response as List<dynamic>;
    return data
        .where((p) => categories.contains(p['category']))
        .cast<Map<String, dynamic>>()
        .toList();
  }

  // ---------- New Profile & Wallet Methods ----------
  @override
  Future<ContractorProfile?> getProfile() async {
    try {
      final res = await _supabase
          .from('contractors')
          .select(
            'business_name, years_experience, bio, categories, social_links, '
            'aadhaar_verified, pan_verified, gst_verified, '
            'users:user_id (full_name, phone, address)',
          )
          .eq('user_id', _userId)
          .maybeSingle();
      if (res == null) return null;

      final userData = res['users'] as Map<String, dynamic>? ?? {};

      return ContractorProfile(
        fullName: userData['full_name'] ?? '',
        phone: userData['phone'] ?? '',
        address: userData['address'] ?? '',
        businessName: res['business_name'] ?? '',
        yearsExperience: (res['years_experience'] ?? 0) as int,
        bio: res['bio'] ?? '',
        categories: (res['categories'] as List?)?.cast<String>() ?? [],
        socialLinks: res['social_links'] as Map<String, dynamic>? ?? {},
        aadhaarVerified: res['aadhaar_verified'] as bool? ?? false,
        panVerified: res['pan_verified'] as bool? ?? false,
        gstVerified: res['gst_verified'] as bool? ?? false,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<int?> getWalletCredits() async {
    try {
      final contractor = await _supabase
          .from('contractors')
          .select('id')
          .eq('user_id', _userId)
          .maybeSingle();
      if (contractor == null) return 0;
      final wallet = await _supabase
          .from('credit_wallets')
          .select('balance')
          .eq('contractor_id', contractor['id'])
          .maybeSingle();
      return wallet?['balance'] as int? ?? 0;
    } catch (_) {
      return 0;
    }
  }

  @override
  Future<void> deductCredits(int amount) async {
    final contractor = await _supabase
        .from('contractors')
        .select('id')
        .eq('user_id', _userId)
        .maybeSingle();
    if (contractor == null) throw 'Contractor profile not found';

    final wallet = await _supabase
        .from('credit_wallets')
        .select('id, balance, total_spent')
        .eq('contractor_id', contractor['id'])
        .maybeSingle();
    if (wallet == null) throw 'Wallet not found';

    final int currentBalance = (wallet['balance'] ?? 0) as int;
    final int currentSpent = (wallet['total_spent'] ?? 0) as int;

    if (currentBalance < amount) {
      throw 'Insufficient credits';
    }

    await _supabase
        .from('credit_wallets')
        .update({
          'balance': currentBalance - amount,
          'total_spent': currentSpent + amount,
        })
        .eq('contractor_id', contractor['id']);

    await _supabase.from('credit_transactions').insert({
      'wallet_id': wallet['id'],
      'contractor_id': contractor['id'],
      'credits': -amount,
      'type': 'spend',
      'description': 'Spent $amount credits to unlock project lead',
    });
  }

  @override
  Future<void> unlockLead(String projectId, int costInCredits) async {
    // Deduct credits first; will throw if insufficient.
    await deductCredits(costInCredits);
    // Insert application row for this contractor.
    final contractor = await _supabase
        .from('contractors')
        .select('id')
        .eq('user_id', _userId)
        .maybeSingle();
    if (contractor == null) throw 'Contractor profile not found';

    await _supabase.from('applications').insert({
      'project_id': projectId,
      'contractor_id': contractor['id'],
      'status': 'pending',
      'credits_used': costInCredits,
      'cover_message': '',
    });
  }

  @override
  Future<void> submitProposal({
    required String projectId,
    required int estimatedCostMin,
    required int estimatedCostMax,
    required String estimatedTimeline,
    required String coverMessage,
  }) async {
    final contractor = await _supabase
        .from('contractors')
        .select('id')
        .eq('user_id', _userId)
        .maybeSingle();
    if (contractor == null) throw 'Contractor profile not found';
    final contractorId = contractor['id'];

    // 1. Check if application already exists
    final existingApp = await _supabase
        .from('applications')
        .select('id')
        .eq('project_id', projectId)
        .eq('contractor_id', contractorId)
        .maybeSingle();

    if (existingApp == null) {
      // 2. Fetch project budget to calculate credit cost
      final project = await _supabase
          .from('projects')
          .select('budget_max')
          .eq('id', projectId)
          .single();
      final budgetMax = (project['budget_max'] ?? 0) as int;

      // Calculate cost based on budget
      int cost = 3; // default
      if (budgetMax >= 2000000) {
        cost = 20;
      } else if (budgetMax >= 500000) {
        cost = 12;
      } else if (budgetMax >= 200000) {
        cost = 8;
      } else if (budgetMax >= 50000) {
        cost = 5;
      }

      // 3. Deduct credits (will throw if insufficient)
      await deductCredits(cost);

      // 4. Insert the application
      await _supabase.from('applications').insert({
        'project_id': projectId,
        'contractor_id': contractorId,
        'status': 'pending',
        'credits_used': cost,
        'estimated_cost_min': estimatedCostMin,
        'estimated_cost_max': estimatedCostMax,
        'estimated_timeline': estimatedTimeline,
        'cover_message': coverMessage,
      });
    } else {
      // 5. Update existing application
      await _supabase
          .from('applications')
          .update({
            'estimated_cost_min': estimatedCostMin,
            'estimated_cost_max': estimatedCostMax,
            'estimated_timeline': estimatedTimeline,
            'cover_message': coverMessage,
          })
          .eq('project_id', projectId)
          .eq('contractor_id', contractorId);
    }
  }

  @override
  Future<void> addCredits(int amount) async {
    final contractor = await _supabase
        .from('contractors')
        .select('id')
        .eq('user_id', _userId)
        .maybeSingle();
    if (contractor == null) throw 'Contractor profile not found';
    final contractorId = contractor['id'];

    final wallet = await _supabase
        .from('credit_wallets')
        .select('id, balance, total_purchased, total_earned')
        .eq('contractor_id', contractorId)
        .maybeSingle();

    if (wallet == null) {
      // Create new wallet
      await _supabase.from('credit_wallets').insert({
        'contractor_id': contractorId,
        'balance': amount,
        'total_purchased': amount,
        'total_earned': amount,
      });
    } else {
      // Update existing wallet balance
      final int currentBalance = (wallet['balance'] ?? 0) as int;
      final int currentPurchased = (wallet['total_purchased'] ?? 0) as int;
      final int currentEarned = (wallet['total_earned'] ?? 0) as int;
      await _supabase
          .from('credit_wallets')
          .update({
            'balance': currentBalance + amount,
            'total_purchased': currentPurchased + amount,
            'total_earned': currentEarned + amount,
          })
          .eq('id', wallet['id']);
    }

    // Log transaction
    final updatedWallet = await _supabase
        .from('credit_wallets')
        .select('id')
        .eq('contractor_id', contractorId)
        .single();

    await _supabase.from('credit_transactions').insert({
      'wallet_id': updatedWallet['id'],
      'contractor_id': contractorId,
      'credits': amount,
      'type': 'purchase',
      'amount_inr': amount * 10, // approximate pricing
      'description': 'Purchased $amount credits via Razorpay',
    });
  }

  @override
  Stream<Map<String, dynamic>?> getWalletBalance() async* {
    try {
      final contractor = await _supabase
          .from('contractors')
          .select('id')
          .eq('user_id', _userId)
          .maybeSingle();
      if (contractor == null) {
        yield {'balance': 0};
        return;
      }
      final contractorId = contractor['id'];
      yield* _supabase
          .from('credit_wallets')
          .stream(primaryKey: ['id'])
          .eq('contractor_id', contractorId)
          .map((events) => events.isNotEmpty ? events.first : {'balance': 0});
    } catch (_) {
      yield {'balance': 0};
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getTransactions() async {
    final contractor = await _supabase
        .from('contractors')
        .select('id')
        .eq('user_id', _userId)
        .maybeSingle();
    if (contractor == null) return [];

    final response = await _supabase
        .from('credit_transactions')
        .select()
        .eq('contractor_id', contractor['id'])
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }
}
