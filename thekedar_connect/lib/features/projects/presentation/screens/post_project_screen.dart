import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:file_picker/file_picker.dart';
import '../providers/project_provider.dart';
import '../../../../core/theme/design_system.dart';

class PostProjectScreen extends ConsumerStatefulWidget {
  const PostProjectScreen({super.key});

  @override
  ConsumerState<PostProjectScreen> createState() => _PostProjectScreenState();
}

class _PostProjectScreenState extends ConsumerState<PostProjectScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _plotAreaController = TextEditingController();

  String _selectedCategory = 'Mason';
  String _selectedTimeline = 'ASAP';
  bool _isLoading = false;

  File? _pdfDrawingFile;
  String? _pdfFileName;
  List<File> _landImageFiles = [];
  final ImagePicker _picker = ImagePicker();

  final categories = ['Mason', 'Plumber', 'Electrician', 'Painter', 'Carpenter'];
  final timelines = ['ASAP', 'Within 1 Week', 'Within 1 Month', 'Flexible'];

  Future<void> _pickPDFDrawing() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (result != null && result.files.single.path != null) {
        setState(() {
          _pdfDrawingFile = File(result.files.single.path!);
          _pdfFileName = result.files.single.name;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick PDF drawing: $e')),
      );
    }
  }

  Future<void> _pickMultipleLandImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        imageQuality: 30,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      if (images.isNotEmpty) {
        setState(() {
          _landImageFiles = images.map((img) => File(img.path)).toList();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick land images: $e')),
      );
    }
  }

  Future<void> _submit() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a project title')),
      );
      return;
    }
    
    setState(() => _isLoading = true);

    String dbTimeline = 'asap';
    switch (_selectedTimeline) {
      case 'ASAP':
        dbTimeline = 'asap';
        break;
      case 'Within 1 Week':
        dbTimeline = '1week';
        break;
      case 'Within 1 Month':
        dbTimeline = '1month';
        break;
      case 'Flexible':
        dbTimeline = 'flexible';
        break;
    }

    try {
      await ref.read(projectRepositoryProvider).createProject(
            title: _titleController.text,
            description: '${_descController.text}\n\n[Plot Area: ${_plotAreaController.text} sq.ft]\n[Drawing Attachment: ${_pdfDrawingFile != null ? _pdfFileName : "None"}]\n[Land Images: ${_landImageFiles.isNotEmpty ? "${_landImageFiles.length} photos selected" : "None"}]',
            category: _selectedCategory,
            budgetMin: 0,
            budgetMax: 0,
            timeline: dbTimeline,
            addressText: _addressController.text,
            city: _cityController.text,
            pdfDrawingFile: _pdfDrawingFile,
            landImageFiles: _landImageFiles,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Project Posted successfully!')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isLargeScreen = screenWidth > 600;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkSurface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Post a Project',
          style: AppTypography.title.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: SizedBox(
          width: isLargeScreen ? 540 : double.infinity,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Tell us about your requirements',
                  style: AppTypography.subtitle.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                
                // Project Title
                TextField(
                  controller: _titleController,
                  style: AppTypography.body.copyWith(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Project Title',
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Detailed Requirements
                TextField(
                  controller: _descController,
                  style: AppTypography.body.copyWith(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Detailed Requirements / Scope of Work...',
                  ),
                  maxLines: 4,
                ),
                const SizedBox(height: AppSpacing.lg),

                // Plot Area
                TextField(
                  controller: _plotAreaController,
                  keyboardType: TextInputType.number,
                  style: AppTypography.body.copyWith(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Plot Area (sq. ft.)',
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Category & Timeline Dropdowns row
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        dropdownColor: AppColors.darkSurface,
                        style: AppTypography.body.copyWith(color: AppColors.textPrimary),
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
                        ),
                        items: categories
                            .map((c) => DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis)))
                            .toList(),
                        onChanged: (val) => setState(() => _selectedCategory = val!),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedTimeline,
                        dropdownColor: AppColors.darkSurface,
                        style: AppTypography.body.copyWith(color: AppColors.textPrimary),
                        decoration: const InputDecoration(
                          labelText: 'Timeline',
                          contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
                        ),
                        items: timelines
                            .map((t) => DropdownMenuItem(value: t, child: Text(t, overflow: TextOverflow.ellipsis)))
                            .toList(),
                        onChanged: (val) => setState(() => _selectedTimeline = val!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // Site Address
                TextField(
                  controller: _addressController,
                  style: AppTypography.body.copyWith(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Site Address',
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // City
                TextField(
                  controller: _cityController,
                  style: AppTypography.body.copyWith(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'City',
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),

                // Upload Land Images & Drawings Heading
                Text(
                  'Upload Land Images & Drawings',
                  style: AppTypography.smallBody.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Blueprint & Land Photos Attachment Buttons
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: _pickPDFDrawing,
                        child: Container(
                          height: 120,
                          decoration: BoxDecoration(
                            color: AppColors.darkCard,
                            borderRadius: BorderRadius.circular(AppRadius.large),
                            border: Border.all(color: AppColors.darkBorder, width: 1.0),
                            boxShadow: AppShadows.darkCardShadow,
                          ),
                          child: _pdfDrawingFile != null
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.picture_as_pdf, color: AppColors.error, size: 36),
                                    const SizedBox(height: 6),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                      child: Text(
                                        _pdfFileName ?? 'blueprint.pdf',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                        style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.edit_road, color: AppColors.primaryLight, size: 28),
                                    const SizedBox(height: 10),
                                    Text(
                                      'Blueprints /\nDrawings (PDF)',
                                      style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: GestureDetector(
                        onTap: _pickMultipleLandImages,
                        child: Container(
                          height: 120,
                          decoration: BoxDecoration(
                            color: AppColors.darkCard,
                            borderRadius: BorderRadius.circular(AppRadius.large),
                            border: Border.all(color: AppColors.darkBorder, width: 1.0),
                            boxShadow: AppShadows.darkCardShadow,
                          ),
                          child: _landImageFiles.isNotEmpty
                              ? Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(AppRadius.large - 1.0),
                                      child: Image.file(_landImageFiles.first, fit: BoxFit.cover),
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.4),
                                        borderRadius: BorderRadius.circular(AppRadius.large - 1.0),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        '+${_landImageFiles.length}\nPhotos',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                    )
                                  ],
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.image_outlined, color: AppColors.primaryLight, size: 28),
                                    const SizedBox(height: 10),
                                    Text(
                                      'Land Photos\n(Multiple)',
                                      style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // Custom Dotted Map Picker Box
                GestureDetector(
                  onTap: () async {
                    setState(() => _isLoading = true);
                    try {
                      bool serviceEnabled = await geolocator.Geolocator.isLocationServiceEnabled();
                      if (!serviceEnabled) {
                        throw 'Location services are disabled.';
                      }

                      geolocator.LocationPermission permission = await geolocator.Geolocator.checkPermission();
                      if (permission == geolocator.LocationPermission.denied) {
                        permission = await geolocator.Geolocator.requestPermission();
                        if (permission == geolocator.LocationPermission.denied) {
                          throw 'Location permissions are denied.';
                        }
                      }
                      
                      if (permission == geolocator.LocationPermission.deniedForever) {
                        throw 'Location permissions are permanently denied.';
                      }

                      geolocator.Position position = await geolocator.Geolocator.getCurrentPosition(
                        desiredAccuracy: geolocator.LocationAccuracy.high,
                      );

                      setState(() {
                        _addressController.text = "Lat: ${position.latitude.toStringAsFixed(6)}, Lon: ${position.longitude.toStringAsFixed(6)}";
                        _cityController.text = "Current Location";
                      });

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Successfully loaded current GPS coordinates!')),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Location error: $e')),
                        );
                      }
                    } finally {
                      if (mounted) setState(() => _isLoading = false);
                    }
                  },
                  child: Container(
                    height: 140,
                    decoration: BoxDecoration(
                      color: AppColors.darkCard,
                      borderRadius: BorderRadius.circular(AppRadius.large),
                      border: Border.all(color: AppColors.darkBorder, width: 1.0),
                      boxShadow: AppShadows.darkCardShadow,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.large - 1.0),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Positioned.fill(
                            child: CustomPaint(
                              painter: BlueprintGridPainter(),
                            ),
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.my_location, size: 36, color: AppColors.primaryLight),
                              const SizedBox(height: 8),
                              Text(
                                'Click to Use Current Location',
                                style: AppTypography.smallBody.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryLight,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),

                // Submit Button
                _isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                    : Container(
                        decoration: BoxDecoration(
                          gradient: AppGradients.primaryGradient,
                          borderRadius: AppRadius.buttonBorderRadius,
                        ),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                          ),
                          onPressed: _submit,
                          child: Text(
                            'Submit Project',
                            style: AppTypography.button.copyWith(color: Colors.white),
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class BlueprintGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.darkBorder.withOpacity(0.3)
      ..strokeWidth = 1.0;

    const step = 20.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
