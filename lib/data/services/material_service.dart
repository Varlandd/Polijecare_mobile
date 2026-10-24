import '../../core/network/api_client.dart';
import '../models/edu_material.dart';

/// Setara `services/materialService.js` (bagian publik).
class MaterialService {
  MaterialService._();
  static final MaterialService instance = MaterialService._();

  final _dio = ApiClient.instance.dio;

  /// GET /materials — materi edukasi publik.
  Future<List<EduMaterial>> getPublicMaterials({
    Map<String, dynamic>? params,
  }) async {
    final res = await _dio.get('/materials', queryParameters: params);
    final body = res.data as Map<String, dynamic>;
    final list = body['materials'] as List?;
    if (list == null) throw Exception('Gagal memuat materi edukasi');
    return list
        .map((e) => EduMaterial.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }
}

