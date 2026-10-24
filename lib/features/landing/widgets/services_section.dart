import 'package:flutter/material.dart';

import '../../../app/routes.dart';
import '../../../core/config/api_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/launcher.dart';
import 'common.dart';

/// Section Cara Melapor (setara `components/Services.jsx`).
class ServicesSection extends StatelessWidget {
  const ServicesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.gray50,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          const Positioned(
            top: -60,
            right: -60,
            child: BlurBlob(size: 260, color: Color(0x4DE9D5FF)),
          ),
          const Positioned(
            bottom: -60,
            left: -60,
            child: BlurBlob(size: 260, color: Color(0x4DBFDBFE)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 56, 20, 56),
            child: Column(
              children: [
                const SectionTitle(first: 'Cara', highlight: 'Melapor'),
                const SizedBox(height: 16),
                const Text(
                  'Kami menyediakan ruang aman bagi Anda untuk bersuara. Pilih metode yang paling nyaman, kami siap mendampingi setiap langkahnya.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 15, color: AppColors.gray600, height: 1.6),
                ),
                const SizedBox(height: 32),
                _MethodCard(
                  icon: Icons.chat_bubble_outline_rounded,
                  iconColor: AppColors.green,
                  blobColor: const Color(0xFFDCFCE7),
                  title: 'Via WhatsApp',
                  description:
                      'Layanan cepat tanggap untuk konsultasi awal dan pelaporan darurat. Terhubung langsung dengan tim satgas kami.',
                  features: const [
                    'Respons 24/7',
                    'Konsultasi Privat',
                    'Pendampingan Awal',
                  ],
                  buttonText: 'Chat WhatsApp Sekarang',
                  buttonColor: AppColors.green,
                  onPressed: () =>
                      openExternal(context, AppContact.emergencyWaUrl),
                ),
                const SizedBox(height: 20),
                _MethodCard(
                  icon: Icons.description_outlined,
                  iconColor: AppColors.navy,
                  blobColor: const Color(0xFFE0E7FF),
                  title: 'Form Pengaduan',
                  description:
                      'Saluran resmi untuk pelaporan mendetail. Mendukung lampiran bukti dan kronologi lengkap untuk investigasi.',
                  features: const [
                    'Form Terstruktur',
                    'Upload Bukti Aman',
                    'Tracking Status',
                  ],
                  buttonText: 'Isi Form Laporan',
                  buttonColor: const Color(0xFF2563EB),
                  onPressed: () => Navigator.of(context).pushNamed(
                    AppRoutes.login,
                    arguments: const {'from': 'form-laporan'},
                  ),
                ),
                const SizedBox(height: 32),
                const _WhyUsCard(),
                const SizedBox(height: 20),
                const _FlowCard(),
                const SizedBox(height: 28),
                const _EmergencyBanner(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MethodCard extends StatelessWidget {
  const _MethodCard({
    required this.icon,
    required this.iconColor,
    required this.blobColor,
    required this.title,
    required this.description,
    required this.features,
    required this.buttonText,
    required this.buttonColor,
    required this.onPressed,
  });

  final IconData icon;
  final Color iconColor;
  final Color blobColor;
  final String title;
  final String description;
  final List<String> features;
  final String buttonText;
  final Color buttonColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white),
        boxShadow: const [
          BoxShadow(
              color: Color(0x14000000), blurRadius: 30, offset: Offset(0, 12)),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -40,
            right: -40,
            child: BlurBlob(size: 200, color: blobColor),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(color: Color(0x14000000), blurRadius: 6),
                    ],
                  ),
                  child: Icon(icon, color: iconColor, size: 30),
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.gray900,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  description,
                  style: const TextStyle(
                      fontSize: 14, color: AppColors.gray600, height: 1.6),
                ),
                const SizedBox(height: 18),
                for (final f in features)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle_outline_rounded,
                            size: 18, color: iconColor),
                        const SizedBox(width: 8),
                        Text(
                          f,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            color: AppColors.gray700,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                FlowButton(
                  text: buttonText,
                  color: buttonColor,
                  onPressed: onPressed,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WhyUsCard extends StatelessWidget {
  const _WhyUsCard();

  static const _items = [
    (
      Icons.shield_outlined,
      'Dijamin Aman',
      'Identitas pelapor dirahasiakan sepenuhnya sesuai kode etik.'
    ),
    (
      Icons.groups_outlined,
      'Profesional',
      'Ditangani oleh tim ahli yang berpengalaman dan objektif.'
    ),
    (
      Icons.handshake_outlined,
      'Pendampingan',
      'Dukungan psikologis dan hukum selama proses berjalan.'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Kenapa Kami?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.gray900,
            ),
          ),
          const SizedBox(height: 20),
          for (final (icon, title, desc) in _items)
            Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEFF6FF),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: AppColors.navy, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.gray900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          desc,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.gray500,
                            height: 1.5,
                          ),
                        ),
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

/// Alur Penanganan (timeline 4 langkah).
class _FlowCard extends StatelessWidget {
  const _FlowCard();

  static const _steps = [
    ('01', 'Pelaporan', 'Laporan masuk via WA atau Website.',
        Icons.description_outlined),
    ('02', 'Verifikasi', 'Validasi data oleh tim Satgas.',
        Icons.check_circle_outline_rounded),
    ('03', 'Tindak Lanjut', 'Investigasi atau mediasi kasus.',
        Icons.search_rounded),
    ('04', 'Penyelesaian', 'Pemulihan dan penutupan kasus.',
        Icons.sentiment_satisfied_alt_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      color: Colors.white.withValues(alpha: 0.85),
      borderColor: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Alur Penanganan',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.gray900,
            ),
          ),
          const SizedBox(height: 24),
          for (var i = 0; i < _steps.length; i++)
            FadeSlideIn(
              delay: Duration(milliseconds: 200 * i + 300),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border:
                                Border.all(color: AppColors.gray100, width: 2),
                            boxShadow: const [
                              BoxShadow(
                                  color: Color(0x14000000), blurRadius: 8),
                            ],
                          ),
                          child: Icon(_steps[i].$4,
                              color: AppColors.navy, size: 22),
                        ),
                        if (i < _steps.length - 1)
                          Expanded(
                            child: Container(
                              width: 2,
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              color: AppColors.navy,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4, bottom: 22),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _steps[i].$1,
                              style: TextStyle(
                                fontSize: 12,
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.bold,
                                color: AppColors.navy.withValues(alpha: 0.8),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _steps[i].$2,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.gray900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _steps[i].$3,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w500,
                                color: AppColors.gray700,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmergencyBanner extends StatelessWidget {
  const _EmergencyBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        border: Border.all(color: const Color(0xFFFEE2E2)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Color(0xFFFEE2E2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.phone_outlined,
                    color: AppColors.red, size: 24),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Butuh Bantuan Darurat?',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.gray900,
                        fontSize: 15,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Jangan ragu untuk menghubungi kami jika situasi mendesak.',
                      style: TextStyle(fontSize: 13, color: AppColors.gray600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FlowButton(
            text: 'Hubungi Sekarang',
            color: AppColors.red,
            onPressed: () => openExternal(context, AppContact.emergencyWaUrl),
          ),
        ],
      ),
    );
  }
}

