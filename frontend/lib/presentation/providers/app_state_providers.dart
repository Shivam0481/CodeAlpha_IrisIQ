import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/network/api_client.dart';
import '../../data/models/history_model.dart';
import '../../data/models/metrics_model.dart';
import '../../data/models/prediction_model.dart';

// 1. ApiBaseUrl Provider
final apiBaseUrlProvider = Provider<String>((ref) {
  // Use localhost for desktop/web testing. Change for production.
  return 'http://127.0.0.1:8080/api';
});

// 2. ApiClient Provider
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

// 2. Theme Mode Notifier & Provider
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  static const String _themeKey = 'user_theme_mode';

  ThemeModeNotifier() : super(ThemeMode.system) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_themeKey);
    if (themeIndex != null) {
      state = ThemeMode.values[themeIndex];
    }
  }

  Future<void> toggleTheme(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, mode.index);
  }
}

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

// 3. API Health Notifier & Provider
class HealthState {
  final String status;
  final String database;
  final bool modelLoaded;
  final int uptime;
  final bool isLoading;
  final String? errorMessage;

  HealthState({
    required this.status,
    required this.database,
    required this.modelLoaded,
    required this.uptime,
    required this.isLoading,
    this.errorMessage,
  });

  factory HealthState.initial() => HealthState(
        status: 'Unknown',
        database: 'Unknown',
        modelLoaded: false,
        uptime: 0,
        isLoading: false,
      );

  factory HealthState.error(String error) => HealthState(
        status: 'Offline',
        database: 'Offline',
        modelLoaded: false,
        uptime: 0,
        isLoading: false,
        errorMessage: error,
      );

