import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_theme.dart';
import '../providers/app_state_providers.dart';
import '../widgets/glass_container.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../data/models/prediction_model.dart';

class PredictScreen extends ConsumerStatefulWidget {
  const PredictScreen({super.key});

  @override
  ConsumerState<PredictScreen> createState() => _PredictScreenState();
}

class _PredictScreenState extends ConsumerState<PredictScreen> {
  // Vision State
  bool _isLoadingVision = false;
  String? _errorMsgVision;
  XFile? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  // Manual State
  double _sepalLength = 5.1;
  double _sepalWidth = 3.5;
  double _petalLength = 1.4;
  double _petalWidth = 0.2;
  bool _isLoadingManual = false;
  String? _errorMsgManual;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _selectedImage = pickedFile;
          _errorMsgVision = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMsgVision = 'Failed to pick image: $e';
      });
    }
  }

  Future<void> _submitVisionPrediction() async {
    if (_selectedImage == null) {
      setState(() => _errorMsgVision = 'Please upload or capture an image first.');
      return;
    }

    setState(() {
      _isLoadingVision = true;
      _errorMsgVision = null;
    });

    try {
      final baseUrl = ref.read(apiBaseUrlProvider);
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/predict/vision'));

      if (kIsWeb) {
        final bytes = await _selectedImage!.readAsBytes();
        request.files.add(http.MultipartFile.fromBytes(
          'image',
          bytes,
          filename: _selectedImage!.name.isNotEmpty ? _selectedImage!.name : 'upload.jpg',
        ));
      } else {
        request.files.add(await http.MultipartFile.fromPath('image', _selectedImage!.path));
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody);
        final predictionModel = PredictionModel.fromJson(data);
        
        ref.read(latestPredictionProvider.notifier).state = predictionModel;
        ref.read(historyProvider.notifier).fetchHistory();
        
        if (mounted) context.push('/result');
      } else {
        setState(() => _errorMsgVision = 'API prediction failed: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _errorMsgVision = 'Failed to connect to backend: $e');
    } finally {
      if (mounted) setState(() => _isLoadingVision = false);
    }
  }

  Future<void> _submitManualPrediction() async {
    setState(() {
      _isLoadingManual = true;
      _errorMsgManual = null;
    });

    try {
      final predictFn = ref.read(predictMethodProvider);
      await predictFn(_sepalLength, _sepalWidth, _petalLength, _petalWidth);
      if (mounted) {
        context.push('/result');
      }
    } catch (e) {
      setState(() {
        _errorMsgManual = 'Prediction failed. Is the backend running?';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoadingManual = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Identify Iris',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/'),
          ),
          bottom: TabBar(
            labelColor: isDark ? Colors.white : Colors.blueGrey.shade900,
            unselectedLabelColor: isDark ? Colors.grey.shade500 : Colors.blueGrey.shade400,
            indicatorColor: AppTheme.primaryColor,
            tabs: const [
              Tab(icon: Icon(Icons.camera_alt), text: "Image Scan"),
              Tab(icon: Icon(Icons.tune), text: "Manual Data"),
            ],
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? [const Color(0xFF0F172A), const Color(0xFF0B0F19)]
                  : [const Color(0xFFF3F4F6), const Color(0xFFE5E7EB)],
            ),
          ),
          child: TabBarView(
            children: [
              _buildVisionTab(context, isDark),
              _buildManualTab(context, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVisionTab(BuildContext context, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: GlassContainer(
        width: 550,
        child: Column(
          children: [
            Text(
              'Upload Image',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.blueGrey.shade900,
                  ),
            ),
            const SizedBox(height: 10),
            Text(
              'Provide a clear image of an Iris flower. Our YOLOv8 model will detect the flower and classify its species.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.grey.shade400 : Colors.blueGrey.shade600,
              ),
            ),
            const SizedBox(height: 30),
            if (_errorMsgVision != null) ...[
              Text(_errorMsgVision!, style: const TextStyle(color: Colors.redAccent)),
              const SizedBox(height: 24),
            ],
            GestureDetector(
              onTap: () => _pickImage(ImageSource.gallery),
              child: Container(
                height: 250,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark ? Colors.black.withOpacity(0.2) : Colors.grey.shade100,
                  border: Border.all(
                    color: _selectedImage != null ? AppTheme.primaryColor : Colors.grey,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: _selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: kIsWeb
                            ? Image.network(_selectedImage!.path, fit: BoxFit.cover)
                            : Image.file(File(_selectedImage!.path), fit: BoxFit.cover),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.cloud_upload_rounded, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text('Tap to upload from Gallery'),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => _pickImage(ImageSource.camera),
              icon: const Icon(Icons.camera_alt),
              label: const Text('Capture Photo'),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: (_isLoadingVision || _selectedImage == null) ? null : _submitVisionPrediction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isLoadingVision
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Identify Species', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManualTab(BuildContext context, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: GlassContainer(
        width: 550,
        child: Column(
          children: [
            Text(
              'Manual Measurements',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.blueGrey.shade900,
                  ),
            ),
            const SizedBox(height: 10),
            Text(
              'Enter the physical measurements of the Iris flower parts to classify the species.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.grey.shade400 : Colors.blueGrey.shade600,
              ),
            ),
            const SizedBox(height: 30),
            if (_errorMsgManual != null) ...[
              Text(_errorMsgManual!, style: const TextStyle(color: Colors.redAccent)),
              const SizedBox(height: 24),
            ],
            _buildSlider('Sepal Length (cm)', _sepalLength, 4.0, 8.0, (v) => setState(() => _sepalLength = v)),
            _buildSlider('Sepal Width (cm)', _sepalWidth, 2.0, 4.5, (v) => setState(() => _sepalWidth = v)),
            _buildSlider('Petal Length (cm)', _petalLength, 1.0, 7.0, (v) => setState(() => _petalLength = v)),
            _buildSlider('Petal Width (cm)', _petalWidth, 0.1, 2.5, (v) => setState(() => _petalWidth = v)),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoadingManual ? null : _submitManualPrediction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isLoadingManual
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Predict Manually', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlider(String label, double value, double min, double max, ValueChanged<double> onChanged) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(color: isDark ? Colors.white70 : Colors.blueGrey.shade700, fontWeight: FontWeight.w600)),
            Text(value.toStringAsFixed(1), style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          activeColor: AppTheme.primaryColor,
          inactiveColor: isDark ? Colors.white24 : Colors.grey.shade300,
          onChanged: onChanged,
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
