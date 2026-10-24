/// Konfigurasi alamat API backend PolijeCare (Laravel).
///
/// Default mengarah ke server produksi yang sama dengan versi web
/// (`frontend/.env.production`). Untuk memakai server lokal, jalankan:
///
/// ```
/// flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api
/// ```
/// (`10.0.2.2` = localhost komputer jika dijalankan di emulator Android.)
class ApiConfig {
  ApiConfig._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.polijecare.my.id/api',
  );

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

  static const Duration timeout = Duration(seconds: 15);
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

