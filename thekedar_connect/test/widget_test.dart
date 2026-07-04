import 'package:flutter_test/flutter_test.dart';
import 'package:thekedar_connect/features/contractor/presentation/models/contractor_profile.dart';

void main() {
  group('ContractorProfile Unit Tests', () {
    test('Verify ContractorProfile initializes correctly with required values', () {
      final profile = ContractorProfile(
        fullName: 'Nikhil Kumar',
        phone: '+919999999999',
        address: 'Patna, Bihar',
        businessName: 'Nikhil Constructions',
        yearsExperience: 8,
        bio: 'Civil contractor with 8 years experience.',
        categories: ['Mason', 'Painter'],
        socialLinks: {'facebook': 'https://facebook.com/nikhil'},
        aadhaarVerified: true,
        panVerified: false,
        gstVerified: false,
        portfolioUrls: ['https://example.com/p1.jpg'],
      );

      expect(profile.fullName, 'Nikhil Kumar');
      expect(profile.phone, '+919999999999');
      expect(profile.address, 'Patna, Bihar');
      expect(profile.businessName, 'Nikhil Constructions');
      expect(profile.yearsExperience, 8);
      expect(profile.bio, 'Civil contractor with 8 years experience.');
      expect(profile.categories, ['Mason', 'Painter']);
      expect(profile.socialLinks['facebook'], 'https://facebook.com/nikhil');
      expect(profile.aadhaarVerified, isTrue);
      expect(profile.panVerified, isFalse);
      expect(profile.gstVerified, isFalse);
      expect(profile.portfolioUrls, ['https://example.com/p1.jpg']);
      
      // Defaults
      expect(profile.projectsCompleted, 0);
      expect(profile.status, 'DRAFT');
    });

    test('Verify custom optional values are initialized', () {
      final profile = ContractorProfile(
        fullName: 'Rajesh Kumar',
        phone: '+918888888888',
        address: 'Ranchi, Jharkhand',
        businessName: 'Rajesh Electricals',
        yearsExperience: 12,
        bio: 'Electrical contractor.',
        categories: ['Electrician'],
        socialLinks: {},
        aadhaarVerified: true,
        panVerified: true,
        gstVerified: true,
        aadhaarDocUrl: 'https://example.com/aadhaar.pdf',
        panDocUrl: 'https://example.com/pan.pdf',
        gstDocUrl: 'https://example.com/gst.pdf',
        portfolioUrls: [],
        projectsCompleted: 25,
        status: 'APPROVED',
      );

      expect(profile.aadhaarDocUrl, 'https://example.com/aadhaar.pdf');
      expect(profile.panDocUrl, 'https://example.com/pan.pdf');
      expect(profile.gstDocUrl, 'https://example.com/gst.pdf');
      expect(profile.projectsCompleted, 25);
      expect(profile.status, 'APPROVED');
    });
  });
}
