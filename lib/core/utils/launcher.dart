import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Membuka URL eksternal (WhatsApp, telepon, email, maps, dokumen).
Future<void> openExternal(BuildContext context, String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return;
  final messenger = ScaffoldMessenger.maybeOf(context);
  final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!ok) {
    messenger?.showSnackBar(
      const SnackBar(content: Text('Tidak dapat membuka tautan.')),
    );
  }
}

