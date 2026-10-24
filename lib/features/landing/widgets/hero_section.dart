import 'package:flutter/material.dart';

import '../../../app/routes.dart';
import '../../../core/config/api_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/launcher.dart';
import 'common.dart';

/// Section Hero (setara `components/Hero.jsx`).
class HeroSection extends StatelessWidget {
  const HeroSection({super.key});

  static const String title = 'Aman Bicara, Aman Melapor';
  static const String subtitle = 'Satgas PPKPT Politeknik Negeri Jember';

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.softWhite,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // Background decorations
          const Positioned(
            top: -80,
            left: -80,
            child: BlurBlob(size: 300, color: Color(0x404C6EF5)),
          ),
          const Positioned(
            bottom: -100,
            right: -100,
            child: BlurBlob(size: 340, color: Color(0x26191970)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const FadeSlideIn(
                  delay: Duration(milliseconds: 150),
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.bold,
                      color: AppColors.gray900,
                      height: 1.15,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const FadeSlideIn(
                  delay: Duration(milliseconds: 250),
                  child: Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.navy,
                      height: 1.3,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const FadeSlideIn(
                  delay: Duration(milliseconds: 350),
                  child: _HeroDescription(),
                ),
                const SizedBox(height: 22),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 450),
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        openExternal(context, AppContact.emergencyWaUrl),
                    icon: const Icon(Icons.phone_in_talk_rounded, size: 20),
                    label: const Text('Bantuan Darurat'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.red,
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shadowColor: AppColors.red.withValues(alpha: 0.4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 22, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const FadeSlideIn(
                  delay: Duration(milliseconds: 600),
                  child: _AnnouncementBanner(),
                ),
                const SizedBox(height: 28),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 500),
                  child: Center(
                    child: Image.asset(
                      'assets/images/gambar_header.png',
                      fit: BoxFit.contain,
                    ),
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

class _HeroDescription extends StatelessWidget {
  const _HeroDescription();

  @override
  Widget build(BuildContext context) {
    const base = TextStyle(
      fontSize: 16,
      color: AppColors.gray600,
      height: 1.6,
    );
    final mark = base.copyWith(
      color: AppColors.gray900,
      fontWeight: FontWeight.w600,
      background: Paint()..color = const Color(0x55FDE047), // highlight-marker
    );
    return Text.rich(
      TextSpan(style: base, children: [
        const TextSpan(text: 'Kami siap mendengar dan membantu Anda dengan '),
        TextSpan(text: 'profesionalisme', style: mark),
        const TextSpan(text: ' dan '),
        TextSpan(text: 'kerahasiaan terjamin', style: mark),
        const TextSpan(text: '. Setiap laporan akan ditangani dengan '),
        TextSpan(text: 'empati', style: mark),
        const TextSpan(text: ' dan '),
        TextSpan(text: 'seksama', style: mark),
        const TextSpan(text: '.'),
      ]),
    );
  }
}

/// Banner "Informasi Pelaporan".
class _AnnouncementBanner extends StatelessWidget {
  const _AnnouncementBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEEF2FF), Color(0xFFEFF6FF)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFDBEAFE)),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -20,
            right: -20,
            child: Icon(Icons.info_rounded,
                size: 140, color: Colors.blue.withValues(alpha: 0.05)),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.info_rounded, color: Color(0xFF2563EB), size: 24),
                    SizedBox(width: 8),
                    Text(
                      'Informasi Pelaporan',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.gray900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text.rich(
                  TextSpan(
                    style: TextStyle(
                        fontSize: 13.5, color: AppColors.gray700, height: 1.55),
                    children: [
                      TextSpan(text: 'Bagi '),
                      TextSpan(
                          text: 'Sivitas Akademika Polije',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(
                          text:
                              ' silahkan login terlebih dahulu. Namun, jika Anda berasal dari '),
                      TextSpan(
                          text: 'Masyarakat Umum / Kampus Lain',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(
                          text:
                              ', Anda dapat membuat laporan langsung tanpa login.'),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        Navigator.of(context).pushNamed(AppRoutes.login),
                    icon: const Icon(Icons.login_rounded, size: 20),
                    label: const Text('Login & Lapor (Polije)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.navy,
                      elevation: 6,
                      shadowColor: AppColors.blue900.withValues(alpha: 0.3),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      textStyle: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        Navigator.of(context).pushNamed(AppRoutes.laporUmum),
                    icon: const Icon(Icons.note_add_rounded, size: 20),
                    label: const Text('Lapor Tanpa Login (Umum)'),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF1D4ED8),
                      side: const BorderSide(color: Color(0xFFBFDBFE)),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      textStyle: const TextStyle(fontWeight: FontWeight.bold),
                    ),
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

