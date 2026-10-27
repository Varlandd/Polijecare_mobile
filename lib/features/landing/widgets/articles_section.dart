import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../app/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/article.dart';
import '../../../data/services/article_service.dart';
import 'common.dart';

/// Section Artikel & Pengumuman (setara `components/Articles.jsx` + `gallery4.jsx`).
class ArticlesSection extends StatefulWidget {
  const ArticlesSection({super.key, this.refreshSeed = 0});

  final int refreshSeed;

  @override
  State<ArticlesSection> createState() => _ArticlesSectionState();
}

class _ArticlesSectionState extends State<ArticlesSection> {
  late Future<List<Article>> _future;
  final _pageController = PageController(viewportFraction: 0.86);
  int _current = 0;

  @override
  void initState() {
    super.initState();
    _future = ArticleService.instance.getAll();
  }

  @override
  void didUpdateWidget(covariant ArticlesSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshSeed != widget.refreshSeed) {
      setState(() => _future = ArticleService.instance.getAll());
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.gray50,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          const Positioned(
            top: -100,
            right: -100,
            child: BlurBlob(size: 320, color: Color(0x143B82F6)),
          ),
          const Positioned(
            bottom: -100,
            left: -100,
            child: BlurBlob(size: 320, color: Color(0x143B82F6)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 56),
            child: FutureBuilder<List<Article>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 80),
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  );
                }
                if (snap.hasError) {
                  return _message(
                    'Gagal memuat artikel',
                    'Periksa koneksi internet Anda lalu tarik ke bawah untuk memuat ulang.',
                    isError: true,
                  );
                }
                final articles = snap.data ?? const [];
                if (articles.isEmpty) {
                  return _message(
                    'Belum ada artikel terbaru.',
                    'Pantau terus halaman ini untuk informasi terkini dari PolijeCare.',
                  );
                }
                return _buildGallery(articles);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _header() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(
            first: 'Artikel &',
            highlight: 'Pengumuman',
            textAlign: TextAlign.start,
          ),
          SizedBox(height: 12),
          Text(
            'Dapatkan informasi terbaru seputar layanan, edukasi, dan pengumuman penting dari Satgas PPKPT Polije. Kami berkomitmen untuk transparansi dan edukasi.',
            style: TextStyle(fontSize: 14, color: AppColors.slate500, height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _message(String title, String sub, {bool isError = false}) {
    return Column(
      children: [
        _header(),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
          child: Column(
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isError ? AppColors.red500 : AppColors.gray500,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                sub,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppColors.gray500),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGallery(List<Article> articles) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header(),
        const SizedBox(height: 28),
        SizedBox(
          height: 420,
          child: PageView.builder(
            controller: _pageController,
            padEnds: articles.length == 1,
            itemCount: articles.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (context, i) => Padding(
              padding: EdgeInsets.only(
                left: i == 0 && articles.length > 1 ? 20 : 8,
                right: 8,
              ),
              child: _ArticleCard(article: articles[i]),
            ),
          ),
        ),
        if (articles.length > 1) ...[
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(articles.length, (i) {
              final active = i == _current;
              return GestureDetector(
                onTap: () => _pageController.animateToPage(
                  i,
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOut,
                ),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: active
                        ? AppColors.primary
                        : AppColors.primary.withValues(alpha: 0.2),
                  ),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}

class _ArticleCard extends StatelessWidget {
  const _ArticleCard({required this.article});

  final Article article;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed(
        AppRoutes.artikelDetail,
        arguments: article.slug,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: article.imageUrl,
              fit: BoxFit.cover,
              placeholder: (_, _) => Container(color: AppColors.gray200),
              errorWidget: (_, _, _) => CachedNetworkImage(
                imageUrl:
                    'https://picsum.photos/seed/${article.slug}/800/400.jpg',
                fit: BoxFit.cover,
                errorWidget: (_, _, _) => Container(
                  color: AppColors.gray300,
                  child: const Icon(Icons.image_not_supported_outlined,
                      color: AppColors.gray500, size: 48),
                ),
              ),
            ),
            // Overlay gradient (primary → transparan)
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.primary.withValues(alpha: 0),
                    AppColors.blue900.withValues(alpha: 0.45),
                    AppColors.navyDark.withValues(alpha: 0.9),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 22,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    article.excerpt,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13.5,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Row(
                    children: [
                      Text(
                        'Baca selengkapnya',
                        style: TextStyle(color: Colors.white, fontSize: 13),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded,
                          color: Colors.white, size: 18),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

