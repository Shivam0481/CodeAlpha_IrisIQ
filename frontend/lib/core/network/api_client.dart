import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  static const String _defaultBaseUrlKey = 'api_base_url';
  
  // Default URL for dev environment
  static const String _localDevUrl = 'http://localhost:8080';
  
  late final Dio _dio;

  ApiClient() {
    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 8),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Resolve dynamic base URL from SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        String? customUrl = prefs.getString(_defaultBaseUrlKey);
        
        if (customUrl != null && customUrl.isNotEmpty) {
          options.baseUrl = customUrl;
        } else {
          // Auto-detect base URL
          if (kIsWeb) {
            // If hosted, use relative paths. If running in debug, default to localhost
            final String origin = Uri.base.origin;
            if (origin.contains('localhost') || origin.contains('127.0.0.1')) {
              options.baseUrl = _localDevUrl;
            } else {
              // Production hosted deployment
              options.baseUrl = origin;
            }
          } else {
            // Android emulator / iOS simulator / Desktop
            options.baseUrl = _localDevUrl;
          }
        }

        // Standardize URL pathing (make sure it ends with /api if needed)
        // Note: our server serves endpoints at /api/predict etc., so we point base URL to [origin]/api
        if (!options.baseUrl.endsWith('/api') && !options.path.startsWith('/api')) {
          if (options.baseUrl.endsWith('/')) {
            options.baseUrl = '${options.baseUrl}api';
          } else {
            options.baseUrl = '${options.baseUrl}/api';
          }
        }

        if (kDebugMode) {
          print('--> [HTTP REQUEST] ${options.method} ${options.baseUrl}${options.path}');
          print('Headers: ${options.headers}');
          print('Body: ${options.data}');
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        if (kDebugMode) {
          print('<-- [HTTP RESPONSE] ${response.statusCode} ${response.requestOptions.path}');
          print('Data: ${response.data}');
        }
        return handler.next(response);
      },
      onError: (DioException e, handler) {
        if (kDebugMode) {
          print('<-- [HTTP ERROR] ${e.type} - ${e.message}');
          print('Response: ${e.response?.data}');
        }
        return handler.next(e);
      },
    ));
  }

  Dio get dio => _dio;

  static Future<void> setCustomBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_defaultBaseUrlKey, url);
  }

  static Future<String> getActiveBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final String? custom = prefs.getString(_defaultBaseUrlKey);
    if (custom != null && custom.isNotEmpty) return custom;
    
    if (kIsWeb) {
      final String origin = Uri.base.origin;
      if (origin.contains('localhost') || origin.contains('127.0.0.1')) {
        return _localDevUrl;
      }
      return origin;
    }
    return _localDevUrl;
  }
}
