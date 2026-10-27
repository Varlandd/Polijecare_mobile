import 'package:flutter/foundation.dart';

/// Konfigurasi alamat API backend PolijeCare (Laravel).
///
/// Menyesuaikan otomatis seperti `frontend/src/config.js`:
/// - Web / Windows / Desktop lokal: `http://localhost:8000/api`
/// - Emulator Android lokal: `http://10.0.2.2:8000/api`
/// - Produksi: `https://polijecare.my.id/backend/api`
class ApiConfig {
  ApiConfig._();

  static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL');

  /// Daftar kandidat URL backend yang akan dicoba secara berurutan
  /// jika server utama belum merespons.
  static List<String> get candidateBaseUrls {
    if (_envBaseUrl.isNotEmpty) return [_envBaseUrl];
    if (kIsWeb) {
      return const [
        'http://localhost:8000/api',
        'http://127.0.0.1:8000/api',
        'https://polijecare.my.id/backend/api',
        'https://polijecare.my.id/api',
      ];
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return const [
        'http://10.0.2.2:8000/api',
        'http://localhost:8000/api',
        'https://polijecare.my.id/backend/api',
        'https://polijecare.my.id/api',
      ];
    }
    return const [
      'http://localhost:8000/api',
      'http://127.0.0.1:8000/api',
      'https://polijecare.my.id/backend/api',
      'https://polijecare.my.id/api',
    ];
  }

  static String _activeBaseUrl = candidateBaseUrls.first;

  static String get baseUrl => _activeBaseUrl;

  static void setActiveBaseUrl(String url) {
    _activeBaseUrl = url;
  }

  /// Base URL tanpa akhiran `/api` (setara `STORAGE_BASE_URL` di web).
  static String get storageBaseUrl {
    var base = baseUrl.endsWith('/api')
        ? baseUrl.substring(0, baseUrl.length - 4)
        : baseUrl;
    if (base.endsWith('/')) base = base.substring(0, base.length - 1);
    return base;
  }

  /// Proxy file dari FileController (`/api/files/view?path=`).
  static String get fileProxyUrl => '$storageBaseUrl/api/files/view?path=';

  /// Nomor WhatsApp konfirmasi pengaduan Satgas PPKPT (setara `CONFIRM_REPORT_WHATSAPP` di web).
  static const String confirmReportWhatsapp = '6282126432696';

  static const Duration timeout = Duration(seconds: 6);
}

/// Konstanta kontak yang sama dengan versi web.
class AppContact {
  AppContact._();

  static const String address =
      'Jl. Mastrip PO Box 164, Jember 68121, Jawa Timur, Indonesia';
  static const String phone = '0821-2643-2696';
  static const String email = 'satgas.ppkpt@polije.ac.id';
  static const String instagram = '@ppkptpolije';
  static const String whatsapp = '+62 821-2643-2696';
  static const String whatsappNumber = '6282126432696';
  static const String emergencyMessage =
      'Halo Satgas PPKPT Polije, saya memerlukan bantuan darurat untuk menangani kasus saya. Mohon bantuan dan arahannya. Terima kasih.';

  static String get emergencyWaUrl =>
      'https://wa.me/$whatsappNumber?text=${Uri.encodeComponent(emergencyMessage)}';

  static const String mapsUrl =
      'https://www.google.com/maps/search/?api=1&query=Politeknik+Negeri+Jember';
}
