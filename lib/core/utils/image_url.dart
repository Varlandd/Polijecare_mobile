import '../config/api_config.dart';

/// Port dari `utils/imageUrl.js` versi web.
/// Mengubah URL gambar/file dari backend menjadi URL proxy FileController
/// agar tidak terkena 403 pada folder storage.
String? normalizeImageUrl(String? url) {
  if (url == null || url.isEmpty) return null;
  final proxy = ApiConfig.fileProxyUrl;

  if (url.contains('/api/files/view')) {
    final match = RegExp(r'path=([^&]+)').firstMatch(url);
    if (match != null) {
      final decoded = Uri.decodeComponent(match.group(1)!);
      return '$proxy${Uri.encodeComponent(decoded)}';
    }
    return url;
  }

  final storageMatch = RegExp(r'/storage/(.+)$').firstMatch(url);
  if (storageMatch != null) {
    return '$proxy${Uri.encodeComponent(storageMatch.group(1)!)}';
  }

  if (!url.startsWith('http://') && !url.startsWith('https://')) {
    final clean = url.startsWith('/') ? url.substring(1) : url;
    return '$proxy${Uri.encodeComponent(clean)}';
  }

  return url;
}

/// Port dari `getStorageUrl` versi web.
String? getStorageUrl(String? path) {
  if (path == null || path.isEmpty) return null;
  if (path.startsWith('http://') || path.startsWith('https://')) {
    return normalizeImageUrl(path);
  }
  final clean = path.startsWith('/') ? path.substring(1) : path;
  return '${ApiConfig.fileProxyUrl}${Uri.encodeComponent(clean)}';
}

