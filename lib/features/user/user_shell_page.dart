import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../data/services/auth_service.dart';
import '../auth/protected_route.dart';
import 'widgets/user_sidebar.dart';

/// Kerangka halaman Mahasiswa / User (`role = user`) setelah berhasil login.
/// Menyediakan `Topbar` (`Layanan / user`) + `UserSidebar` (`User Dashboard`)
/// sesuai `pages/user/dashboard.jsx`, `components/layout/Topbar.jsx`, & `Sidebar.jsx` di web.
class UserShellPage extends StatelessWidget {
  const UserShellPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.activePath,
    this.body,
  });

  final String title;
  final String subtitle;
  final String activePath;
  final Widget? body;

  Future<void> _handleLogout(BuildContext context) async {
    await AuthService.instance.logout();
    if (!context.mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.login,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scaffoldKey = GlobalKey<ScaffoldState>();

    return ProtectedRoute(
      requiredRoles: const ['user', 'admin'],
      child: ListenableBuilder(
        listenable: AuthService.instance,
        builder: (context, _) {
          final user = AuthService.instance.user;
          return Scaffold(
            key: scaffoldKey,
            backgroundColor: AppColors.gray50,
            drawer: UserSidebar(activePath: activePath),
            appBar: AppBar(
              toolbarHeight: 68,
              backgroundColor: Colors.white,
              elevation: 0,
              automaticallyImplyLeading: false,
              shape: const Border(
                bottom: BorderSide(color: AppColors.gray200),
              ),
              titleSpacing: 16,
              title: Row(
                children: [
                  Material(
                    color: AppColors.gray50,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => scaffoldKey.currentState?.openDrawer(),
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(
                          Icons.menu_rounded,
                          size: 20,
                          color: AppColors.gray600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Breadcrumb `Layanan / user` sesuai `Topbar.jsx`
                        const Row(
                          children: [
                            Text(
                              'Layanan',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF6666DE),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 4),
                              child: Text(
                                '/',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.gray400,
                                ),
                              ),
                            ),
                            Text(
                              'user',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.gray500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.gray900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                // Avatar ke `/profile` sesuai `Topbar.jsx`
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    if (activePath != AppRoutes.profile) {
                      Navigator.of(context)
                          .pushReplacementNamed(AppRoutes.profile);
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 10),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFFE6E6FA), Color(0xFFD6D6EA)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        user?.initial ?? 'M',
                        style: const TextStyle(
                          color: AppColors.gray800,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 16, left: 4),
                  child: Material(
                    color: const Color(0xFFFFF1F2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Color(0xFFFFE4E6)),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _handleLogout(context),
                      child: const Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.logout_rounded,
                              size: 16,
                              color: Color(0xFFE11D48),
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Keluar',
                              style: TextStyle(
                                color: Color(0xFFE11D48),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            body: body ??
                SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Welcome Banner persis `pages/user/dashboard.jsx` (from-violet-600 to-indigo-700)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF7C3AED), Color(0xFF4338CA)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x334338CA),
                              blurRadius: 20,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Halo, ${user?.name ?? 'Mahasiswa'}!',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                height: 1.25,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Selamat datang di pusat layanan pengaduan PolijeCare. Kami siap mendengarkan dan membantu menyelesaikan masalah Anda dengan aman dan rahasia.',
                              style: TextStyle(
                                color: Color(0xFFDDD6FE),
                                fontSize: 13,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Akses Cepat sesuai `pages/user/dashboard.jsx`
                      const Text(
                        'Akses Cepat',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.gray900,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _QuickActionTile(
                        title: 'Buat Laporan Baru',
                        description:
                            'Laporkan insiden kekerasan, perundungan, atau masalah lainnya secara aman.',
                        icon: Icons.add_rounded,
                        iconBg: const Color(0xFFF3E8FF),
                        iconColor: const Color(0xFF7C3AED),
                        onTap: () {
                          Navigator.of(context).pushReplacementNamed(
                            AppRoutes.userBuatLaporan,
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      _QuickActionTile(
                        title: 'Riwayat Pengaduan',
                        description:
                            'Pantau status dan tindak lanjut dari laporan yang telah Anda kirimkan.',
                        icon: Icons.access_time_rounded,
                        iconBg: const Color(0xFFDBEAFE),
                        iconColor: const Color(0xFF2563EB),
                        onTap: () {
                          Navigator.of(context).pushReplacementNamed(
                            AppRoutes.userHistoriPengaduan,
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      _QuickActionTile(
                        title: 'Ajukan Penanganan',
                        description:
                            'Jadwalkan sesi penanganan atau pendampingan dengan Satgas profesional.',
                        icon: Icons.calendar_today_outlined,
                        iconBg: const Color(0xFFD1FAE5),
                        iconColor: const Color(0xFF059669),
                        onTap: () {
                          Navigator.of(context).pushReplacementNamed(
                            AppRoutes.userCounselingRequest,
                          );
                        },
                      ),
                      const SizedBox(height: 20),

                      // Kartu Identitas Mahasiswa yang sedang login
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AppColors.gray100),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x0A000000),
                              blurRadius: 16,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEC4899),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                user?.initial ?? 'M',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user?.name ?? 'Mahasiswa Polije',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    user?.email ?? '',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.slate500,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFCE7F3),
                                          borderRadius:
                                              BorderRadius.circular(999),
                                        ),
                                        child: const Text(
                                          'Mahasiswa / User',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFFDB2777),
                                          ),
                                        ),
                                      ),
                                      if (user?.nim != null &&
                                          user!.nim!.isNotEmpty)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFEEF2FF),
                                            borderRadius:
                                                BorderRadius.circular(999),
                                          ),
                                          child: Text(
                                            'NIM: ${user.nim}',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.indigo600,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
          );
        },
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.title,
    required this.description,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.gray100),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.gray900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.gray500,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_rounded,
                size: 18,
                color: iconColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

