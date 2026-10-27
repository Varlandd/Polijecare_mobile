import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/routes.dart';
import '../../core/config/api_config.dart';
import '../../core/network/api_client.dart';
import '../models/app_user.dart';

/// Hasil proses login (sesuai return structure `NewAuthService.login` di web).
class AuthResult {
  final bool success;
  final String message;
  final String? token;
  final AppUser? user;
  final String? redirectRoute;

  const AuthResult({
    required this.success,
    required this.message,
    this.token,
    this.user,
    this.redirectRoute,
  });
}

/// Akun seeder bawaan (`DatabaseSeeder.php`, `UserSeeder.php`, `update_passwords.php`)
/// sebagai fallback otomatis apabila server backend lokal (`php artisan serve`)
/// belum dinyalakan saat pengujian UI.
class _SeedAccount {
  final AppUser user;
  final List<String> validPasswords;

  const _SeedAccount({
    required this.user,
    required this.validPasswords,
  });
}

const List<_SeedAccount> _kSeedAccounts = [
  _SeedAccount(
    user: AppUser(
      id: 1,
      name: 'Operator PolijeCare',
      email: 'operator@polije.ac.id',
      role: 'operator',
      unit: 'Satgas PPKPT Polije',
    ),
    validPasswords: [
      'Polije2024!',
      'Password1234',
      'Password1111',
      'password123',
    ],
  ),
  _SeedAccount(
    user: AppUser(
      id: 3,
      name: 'Budi Operator',
      email: 'budi@polije.ac.id',
      role: 'operator',
      unit: 'Satgas PPKPT Polije',
    ),
    validPasswords: [
      'Password1111',
      'Password1234',
      'password123',
      'Polije2024!',
    ],
  ),
  _SeedAccount(
    user: AppUser(
      id: 2,
      name: 'Siti Konselor',
      email: 'siti@polije.ac.id',
      role: 'konselor',
      unit: 'Satgas PPKPT Polije',
    ),
    validPasswords: [
      'Password1111',
      'Password1234',
      'password123',
    ],
  ),
  _SeedAccount(
    user: AppUser(
      id: 4,
      name: 'Ahmad Mahasiswa',
      email: '2021001@student.polije.ac.id',
      role: 'user',
      nim: '2021001',
      semester: '6',
      phone: '081234567890',
      gender: 'Laki-laki',
      unit: 'Jurusan Teknologi Informasi',
      prodi: 'Teknik Informatika',
      bio: 'Mahasiswa Aktif Politeknik Negeri Jember',
    ),
    validPasswords: [
      'Password1111',
      'Password1234',
      'password123',
    ],
  ),
];

/// Service & state autentikasi global (port dari `services/newAuthService.js`
/// dan `contexts/AuthContext.jsx` di web).
class AuthService extends ChangeNotifier {
  AuthService._() {
    ApiClient.instance.onUnauthorized = () {
      clearAuthData();
    };
  }

  static final AuthService instance = AuthService._();

  static const String _tokenKey = 'token';
  static const String _userKey = 'user';

  AppUser? _user;
  String? _token;
  bool _isLoading = false;
  bool _initialized = false;

  AppUser? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get initialized => _initialized;

  /// Sesuai `NewAuthService.isAuthenticated()` di web.
  bool get isAuthenticated =>
      _token != null && _token!.isNotEmpty && _user != null;

  /// Sesuai `NewAuthService.getUserRole()` di web.
  String? get userRole => _user?.normalizedRole;

  /// Sesuai `NewAuthService.getRedirectPath()` & `NewLoginPage.jsx` di web.
  String get redirectPath => dashboardRouteForRole(_user?.role);

  static String dashboardRouteForRole(String? role) {
    switch ((role ?? '').trim().toLowerCase()) {
      case 'operator':
      case 'admin':
        return AppRoutes.operatorDashboard;
      case 'konselor':
        return AppRoutes.konselorDashboard;
      case 'user':
      default:
        return AppRoutes.userDashboard;
    }
  }

  /// Memuat sesi yang tersimpan di penyimpanan lokal saat aplikasi dibuka.
  Future<void> init() async {
    if (_initialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString(_tokenKey);
      final savedUserStr = prefs.getString(_userKey);

      if (savedToken != null &&
          savedToken.isNotEmpty &&
          savedUserStr != null &&
          savedUserStr.isNotEmpty) {
        final decoded = jsonDecode(savedUserStr);
        if (decoded is Map) {
          _token = savedToken;
          _user = AppUser.fromJson(Map<String, dynamic>.from(decoded));
          ApiClient.instance.setToken(savedToken);
        }
      }
    } catch (_) {
      await clearAuthData();
    } finally {
      _initialized = true;
      notifyListeners();
    }

    if (isAuthenticated && !(_token?.startsWith('local-seed-token-') ?? false)) {
      validateToken();
    }
  }

  /// Login menggunakan endpoint `/login-new` (sama dengan `NewLoginPage.jsx`).
  /// Mencoba semua kandidat URL backend (`localhost:8000`, `polijecare.my.id/backend/api`, dll).
  /// Jika semua server belum aktif / tidak terjangkau, otomatis memverifikasi ke akun seeder
  /// agar pengujian tetap berjalan lancar.
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    final cleanEmail = email.trim();

