import 'package:flutter/material.dart';

import '../../../app/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/services/auth_service.dart';
import '../../operator/widgets/operator_sidebar.dart';

/// Konfigurasi menu User (Mahasiswa/Pelapor) persis seperti `USER_MENU` di `Sidebar.jsx`.
const List<OperatorMenuSection> kUserMenu = [
  OperatorMenuSection(
    category: 'UTAMA',
    items: [
      OperatorMenuItem(
        name: 'Dashboard',
        icon: Icons.home_outlined,
        path: AppRoutes.userDashboard,
      ),
    ],
  ),
  OperatorMenuSection(
    category: 'LAYANAN PENGADUAN',
    items: [
      OperatorMenuItem(
        name: 'Buat Laporan',
        icon: Icons.description_outlined,
        path: AppRoutes.userBuatLaporan,
      ),
      OperatorMenuItem(
        name: 'Histori Pengaduan',
        icon: Icons.access_time_rounded,
        path: AppRoutes.userHistoriPengaduan,
      ),
    ],
  ),
  OperatorMenuSection(
    category: 'AKUN',
    items: [
      OperatorMenuItem(
        name: 'Profil Saya',
        icon: Icons.person_outline_rounded,
        path: AppRoutes.profile,
      ),
    ],
  ),
];

/// Sidebar Drawer User / Mahasiswa (`role = user`) — port 1:1 dari `Sidebar.jsx`.
class UserSidebar extends StatelessWidget {
  const UserSidebar({
    super.key,
    required this.activePath,
  });

  final String activePath;

  /// Warna identitas `ROLE_META.user` di `Sidebar.jsx`: `#ec4899` (Pink-500).
  static const Color _metaColor = Color(0xFFEC4899);

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
    final user = AuthService.instance.user;

    return Drawer(
      backgroundColor: Colors.white,
      width: 288,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header (`ROLE_META.user`: User Dashboard) ──
            Container(
              padding: const EdgeInsets.fromLTRB(24, 24, 16, 24),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.gray100),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _metaColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x33EC4899),
                          blurRadius: 16,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'PC',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 19,
                        letterSpacing: -0.8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PolijeCare',
                          style: TextStyle(
                            color: Color(0xFF0F172A),
                            fontWeight: FontWeight.bold,
                            fontSize: 19,
                            height: 1.1,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'User Dashboard',
                          style: TextStyle(
                            color: AppColors.slate500,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.chevron_left_rounded,
                      color: AppColors.gray400,
                      size: 26,
                    ),
                  ),
                ],
              ),
            ),

            // ── Menu (`USER_MENU`) ──
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  for (final section in kUserMenu) ...[
                    Padding(
                      padding: const EdgeInsets.only(
                          left: 14, bottom: 10, top: 8),
                      child: Text(
                        section.category,
                        style: const TextStyle(
                          color: AppColors.gray400,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    for (final item in section.items)
                      _UserSidebarTile(
                        item: item,
                        isActive: activePath == item.path,
                        onTap: () {
                          Navigator.of(context).pop();
                          if (activePath != item.path) {
                            Navigator.of(context)
                                .pushReplacementNamed(item.path);
                          }
                        },
                      ),
                    const SizedBox(height: 14),
                  ],
                ],
              ),
            ),

            // ── Footer / User Info + Logout ──
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.gray50.withValues(alpha: 0.6),
                border: const Border(
                  top: BorderSide(color: AppColors.gray100),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _metaColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x26EC4899),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      user?.initial ?? 'M',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
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
                          user?.firstName ?? 'Mahasiswa',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          user?.roleLabel ?? 'User / Pelapor',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.slate500,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => _handleLogout(context),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFFFE4E6)),
                          color: const Color(0xFFFFF1F2),
                        ),
                        child: const Icon(
                          Icons.logout_rounded,
                          color: Color(0xFFE11D48),
                          size: 20,
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

class _UserSidebarTile extends StatelessWidget {
  const _UserSidebarTile({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  final OperatorMenuItem item;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: isActive ? AppColors.indigo600 : Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        elevation: isActive ? 4 : 0,
        shadowColor: const Color(0x4D4F46E5),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Stack(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                child: Row(
                  children: [
                    Icon(
                      item.icon,
                      size: 22,
                      color: isActive ? Colors.white : AppColors.slate600,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        item.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isActive ? Colors.white : AppColors.slate600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (isActive)
                Positioned(
                  right: 0,
                  top: 14,
                  bottom: 14,
                  child: Container(
                    width: 5,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.horizontal(
                        left: Radius.circular(999),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

