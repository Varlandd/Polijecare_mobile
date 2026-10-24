import 'package:flutter/material.dart';

import '../../../core/config/api_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/launcher.dart';

/// Footer (setara `components/Footer.jsx`).
class FooterSection extends StatelessWidget {
  const FooterSection({super.key, required this.onNavigate});

  /// Menerima href anchor (`#about`) atau route.
  final ValueChanged<String> onNavigate;

  static const Map<String, List<(String, String)>> _links = {
    'Menu Utama': [
      ('Beranda', '#hero'),
      ('Tentang Kami', '#about'),
      ('Layanan', '#services'),
      ('Artikel', '#articles'),
    ],
    'Layanan': [
      ('Pelaporan Online', '#services'),
      ('Konsultasi Psikologi', '#contact'),
      ('Pendampingan Hukum', '#contact'),
      ('Edukasi & Sosialisasi', '#materials'),
    ],
    'Bantuan': [
      ('Kontak Darurat', '#contact'),
      ('Prosedur Lapor', '#services'),
    ],
  };

  @override
  Widget build(BuildContext context) {
    final year = DateTime.now().year;
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.gray200)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 28),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Image.asset('assets/images/logo_polijecare_new.png',
                    width: 56, height: 56),
                const SizedBox(width: 14),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PolijeCare',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      'SATGAS PPKPT POLIJE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Text(
              'Mewujudkan lingkungan kampus yang aman, inklusif, dan bebas kekerasan seksual. Kami hadir untuk melayani, melindungi, dan mendampingi sivitas akademika Polije.',
              style: TextStyle(fontSize: 13.5, color: AppColors.gray800, height: 1.6),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                _social(context, Icons.camera_alt_outlined,
                    'https://instagram.com/ppkptpolije'),
                _social(context, Icons.chat_bubble_outline_rounded,
                    'https://wa.me/${AppContact.whatsappNumber}'),
                _social(context, Icons.mail_outline_rounded,
                    'mailto:${AppContact.email}'),
              ],
            ),
            const SizedBox(height: 32),
            Wrap(
              spacing: 24,
              runSpacing: 24,
              children: [
                for (final entry in _links.entries)
                  SizedBox(
                    width: 150,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.key.toUpperCase(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            letterSpacing: 1,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 14),
                        for (final (name, href) in entry.value)
                          InkWell(
                            onTap: () => onNavigate(href),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.gray700,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 32),
            const Divider(color: AppColors.gray200, height: 1),
            const SizedBox(height: 20),
            Center(
              child: Column(
                children: [
                  Text(
                    '© $year PolijeCare. All rights reserved.',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 10),
                  const Wrap(
                    spacing: 20,
                    runSpacing: 6,
                    alignment: WrapAlignment.center,
                    children: [
                      _MiniInfo(Icons.location_on_outlined, 'Jember, East Java'),
                      _MiniInfo(Icons.mail_outline_rounded, AppContact.email),
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

  Widget _social(BuildContext context, IconData icon, String url) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Material(
        color: AppColors.gray100,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => openExternal(context, url),
          child: Padding(
            padding: const EdgeInsets.all(9),
            child: Icon(icon, size: 18, color: AppColors.gray500),
          ),
        ),
      ),
    );
  }
}

class _MiniInfo extends StatelessWidget {
  const _MiniInfo(this.icon, this.text);
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13),
        const SizedBox(width: 6),
        Text(text,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

