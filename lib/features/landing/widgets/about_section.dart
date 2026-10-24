import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import 'common.dart';

/// Section Tentang Kami (setara `components/ui/about-section.jsx`).
class AboutSection extends StatelessWidget {
  const AboutSection({super.key, required this.onContact});

  final VoidCallback onContact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFF9F9F9),
      padding: const EdgeInsets.fromLTRB(20, 48, 20, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: ✱ TENTANG KAMI + ikon nilai
          Row(
            children: [
              const _SpinningStar(),
              const SizedBox(width: 8),
              const Text(
                'TENTANG KAMI',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.gray600,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              for (final icon in const [
                Icons.shield_outlined,
                Icons.favorite_border_rounded,
                Icons.lock_outline_rounded,
                Icons.balance_rounded,
              ])
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    border: Border.all(color: const Color(0xFFC7D2FE)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 16, color: AppColors.navy),
                ),
            ],
          ),
          const SizedBox(height: 16),
          const _HeroCarousel(),
          const SizedBox(height: 16),
          // Stats
          const Wrap(
            spacing: 10,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _Stat(bold: '24/7', label: 'layanan aktif'),
              Text('|', style: TextStyle(color: AppColors.gray300)),
              _Stat(bold: 'Gratis', label: 'tanpa biaya'),
              Text('|', style: TextStyle(color: AppColors.gray300)),
              _Stat(bold: 'Cepat', label: 'respon tanggap'),
            ],
          ),
          const SizedBox(height: 28),
          const Text(
            'Menciptakan Kampus Aman & Bermartabat.',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: AppColors.gray900,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'PolijeCare merupakan kanal resmi pengaduan Satgas Pencegahan dan Penanganan Kekerasan Seksual (PPKPT) Politeknik Negeri Jember. Kami hadir sebagai garda terdepan dalam melindungi korban dan memberikan pendampingan profesional.',
            textAlign: TextAlign.justify,
            style: TextStyle(fontSize: 14, color: AppColors.gray600, height: 1.65),
          ),
          const SizedBox(height: 14),
          const Text(
            'Setiap laporan ditangani secara empatik, profesional, dan menjaga kerahasiaan penuh. Kami percaya bahwa setiap individu berhak mendapat rasa aman dalam menempuh pendidikan tanpa ancaman kekerasan seksual.',
            textAlign: TextAlign.justify,
            style: TextStyle(fontSize: 14, color: AppColors.gray600, height: 1.65),
          ),
          const SizedBox(height: 32),
          Align(
            alignment: Alignment.centerRight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  'SATGAS PPKPT',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Politeknik Negeri Jember',
                  style: TextStyle(fontSize: 13, color: AppColors.gray600),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Siap untuk melaporkan atau butuh bantuan? Kami siap mendengarkan Anda.',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.gray900,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: onContact,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.phone_outlined, size: 16, color: Colors.white60),
                      SizedBox(width: 8),
                      Text('HUBUNGI KAMI',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13)),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, size: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.bold, required this.label});
  final String bold;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text.rich(TextSpan(children: [
      TextSpan(
        text: '$bold ',
        style: const TextStyle(
            color: AppColors.navy, fontWeight: FontWeight.bold, fontSize: 13),
      ),
      TextSpan(
        text: label,
        style: const TextStyle(color: AppColors.gray600, fontSize: 13),
      ),
    ]));
  }
}

class _SpinningStar extends StatefulWidget {
  const _SpinningStar();

  @override
  State<_SpinningStar> createState() => _SpinningStarState();
}

class _SpinningStarState extends State<_SpinningStar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(seconds: 1))
    ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _c,
      child: const Text('✱',
          style: TextStyle(fontSize: 18, color: AppColors.navy)),
    );
  }
}

/// Carousel 3 gambar dengan indikator progres (5 detik / slide)
/// dan badge "100% Rahasia".
class _HeroCarousel extends StatefulWidget {
  const _HeroCarousel();

  @override
  State<_HeroCarousel> createState() => _HeroCarouselState();
}

class _HeroCarouselState extends State<_HeroCarousel>
    with TickerProviderStateMixin {
  static const _images = [
    'assets/images/Gambar1.jpg',
    'assets/images/Gambar2.jpeg',
    'assets/images/Gambar3.jpeg',
  ];
  static const _slideDuration = Duration(seconds: 5);

  int _index = 0;
  late final AnimationController _progress =
      AnimationController(vsync: this, duration: _slideDuration)
        ..addStatusListener((s) {
          if (s == AnimationStatus.completed) _next();
        })
        ..forward();

  // Counter 0 → 100%
  late final AnimationController _counter = AnimationController(
      vsync: this, duration: const Duration(seconds: 2))
    ..forward();

  void _next() => _goTo((_index + 1) % _images.length);

  void _goTo(int i) {
    setState(() => _index = i);
    _progress
      ..reset()
      ..forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    for (final img in _images) {
      unawaited(precacheImage(AssetImage(img), context));
    }
  }

  @override
  void dispose() {
    _progress.dispose();
    _counter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: AspectRatio(
        aspectRatio: 16 / 10,
        child: Stack(
          fit: StackFit.expand,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 800),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: ScaleTransition(
                  scale: Tween(begin: 1.1, end: 1.0).animate(anim),
                  child: child,
                ),
              ),
              child: Image.asset(
                _images[_index],
                key: ValueKey(_index),
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
            // Indikator progres slide
            Positioned(
              left: 16,
              bottom: 16,
              child: AnimatedBuilder(
                animation: _progress,
                builder: (context, _) => Row(
                  children: List.generate(_images.length, (i) {
                    final active = i == _index;
                    final fill = active
                        ? _progress.value
                        : (i < _index ? 1.0 : 0.0);
                    return GestureDetector(
                      onTap: () => _goTo(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 8),
                        width: active ? 40 : 20,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white30,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: fill,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
            // Badge 100% Rahasia
            Positioned(
              right: 12,
              bottom: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white54),
                  boxShadow: const [
                    BoxShadow(color: Color(0x33000000), blurRadius: 16),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedBuilder(
                      animation: _counter,
                      builder: (context, _) => Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '${(_counter.value * 100).round()}%',
                            style: const TextStyle(
                              color: AppColors.navy,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'RAHASIA',
                            style: TextStyle(
                              color: AppColors.gray900,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Text(
                      'kerahasiaan terjamin',
                      style: TextStyle(
                          fontSize: 10,
                          color: AppColors.gray600,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

