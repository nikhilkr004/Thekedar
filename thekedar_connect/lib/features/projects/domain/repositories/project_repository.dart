abstract class ProjectRepository {
  Future<void> createProject({
    required String title,
    required String description,
    required String category,
    required int budgetMin,
    required int budgetMax,
    required String timeline,
    required String addressText,
    required String city,
    dynamic pdfDrawingFile, // dynamic to prevent File import overhead if not needed globally
    List<dynamic>? landImageFiles,
  });

  Future<List<Map<String, dynamic>>> getCustomerProjects(String customerId);
}
