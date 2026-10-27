import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/user_complaint.dart';
import '../../data/services/user_portal_service.dart';
import 'user_shell_page.dart';

/// Halaman Histori Pengaduan (`/user/histori-pengaduan`)
/// — port 1:1 dari `pages/user/histori-pengaduan.jsx`.
class HistoriPengaduanPage extends StatefulWidget {
  const HistoriPengaduanPage({
    super.key,
    this.initialStatus = '',
  });

  final String initialStatus;

  @override
  State<HistoriPengaduanPage> createState() => _HistoriPengaduanPageState();
}

class _HistoriPengaduanPageState extends State<HistoriPengaduanPage> {
  final _searchCtrl = TextEditingController();
  late String _statusFilter;
  List<UserComplaint> _allComplaints = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _statusFilter = widget.initialStatus;
    _fetchComplaints();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchComplaints() async {
    setState(() => _loading = true);
    final res = await UserPortalService.instance.getHistoriPengaduan();
    if (!mounted) return;
    setState(() {
      _allComplaints = res;
      _loading = false;
    });
  }

  List<UserComplaint> get _filteredComplaints {
    final q = _searchCtrl.text.trim().toLowerCase();
    return _allComplaints.where((c) {
      final matchStatus = _statusFilter.isEmpty || c.status == _statusFilter;
      final matchSearch = q.isEmpty ||
          c.title.toLowerCase().contains(q) ||
          c.reportReference.toLowerCase().contains(q) ||
          c.categoryName.toLowerCase().contains(q);
      return matchStatus && matchSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final total = _allComplaints.length;
    final pending = _allComplaints.where((c) => c.status == 'pending').length;
    final approved = _allComplaints.where((c) => c.status == 'approved').length;
    final completed =
        _allComplaints.where((c) => c.status == 'completed').length;
    final filtered = _filteredComplaints;

    return UserShellPage(
      title: 'Histori Pengaduan',
      subtitle: 'Riwayat dan status tindak lanjut laporan Anda',
      activePath: AppRoutes.userHistoriPengaduan,
      body: RefreshIndicator(
        onRefresh: _fetchComplaints,
        color: const Color(0xFF7C3AED),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Page Header ──
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'RIWAYAT SAYA',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF8B5CF6),
                            letterSpacing: 1.0,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Histori Pengaduan',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.gray900,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Daftar laporan tindak kekerasan yang pernah Anda ajukan',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.gray500,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: _fetchComplaints,
                    icon: const Icon(
                      Icons.refresh_rounded,
                      size: 16,
                      color: AppColors.gray600,
                    ),
                    label: const Text(
                      'Refresh',
                      style: TextStyle(
                        color: AppColors.gray600,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: AppColors.gray200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── 4 Stat Cards (`histori-pengaduan.jsx`) ──
              Row(
                children: [
                  Expanded(
                    child: _MiniStatCard(
                      label: 'TOTAL LAPORAN',
                      value: '$total',
                      sub: 'semua laporan Anda',
                      icon: Icons.description_outlined,
                      color: const Color(0xFF7C3AED),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MiniStatCard(
                      label: 'PENINJAUAN',
                      value: '$pending',
                      sub: 'laporan sedang ditinjau',
                      icon: Icons.access_time_rounded,
                      color: const Color(0xFFF59E0B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _MiniStatCard(
                      label: 'DITANGANI',
                      value: '$approved',
                      sub: 'laporan sedang ditangani',
                      icon: Icons.shield_outlined,
                      color: const Color(0xFF2563EB),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MiniStatCard(
                      label: 'SELESAI',
                      value: '$completed',
                      sub: 'kasus selesai',
                      icon: Icons.check_circle_outline_rounded,
                      color: const Color(0xFF059669),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Filter Bar ──
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.gray100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: _searchCtrl,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              hintText: 'Cari...',
                              prefixIcon: const Icon(
                                Icons.search_rounded,
                                size: 18,
                                color: AppColors.gray400,
                              ),
                              filled: true,
                              fillColor: AppColors.gray50,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<String>(
                            initialValue: _statusFilter,
                            isExpanded: true,
                            items: const [
                              DropdownMenuItem(
                                  value: '', child: Text('Status')),
                              DropdownMenuItem(
                                  value: 'pending',
                                  child: Text('Sedang Ditinjau')),
                              DropdownMenuItem(
                                  value: 'approved',
                                  child: Text('Sedang Ditangani')),
                              DropdownMenuItem(
                                  value: 'completed', child: Text('Selesai')),
                              DropdownMenuItem(
                                  value: 'rejected',
                                  child: Text('Jadwalkan Ulang')),
                            ],
                            onChanged: (v) =>
                                setState(() => _statusFilter = v ?? ''),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: AppColors.gray50,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${filtered.length} DARI $total LAPORAN',
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.gray400,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // ── Card List ──
              if (_loading)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 60),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: AppColors.gray100),
                  ),
                  child: const Column(
                    children: [
                      CircularProgressIndicator(color: Color(0xFF7C3AED)),
                      SizedBox(height: 14),
                      Text(
                        'Memuat data laporan...',
                        style: TextStyle(
                          color: AppColors.gray500,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )
              else if (filtered.isEmpty)
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 56, horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: AppColors.gray100),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F3FF),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.description_outlined,
                          color: Color(0xFFA78BFA),
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Tidak Ada Laporan',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.gray900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _searchCtrl.text.isNotEmpty || _statusFilter.isNotEmpty
                            ? 'Tidak ada laporan yang cocok dengan filter.'
                            : 'Anda belum pernah mengajukan laporan pengaduan.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.gray400,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Column(
                  children: [
                    for (final item in filtered) ...[
                      _ComplaintHistoryCard(
                        item: item,
                        onViewDetail: () {
                          Navigator.of(context).pushNamed(
                            AppRoutes.userDetailPengaduan,
                            arguments: item.id,
                          );
                        },
                      ),
                      const SizedBox(height: 14),
                    ],
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  const _MiniStatCard({
    required this.label,
    required this.value,
    required this.sub,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final String sub;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gray100),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: AppColors.gray400,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.gray900,
                    height: 1.1,
                  ),
                ),
                Text(
                  sub,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.gray400,
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

class _ComplaintHistoryCard extends StatelessWidget {
  const _ComplaintHistoryCard({
    required this.item,
    required this.onViewDetail,
  });

  final UserComplaint item;
  final VoidCallback onViewDetail;

  @override
  Widget build(BuildContext context) {
    // Status config (`getStatusConfig` in `histori-pengaduan.jsx`)
    String statusLabel;
    Color statusBg;
    Color statusFg;
    Color dotColor;
    switch (item.status) {
      case 'pending':
        statusLabel = 'SEDANG DITINJAU';
        statusBg = const Color(0xFFFFFBEB);
        statusFg = const Color(0xFFB45309);
        dotColor = const Color(0xFFFBBF24);
        break;
      case 'approved':
        statusLabel = 'SEDANG DITANGANI';
        statusBg = const Color(0xFFEFF6FF);
        statusFg = const Color(0xFF1D4ED8);
        dotColor = const Color(0xFF3B82F6);
        break;
      case 'completed':
        statusLabel = 'LAPORAN SELESAI';
        statusBg = const Color(0xFFECFDF5);
        statusFg = const Color(0xFF047857);
        dotColor = const Color(0xFF10B981);
        break;
      case 'rejected':
        statusLabel = 'JADWALKAN ULANG';
        statusBg = const Color(0xFFFFF1F2);
        statusFg = const Color(0xFFBE123C);
        dotColor = const Color(0xFFF43F5E);
        break;
      default:
        statusLabel = item.status.toUpperCase();
        statusBg = AppColors.gray50;
        statusFg = AppColors.gray600;
        dotColor = AppColors.gray400;
    }

    // Urgency config (`getUrgencyConfig` in `histori-pengaduan.jsx`)
    String urgLabel;
    Color urgBg;
    Color urgFg;
    switch (item.urgencyLevel.toLowerCase()) {
      case 'high':
      case 'tinggi':
        urgLabel = 'TINGGI';
        urgBg = const Color(0xFFFEF2F2);
        urgFg = const Color(0xFFB91C1C);
        break;
      case 'medium':
      case 'sedang':
        urgLabel = 'SEDANG';
        urgBg = const Color(0xFFFFF7ED);
        urgFg = const Color(0xFFC2410C);
        break;
      case 'low':
      case 'rendah':
      default:
        urgLabel = 'RENDAH';
        urgBg = const Color(0xFFEFF6FF);
        urgFg = const Color(0xFF1D4ED8);
    }

    final dateStr = DateFormat('dd MMM yyyy').format(item.createdAt);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.gray100),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ref ID + Urgency badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.gray100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        item.reportReference,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.gray600,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: urgBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        urgLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: urgFg,
                          letterSpacing: 0.7,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Judul & Korban
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.gray900,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.person_outline_rounded,
                      size: 13,
                      color: AppColors.gray400,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        item.victimName ?? 'Korban tidak disebutkan',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.gray400,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Info Kategori
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.gray50,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.shield_outlined,
                          size: 14,
                          color: Color(0xFF8B5CF6),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'KATEGORI',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: AppColors.gray400,
                                letterSpacing: 0.6,
                              ),
                            ),
                            Text(
                              item.categoryName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.gray800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Info Satgas
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.gray50,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.person_outline_rounded,
                          size: 14,
                          color: Color(0xFF3B82F6),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'SATGAS',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: AppColors.gray400,
                                letterSpacing: 0.6,
                              ),
                            ),
                            Text(
                              item.counselorName ?? 'Belum ditugaskan',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.gray800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Status & Tanggal
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: dotColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            statusLabel,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: statusFg,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 12,
                          color: AppColors.gray400,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          dateStr,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.gray500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Card Footer: Lihat Detail
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              color: Color(0xFFFAFAFA),
              border: Border(top: BorderSide(color: AppColors.gray100)),
            ),
            child: OutlinedButton.icon(
              onPressed: onViewDetail,
              icon: const Icon(
                Icons.visibility_outlined,
                size: 16,
                color: Color(0xFF7C3AED),
              ),
              label: const Text(
                'Lihat Detail',
                style: TextStyle(
                  color: Color(0xFF7C3AED),
                  fontWeight: FontWeight.bold,
                  fontSize: 12.5,
                ),
              ),
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                side: const BorderSide(color: AppColors.gray200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

