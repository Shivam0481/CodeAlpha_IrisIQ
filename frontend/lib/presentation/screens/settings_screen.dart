import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../providers/app_state_providers.dart';
import '../widgets/glass_container.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(themeModeProvider);
    final health = ref.watch(apiHealthProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Settings', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                children: [


                  // API Health Status
                  GlassContainer(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.monitor_heart, color: AppTheme.accentColor),
                            const SizedBox(width: 10),
                            Text('API Health Monitor', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18)),
                            const Spacer(),
                            IconButton(
                              icon: Icon(Icons.refresh, color: Colors.grey.shade500, size: 20),
                              onPressed: () => ref.read(apiHealthProvider.notifier).checkHealth(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _healthRow('Status', health.status,
                            color: health.status == 'ok' ? const Color(0xFF10B981) : Colors.amber),
                        _healthRow('Database', health.database,
                            color: health.database == 'connected' ? const Color(0xFF10B981) : Colors.redAccent),
                        _healthRow('Model Loaded', health.modelLoaded ? 'Yes' : 'No',
                            color: health.modelLoaded ? const Color(0xFF10B981) : Colors.redAccent),
                        _healthRow('Uptime', '${health.uptime}s'),
                        if (health.errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.red.withOpacity(0.15)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline, color: Colors.redAccent, size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      health.errorMessage!,
                                      style: const TextStyle(fontSize: 12, color: Colors.redAccent),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Navigation Shortcuts
                  GlassContainer(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.navigation, color: AppTheme.secondaryColor),
                            const SizedBox(width: 10),
                            Text('Quick Navigation', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _navItem(context, 'Run Prediction', Icons.online_prediction, '/predict'),
                        _navItem(context, 'View History', Icons.history, '/history'),
                        _navItem(context, 'Analytics Dashboard', Icons.analytics, '/analytics'),
                        _navItem(context, 'Model Information', Icons.info, '/model-info'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // About Section
                  GlassContainer(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [AppTheme.primaryColor, AppTheme.accentColor],
                          ).createShader(bounds),
                          child: const Icon(Icons.bubble_chart, size: 40, color: Colors.white),
                        ),
                        const SizedBox(height: 12),
                        Text('IrisIQ', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 22)),
                        const SizedBox(height: 4),
                        Text('v1.0.0', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                        const SizedBox(height: 12),
                        Text(
                          'Portfolio-grade AI Classification Engine.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500, height: 1.5),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }



  Widget _healthRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: (color ?? Colors.grey).withOpacity(0.1),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: color)),
          ),
        ],
      ),
    );
  }

  Widget _navItem(BuildContext context, String label, IconData icon, String path) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: () => context.go(path),
        leading: Icon(icon, color: AppTheme.primaryColor, size: 20),
        title: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.chevron_right, size: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      ),
    );
  }
}
