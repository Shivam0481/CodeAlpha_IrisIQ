import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../providers/app_state_providers.dart';
import '../widgets/flower_painter.dart';
import '../widgets/glass_container.dart';

class LandingScreen extends ConsumerWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final health = ref.watch(apiHealthProvider);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF030712),
                    const Color(0xFF0F172A),
                    const Color(0xFF1E1B4B),
                  ]
                : [
                    const Color(0xFFF9FAFB),
                    const Color(0xFFEEF2F6),
                    const Color(0xFFE0E7FF),
                  ],
            stops: const [0.2, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                // 1. Navigation Header
                _buildHeader(context, health),
                
                // 2. Hero Section
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: size.width > 900 ? 80.0 : 24.0,
                    vertical: 40.0,
                  ),
                  child: size.width > 900
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(child: _buildHeroText(context)),
                            const SizedBox(width: 40),
                            Expanded(child: _buildHeroVisual(context)),
                          ],
                        )
                      : Column(
                          children: [
                            _buildHeroText(context),
                            const SizedBox(height: 40),
                            _buildHeroVisual(context),
                          ],
                        ),
                ),

                const SizedBox(height: 60),

                // 3. Features Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      Text(
                        'Engineered for High-Precision Classification',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.blueGrey.shade900,
                            ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'State-of-the-art technologies coming together in a lightweight pipeline.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: isDark ? Colors.grey.shade400 : Colors.blueGrey.shade600,
                        ),
                      ),
                      const SizedBox(height: 40),
                      _buildFeaturesGrid(context, size.width),
                    ],
                  ),
                ),



                // 5. Performance Metrics Section
                _buildPerformanceSection(context, isDark),

                const SizedBox(height: 100),

                // 6. Footer
                _buildFooter(context, isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, HealthState health) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
        borderRadius: BorderRadius.circular(100),
        child: Row(
          children: [
            Row(
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [AppTheme.primaryColor, AppTheme.accentColor],
                  ).createShader(bounds),
                  child: const Icon(
                    Icons.bubble_chart,
                    size: 32,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'IrisIQ',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                      ),
                ),
              ],
            ),
            const Spacer(),
            // Health indicator badge
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: health.status == 'ok'
                        ? const Color(0xFF10B981)
                        : Colors.amber,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (health.status == 'ok'
                                ? const Color(0xFF10B981)
                                : Colors.amber)
                            .withOpacity(0.4),
                        blurRadius: 8,
                        spreadRadius: 2,
                      )
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  health.status == 'ok' ? 'API Online' : 'Connecting...',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.grey.shade300 : Colors.blueGrey.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: () => context.go('/settings'),
              style: ElevatedButton.styleFrom(
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(10),
                backgroundColor: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                elevation: 0,
              ),
              child: const Icon(Icons.settings, size: 20),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildHeroText(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: AppTheme.primaryColor.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.star,
                size: 16,
                color: AppTheme.accentColor,
              ),
              const SizedBox(width: 6),
              Text(
                'AI Classification Engine',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Deep Statistical\nClassification.',
          style: GoogleFonts.outfit(
            fontSize: 48,
            height: 1.1,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : Colors.blueGrey.shade900,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'A sleek application classifying Iris flower species using an optimized Scikit-Learn Random Forest model converted to ONNX and run locally.',
          style: TextStyle(
            fontSize: 16,
            height: 1.5,
            color: isDark ? Colors.grey.shade400 : Colors.blueGrey.shade600,
          ),
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            ElevatedButton(
              onPressed: () => context.go('/predict'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: Row(
                children: [
                  Text(
                    'Run Prediction',
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, size: 18),
                ],
              ),
            ),
            const SizedBox(width: 16),
            OutlinedButton(
              onPressed: () => context.go('/analytics'),
              style: OutlinedButton.styleFrom(
                foregroundColor: isDark ? Colors.white : Colors.blueGrey.shade800,
                side: BorderSide(
                  color: isDark ? Colors.grey.shade800 : Colors.blueGrey.shade300,
                  width: 1.5,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                'Dashboard',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeroVisual(BuildContext context) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Ambient back glowing circle
          Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppTheme.secondaryColor.withOpacity(0.2),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          GlassContainer(
            width: 280,
            height: 320,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const IrisFlowerWidget(speciesKey: 'versicolor', size: 160),
                const SizedBox(height: 20),
                Text(
                  '🌸 Iris Versicolor',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Dynamic 3D Vector Simulation',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesGrid(BuildContext context, double width) {
    final columns = width > 900 ? 3 : (width > 600 ? 2 : 1);
    
    final features = [
      _FeatureData(
        icon: Icons.flash_on,
        title: 'High Performance',
        desc: 'Asynchronous event loop runtime yielding sub-millisecond API response pipelines.',
        color: const Color(0xFFEF4444),
      ),
      _FeatureData(
        icon: Icons.psychology,
        title: 'ONNX Execution',
        desc: 'Direct execution of a trained Random Forest model compiled into ONNX using a zero-native-dependency engine.',
        color: const Color(0xFF3B82F6),
      ),
      _FeatureData(
        icon: Icons.dashboard,
        title: 'Visual Dashboard',
        desc: 'Real-time charting and analytic stats tracking class distribution, average confidences, and model data metrics.',
        color: const Color(0xFF10B981),
      ),
      _FeatureData(
        icon: Icons.storage,
        title: 'SQLite Caching',
        desc: 'Saves classification records inside a structured SQLite database. Supports searching, filters, and pagination.',
        color: const Color(0xFFF59E0B),
      ),
      _FeatureData(
        icon: Icons.devices,
        title: 'Cross Platform',
        desc: 'Crafted using Flutter Material 3, adapting elegantly across Mobile, Tablet, Desktop, and Web.',
        color: const Color(0xFFEC4899),
      ),
      _FeatureData(
        icon: Icons.file_download,
        title: 'Data Export',
        desc: 'Allows downloading logs immediately to a local CSV file. Enables saving offline analytics details.',
        color: const Color(0xFF06B6D4),
      ),
    ];

    return LayoutBuilder(builder: (context, constraints) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
          childAspectRatio: 1.4,
        ),
        itemCount: features.length,
        itemBuilder: (context, index) {
          final item = features[index];
          return GlassContainer(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(item.icon, color: item.color, size: 28),
                const SizedBox(height: 16),
                Text(
                  item.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Text(
                    item.desc,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey.shade400
                          : Colors.blueGrey.shade600,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    });
  }

  Widget _buildTechStackSection(BuildContext context, bool isDark) {
    final technologies = [
      'Flutter 3',
      'Dart',
      'Rust',
      'Actix-Web',
      'ONNX Runtime',
      'SQLite',
      'Scikit-Learn',
      'Riverpod',
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
      color: isDark ? const Color(0xFF111827).withOpacity(0.3) : Colors.blueGrey.shade100.withOpacity(0.5),
      child: Column(
        children: [
          const Text(
            'TECHNOLOGY STACK',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              letterSpacing: 2.0,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 30),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: technologies.map((tech) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: isDark ? Colors.white.withOpacity(0.07) : Colors.black.withOpacity(0.07),
                  ),
                ),
                child: Text(
                  tech,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isDark ? Colors.white70 : Colors.blueGrey.shade800,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceSection(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        child: Column(
          children: [
            Text(
              'Optimized Infrastructure Metrics',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem('Inference Speed', '< 1ms', 'Model Response'),
                _buildStatItem('Database Logging', '< 2ms', 'SQLite I/O'),
                _buildStatItem('Classification Acc.', '93.3%', 'Stratified Test'),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String stat, String sub) {
    return Column(
      children: [
        Text(
          stat,
          style: GoogleFonts.outfit(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        Text(
          sub,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
        )
      ],
    );
  }

  Widget _buildFooter(BuildContext context, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.blueGrey.shade200,
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.bubble_chart,
                color: AppTheme.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'IrisIQ Classification Engine',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Designed for startup-grade showcase. Developed using Python.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 20),
          Text(
            '© 2026 IrisIQ. All rights reserved.',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          )
        ],
      ),
    );
  }
}

class _FeatureData {
  final IconData icon;
  final String title;
  final String desc;
  final Color color;

  _FeatureData({
    required this.icon,
    required this.title,
    required this.desc,
    required this.color,
  });
}
