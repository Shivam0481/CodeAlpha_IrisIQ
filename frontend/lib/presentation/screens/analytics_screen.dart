import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/app_theme.dart';
import '../providers/app_state_providers.dart';
import '../widgets/glass_container.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsState = ref.watch(analyticsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: Text('Analytics Dashboard', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/')),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(analyticsProvider.notifier).fetchMetrics(),
          ),
        ],
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
                ? _buildError(context, analyticsState.errorMessage)
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Overview Cards Row
                        _buildOverviewCards(context, analyticsState.summary!, isDark),
                        const SizedBox(height: 24),

                        // Charts Section
                        size.width > 800
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: _buildPieChart(context, analyticsState.summary!, isDark)),
                                  const SizedBox(width: 20),
                                  Expanded(child: _buildBarChart(context, analyticsState.summary!, isDark)),
                                ],
                              )
                            : Column(
                                children: [
                                  _buildPieChart(context, analyticsState.summary!, isDark),
                                  const SizedBox(height: 20),
                                  _buildBarChart(context, analyticsState.summary!, isDark),
                                ],
                              ),

                        const SizedBox(height: 24),

                        // Dataset Insights
                        _buildDatasetInsights(context, analyticsState.summary!, isDark),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildOverviewCards(BuildContext context, dynamic summary, bool isDark) {
    return LayoutBuilder(builder: (context, constraints) {
      final crossAxisCount = constraints.maxWidth > 700 ? 4 : 2;
      return GridView.count(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 1.8,
        children: [
          _overviewCard('Total Predictions', '${summary.totalPredictions}', Icons.analytics, const Color(0xFF3B82F6)),
          _overviewCard('Avg Confidence', '${(summary.averageConfidence * 100).toStringAsFixed(1)}%', Icons.speed, const Color(0xFF10B981)),
          _overviewCard('Species Tracked', '${summary.speciesDistribution.length}', Icons.category, const Color(0xFF8B5CF6)),
          _overviewCard('Dataset Size', '${summary.datasetInfo.datasetSize}', Icons.storage, const Color(0xFFF59E0B)),
        ],
      );
    });
  }

  Widget _overviewCard(String label, String value, IconData icon, Color color) {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(value, style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 22)),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  Widget _buildPieChart(BuildContext context, dynamic summary, bool isDark) {
    final dist = summary.speciesDistribution as Map<String, int>;
    final total = dist.values.fold(0, (a, b) => a + b);
    final colors = [const Color(0xFF3B82F6), const Color(0xFF8B5CF6), const Color(0xFFEC4899)];

    if (total == 0) {
      return GlassContainer(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text('Species Distribution', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 40),
            Icon(Icons.pie_chart_outline, size: 64, color: Colors.grey.shade600),
            const SizedBox(height: 12),
            Text('No data yet', style: TextStyle(color: Colors.grey.shade500)),
          ],
        ),
      );
    }

    final sections = dist.entries.toList().asMap().entries.map((entry) {
      final i = entry.key;
      final e = entry.value;
      final percentage = (e.value / total * 100);
      return PieChartSectionData(
        value: e.value.toDouble(),
        title: '${percentage.toStringAsFixed(0)}%',
        color: colors[i % colors.length],
        radius: 60,
        titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
      );
    }).toList();

    return GlassContainer(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Text('Species Distribution', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: PieChart(PieChartData(
              sections: sections,
              centerSpaceRadius: 40,
              sectionsSpace: 3,
            )),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: dist.entries.toList().asMap().entries.map((entry) {
              final i = entry.key;
              final e = entry.value;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 12, height: 12, decoration: BoxDecoration(color: colors[i % colors.length], shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text('${e.key} (${e.value})', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              );
            }).toList(),
          )
        ],
      ),
    );
  }

  Widget _buildBarChart(BuildContext context, dynamic summary, bool isDark) {
    final metrics = summary.metrics;
    final classes = summary.datasetInfo.classes as List<String>;
    final colors = [const Color(0xFF3B82F6), const Color(0xFF8B5CF6), const Color(0xFFEC4899)];

    return GlassContainer(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Text('Per-Class F1 Score', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: BarChart(BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: 1.1,
              barTouchData: BarTouchData(enabled: true),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (v, _) => Text(
                      '${(v * 100).toInt()}%',
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, _) {
                      final idx = v.toInt();
                      if (idx < classes.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(classes[idx], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (v) => FlLine(
                  color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                  strokeWidth: 1,
                ),
              ),
              barGroups: List.generate(
                metrics.f1ScorePerClass.length,
                (i) => BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: metrics.f1ScorePerClass[i],
                      color: colors[i % colors.length],
                      width: 28,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(6),
                        topRight: Radius.circular(6),
                      ),
                    ),
                  ],
                ),
              ),
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildDatasetInsights(BuildContext context, dynamic summary, bool isDark) {
    final di = summary.datasetInfo;
    return GlassContainer(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Dataset Insights', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          _insightRow('Dataset', di.datasetName),
          _insightRow('Total Samples', '${di.datasetSize}'),
          _insightRow('Features', '${di.featuresCount} (${(di.features as List).join(", ")})'),
          _insightRow('Classes', '${di.classesCount} (${(di.classes as List).join(", ")})'),
        ],
      ),
    );
  }

  Widget _insightRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
          ),
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
          children: List.generate(3, (_) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Container(height: 120, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16))),
          )),
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, String? msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(msg ?? 'Failed to load analytics', style: TextStyle(color: Colors.grey.shade500)),
        ],
      ),
    );
  }
}
