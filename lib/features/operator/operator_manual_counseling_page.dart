import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../core/theme/app_colors.dart';
import 'operator_shell_page.dart';

/// Halaman Penanganan Satgas Manual pada sisi Super Admin (`/operator/manual-counseling`).
/// Porting 1:1 dari `pages/operator/manual-counseling.jsx`: menampilkan informasi pembatasan
/// hak akses sesuai SOP bahwa pencatatan sesi manual dilakukan oleh Tim Satgas (Konselor).
class OperatorManualCounselingPage extends StatelessWidget {
  const OperatorManualCounselingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return OperatorShellPage(
      title: 'Penanganan Satgas Manual',
      subtitle: 'Dokumentasi & Penjadwalan Langsung',
      activePath: AppRoutes.operatorCaseManagement,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: const Text(
                'KEMBALI',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
              style: TextButton.styleFrom(foregroundColor: AppColors.slate600),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFFBEB), Color(0xFFFFF7ED)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: const Color(0xFFFCD34D), width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14D97706),
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFFDE68A),
                        width: 4,
                      ),
                    ),
                    child: const Icon(
                      Icons.error_outline_rounded,
                      size: 38,
                      color: Color(0xFFD97706),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Akses Ditolak',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF92400E),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text.rich(
                    TextSpan(
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFFB45309),
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                      children: [
                        TextSpan(
                          text: 'Super Admin',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        TextSpan(
                          text:
                              ' tidak memiliki hak akses untuk melakukan input manual penanganan Satgas.',
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text.rich(
                    TextSpan(
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFFD97706),
                        height: 1.5,
                      ),
                      children: [
                        TextSpan(text: 'Fitur ini hanya tersedia untuk '),
                        TextSpan(
                          text: 'Tim Satgas (Konselor)',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        TextSpan(
                          text:
                              '. Silakan minta anggota Satgas yang aktif untuk melakukan pencatatan sesi.',
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD97706),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      child: const Text(
                        'KEMBALI KE HALAMAN SEBELUMNYA',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacementNamed(
                          AppRoutes.operatorCaseManagement,
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFFB45309),
                        side: const BorderSide(
                          color: Color(0xFFFCD34D),
                          width: 1.5,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      child: const Text(
                        'KE MANAJEMEN KASUS',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
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