    try {
      DioException? lastError;

      for (final candidateUrl in ApiConfig.candidateBaseUrls) {
        try {
          final dio = Dio(
            BaseOptions(
              baseUrl: candidateUrl,
              connectTimeout: const Duration(seconds: 4),
              receiveTimeout: const Duration(seconds: 6),
              headers: const {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
            ),
          );

          final res = await dio.post(
            '/login-new',
            data: {
              'email': cleanEmail,
              'password': password,
            },
          );

          final data = res.data;
          if (data is Map) {
            final body = Map<String, dynamic>.from(data);
            if (body['success'] == true &&
                body['token'] != null &&
                body['user'] is Map) {
              ApiConfig.setActiveBaseUrl(candidateUrl);
              final token = body['token'].toString();
              final loggedInUser = AppUser.fromJson(
                Map<String, dynamic>.from(body['user'] as Map),
              );
              await saveAuthData(token, loggedInUser);

              return AuthResult(
                success: true,
                message: body['message']?.toString() ?? 'Login berhasil',
                token: token,
                user: loggedInUser,
                redirectRoute: dashboardRouteForRole(loggedInUser.role),
              );
            } else {
              ApiConfig.setActiveBaseUrl(candidateUrl);
              return AuthResult(
                success: false,
                message: body['message']?.toString() ??
                    'Login gagal. Silakan coba lagi.',
              );
            }
          }
        } on DioException catch (e) {
          lastError = e;
          // Jika server merespons 401 atau 422, berarti server aktif tapi kredensial salah.
          if (e.response?.statusCode == 401 || e.response?.statusCode == 422) {
            ApiConfig.setActiveBaseUrl(candidateUrl);
            final resData = e.response?.data;
            String msg = 'Email atau password salah.';
            if (resData is Map && resData['message'] != null) {
              msg = resData['message'].toString();
            }
            return AuthResult(success: false, message: msg);
          }
          // Jika connectionError / timeout / 404, lanjut coba kandidat URL berikutnya
          continue;
        }
      }

      // Jika semua server tidak merespons (misalnya `php artisan serve` belum dijalankan),
      // cek terhadap akun seeder bawaan PolijeCare:
      final seedMatch = _kSeedAccounts
          .where((acc) =>
              acc.user.email.toLowerCase() == cleanEmail.toLowerCase())
          .firstOrNull;

      if (seedMatch != null) {
        if (seedMatch.validPasswords.contains(password)) {
          final token = 'local-seed-token-${seedMatch.user.id}';
          await saveAuthData(token, seedMatch.user);
          return AuthResult(
            success: true,
            message: 'Login berhasil',
            token: token,
            user: seedMatch.user,
            redirectRoute: dashboardRouteForRole(seedMatch.user.role),
          );
        } else {
          return const AuthResult(
            success: false,
            message: 'Password salah',
          );
        }
      }

      // Jika bukan akun seeder dan semua server mati:
      if (lastError != null) {
        return const AuthResult(
          success: false,
          message:
              'Email tidak ditemukan atau server backend (php artisan serve) belum dijalankan.',
        );
      }

      return const AuthResult(
        success: false,
        message: 'Login gagal. Silakan coba lagi.',
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Terjadi kesalahan saat login: $e',
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Menyimpan `token` & `user` ke `SharedPreferences` (setara `saveAuthData`).
  Future<void> saveAuthData(String token, AppUser user) async {
    _token = token;
    _user = user;
    ApiClient.instance.setToken(token);
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  /// Memperbarui data user di state & penyimpanan lokal (setara `setUser`).
  Future<void> setUser(AppUser user) async {
    _user = user;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  /// Memvalidasi token aktif ke `/user-new` (setara `NewAuthService.validateToken`).
  Future<bool> validateToken() async {
    if (_token == null || _token!.isEmpty) return false;
    if (_token!.startsWith('local-seed-token-')) return true;
    try {
      final res = await ApiClient.instance.dio.get('/user-new');
      final data = res.data;
      if (data is Map && data['success'] == true && data['user'] is Map) {
        final refreshed = AppUser.fromJson(
          Map<String, dynamic>.from(data['user'] as Map),
        );
        await setUser(refreshed);
        return true;
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await clearAuthData();
        return false;
      }
    } catch (_) {}
    return isAuthenticated;
  }

  /// Logout dari sesi aktif (memanggil `/logout-new` lalu menghapus token lokal).
  Future<void> logout() async {
    try {
      if (_token != null &&
          _token!.isNotEmpty &&
          !_token!.startsWith('local-seed-token-')) {
        await ApiClient.instance.dio.post('/logout-new');
      }
    } catch (_) {
      // Tetap bersihkan sesi lokal meskipun request jaringan gagal
    } finally {
      await clearAuthData();
    }
  }

  /// Menghapus token & data user dari state dan penyimpanan lokal.
  Future<void> clearAuthData() async {
    _token = null;
    _user = null;
    ApiClient.instance.setToken(null);
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_userKey);
    } catch (_) {}
  }
}
