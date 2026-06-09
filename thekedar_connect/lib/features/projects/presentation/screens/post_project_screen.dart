import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:file_picker/file_picker.dart';
import '../providers/project_provider.dart';

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

  // Attachment references (PDF only for blueprint, multiple images for land photos)
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
        imageQuality: 30, // Compress down highly to KBs
        maxWidth: 1024,   // Resize large dimensions for fast upload
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
    // Custom border definition to match the exact design in the image (soft, rounded, light grey border)
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
    );

    const labelStyle = TextStyle(
      color: Color(0xFF94A3B8),
      fontSize: 14,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFFCFDFF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF0F172A), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Post a Project',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Tell us about your requirements',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 24),
            
            // Project Title
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Project Title',
                labelStyle: labelStyle,
                fillColor: Colors.white,
                filled: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                enabledBorder: inputBorder,
                focusedBorder: inputBorder.copyWith(
                  borderSide: const BorderSide(color: Color(0xFF0284C7), width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Detailed Requirements
            TextField(
              controller: _descController,
              decoration: InputDecoration(
                labelText: 'Detailed Requirements / Scope of Work...',
                labelStyle: labelStyle,
                fillColor: Colors.white,
                filled: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                enabledBorder: inputBorder,
                focusedBorder: inputBorder.copyWith(
                  borderSide: const BorderSide(color: Color(0xFF0284C7), width: 2),
                ),
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 16),

            // Plot Area
            TextField(
              controller: _plotAreaController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Plot Area (sq. ft.)',
                labelStyle: labelStyle,
                fillColor: Colors.white,
                filled: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                enabledBorder: inputBorder,
                focusedBorder: inputBorder.copyWith(
                  borderSide: const BorderSide(color: Color(0xFF0284C7), width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Category & Timeline Dropdowns row
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Category',
                      labelStyle: labelStyle,
                      fillColor: Colors.white,
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      enabledBorder: inputBorder,
                      focusedBorder: inputBorder.copyWith(
                        borderSide: const BorderSide(color: Color(0xFF0284C7), width: 2),
                      ),
                    ),
                    items: categories
                        .map((c) => DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis)))
                        .toList(),
                    onChanged: (val) => setState(() => _selectedCategory = val!),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedTimeline,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Timeline',
                      labelStyle: labelStyle,
                      fillColor: Colors.white,
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      enabledBorder: inputBorder,
                      focusedBorder: inputBorder.copyWith(
                        borderSide: const BorderSide(color: Color(0xFF0284C7), width: 2),
                      ),
                    ),
                    items: timelines
                        .map((t) => DropdownMenuItem(value: t, child: Text(t, overflow: TextOverflow.ellipsis)))
                        .toList(),
                    onChanged: (val) => setState(() => _selectedTimeline = val!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Site Address
            TextField(
              controller: _addressController,
              decoration: InputDecoration(
                labelText: 'Site Address',
                labelStyle: labelStyle,
                fillColor: Colors.white,
                filled: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                enabledBorder: inputBorder,
                focusedBorder: inputBorder.copyWith(
                  borderSide: const BorderSide(color: Color(0xFF0284C7), width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // City
            TextField(
              controller: _cityController,
              decoration: InputDecoration(
                labelText: 'City',
                labelStyle: labelStyle,
                fillColor: Colors.white,
                filled: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                enabledBorder: inputBorder,
                focusedBorder: inputBorder.copyWith(
                  borderSide: const BorderSide(color: Color(0xFF0284C7), width: 2),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Upload Land Images & Drawings Heading
            const Text(
              'Upload Land Images & Drawings',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 16),

            // Blueprint & Land Photos Attachment Buttons
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _pickPDFDrawing,
                    child: Container(
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.015),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ]
                      ),
                      child: _pdfDrawingFile != null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.picture_as_pdf, color: Colors.redAccent, size: 36),
                                const SizedBox(height: 6),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  child: Text(
                                    _pdfFileName ?? 'blueprint.pdf',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.edit_road, color: Color(0xFF0284C7), size: 28),
                                SizedBox(height: 10),
                                Text(
                                  'Blueprints /\nDrawings (PDF)',
                                  style: TextStyle(fontSize: 12, color: Color(0xFF475569), fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: GestureDetector(
                    onTap: _pickMultipleLandImages,
                    child: Container(
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.015),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ]
                      ),
                      child: _landImageFiles.isNotEmpty
                          ? Stack(
                              fit: StackFit.expand,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: Image.file(_landImageFiles.first, fit: BoxFit.cover),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.4),
                                    borderRadius: BorderRadius.circular(20),
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
                              children: const [
                                Icon(Icons.image_outlined, color: Color(0xFF0284C7), size: 28),
                                SizedBox(height: 10),
                                Text(
                                  'Land Photos\n(Multiple)',
                                  style: TextStyle(fontSize: 12, color: Color(0xFF475569), fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Custom Dotted Map Picker Box to match exactly the screenshot
            GestureDetector(
              onTap: () async {
                setState(() => _isLoading = true);
                try {
                  // Check if location services are enabled
                  bool serviceEnabled = await geolocator.Geolocator.isLocationServiceEnabled();
                  if (!serviceEnabled) {
                    throw 'Location services are disabled.';
                  }

                  // Check location permissions
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

                  // Get current position
                  geolocator.Position position = await geolocator.Geolocator.getCurrentPosition(
                    desiredAccuracy: geolocator.LocationAccuracy.high,
                  );

                  // Update UI with latitude/longitude details
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.01),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ]
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Subtle blueprint grid design pattern in the background
                      Positioned.fill(
                        child: CustomPaint(
                          painter: BlueprintGridPainter(),
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.my_location, size: 36, color: Color(0xFF0284C7)),
                          SizedBox(height: 8),
                          Text(
                            'Click to Use Current Location',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0284C7),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Submit Button
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0284C7).withOpacity(0.25),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0284C7),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: _submit,
                      child: const Text(
                        'Submit Project',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

// Background blueprint grid pattern painter to make the Map select card look premium
class BlueprintGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE2E8F0).withOpacity(0.4)
      ..strokeWidth = 1.0;

    const step = 20.0;
    
    // Draw vertical lines
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    
    // Draw horizontal lines
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
