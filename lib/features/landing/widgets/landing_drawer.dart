import 'package:flutter/material.dart';

import '../../../app/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/services/auth_service.dart';

/// Item menu navbar — sama dengan `navLinks` di `Navbar.jsx`.
class NavLink {
  final String name;
  final String href;
  final IconData icon;
  const NavLink(this.name, this.href, this.icon);
}

const List<NavLink> kNavLinks = [
  NavLink('Beranda', '#hero', Icons.home_outlined),
  NavLink('Tentang Kami', '#about', Icons.info_outline_rounded),
  NavLink('Cara Melapor', '#services', Icons.description_outlined),
  NavLink('Artikel', '#articles', Icons.article_outlined),
  NavLink('Edukasi', '#materials', Icons.menu_book_outlined),
  NavLink('Lacak Laporan', AppRoutes.lacakLaporan, Icons.search_rounded),
  NavLink('Kontak', '#contact', Icons.phone_outlined),
];

/// Menu mobile (drawer) — versi HP dari `Navbar.jsx` web.
class LandingDrawer extends StatelessWidget {
  const LandingDrawer({
    super.key,
    required this.activeSection,
    required this.onNavigate,
    required this.onLogin,
  });

  final String activeSection;
  final ValueChanged<String> onNavigate;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AuthService.instance,
      builder: (context, _) {
        final auth = AuthService.instance;
        final isAuthenticated = auth.isAuthenticated;

        return Drawer(
          backgroundColor: Colors.white,
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 12, 12),
                  child: Row(
                    children: [
                      Image.asset('assets/images/logo_polijecare_new.png',
                          height: 40),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded,
                            color: AppColors.navy),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppColors.gray200),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                    children: [
                      for (final link in kNavLinks)
                        _NavTile(
                          link: link,
                          active: link.href == '#$activeSection',
                          onTap: () => onNavigate(link.href),
                        ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppColors.gray100),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: isAuthenticated
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(
                              height: 48,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  Navigator.of(context)
                                      .pushNamed(auth.redirectPath);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.navy,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: const Text('Dashboard'),
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              height: 48,
                              child: OutlinedButton(
                                onPressed: () async {
                                  Navigator.of(context).pop();
                                  await auth.logout();
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.navy,
                                  side: const BorderSide(
                                      color: AppColors.navy, width: 2),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: const Text(
                                  'Keluar',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                          ],
                        )
                      : SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: onLogin,
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                            child: const Text('Masuk'),
                          ),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.link,
    required this.active,
    required this.onTap,
  });

  final NavLink link;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: active ? AppColors.navy : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(link.icon,
                    size: 22,
                    color: active ? Colors.white : AppColors.gray600),
                const SizedBox(width: 14),
                Text(
                  link.name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: active ? Colors.white : AppColors.gray600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
