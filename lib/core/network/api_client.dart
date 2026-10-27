import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/api_config.dart';

/// HTTP client bersama (setara `api/axios.js` & `utils/axiosConfig.js` di web).
class ApiClient {
  ApiClient._() {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.timeout,
        receiveTimeout: ApiConfig.timeout,
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          options.baseUrl = ApiConfig.baseUrl;
          final token = _token;
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) {
          if (error.response?.statusCode == 401) {
            final path = error.requestOptions.path;
            final isLoginRequest =
                path.contains('/login-new') || path.contains('/login');
            if (!isLoginRequest) {
              onUnauthorized?.call();
            }
          }
          handler.next(error);
        },
      ),
    );
  }

  static final ApiClient instance = ApiClient._();

  late final Dio dio;
  String? _token;

  /// Dipanggil saat response 401 diterima di luar endpoint login.
  VoidCallback? onUnauthorized;

  String? get token => _token;

  void setToken(String? token) => _token = token;
}
