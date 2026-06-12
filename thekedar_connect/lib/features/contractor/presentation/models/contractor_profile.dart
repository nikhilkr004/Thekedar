class ContractorProfile {
  final String fullName;
  final String phone;
  final String address;
  final String businessName;
  final int yearsExperience;
  final String bio;
  final List<String> categories;
  final Map<String, dynamic> socialLinks;
  final bool aadhaarVerified;
  final bool panVerified;
  final bool gstVerified;
  final String? aadhaarDocUrl;
  final String? panDocUrl;
  final String? gstDocUrl;
  final List<String> portfolioUrls;
  final int projectsCompleted;

  ContractorProfile({
    required this.fullName,
    required this.phone,
    required this.address,
    required this.businessName,
    required this.yearsExperience,
    required this.bio,
    required this.categories,
    required this.socialLinks,
    required this.aadhaarVerified,
    required this.panVerified,
    required this.gstVerified,
    this.aadhaarDocUrl,
    this.panDocUrl,
    this.gstDocUrl,
    required this.portfolioUrls,
    this.projectsCompleted = 0,
  });
}
