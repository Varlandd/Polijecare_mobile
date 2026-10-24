import 'package:flutter/material.dart';

import '../features/landing/landing_page.dart';
import '../features/common/coming_soon_page.dart';

/// Daftar route aplikasi (disamakan dengan path di web `App.jsx`).
class AppRoutes {
  AppRoutes._();

  static const String landing = '/';
  static const String login = '/login-new';
  static const String laporUmum = '/lapor-umum';
  static const String lacakLaporan = '/lacak-laporan';
  static const String edukasi = '/edukasi';
  static const String artikelDetail = '/artikel'; // argumen: slug (String)

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    Widget page;
    switch (settings.name) {
      case landing:
        page = const LandingPage();
        break;
      case login:
        page = const ComingSoonPage(title: 'Masuk');
        break;
      case laporUmum:
        page = const ComingSoonPage(title: 'Lapor Tanpa Login (Umum)');
        break;
      case lacakLaporan:
        page = const ComingSoonPage(title: 'Lacak Laporan');
        break;
      case edukasi:
        page = const ComingSoonPage(title: 'Pusat Edukasi');
        break;
      case artikelDetail:
        page = const ComingSoonPage(title: 'Detail Artikel');
        break;
      default:
        page = const LandingPage();
    }
    return MaterialPageRoute(builder: (_) => page, settings: settings);
  }
}