  HealthState copyWith({
    String? status,
    String? database,
    bool? modelLoaded,
    int? uptime,
    bool? isLoading,
    String? errorMessage,
  }) {
    return HealthState(
      status: status ?? this.status,
      database: database ?? this.database,
      modelLoaded: modelLoaded ?? this.modelLoaded,
      uptime: uptime ?? this.uptime,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class ApiHealthNotifier extends StateNotifier<HealthState> {
  final Ref _ref;
  Timer? _timer;

  ApiHealthNotifier(this._ref) : super(HealthState.initial()) {
    checkHealth();
    // Poll health status every 15 seconds
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => checkHealth());
  }

  Future<void> checkHealth() async {
    state = state.copyWith(isLoading: true);
    try {
      final dio = _ref.read(apiClientProvider).dio;
      final response = await dio.get('/health');
      
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        state = HealthState(
          status: data['status'] as String? ?? 'ok',
          database: data['database'] as String? ?? 'connected',
          modelLoaded: data['model_loaded'] as bool? ?? true,
          uptime: (data['uptime_seconds'] as num? ?? 0).toInt(),
          isLoading: false,
        );
      } else {
        state = HealthState.error('Server returned code ${response.statusCode}');
      }
    } catch (e) {
      state = HealthState.error(e.toString());
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final apiHealthProvider = StateNotifierProvider<ApiHealthNotifier, HealthState>((ref) {
  return ApiHealthNotifier(ref);
});

// 4. Latest Prediction Result Provider
final latestPredictionProvider = StateProvider<PredictionModel?>((ref) => null);

// 5. Prediction History Notifier & Provider
class HistoryState {
  final List<HistoryRecordModel> records;
  final int totalCount;
  final int currentPage;
  final int limit;
  final String searchQuery;
  final bool isLoading;
  final String? errorMessage;

  HistoryState({
    required this.records,
    required this.totalCount,
    required this.currentPage,
    required this.limit,
    required this.searchQuery,
    required this.isLoading,
    this.errorMessage,
  });

  factory HistoryState.initial() => HistoryState(
        records: [],
        totalCount: 0,
        currentPage: 1,
        limit: 10,
        searchQuery: '',
        isLoading: false,
      );

  HistoryState copyWith({
    List<HistoryRecordModel>? records,
    int? totalCount,
    int? currentPage,
    int? limit,
    String? searchQuery,
    bool? isLoading,
    String? errorMessage,
  }) {
    return HistoryState(
      records: records ?? this.records,
      totalCount: totalCount ?? this.totalCount,
      currentPage: currentPage ?? this.currentPage,
      limit: limit ?? this.limit,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class HistoryNotifier extends StateNotifier<HistoryState> {
  final Ref _ref;

  HistoryNotifier(this._ref) : super(HistoryState.initial()) {
    fetchHistory();
  }

  Future<void> fetchHistory({
    String? search,
    int? page,
    int? limit,
  }) async {
    state = state.copyWith(
      isLoading: true,
      searchQuery: search ?? state.searchQuery,
      currentPage: page ?? state.currentPage,
      limit: limit ?? state.limit,
    );

    try {
      final dio = _ref.read(apiClientProvider).dio;
      final response = await dio.get(
        '/history',
        queryParameters: {
          if (state.searchQuery.isNotEmpty) 'search': state.searchQuery,
          'page': state.currentPage,
          'limit': state.limit,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final list = (data['data'] as List<dynamic>?)
                ?.map((e) => HistoryRecordModel.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [];
        final total = data['total'] as int? ?? 0;

        state = state.copyWith(
          records: list,
          totalCount: total,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Failed to fetch history (${response.statusCode})',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<bool> deleteRecord(int id) async {
    try {
      final dio = _ref.read(apiClientProvider).dio;
      final response = await dio.delete('/history/$id');
      if (response.statusCode == 200) {
        // Refresh history page
        fetchHistory();
        return true;
      }
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete record: $e');
    }
    return false;
  }

  Future<bool> clearAllHistory() async {
    try {
      final dio = _ref.read(apiClientProvider).dio;
      final response = await dio.delete('/history');
      if (response.statusCode == 200) {
        state = HistoryState.initial();
        return true;
      }
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to clear history: $e');
    }
    return false;
  }
}

final historyProvider = StateNotifierProvider<HistoryNotifier, HistoryState>((ref) {
  return HistoryNotifier(ref);
});

// 6. Analytics & Model Information Notifier & Provider
class AnalyticsState {
  final MetricsSummaryModel? summary;
  final bool isLoading;
  final String? errorMessage;

  AnalyticsState({
    this.summary,
    required this.isLoading,
    this.errorMessage,
  });

  factory AnalyticsState.initial() => AnalyticsState(isLoading: false);

  AnalyticsState copyWith({
    MetricsSummaryModel? summary,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AnalyticsState(
      summary: summary ?? this.summary,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class AnalyticsNotifier extends StateNotifier<AnalyticsState> {
  final Ref _ref;

  AnalyticsNotifier(this._ref) : super(AnalyticsState.initial()) {
    fetchMetrics();
  }

  Future<void> fetchMetrics() async {
    state = state.copyWith(isLoading: true);
    try {
      final dio = _ref.read(apiClientProvider).dio;
      final response = await dio.get('/metrics');
      if (response.statusCode == 200) {
        final summary = MetricsSummaryModel.fromJson(response.data as Map<String, dynamic>);
        state = AnalyticsState(summary: summary, isLoading: false);
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Failed to load metrics (${response.statusCode})',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }
}

final analyticsProvider = StateNotifierProvider<AnalyticsNotifier, AnalyticsState>((ref) {
  return AnalyticsNotifier(ref);
});

// Helper Prediction Method Provider
final predictMethodProvider = Provider((ref) {
  return (double sl, double sw, double pl, double pw) async {
    final dio = ref.read(apiClientProvider).dio;
    final response = await dio.post(
      '/predict/manual',
      data: {
        'sepal_length': sl,
        'sepal_width': sw,
        'petal_length': pl,
        'petal_width': pw,
      },
    );

    if (response.statusCode == 200) {
      final model = PredictionModel.fromJson(response.data as Map<String, dynamic>);
      // Set latest prediction
      ref.read(latestPredictionProvider.notifier).state = model;
      // Refresh history and analytics lists
      ref.read(historyProvider.notifier).fetchHistory();
      ref.read(analyticsProvider.notifier).fetchMetrics();
      return model;
    } else {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
      );
    }
  };
});
