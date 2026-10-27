import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/image_url.dart';
import '../../core/utils/launcher.dart';
import '../../data/models/article.dart';
import '../../data/models/edu_material.dart';
import '../../data/models/user_complaint.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/material_service.dart';
import '../../data/services/user_portal_service.dart';
import 'user_shell_page.dart';

/// Halaman Dashboard User / Mahasiswa (`/user/dashboard`) — port 1:1 dari `pages/user/dashboard.jsx`.
class UserDashboardPage extends StatefulWidget {
  const UserDashboardPage({super.key});

  @override
  State<UserDashboardPage> createState() => _UserDashboardPageState();
}

class _UserDashboardPageState extends State<UserDashboardPage> {
  UserDashboardData? _data;
  List<EduMaterial> _materials = const [];
  bool _loading = true;
  bool _materialsLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _materialsLoading = true;
    });
    final dashFuture = UserPortalService.instance.getDashboardData();
    final matFuture = MaterialService.instance.getPublicMaterials(limit: 4);

    final dash = await dashFuture;
    if (mounted) {
      setState(() {
        _data = dash;
        _loading = false;
      });
    }

    final mats = await matFuture;
    if (mounted) {
      setState(() {
        _materials = mats;
        _materialsLoading = false;
      });
    }
  }

  String _formatDateId(DateTime dt, {bool withDayName = false}) {
    try {
      return DateFormat(
        withDayName ? 'EEEE, dd MMMM yyyy' : 'dd MMMM yyyy',
        'id_ID',
      ).format(dt);
    } catch (_) {
      return DateFormat('dd MMM yyyy').format(dt);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.user;
    final data = _data;

    return UserShellPage(
      title: 'Mahasiswa PolijeCare',
      subtitle: 'Pusat layanan pengaduan dan pendampingan mahasiswa',
      activePath: AppRoutes.userDashboard,
      body: RefreshIndicator(
        onRefresh: _loadAll,
        color: const Color(0xFF7C3AED),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Welcome Banner (`from-violet-600 to-indigo-700`) ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFF4338CA)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
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
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Ruang aman Anda untuk menyampaikan laporan dan mendapatkan dukungan penuh dari Satgas PPKPT Polije. Kami siap mendengar dan membantu Anda.',
                      style: TextStyle(
                        color: Color(0xEEFFFFFF),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── 1. Statistik Laporan Anda ──
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  'Statistik Laporan Anda',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.gray900,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _StatCard(
                label: 'TOTAL LAPORAN',
                value: _loading ? '-' : '${data?.total ?? 0}',
                sub: 'semua laporan Anda',
                icon: Icons.description_outlined,
                color: const Color(0xFF7C3AED),
                onTap: () => Navigator.of(context)
                    .pushReplacementNamed(AppRoutes.userHistoriPengaduan),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'DALAM PENINJAUAN',
                      value: _loading ? '-' : '${data?.processing ?? 0}',
                      sub: 'laporan sedang ditinjau',
                      icon: Icons.shield_outlined,
                      color: const Color(0xFF2563EB),
                      compact: true,
                      onTap: () => Navigator.of(context).pushReplacementNamed(
                        AppRoutes.userHistoriPengaduan,
                        arguments: {'status': 'approved'},
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatCard(
                      label: 'LAPORAN SELESAI',
                      value: _loading ? '-' : '${data?.completed ?? 0}',
                      sub: 'penanganan tuntas',
                      icon: Icons.check_circle_outline_rounded,
                      color: const Color(0xFF059669),
                      compact: true,
                      onTap: () => Navigator.of(context).pushReplacementNamed(
                        AppRoutes.userHistoriPengaduan,
                        arguments: {'status': 'completed'},
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── 2. Akses Cepat ──
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  'Akses Cepat',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.gray900,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _QuickActionBox(
                      title: 'Buat Laporan\nBaru',
                      icon: Icons.add_rounded,
                      iconBg: const Color(0xFFFFF1F2),
                      iconColor: const Color(0xFFF43F5E),
                      onTap: () => Navigator.of(context)
                          .pushReplacementNamed(AppRoutes.userBuatLaporan),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _QuickActionBox(
                      title: 'Riwayat\nPengaduan',
                      icon: Icons.description_outlined,
                      iconBg: const Color(0xFFF5F3FF),
                      iconColor: const Color(0xFF8B5CF6),
                      onTap: () => Navigator.of(context)
                          .pushReplacementNamed(AppRoutes.userHistoriPengaduan),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _QuickActionBox(
                      title: 'Ajukan\nPenanganan',
                      icon: Icons.calendar_today_outlined,
                      iconBg: const Color(0xFFEFF6FF),
                      iconColor: const Color(0xFF3B82F6),
                      onTap: () => Navigator.of(context).pushReplacementNamed(
                        AppRoutes.userCounselingRequest,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── 3. Aktivitas Laporan Terbaru ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: AppColors.gray100),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x08000000),
                      blurRadius: 14,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            'Aktivitas Laporan Terbaru',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: AppColors.gray900,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () => Navigator.of(context)
                              .pushReplacementNamed(
                                  AppRoutes.userHistoriPengaduan),
                          borderRadius: BorderRadius.circular(8),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 6, vertical: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Lihat Semua',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF7C3AED),
                                  ),
                                ),
                                SizedBox(width: 2),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  size: 18,
                                  color: Color(0xFF7C3AED),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_loading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF7C3AED),
                          ),
                        ),
                      )
                    else if (data == null || data.recentComplaints.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            vertical: 28, horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppColors.gray50,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.gray200),
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.description_outlined,
                                color: AppColors.gray400,
                                size: 24,
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Belum ada aktivitas laporan saat ini.',
                              style: TextStyle(
                                color: AppColors.gray500,
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Column(
                        children: [
                          for (final item in data.recentComplaints) ...[
                            _RecentComplaintTile(
                              item: item,
                              formattedDate: _formatDateId(item.createdAt),
                              onTap: () {
                                Navigator.of(context).pushNamed(
                                  AppRoutes.userDetailPengaduan,
                                  arguments: item.id,
                                );
                              },
                            ),
                            const SizedBox(height: 10),
                          ],
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── 4. Jadwal Penanganan Terdekat ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: AppColors.gray100),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x08000000),
                      blurRadius: 14,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Jadwal Penanganan Terdekat',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.gray900,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_loading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF4F46E5),
                          ),
                        ),
                      )
                    else if (data?.upcomingSchedule == null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            vertical: 28, horizontal: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF).withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: const Color(0xFFE0E7FF)),
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.calendar_today_outlined,
                                color: Color(0xFFA5B4FC),
                                size: 26,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Belum Ada Jadwal',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.gray900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Anda tidak memiliki jadwal penanganan yang aktif atau disetujui dalam waktu dekat.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: AppColors.gray500,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () =>
                                  Navigator.of(context).pushReplacementNamed(
                                AppRoutes.userCounselingRequest,
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.indigo600,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Ajukan Penanganan Baru',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      _UpcomingScheduleCard(
                        schedule: data!.upcomingSchedule!,
                        formatDate: (s) {
                          final dt = DateTime.tryParse(s);
                          return dt != null
                              ? _formatDateId(dt, withDayName: true)
                              : s;
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── 5. Bantuan Darurat Satgas (`dashboard.jsx`) ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFAF5FF), Colors.white],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: const Color(0xFFF3E8FF)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF43F5E),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x99F43F5E),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Bantuan Darurat Satgas',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.gray900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _EmergencyContactRow(
                      icon: Icons.phone_in_talk_outlined,
                      iconBg: const Color(0xFFFFF1F2),
                      iconColor: const Color(0xFFF43F5E),
                      label: 'HOTLINE 24/7',
                      value: data?.satgasPhone ?? '+62 812-3456-7890',
                      onTap: () => AppLauncher.openUrl(
                          'tel:${data?.satgasPhone ?? '+6281234567890'}'),
                    ),
                    const SizedBox(height: 14),
                    _EmergencyContactRow(
                      icon: Icons.mail_outline_rounded,
                      iconBg: const Color(0xFFEFF6FF),
                      iconColor: const Color(0xFF3B82F6),
                      label: 'EMAIL SATGAS',
                      value: data?.satgasEmail ?? 'satgas.ppkpt@polije.ac.id',
                      onTap: () => AppLauncher.openUrl(
                          'mailto:${data?.satgasEmail ?? 'satgas.ppkpt@polije.ac.id'}'),
                    ),
                    const SizedBox(height: 14),
                    _EmergencyContactRow(
                      icon: Icons.location_on_outlined,
                      iconBg: const Color(0xFFECFDF5),
                      iconColor: const Color(0xFF10B981),
                      label: 'LOKASI KANTOR',
                      value: data?.satgasLocation ??
                          'Gedung Rektorat Lt. 1, Politeknik Negeri Jember',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── 6. Ruang Aman & Rahasia Widget ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFECFDF5), Color(0xFFF0FDFA)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: const Color(0xFFD1FAE5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.shield_outlined,
                        color: Color(0xFF10B981),
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Ruang Aman & Rahasia',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF022C22),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'PolijeCare menjamin kerahasiaan penuh atas identitas dan cerita Anda. Sistem ini dienkripsi dan hanya dapat diakses oleh Satgas PPKPT yang terikat kode etik kerahasiaan.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF065F46),
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── 7. Materi Edukasi ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: AppColors.gray100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Materi Edukasi',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.gray900,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_materialsLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_materials.isEmpty)
                      const Text(
                        'Belum ada materi.',
                        style: TextStyle(color: AppColors.gray500),
                      )
                    else
                      Column(
                        children: [
                          for (final m in _materials) ...[
                            InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                final url = m.isFile
                                    ? MaterialService.instance
                                        .getFileUrl(m.filePath)
                                    : (m.link ?? '');
                                if (url.isNotEmpty) {
                                  AppLauncher.openUrl(url);
                                }
                              },
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 6),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 54,
                                      height: 54,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEEF2FF),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      alignment: Alignment.center,
                                      child: Icon(
                                        m.isFile
                                            ? Icons.description_outlined
                                            : Icons.menu_book_outlined,
                                        color: AppColors.indigo600,
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            m.kategori.toUpperCase(),
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.gray400,
                                              letterSpacing: 0.6,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            m.judul,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.gray900,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ],
                      ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () =>
                            Navigator.of(context).pushNamed(AppRoutes.edukasi),
                        style: TextButton.styleFrom(
                          backgroundColor: AppColors.gray50,
                          foregroundColor: AppColors.gray600,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Jelajahi Semua Materi',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── 8. Artikel & Pengumuman ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: AppColors.gray100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Artikel & Pengumuman',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.gray900,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_loading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (data == null || data.recentArticles.isEmpty)
                      const Text(
                        'Belum ada artikel edukasi.',
                        style: TextStyle(color: AppColors.gray500),
                      )
                    else
                      Column(
                        children: [
                          for (final Article art in data.recentArticles) ...[
                            _ArticleMiniRow(article: art),
                            const SizedBox(height: 12),
                          ],
                        ],
                      ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () =>
                            Navigator.of(context).pushNamed(AppRoutes.landing),
                        style: TextButton.styleFrom(
                          backgroundColor: AppColors.gray50,
                          foregroundColor: AppColors.gray600,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Jelajahi Semua Artikel',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.sub,
    required this.icon,
    required this.color,
    this.compact = false,
    required this.onTap,
  });

  final String label;
  final String value;
  final String sub;
  final IconData icon;
  final Color color;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(compact ? 14 : 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.gray100),
          ),
          child: Row(
            children: [
              Container(
                width: compact ? 40 : 48,
                height: compact ? 40 : 48,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: Colors.white, size: compact ? 18 : 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: compact ? 9 : 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.gray400,
                        letterSpacing: 0.7,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: compact ? 22 : 26,
                        fontWeight: FontWeight.bold,
                        color: AppColors.gray900,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sub,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: AppColors.gray400,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionBox extends StatelessWidget {
  const _QuickActionBox({
    required this.title,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.gray100),
          ),
          child: Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.gray800,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentComplaintTile extends StatelessWidget {
  const _RecentComplaintTile({
    required this.item,
    required this.formattedDate,
    required this.onTap,
  });

  final UserComplaint item;
  final String formattedDate;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    Color badgeBg;
    Color badgeFg;
    String badgeText;
    switch (item.status) {
      case 'completed':
        badgeBg = const Color(0xFFD1FAE5);
        badgeFg = const Color(0xFF047857);
        badgeText = 'LAPORAN SELESAI';
        break;
      case 'approved':
        badgeBg = const Color(0xFFDBEAFE);
        badgeFg = const Color(0xFF1D4ED8);
        badgeText = 'SEDANG DITANGANI';
        break;
      case 'rejected':
        badgeBg = const Color(0xFFFFE4E6);
        badgeFg = const Color(0xFFBE123C);
        badgeText = 'JADWAL ULANG';
        break;
      default:
        badgeBg = const Color(0xFFFEF3C7);
        badgeFg = const Color(0xFFB45309);
        badgeText = 'SEDANG DITINJAU';
    }

    return Material(
      color: AppColors.gray50,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    formattedDate,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.gray400,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      badgeText,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: badgeFg,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.gray900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                item.categoryName,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.gray500,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UpcomingScheduleCard extends StatelessWidget {
  const _UpcomingScheduleCard({
    required this.schedule,
    required this.formatDate,
  });

  final CounselingScheduleItem schedule;
  final String Function(String) formatDate;

  @override
  Widget build(BuildContext context) {
    final isOnline = schedule.metode.toLowerCase() == 'online';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE0E7FF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE0E7FF)),
            ),
            child: const Text(
              'DISETUJUI',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppColors.indigo600,
                letterSpacing: 0.8,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            formatDate(schedule.tanggal),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.gray900,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(
                Icons.access_time_rounded,
                size: 16,
                color: AppColors.indigo600,
              ),
              const SizedBox(width: 6),
              Text(
                '${schedule.jamMulaiShort} - ${schedule.jamSelesaiShort} WIB',
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.indigo600,
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(color: AppColors.gray100, height: 1),
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SATGAS BERTUGAS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.gray400,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.favorite_rounded,
                          size: 14,
                          color: Color(0xFFF43F5E),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            schedule.counselorName ?? 'Tim Satgas PPKPT',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.gray800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'METODE & LOKASI',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.gray400,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          isOnline
                              ? Icons.videocam_outlined
                              : Icons.location_on_outlined,
                          size: 15,
                          color: isOnline
                              ? const Color(0xFF0EA5E9)
                              : const Color(0xFF10B981),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            isOnline
                                ? 'Penanganan Online'
                                : 'Tatap Muka (Offline)',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.gray800,
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
          if (isOnline &&
              schedule.meetingLink != null &&
              schedule.meetingLink!.isNotEmpty) ...[
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: () => AppLauncher.openUrl(schedule.meetingLink!),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.indigo600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Masuk Ruangan Online'),
            ),
          ],
          if (!isOnline &&
              schedule.lokasi != null &&
              schedule.lokasi!.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.gray50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.gray100),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: AppColors.gray400,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Lokasi Tatap Muka: ${schedule.lokasi}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.gray700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmergencyContactRow extends StatelessWidget {
  const _EmergencyContactRow({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.value,
    this.onTap,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.gray400,
                    letterSpacing: 0.7,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gray900,
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

class _ArticleMiniRow extends StatelessWidget {
  const _ArticleMiniRow({required this.article});

  final Article article;

  @override
  Widget build(BuildContext context) {
    final imgUrl = normalizeImageUrl(article.image) ?? '';
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        Navigator.of(context).pushNamed(
          AppRoutes.artikelDetail,
          arguments: article.slug,
        );
      },
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 68,
              height: 68,
              color: const Color(0xFFF0F9FF),
              child: imgUrl.isNotEmpty
                  ? Image.network(
                      imgUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.menu_book_outlined,
                        color: Color(0xFF7DD3FC),
                      ),
                    )
                  : const Icon(
                      Icons.menu_book_outlined,
                      color: Color(0xFF7DD3FC),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  article.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gray900,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  article.excerpt,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.gray500,
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

