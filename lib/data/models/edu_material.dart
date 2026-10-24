import '../../core/config/api_config.dart';

/// Model materi edukasi (tabel `materials`).
class EduMaterial {
  final String uniqueId;
  final String judul;
  final String? deskripsi;
  final String tipe; // 'file' | 'link'
  final String kategori;
  final String? filePath;
  final String? link;
  final DateTime? createdAt;

  const EduMaterial({
    required this.uniqueId,
    required this.judul,
    required this.tipe,
    required this.kategori,
    this.deskripsi,
    this.filePath,
    this.link,
    this.createdAt,
  });

  bool get isFile => tipe == 'file';

  /// Setara `materialService.getFileUrl` di web.
  String get fileUrl {
    final p = filePath;
    if (p == null || p.isEmpty) return '';
    if (p.startsWith('http')) return p;
    return '${ApiConfig.storageBaseUrl}/storage/${Uri.encodeComponent(p)}';
  }

  /// URL yang dibuka saat tombol "Baca Dokumen"/"Buka Tautan" ditekan.
  String get openUrl => isFile ? fileUrl : (link ?? '');

  factory EduMaterial.fromJson(Map<String, dynamic> json) {
    return EduMaterial(
      uniqueId: (json['unique_id'] ?? json['id'] ?? '').toString(),
      judul: json['judul']?.toString() ?? '',
      deskripsi: json['deskripsi']?.toString(),
      tipe: json['tipe']?.toString() ?? 'link',
      kategori: json['kategori']?.toString() ?? '',
      filePath: json['file_path']?.toString(),
      link: json['link']?.toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }
}

