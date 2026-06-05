import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/app_theme.dart';
import '../providers/app_state_providers.dart';
import '../widgets/glass_container.dart';

class ModelInfoScreen extends ConsumerWidget {
  const ModelInfoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsState = ref.watch(analyticsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Model Information', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/')),
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
        child: analyticsState.isLoading
            ? _buildShimmer()
            : analyticsState.summary == null
                ? Center(child: Text('Unable to load model info', style: TextStyle(color: Colors.grey.shade500)))
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Model Overview
                        _buildModelOverview(context, analyticsState.summary!, isDark),
                        const SizedBox(height: 24),

                        // Accuracy Metrics Grid
                        _buildAccuracyGrid(context, analyticsState.summary!, isDark),
                        const SizedBox(height: 24),

                        // Per-Class Metrics Table
                        _buildPerClassTable(context, analyticsState.summary!, isDark),
                        const SizedBox(height: 24),

                        // Confusion Matrix
                        _buildConfusionMatrix(context, analyticsState.summary!, isDark),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildModelOverview(BuildContext context, dynamic summary, bool isDark) {
    final di = summary.datasetInfo;
    return GlassContainer(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [AppTheme.primaryColor, AppTheme.accentColor],
                ).createShader(bounds),
                child: const Icon(Icons.psychology, size: 32, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Random Forest Classifier', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18)),
                  Text('Scikit-Learn → ONNX', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                ],
              ),
            ],
          ),
          const Divider(height: 32),
          _infoRow('Dataset', di.datasetName),
          _infoRow('Samples', '${di.datasetSize}'),
          _infoRow('Features', '${di.featuresCount}'),
          _infoRow('Classes', '${di.classesCount}'),
          _infoRow('Feature Names', (di.features as List).join(', ')),
          _infoRow('Class Labels', (di.classes as List).join(', ')),
        ],
      ),
    );
  }

  Widget _buildAccuracyGrid(BuildContext context, dynamic summary, bool isDark) {
    final m = summary.metrics;
    return LayoutBuilder(builder: (context, constraints) {
      final crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
      return GridView.count(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 1.6,
        children: [
          _metricCard('Train Accuracy', m.trainAccuracy, const Color(0xFF10B981)),
          _metricCard('Test Accuracy', m.testAccuracy, const Color(0xFF3B82F6)),
          _metricCard('Precision', m.precision, const Color(0xFF8B5CF6)),
          _metricCard('Recall', m.recall, const Color(0xFFF59E0B)),
          _metricCard('F1 Score', m.f1Score, const Color(0xFFEC4899)),
        ],
      );
    });
  }

  Widget _metricCard(String label, double value, Color color) {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(height: 10),
          Text(
            '${(value * 100).toStringAsFixed(1)}%',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 24, color: color),
          ),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildPerClassTable(BuildContext context, dynamic summary, bool isDark) {
    final classes = summary.datasetInfo.classes as List<String>;
    final m = summary.metrics;

    return GlassContainer(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Per-Class Performance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          Table(
            border: TableBorder(
              horizontalInside: BorderSide(
                color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.06),
                width: 1,
              ),
            ),
            columnWidths: const {
              0: FlexColumnWidth(2),
              1: FlexColumnWidth(1.5),
              2: FlexColumnWidth(1.5),
              3: FlexColumnWidth(1.5),
            },
            children: [
              TableRow(
                children: ['Class', 'Precision', 'Recall', 'F1 Score']
                    .map((h) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(h, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey.shade500)),
                        ))
                    .toList(),
              ),
              for (int i = 0; i < classes.length; i++)
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text(classes[i], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text('${(m.precisionPerClass[i] * 100).toStringAsFixed(1)}%', style: const TextStyle(fontSize: 13)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text('${(m.recallPerClass[i] * 100).toStringAsFixed(1)}%', style: const TextStyle(fontSize: 13)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text('${(m.f1ScorePerClass[i] * 100).toStringAsFixed(1)}%', style: const TextStyle(fontSize: 13)),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConfusionMatrix(BuildContext context, dynamic summary, bool isDark) {
    final classes = summary.datasetInfo.classes as List<String>;
    final cm = summary.metrics.confusionMatrix as List<List<int>>;

    return GlassContainer(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Confusion Matrix', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 6),
          Text('Rows = Actual | Columns = Predicted', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
          const SizedBox(height: 20),
          Center(
            child: Table(
              defaultColumnWidth: const FixedColumnWidth(80),
              border: TableBorder.all(
                color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              children: [
                // Header Row
                TableRow(
                  children: [
                    _cmCell('', isHeader: true),
                    for (final c in classes) _cmCell(c, isHeader: true),
                  ],
                ),
                // Data Rows
                for (int i = 0; i < cm.length; i++)
                  TableRow(
                    children: [
                      _cmCell(classes[i], isHeader: true),
                      for (int j = 0; j < cm[i].length; j++)
                        _cmCell(
                          '${cm[i][j]}',
                          isDiagonal: i == j,
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _cmCell(String text, {bool isHeader = false, bool isDiagonal = false}) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: isDiagonal
          ? AppTheme.primaryColor.withOpacity(0.15)
          : Colors.transparent,
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            fontWeight: isHeader || isDiagonal ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
            color: isDiagonal ? AppTheme.primaryColor : null,
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 130, child: Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade500, fontWeight: FontWeight.bold))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade800,
      highlightColor: Colors.grey.shade700,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: List.generate(4, (_) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Container(height: 100, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16))),
          )),
        ),
      ),
    );
  }
}
