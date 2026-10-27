import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Helper terpusat untuk membuka URL eksternal (WhatsApp, telepon, email, maps, dokumen).
class AppLauncher {
  AppLauncher._();

  static Future<bool> openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

/// Membuka URL eksternal (WhatsApp, telepon, email, maps, dokumen).
Future<void> openExternal(BuildContext context, String url) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final ok = await AppLauncher.openUrl(url);
  if (!ok) {
    messenger?.showSnackBar(
      const SnackBar(content: Text('Tidak dapat membuka tautan.')),
    );
  }
}


