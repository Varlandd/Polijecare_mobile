import 'package:flutter/material.dart';

import '../../../core/config/api_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/launcher.dart';
import 'common.dart';

/// Section Hubungi Kami (setara `components/Contact.jsx`).
class ContactSection extends StatelessWidget {
  const ContactSection({super.key});

  @override
  Widget build(BuildContext context) {
    final waDigits = AppContact.whatsapp.replaceAll(RegExp(r'[^0-9]'), '');
    final methods = [
      _ContactMethod(Icons.phone_outlined, 'Telepon Kantor', AppContact.phone,
          'tel:${AppContact.phone}', const Color(0xFF3B82F6)),
      _ContactMethod(Icons.mail_outline_rounded, 'Email Resmi',
          AppContact.email, 'mailto:${AppContact.email}', const Color(0xFFA855F7)),
      _ContactMethod(
          Icons.camera_alt_outlined,
          'Instagram',
          AppContact.instagram,
          'https://instagram.com/${AppContact.instagram.replaceAll('@', '')}',
          const Color(0xFFEC4899)),
      _ContactMethod(Icons.chat_bubble_outline_rounded, 'WhatsApp Admin',
          AppContact.whatsapp, 'https://wa.me/$waDigits', const Color(0xFF22C55E)),
    ];

    return Container(
      width: double.infinity,
      color: AppColors.gray50,
      padding: const EdgeInsets.fromLTRB(20, 56, 20, 56),
      child: Column(
        children: [
          const SectionTitle(first: 'Hubungi', highlight: 'Kami'),
          const SizedBox(height: 16),
          const Text(
            'Kami siap membantu Anda. Jangan ragu untuk menghubungi kami melalui berbagai saluran komunikasi yang tersedia. Privasi Anda adalah prioritas kami.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: AppColors.gray600, height: 1.6),
          ),
          const SizedBox(height: 32),

          // Emergency card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2).withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0x80FECACA)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.gpp_maybe_outlined,
                          color: AppColors.red, size: 28),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bantuan Darurat 24/7',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.gray900,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Jika Anda dalam situasi darurat atau bahaya, segera hubungi tim Satgas PPKPT melalui saluran khusus ini.',
                            style: TextStyle(
                                fontSize: 13,
                                color: AppColors.gray600,
                                height: 1.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                FlowButton(
                  text: 'Hubungi Darurat Sekarang',
                  color: AppColors.red500,
                  onPressed: () =>
                      openExternal(context, AppContact.emergencyWaUrl),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Grid 2x2 kontak
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.95,
            children: [
              for (final m in methods) _ContactTile(method: m),
            ],
          ),
          const SizedBox(height: 20),

          // Jam operasional
          SoftCard(
            padding: const EdgeInsets.all(20),
            radius: 18,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.access_time_rounded,
                        color: AppColors.primary, size: 20),
                    SizedBox(width: 10),
                    Text(
                      'Jam Operasional Kantor',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.gray900,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _hoursRow('Senin - Jumat', '08.00 - 16.00 WIB', AppColors.gray600),
                const SizedBox(height: 8),
                _hoursRow('Sabtu - Minggu', 'Tutup (Kecuali Darurat)',
                    AppColors.red500),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Lokasi (pengganti iframe Google Maps)
          const _LocationCard(),
        ],
      ),
    );
  }

  Widget _hoursRow(String day, String time, Color timeColor) {
    return Row(
      children: [
        Text(day, style: const TextStyle(fontSize: 13, color: AppColors.gray600)),
        const Spacer(),
        Flexible(
          child: Text(
            time,
            textAlign: TextAlign.right,
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w500, color: timeColor),
          ),
        ),
      ],
    );
  }
}

class _ContactMethod {
  final IconData icon;
  final String label;
  final String value;
  final String href;
  final Color color;
  const _ContactMethod(this.icon, this.label, this.value, this.href, this.color);
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({required this.method});
  final _ContactMethod method;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.8),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => openExternal(context, method.href),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.gray100),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  color: AppColors.gray50,
                  shape: BoxShape.circle,
                ),
                child: Icon(method.icon, color: method.color, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                method.label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.gray900,
                  fontSize: 13.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                method.value,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11.5, color: AppColors.gray500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.gray100),
        boxShadow: const [
          BoxShadow(color: Color(0x14000000), blurRadius: 24, offset: Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ilustrasi peta
          Container(
            height: 150,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFE0E7FF), Color(0xFFDBEAFE), Color(0xFFDCFCE7)],
              ),
            ),
            child: Stack(
              children: [
                Positioned.fill(child: CustomPaint(painter: _GridPainter())),
                const Center(
                  child: Icon(Icons.location_on_rounded,
                      color: AppColors.red500, size: 56),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.location_on_outlined,
                        color: AppColors.red500, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kampus Politeknik Negeri Jember',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.gray900,
                              fontSize: 15,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            AppContact.address,
                            style: TextStyle(
                                fontSize: 13,
                                color: AppColors.gray600,
                                height: 1.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => openExternal(context, AppContact.mapsUrl),
                    icon: const Icon(Icons.map_outlined, size: 18),
                    label: const Text('Buka di Google Maps'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: Color(0xFFBFDBFE)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      textStyle: const TextStyle(fontWeight: FontWeight.w600),
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

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 28) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (double y = 0; y < size.height; y += 28) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
    final road = Paint()
      ..color = Colors.white
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(0, size.height * 0.7),
        Offset(size.width, size.height * 0.35), road);
    canvas.drawLine(Offset(size.width * 0.3, 0),
        Offset(size.width * 0.45, size.height), road);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

