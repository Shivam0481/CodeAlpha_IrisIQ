import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../providers/app_state_providers.dart';
import '../widgets/glass_container.dart';
import '../widgets/flower_painter.dart';

class ResultScreen extends ConsumerWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prediction = ref.watch(latestPredictionProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    if (prediction == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Result')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.warning, size: 48, color: Colors.orange),
              const SizedBox(height: 16),
              const Text('No prediction run yet.'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/predict'),
                child: const Text('Run Prediction'),
              )
            ],
          ),
        ),
      );
    }

    final confidencePercent = (prediction.confidence * 100);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Vision Analysis Results',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/predict'),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF0F172A), const Color(0xFF0B0F19)]
                : [const Color(0xFFF3F4F6), const Color(0xFFE5E7EB)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Flex(
              direction: size.width > 950 ? Axis.horizontal : Axis.vertical,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Column 1: Image & Bounding Boxes
                _buildVisualColumn(context, prediction, confidencePercent, size.width, ref),
                
                const SizedBox(width: 24, height: 24),

                // Column 2: Details & Probability Breakdown
                _buildDetailsColumn(context, prediction, isDark, size.width),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVisualColumn(BuildContext context, dynamic prediction, double confidencePercent, double screenWidth, WidgetRef ref) {
    final baseUrl = ref.watch(apiBaseUrlProvider);
    final String? imageUrl = prediction.imageUrl != null && prediction.imageUrl!.isNotEmpty 
        ? '$baseUrl${prediction.imageUrl}' 
        : null;

    return GlassContainer(
      width: screenWidth > 950 ? 450 : double.infinity,
      child: Column(
        children: [
          Text(
            imageUrl != null ? 'Computer Vision Output' : 'Manual Analysis Output',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 20),
          
          // Image with Bounding Boxes overlay or a placeholder
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: imageUrl != null && imageUrl.isNotEmpty
              ? AspectRatio(
                  aspectRatio: 1.0,
                  child: Stack(
                    children: [
                      Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            color: Colors.black12,
                            child: const Center(child: CircularProgressIndicator()),
                          );
                        },
                      ),
                    Positioned.fill(
                      child: CustomPaint(
                        painter: BoundingBoxPainter(prediction.boundingBoxes),
                      ),
                    ),
                  ],
                ),
              )
              : Container(
                  height: 350,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.blueGrey.withOpacity(0.1),
                        Colors.blueGrey.withOpacity(0.2),
                      ],
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          shape: BoxShape.circle,
                        ),
                        child: IrisFlowerWidget(speciesKey: prediction.speciesKey ?? 'versicolor', size: 160),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Matched Iris Species',
                        style: TextStyle(
                          color: Colors.blueGrey.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
          ),
          
          const SizedBox(height: 20),

          // Confidence gauge
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  value: prediction.confidence,
                  strokeWidth: 6,
                  backgroundColor: Colors.white.withOpacity(0.08),
                  color: _getConfidenceColor(prediction.confidence),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${confidencePercent.toStringAsFixed(1)}%',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w900,
                      fontSize: 24,
                    ),
                  ),
                  Text(
                    'Overall Confidence',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  )
                ],
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsColumn(BuildContext context, dynamic prediction, bool isDark, double screenWidth) {
    return GlassContainer(
      width: screenWidth > 950 ? 550 : double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '🌸 ${prediction.species}',
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getConfidenceColor(prediction.confidence).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: _getConfidenceColor(prediction.confidence).withOpacity(0.3),
                  ),
                ),
                child: Text(
                  _getClassificationLabel(prediction.confidence),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _getConfidenceColor(prediction.confidence),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            prediction.scientificName ?? 'Unknown',
            style: GoogleFonts.outfit(
              fontStyle: FontStyle.italic,
              fontSize: 18,
              color: AppTheme.accentColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          
          const Divider(height: 32),
          
          // Botanical Information Grid
          Text(
            'Botanical Details',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : Colors.black),
          ),
          const SizedBox(height: 16),
          
          _buildInfoRow('Family', prediction.botanicalFamily ?? 'Iridaceae', Icons.account_tree),
          _buildInfoRow('Habitat', prediction.nativeHabitat ?? 'Wetlands', Icons.landscape),
          _buildInfoRow('Season', prediction.floweringSeason ?? 'Spring/Summer', Icons.wb_sunny),

          const SizedBox(height: 16),
          Text(
            prediction.detailedDescription ?? '',
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: isDark ? Colors.grey.shade300 : Colors.blueGrey.shade700,
            ),
          ),

          const Divider(height: 32),

          // Features List
          const Text(
            'Key Characteristics',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 10),
          ...((prediction.characteristics as List<dynamic>?)?.map((char) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        color: Color(0xFF10B981),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          char as String,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.grey.shade300 : Colors.blueGrey.shade700,
                          ),
                        ),
                      )
                    ],
                  ),
                );
              }).toList() ??
              []),

          const Divider(height: 32),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => context.go('/predict'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04),
                    foregroundColor: isDark ? Colors.white : Colors.blueGrey.shade800,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('New Scan', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => context.go('/history'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('View Logs', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.primaryColor),
          const SizedBox(width: 12),
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Color _getConfidenceColor(double conf) {
    if (conf >= 0.90) return const Color(0xFF10B981); // Emerald
    if (conf >= 0.70) return Colors.blueAccent;
    return Colors.amber;
  }

  String _getClassificationLabel(double conf) {
    if (conf >= 0.95) return 'HIGH CERTAINTY';
    if (conf >= 0.80) return 'CERTAIN';
    return 'MARGINAL';
  }
}

class BoundingBoxPainter extends CustomPainter {
  final List<dynamic>? boundingBoxes;

  BoundingBoxPainter(this.boundingBoxes);

  @override
  void paint(Canvas canvas, Size size) {
    if (boundingBoxes == null) return;

    for (var boxData in boundingBoxes!) {
      final label = boxData.label as String;
      final x = boxData.x as double;
      final y = boxData.y as double;
      final w = boxData.w as double;
      final h = boxData.h as double;
      final conf = boxData.confidence as double;

      // Color mapping
      Color boxColor;
      if (label == 'Flower') {
        boxColor = Colors.purpleAccent;
      } else if (label == 'Petal') {
        boxColor = Colors.greenAccent;
      } else {
        boxColor = Colors.orangeAccent;
      }

      final paint = Paint()
        ..color = boxColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;

      // Un-normalize coordinates
      final left = (x - w/2) * size.width;
      final top = (y - h/2) * size.height;
      final right = (x + w/2) * size.width;
      final bottom = (y + h/2) * size.height;
      
      final rect = Rect.fromLTRB(left, top, right, bottom);
      canvas.drawRect(rect, paint);
      
      // Draw label background
      final textStyle = const TextStyle(
        color: Colors.black,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      );
      final textSpan = TextSpan(
        text: '$label ${(conf * 100).toStringAsFixed(0)}%',
        style: textStyle,
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      
      final bgPaint = Paint()..color = boxColor;
      canvas.drawRect(
        Rect.fromLTWH(left, top - 20, textPainter.width + 8, 20),
        bgPaint,
      );
      
      textPainter.paint(canvas, Offset(left + 4, top - 18));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
