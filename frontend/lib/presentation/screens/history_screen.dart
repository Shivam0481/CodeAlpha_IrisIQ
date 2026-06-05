import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/app_theme.dart';
import '../providers/app_state_providers.dart';
import '../widgets/glass_container.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final historyState = ref.watch(historyProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: Text('Prediction History', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/')),
        actions: [
          if (historyState.records.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.download),
              tooltip: 'Export CSV',
              onPressed: () => _exportCsv(historyState),
            ),
          if (historyState.records.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Clear All',
              onPressed: () => _confirmClearAll(context),
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
        child: RefreshIndicator(
          onRefresh: () => ref.read(historyProvider.notifier).fetchHistory(),
          child: Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: GlassContainer(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  borderRadius: BorderRadius.circular(100),
                  child: Row(
                    children: [
                      const Icon(Icons.search, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            hintText: 'Search by species name...',
                            border: InputBorder.none,
                          ),
                          onSubmitted: (val) {
                            ref.read(historyProvider.notifier).fetchHistory(search: val, page: 1);
                          },
                        ),
                      ),
                      if (_searchController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            ref.read(historyProvider.notifier).fetchHistory(search: '', page: 1);
                          },
                        ),
                    ],
                  ),
                ),
              ),

              // Stats Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Text(
                      '${historyState.totalCount} records',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey.shade500),
                    ),
                    const Spacer(),
                    Text(
                      'Page ${historyState.currentPage}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Records List
              Expanded(
                child: historyState.isLoading
                    ? _buildShimmerList()
                    : historyState.records.isEmpty
                        ? _buildEmptyState(context)
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: historyState.records.length,
                            itemBuilder: (context, index) {
                              final record = historyState.records[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: GlassContainer(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: _speciesColor(record.prediction).withOpacity(0.12),
                                              borderRadius: BorderRadius.circular(100),
                                            ),
                                            child: Text(
                                              '🌸 ${record.prediction}',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                                color: _speciesColor(record.prediction),
                                              ),
                                            ),
                                          ),
                                          const Spacer(),
                                          Text(
                                            '${(record.confidence * 100).toStringAsFixed(1)}%',
                                            style: GoogleFonts.outfit(
                                              fontWeight: FontWeight.w900,
                                              fontSize: 16,
                                              color: AppTheme.primaryColor,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                                            onPressed: () => _confirmDelete(context, record.id),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          _buildMiniStat('SL', record.sepalLength),
                                          _buildMiniStat('SW', record.sepalWidth),
                                          _buildMiniStat('PL', record.petalLength),
                                          _buildMiniStat('PW', record.petalWidth),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(Icons.access_time, size: 12, color: Colors.grey.shade500),
                                          const SizedBox(width: 4),
                                          Text(
                                            record.createdAt,
                                            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                          ),
                                          const Spacer(),
                                          Text(
                                            '#${record.id}',
                                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
              ),

              // Pagination Row
              if (historyState.totalCount > historyState.limit)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: historyState.currentPage > 1
                            ? () => ref.read(historyProvider.notifier).fetchHistory(page: historyState.currentPage - 1)
                            : null,
                      ),
                      Text(
                        'Page ${historyState.currentPage} of ${(historyState.totalCount / historyState.limit).ceil()}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: historyState.currentPage < (historyState.totalCount / historyState.limit).ceil()
                            ? () => ref.read(historyProvider.notifier).fetchHistory(page: historyState.currentPage + 1)
                            : null,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, double value) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
          Text('${value.toStringAsFixed(1)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildShimmerList() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade800,
      highlightColor: Colors.grey.shade700,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 5,
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(height: 100, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16))),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64, color: Colors.grey.shade600),
          const SizedBox(height: 16),
          Text('No predictions yet', style: TextStyle(fontSize: 16, color: Colors.grey.shade500)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.go('/predict'),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white),
            child: const Text('Run your first prediction'),
          ),
        ],
      ),
    );
  }

  Color _speciesColor(String species) {
    switch (species.toLowerCase()) {
      case 'setosa': return const Color(0xFF3B82F6);
      case 'versicolor': return const Color(0xFF8B5CF6);
      case 'virginica': return const Color(0xFFEC4899);
      default: return AppTheme.primaryColor;
    }
  }

  void _confirmDelete(BuildContext context, int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Record'),
        content: Text('Are you sure you want to delete prediction #$id?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(historyProvider.notifier).deleteRecord(id);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _confirmClearAll(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All History'),
        content: const Text('This action cannot be undone. All records will be permanently deleted.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(historyProvider.notifier).clearAllHistory();
            },
            child: const Text('Clear All', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _exportCsv(HistoryState state) {
    // Build CSV content
    final header = 'ID,Sepal Length,Sepal Width,Petal Length,Petal Width,Species,Confidence,Timestamp';
    final rows = state.records.map((r) =>
        '${r.id},${r.sepalLength},${r.sepalWidth},${r.petalLength},${r.petalWidth},${r.prediction},${(r.confidence * 100).toStringAsFixed(1)},${r.createdAt}');
    final csvContent = [header, ...rows].join('\n');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('CSV prepared with ${state.records.length} records'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }
}
