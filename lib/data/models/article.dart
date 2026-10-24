import '../../core/utils/image_url.dart';

/// Model artikel (sesuai `ArticleResource.php`).
class Article {
  final int id;
  final String title;
  final String slug;
  final String? image;
  final String excerpt;
  final String content;
  final String? statusLabel;
  final DateTime? publishedAt;
  final DateTime? createdAt;

  const Article({
    required this.id,
    required this.title,
    required this.slug,
    this.image,
    this.excerpt = '',
    this.content = '',
    this.statusLabel,
    this.publishedAt,
    this.createdAt,
  });

  /// URL gambar siap pakai (sudah dinormalisasi ke proxy FileController),
  /// fallback ke picsum seperti di web.
  String get imageUrl =>
      normalizeImageUrl(image) ?? 'https://picsum.photos/seed/$slug/800/400.jpg';

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      image: json['image']?.toString(),
      excerpt: json['excerpt']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      statusLabel: json['status_label']?.toString(),
      publishedAt: DateTime.tryParse(json['published_at']?.toString() ?? ''),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }
}

