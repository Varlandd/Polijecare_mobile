import 'package:dio/dio.dart';

import '../../core/config/api_config.dart';
import '../models/article.dart';

/// Data artikel bawaan `DatabaseSeeder.php` sebagai fallback jika server belum aktif.
final List<Article> _kSeedArticles = [
  const Article(
    id: 1,
    title: 'Pentingnya Menjaga Lingkungan Kampus Aman dari Kekerasan Seksual',
    slug: 'pentingnya-menjaga-lingkungan-kampus-aman-dari-kekerasan-seksual',
    excerpt:
        'Lingkungan kampus yang aman adalah hak setiap sivitas akademika. Satgas PPKPT Politeknik Negeri Jember berkomitmen untuk menciptakan suasana belajar yang bebas dari kekerasan seksual.',
    content:
        '<p>Lingkungan kampus yang aman adalah hak setiap sivitas akademika. Satgas PPKPT Politeknik Negeri Jember berkomitmen untuk menciptakan suasana belajar yang bebas dari kekerasan seksual.</p><p>Kekerasan seksual dalam lingkungan kampus dapat berupa berbagai bentuk, mulai dari pelecehan verbal hingga kekerasan fisik. Penting bagi kita semua untuk mengenali tanda-tanda dan bagaimana cara melaporkannya.</p><p>Setiap individu berhak mendapatkan perlindungan dan rasa aman dalam menempuh pendidikan. Mari bersama-sama menjaga kampus kita sebagai tempat yang aman dan mendukung bagi semua.</p>',
    statusLabel: 'Publish',
  ),
  const Article(
    id: 2,
    title: 'Prosedur Pelaporan Kasus Kekerasan Seksual di Polije',
    slug: 'prosedur-pelaporan-kasus-kekerasan-seksual-di-polije',
    excerpt:
        'Prosedur pelaporan kasus kekerasan seksual di Politeknik Negeri Jember dirancang untuk memberikan kemudahan dan rasa aman bagi pelapor.',
    content:
        '<p>Prosedur pelaporan kasus kekerasan seksual di Politeknik Negeri Jember dirancang untuk memberikan kemudahan dan rasa aman bagi pelapor.</p><p><strong>Langkah 1:</strong> Hubungi Satgas PPKPT melalui WhatsApp atau datang langsung ke sekretariat.</p><p><strong>Langkah 2:</strong> Tim kami akan melakukan pendengaran awal dan memberikan informasi tentang hak-hak Anda.</p><p><strong>Langkah 3:</strong> Jika Anda setuju, kami akan membantu proses pelaporan formal.</p><p><strong>Langkah 4:</strong> Pendampingan psikologis dan hukum akan disediakan selama proses berlangsung.</p>',
    statusLabel: 'Publish',
  ),
  const Article(
    id: 3,
    title: 'Hak dan Kewajiban Korban dan Pelapor Kekerasan Seksual',
    slug: 'hak-dan-kewajiban-korban-dan-pelapor-kekerasan-seksual',
    excerpt:
        'Sebagai korban atau pelapor kekerasan seksual, Anda memiliki hak-hak yang dilindungi oleh undang-undang dan peraturan institusi.',
    content:
        '<p>Sebagai korban atau pelapor kekerasan seksual, Anda memiliki hak-hak yang dilindungi oleh undang-undang dan peraturan institusi.</p>',
    statusLabel: 'Publish',
  ),
  const Article(
    id: 4,
    title: 'Peran Satgas PPKPT dalam Mencegah Kekerasan Seksual',
    slug: 'peran-satgas-ppkpt-dalam-mencegah-kekerasan-seksual',
    excerpt:
        'Satgas PPKPT Politeknik Negeri Jember memiliki peran penting dalam pencegahan dan penanganan kekerasan seksual di lingkungan kampus.',
    content:
        '<p>Satgas PPKPT Politeknik Negeri Jember memiliki peran penting dalam pencegahan dan penanganan kekerasan seksual di lingkungan kampus.</p>',
    statusLabel: 'Publish',
  ),
  const Article(
    id: 5,
    title: 'Dukungan Psikologis bagi Korban Kekerasan Seksual',
    slug: 'dukungan-psikologis-bagi-korban-kekerasan-seksual',
    excerpt:
        'Dampak psikologis kekerasan seksual dapat sangat berat bagi korban. Satgas PPKPT menyediakan layanan dukungan psikologis profesional.',
    content:
        '<p>Dampak psikologis kekerasan seksual dapat sangat berat bagi korban. Satgas PPKPT menyediakan layanan dukungan psikologis profesional.</p>',
    statusLabel: 'Publish',
  ),
];

/// Setara `services/articleService.js` (bagian publik).
class ArticleService {
  ArticleService._();
  static final ArticleService instance = ArticleService._();

  /// GET /articles — artikel aktif & sudah publish (dengan dukungan limit opsional).
  Future<List<Article>> getPublicArticles({int? limit}) async {
    final all = await getAll();
    if (limit != null && limit > 0 && all.length > limit) {
      return all.take(limit).toList();
    }
    return all;
  }

  /// GET /articles — artikel aktif & sudah publish.
  Future<List<Article>> getAll() async {
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
        final res = await dio.get('/articles');
        final data = res.data;
        if (data is Map && data['success'] == true) {
          ApiConfig.setActiveBaseUrl(candidateUrl);
          final list = (data['data'] as List?) ?? const [];
          return list
              .map((e) => Article.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList();
        }
      } catch (_) {
        continue;
      }
    }
    return _kSeedArticles;
  }

  /// GET /articles/{slug}
  Future<Article> getBySlug(String slug) async {
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
        final res = await dio.get('/articles/$slug');
        final data = res.data;
        if (data is Map && data['data'] is Map) {
          ApiConfig.setActiveBaseUrl(candidateUrl);
          return Article.fromJson(
            Map<String, dynamic>.from(data['data'] as Map),
          );
        }
      } catch (_) {
        continue;
      }
    }
    return _kSeedArticles.firstWhere(
      (a) => a.slug == slug,
      orElse: () => _kSeedArticles.first,
    );
  }
}
