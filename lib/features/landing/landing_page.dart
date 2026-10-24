import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../core/theme/app_colors.dart';
import 'widgets/about_section.dart';
import 'widgets/articles_section.dart';
import 'widgets/contact_section.dart';
import 'widgets/footer_section.dart';
import 'widgets/hero_section.dart';
import 'widgets/landing_drawer.dart';
import 'widgets/materials_section.dart';
import 'widgets/services_section.dart';

/// Halaman utama (setara `pages/LandingPage.jsx`):
/// Navbar → Hero → About → Services → Articles → Materials → Contact → Footer.
class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _scrollController = ScrollController();

  // Anchor tiap section (#hero, #about, dst. di web)
  final Map<String, GlobalKey> _sectionKeys = {
    'hero': GlobalKey(),
    'about': GlobalKey(),
    'services': GlobalKey(),
    'articles': GlobalKey(),
    'materials': GlobalKey(),
    'contact': GlobalKey(),
  };

  String _activeSection = 'hero';
  bool _isScrolled = false;

  // Untuk refresh data artikel & materi saat pull-to-refresh
  int _refreshSeed = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  /// ScrollSpy — menandai section aktif seperti navbar web.
  void _onScroll() {
    final scrolled = _scrollController.offset > 40;
    String current = _activeSection;
    for (final entry in _sectionKeys.entries) {
      final ctx = entry.value.currentContext;
      if (ctx == null) continue;
      final box = ctx.findRenderObject() as RenderBox?;
      if (box == null || !box.attached) continue;
      final top = box.localToGlobal(Offset.zero).dy;
      final bottom = top + box.size.height;
      if (top <= 160 && bottom >= 160) current = entry.key;
    }
    if (scrolled != _isScrolled || current != _activeSection) {
      setState(() {
        _isScrolled = scrolled;
        _activeSection = current;
      });
    }
  }

  void _scrollTo(String section) {
    final ctx = _sectionKeys[section]?.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOutCubic,
    );
  }

  /// Menangani klik menu navbar (anchor `#...` atau route).
  void _handleNav(String href) {
    Navigator.of(context).maybePop(); // tutup drawer jika terbuka
    if (href.startsWith('#')) {
      Future.delayed(const Duration(milliseconds: 250),
          () => _scrollTo(href.substring(1)));
    } else {
      Navigator.of(context).pushNamed(href);
    }
  }

  Future<void> _onRefresh() async {
    setState(() => _refreshSeed++);
    await Future.delayed(const Duration(milliseconds: 600));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.softWhite,
      endDrawer: LandingDrawer(
        activeSection: _activeSection,
        onNavigate: _handleNav,
        onLogin: () {
          Navigator.of(context).pop();
          Navigator.of(context).pushNamed(AppRoutes.login);
        },
      ),
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        color: AppColors.navy,
        onRefresh: _onRefresh,
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              HeroSection(key: _sectionKeys['hero']),
              AboutSection(
                key: _sectionKeys['about'],
                onContact: () => _scrollTo('contact'),
              ),
              ServicesSection(key: _sectionKeys['services']),
              ArticlesSection(
                key: _sectionKeys['articles'],
                refreshSeed: _refreshSeed,
              ),
              MaterialsSection(
                key: _sectionKeys['materials'],
                refreshSeed: _refreshSeed,
              ),
              ContactSection(key: _sectionKeys['contact']),
              FooterSection(onNavigate: _handleNav),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      toolbarHeight: _isScrolled ? 60 : 68,
      backgroundColor: Colors.white,
      elevation: _isScrolled ? 2 : 0,
      shadowColor: Colors.black12,
      automaticallyImplyLeading: false,
      titleSpacing: 16,
      shape: const Border(
        bottom: BorderSide(color: AppColors.gray100),
      ),
      title: GestureDetector(
        onTap: () => _scrollTo('hero'),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/logo_polije.png', height: 34),
            Container(
              width: 1,
              height: 28,
              margin: const EdgeInsets.symmetric(horizontal: 10),
              color: AppColors.gray200,
            ),
            Image.asset('assets/images/logo_polijecare_new.png', height: 38),
          ],
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Material(
            color: AppColors.gray50,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.gray200),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _scaffoldKey.currentState?.openEndDrawer(),
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Icons.menu_rounded, color: AppColors.navy, size: 26),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

