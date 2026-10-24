import 'package:dio/dio.dart';

import '../config/api_config.dart';

/// HTTP client bersama (setara `api/axios.js` di web).
///
/// Token Bearer akan ditambahkan pada tahap autentikasi berikutnya.
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
          final token = _token;
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
  }

  static final ApiClient instance = ApiClient._();

  late final Dio dio;
  String? _token;

  void setToken(String? token) => _token = token;
}

