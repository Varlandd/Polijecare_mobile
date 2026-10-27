import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../data/services/auth_service.dart';
import '../auth/protected_route.dart';
import 'widgets/konselor_sidebar.dart';

/// Kerangka halaman Satgas / Konselor (`role = konselor`) setelah berhasil login.
/// Menyediakan `Topbar` (`Layanan / Satgas`) + `KonselorSidebar` (`Satgas Dashboard`)
/// sesuai `pages/konselor/dashboard.jsx`, `components/layout/Topbar.jsx`, & `Sidebar.jsx` di web.
class KonselorShellPage extends StatelessWidget {
  const KonselorShellPage({
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
      requiredRoles: const ['konselor', 'operator', 'admin'],
      child: ListenableBuilder(
        listenable: AuthService.instance,
        builder: (context, _) {
          final user = AuthService.instance.user;
          return Scaffold(
            key: scaffoldKey,
            backgroundColor: const Color(0xFFF8F9FA),
            drawer: KonselorSidebar(activePath: activePath),
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
                        // Breadcrumb `Layanan / Satgas` sesuai `Topbar.jsx`
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
                              'Satgas',
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
                        user?.initial ?? 'S',
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
                      // Welcome Section sesuai `pages/konselor/dashboard.jsx`
                      Text.rich(
                        TextSpan(
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: AppColors.gray900,
                            height: 1.2,
                          ),
                          children: [
                            const TextSpan(text: 'Selamat Datang, '),
                            TextSpan(
                              text:
                                  'Satgas ${user?.firstName ?? 'Konselor'}!',
                              style: const TextStyle(
                                color: Color(0xFF6666DE),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 13.5,
                          color: AppColors.gray500,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Action Buttons `Lihat Jadwal` & `Lihat Pengaduan` sesuai `konselor/dashboard.jsx`
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () {
                              Navigator.of(context).pushReplacementNamed(
                                AppRoutes.konselorCounselingDashboard,
                              );
                            },
                            icon: const Icon(
                              Icons.calendar_today_outlined,
                              size: 16,
                              color: AppColors.gray700,
                            ),
                            label: const Text(
                              'Lihat Jadwal',
                              style: TextStyle(
                                color: AppColors.gray700,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              side: const BorderSide(color: AppColors.gray200),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).pushReplacementNamed(
                                AppRoutes.konselorPengaduan,
                              );
                            },
                            icon: const Icon(
                              Icons.description_outlined,
                              size: 16,
                              color: Colors.white,
                            ),
                            label: const Text(
                              'Lihat Pengaduan',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6666DE),
                              elevation: 2,
                              shadowColor: const Color(0x4D6666DE),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Kartu Identitas Satgas yang sedang login
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
                                color: const Color(0xFF8B5CF6),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                user?.initial ?? 'S',
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
                                    user?.name ?? 'Konselor PolijeCare',
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
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF3E8FF),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      user?.roleLabel ?? 'Satgas (Petugas)',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF7C3AED),
                                      ),
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
                ),
          );
        },
      ),
    );
  }
}

