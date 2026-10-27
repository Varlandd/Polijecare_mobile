import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../data/services/auth_service.dart';
import '../auth/protected_route.dart';
import 'widgets/operator_sidebar.dart';

/// Kerangka halaman Super Admin (`role = operator`) setelah berhasil login.
/// Menyediakan Header + Sidebar Drawer Super Admin sesuai `pages/operator/dashboard.jsx`
/// & `components/layout/Sidebar.jsx` di web.
class OperatorShellPage extends StatelessWidget {
  const OperatorShellPage({
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
      requiredRoles: const ['operator', 'admin'],
      child: ListenableBuilder(
        listenable: AuthService.instance,
        builder: (context, _) {
          final user = AuthService.instance.user;
          return Scaffold(
            key: scaffoldKey,
            backgroundColor: AppColors.slate50,
            drawer: OperatorSidebar(activePath: activePath),
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
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: AppColors.gray200),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => scaffoldKey.currentState?.openDrawer(),
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(
                          Icons.menu_rounded,
                          size: 20,
                          color: AppColors.slate800,
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
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.slate500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
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
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE0E7FF)),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        user?.initial ?? 'A',
                        style: const TextStyle(
                          color: AppColors.indigo600,
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
                      // Welcome Banner sesuai `operator/dashboard.jsx`
                      Text.rich(
                        TextSpan(
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                            height: 1.2,
                          ),
                          children: [
                            const TextSpan(text: 'Selamat Datang, Satgas '),
                            TextSpan(
                              text: '${user?.firstName ?? 'Admin'}!',
                              style: const TextStyle(
                                  color: AppColors.indigo600),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Anda berhasil masuk sebagai Super Admin PolijeCare. Gunakan menu di pojok kiri atas untuk mengakses modul manajemen.',
                        style: TextStyle(
                          fontSize: 13.5,
                          color: AppColors.slate500,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 20),
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
                                color: const Color(0xFF6366F1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                user?.initial ?? 'A',
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
                                    user?.name ?? 'Operator PolijeCare',
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
                                      color: const Color(0xFFEEF2FF),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      user?.roleLabel ?? 'Super Admin',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.indigo600,
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

