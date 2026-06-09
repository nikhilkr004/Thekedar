import '../../presentation/models/contractor_profile.dart';

abstract class ContractorRepository {
  Future<List<Map<String, dynamic>>> getLeads(List<String> categories);
  Future<void> unlockLead(String projectId, int costInCredits);
  Future<void> submitProposal({
    required String projectId,
    required int estimatedCostMin,
    required int estimatedCostMax,
    required String estimatedTimeline,
    required String coverMessage,
  });
  Stream<Map<String, dynamic>?> getWalletBalance();

  // New methods for profile & wallet handling
  Future<ContractorProfile?> getProfile();
  Future<int?> getWalletCredits();
  Future<void> deductCredits(int amount);
  Future<void> addCredits(int amount);
  Future<List<Map<String, dynamic>>> getTransactions();
}
