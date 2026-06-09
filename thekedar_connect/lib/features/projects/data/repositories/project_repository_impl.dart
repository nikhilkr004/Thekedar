import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repositories/project_repository.dart';

class ProjectRepositoryImpl implements ProjectRepository {
  final SupabaseClient _supabase;

  ProjectRepositoryImpl(this._supabase);

  @override
  Future<void> createProject({
    required String title,
    required String description,
    required String category,
    required int budgetMin,
    required int budgetMax,
    required String timeline,
    required String addressText,
    required String city,
    dynamic pdfDrawingFile,
    List<dynamic>? landImageFiles,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    String? drawingUrl;
    List<String> imageUrls = [];

    // 1. Upload PDF blueprint drawing if selected
    if (pdfDrawingFile != null) {
      try {
        final String fileName = 'drawing_${DateTime.now().millisecondsSinceEpoch}.pdf';
        final fileBytes = await (pdfDrawingFile as File).readAsBytes();
        await _supabase.storage.from('project_drawings').uploadBinary(
              '${user.id}/$fileName',
              fileBytes,
              fileOptions: const FileOptions(contentType: 'application/pdf'),
            );
        drawingUrl = _supabase.storage.from('project_drawings').getPublicUrl('${user.id}/$fileName');
      } catch (e) {
        print('Drawing upload error detail: $e');
      }
    }

    // 2. Upload multiple land photo images if selected
    if (landImageFiles != null && landImageFiles.isNotEmpty) {
      for (int i = 0; i < landImageFiles.length; i++) {
        try {
          final String fileName = 'land_photo_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
          final File imageFile = landImageFiles[i] as File;
          final fileBytes = await imageFile.readAsBytes();
          
          await _supabase.storage.from('project_photos').uploadBinary(
                '${user.id}/$fileName',
                fileBytes,
                fileOptions: const FileOptions(contentType: 'image/jpeg'),
              );
          final url = _supabase.storage.from('project_photos').getPublicUrl('${user.id}/$fileName');
          imageUrls.add(url);
        } catch (e) {
          print('Image upload error detail: $e');
        }
      }
    }

    // 3. Assemble description with public URL details & save metadata
    String finalDescription = description;
    if (drawingUrl != null) {
      finalDescription += '\n\n[Drawing PDF URL: $drawingUrl]';
    }
    if (imageUrls.isNotEmpty) {
      finalDescription += '\n\n[Land Image URLs: ${imageUrls.join(', ')}]';
    }

    await _supabase.from('projects').insert({
      'customer_id': user.id,
      'title': title,
      'description': finalDescription,
      'category': category,
      'budget_min': budgetMin,
      'budget_max': budgetMax,
      'timeline': timeline,
      'address_text': addressText,
      'city': city,
      'status': 'active', // default status
    });
  }

  @override
  Future<List<Map<String, dynamic>>> getCustomerProjects(String customerId) async {
    try {
      final response = await _supabase
          .from('projects')
          .select()
          .eq('customer_id', customerId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e, st) {
      print('getCustomerProjects database error: $e');
      print(st);
      rethrow;
    }
  }
}
