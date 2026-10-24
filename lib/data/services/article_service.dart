import '../../core/network/api_client.dart';
import '../models/article.dart';

/// Setara `services/articleService.js` (bagian publik).
class ArticleService {
  ArticleService._();
  static final ArticleService instance = ArticleService._();

  final _dio = ApiClient.instance.dio;

  /// GET /articles — artikel aktif & sudah publish.
  Future<List<Article>> getAll() async {
    final res = await _dio.get('/articles');
    final body = res.data as Map<String, dynamic>;
    if (body['success'] != true) {
      throw Exception(body['message'] ?? 'Gagal memuat artikel');
    }
    final list = (body['data'] as List?) ?? const [];
    return list
        .map((e) => Article.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// GET /articles/{slug}
  Future<Article> getBySlug(String slug) async {
    final res = await _dio.get('/articles/$slug');
    final body = res.data as Map<String, dynamic>;
    return Article.fromJson(Map<String, dynamic>.from(body['data'] as Map));
  }
}

