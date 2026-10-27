import 'package:dio/dio.dart';

import '../../core/config/api_config.dart';
import '../../core/utils/image_url.dart';
import '../models/edu_material.dart';

/// Data materi edukasi bawaan `DatabaseSeeder.php` sebagai fallback jika server belum aktif.
final List<EduMaterial> _kSeedMaterials = [
  const EduMaterial(
    uniqueId: 'MAT-DEMO-001-2026',
    judul: 'Panduan Konseling Dasar',
    deskripsi: 'Panduan lengkap untuk konselor pemula',
    tipe: 'file',
    filePath: 'materials/panduan-konseling-dasar.pdf',
    kategori: 'Panduan Konseling',
  ),
  const EduMaterial(
    uniqueId: 'MAT-DEMO-002-2026',
    judul: 'Protokol Penanganan Korban Kekerasan',
    deskripsi: 'Standar operasional penanganan korban kekerasan',
    tipe: 'file',
    filePath: 'materials/protokol-penanganan.pdf',
    kategori: 'Protokol',
  ),
];

/// Setara `services/materialService.js` (bagian publik).
class MaterialService {
  MaterialService._();
  static final MaterialService instance = MaterialService._();

  /// GET /materials — materi edukasi publik.
  Future<List<EduMaterial>> getPublicMaterials({
    Map<String, dynamic>? params,
    int? limit,
  }) async {
    final queryParams = <String, dynamic>{
      if (params != null) ...params,
      'limit': ?limit,
    };
    for (final candidateUrl in ApiConfig.candidateBaseUrls) {
      try {
        final dio = Dio(
          BaseOptions(
            baseUrl: candidateUrl,
            connectTimeout: const Duration(seconds: 4),
            receiveTimeout: const Duration(seconds: 6),
            headers: const {'Accept': 'application/json'},
          ),
        );
        final res = await dio.get(
          '/materials',
          queryParameters: queryParams.isEmpty ? null : queryParams,
        );
        final data = res.data;
        if (data is Map && data['materials'] is List) {
          ApiConfig.setActiveBaseUrl(candidateUrl);
          final list = (data['materials'] as List)
              .map((e) =>
                  EduMaterial.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList();
          if (limit != null && limit > 0 && list.length > limit) {
            return list.take(limit).toList();
          }
          return list;
        }
      } catch (_) {
        continue;
      }
    }
    if (limit != null && limit > 0 && _kSeedMaterials.length > limit) {
      return _kSeedMaterials.take(limit).toList();
    }
    return _kSeedMaterials;
  }

  /// Mengubah path file materi menjadi URL penuh yang siap dibuka/diunduh.
  String getFileUrl(String? filePath) {
    return getStorageUrl(filePath) ?? '';
  }
}
