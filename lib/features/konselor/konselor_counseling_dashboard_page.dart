import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../data/services/konselor_portal_service.dart';
import 'konselor_shell_page.dart';

/// Halaman Jadwal Konseling & Pendampingan Satgas (`/konselor/counseling-dashboard`).
/// Porting 1:1 dari `pages/konselor/counseling-dashboard.jsx` di web PolijeCare.
class KonselorCounselingDashboardPage extends StatefulWidget {
  const KonselorCounselingDashboardPage({super.key});

  @override
  State<KonselorCounselingDashboardPage> createState() =>
      _KonselorCounselingDashboardPageState();
}

class _KonselorCounselingDashboardPageState
    extends State<KonselorCounselingDashboardPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedStatus = 'all';
  String _selectedMetode = 'all';
  String _dateFrom = '';

  bool _loading = true;
  List<SatgasSessionRecord> _schedules = [];

  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSchedules() async {
    setState(() => _loading = true);
    try {
      final list = await KonselorPortalService.instance.getSchedules(
        search: _searchCtrl.text,
        status: _selectedStatus,
        metode: _selectedMetode,
        dateFrom: _dateFrom,
      );
      if (!mounted) return;
      setState(() => _schedules = list);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _resetFilters() {
    setState(() {
      _searchCtrl.clear();
      _selectedStatus = 'all';
      _selectedMetode = 'all';
      _dateFrom = '';
    });
    _loadSchedules();
  }

  Future<void> _showScheduleDetailModal(SatgasSessionRecord sched) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.event_note_rounded,
                color: Color(0xFF4F46E5),
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Detail Sesi Penanganan',
                style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildModalRow('Pihak / Pelapor', sched.counseleeName),
              _buildModalRow(
                  'NIM / ID', sched.guestNim.isNotEmpty ? sched.guestNim : '-'),
              _buildModalRow('Kategori Kasus', sched.jenisPengaduan),
              _buildModalRow('Tanggal Sesi', sched.tanggal),
              _buildModalRow(
                  'Waktu', '${sched.jamMulai} - ${sched.jamSelesai} WIB'),
              _buildModalRow('Metode', sched.metode.toUpperCase()),
              _buildModalRow('Lokasi / Media', sched.lokasi),
              _buildModalRow('Satgas PJ', sched.counselorName),
              if (sched.keteranganPihak.isNotEmpty) ...[
                const Divider(height: 18),
                const Text(
                  'KETERANGAN PIHAK:',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.gray500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  sched.keteranganPihak,
                  style: const TextStyle(fontSize: 12.5, height: 1.4),
                ),
              ],
              if (sched.saranKonselor.isNotEmpty) ...[
                const SizedBox(height: 10),
                const Text(
                  'SARAN / TINDAK LANJUT SATGAS:',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF059669),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  sched.saranKonselor,
                  style: const TextStyle(fontSize: 12.5, height: 1.4),
                ),
              ],
            ],
          ),
        ),
        actions: [
          if (sched.status != 'completed' && sched.status != 'cancelled') ...[
            TextButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                await KonselorPortalService.instance.updateScheduleStatus(
                  sched.id,
                  'cancelled',
                );
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Jadwal sesi telah dibatalkan.'),
                    backgroundColor: Color(0xFFE11D48),
                  ),
                );
                _loadSchedules();
              },
              child: const Text(
                'Batalkan',
                style: TextStyle(color: Color(0xFFE11D48)),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                await KonselorPortalService.instance.updateScheduleStatus(
                  sched.id,
                  'completed',
                );
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Sesi ditandai telah selesai!'),
                    backgroundColor: Color(0xFF059669),
                  ),
                );
                _loadSchedules();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Tandai Selesai'),
            ),
          ],
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Widget _buildModalRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.gray500,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.gray900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final total = _schedules.length;
    final todayCount = _schedules.where((s) => s.tanggal == todayStr).length;
    final upcomingCount =
        _schedules.where((s) => s.tanggal.compareTo(todayStr) > 0).length;
    final pendingCount =
        _schedules.where((s) => s.status == 'pending').length;
    final approvedCount =
        _schedules.where((s) => s.status == 'approved').length;
    final completedCount =
        _schedules.where((s) => s.status == 'completed').length;
    final cancelledCount =
        _schedules.where((s) => s.status == 'cancelled').length;

    return KonselorShellPage(
      title: 'Jadwal Konseling',
      subtitle: 'Kelola jadwal sesi pendampingan dan konseling Satgas.',
      activePath: AppRoutes.konselorDashboard,
      body: RefreshIndicator(
        color: const Color(0xFF4F46E5),
        onRefresh: _loadSchedules,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Jadwal Penanganan',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.gray900,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Pantau seluruh agenda konseling dan pendampingan korban.',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: AppColors.gray500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await Navigator.of(context).pushNamed(
                        AppRoutes.konselorManualCounseling,
                      );
                      _loadSchedules();
                    },
                    icon: const Icon(Icons.add_rounded, size: 17),
                    label: const Text(
                      'Tambah Manual',
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w800),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 11),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // 4 Main Stat Cards
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.75,
                children: [
                  _buildStatTile(
                    label: 'Total Penanganan',
                    value: '$total',
                    color: const Color(0xFF4F46E5),
                    icon: Icons.calendar_month_outlined,
                  ),
                  _buildStatTile(
                    label: 'Hari Ini',
                    value: '$todayCount',
                    color: const Color(0xFF059669),
                    icon: Icons.today_rounded,
                  ),
                  _buildStatTile(
                    label: 'Akan Datang',
                    value: '$upcomingCount',
                    color: const Color(0xFF2563EB),
                    icon: Icons.upcoming_outlined,
                  ),
                  _buildStatTile(
                    label: 'Menunggu',
                    value: '$pendingCount',
                    color: const Color(0xFFD97706),
                    icon: Icons.hourglass_top_rounded,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // 3 Quick Sub-stats
              Row(
                children: [
                  Expanded(
                    child: _buildMiniStat('Disetujui', approvedCount,
                        const Color(0xFF4F46E5)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMiniStat(
                        'Selesai', completedCount, const Color(0xFF059669)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMiniStat('Dibatalkan', cancelledCount,
                        const Color(0xFFE11D48)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Filter bar
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.gray100),
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchCtrl,
                      onSubmitted: (_) => _loadSchedules(),
                      decoration: InputDecoration(
                        hintText: 'Cari nama pelapor, NIM, atau kategori...',
                        hintStyle: const TextStyle(fontSize: 13),
                        prefixIcon:
                            const Icon(Icons.search_rounded, size: 19),
                        filled: true,
                        fillColor: AppColors.gray50,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedStatus,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: 'Status',
                              filled: true,
                              fillColor: AppColors.gray50,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 8),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(
                                  value: 'all',
                                  child: Text('Semua',
                                      style: TextStyle(fontSize: 12))),
                              DropdownMenuItem(
                                  value: 'pending',
                                  child: Text('Menunggu',
                                      style: TextStyle(fontSize: 12))),
                              DropdownMenuItem(
                                  value: 'approved',
                                  child: Text('Disetujui',
                                      style: TextStyle(fontSize: 12))),
                              DropdownMenuItem(
                                  value: 'completed',
                                  child: Text('Selesai',
                                      style: TextStyle(fontSize: 12))),
                              DropdownMenuItem(
                                  value: 'cancelled',
                                  child: Text('Dibatalkan',
                                      style: TextStyle(fontSize: 12))),
                            ],
                            onChanged: (v) {
                              if (v != null) {
                                setState(() => _selectedStatus = v);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedMetode,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: 'Metode',
                              filled: true,
                              fillColor: AppColors.gray50,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 8),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(
                                  value: 'all',
                                  child: Text('Semua',
                                      style: TextStyle(fontSize: 12))),
                              DropdownMenuItem(
                                  value: 'offline',
                                  child: Text('Tatap Muka',
                                      style: TextStyle(fontSize: 12))),
                              DropdownMenuItem(
                                  value: 'online',
                                  child: Text('Online',
                                      style: TextStyle(fontSize: 12))),
                            ],
                            onChanged: (v) {
                              if (v != null) {
                                setState(() => _selectedMetode = v);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _loadSchedules,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.gray900,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Cari',
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w700)),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          onPressed: _resetFilters,
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          tooltip: 'Reset Filter',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (_loading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(36),
                    child:
                        CircularProgressIndicator(color: Color(0xFF4F46E5)),
                  ),
                )
              else if (_schedules.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(36),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: AppColors.gray100),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.event_busy_outlined,
                          size: 40, color: AppColors.gray300),
                      SizedBox(height: 10),
                      Text(
                        'Belum Ada Jadwal Penanganan',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                )
              else
                ..._schedules.map(_buildScheduleItemCard),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatTile({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.gray100),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.gray900,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.gray500,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.gray100),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.gray600,
            ),
          ),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleItemCard(SatgasSessionRecord sched) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gray100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  sched.tanggal,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF4F46E5),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${sched.jamMulai} - ${sched.jamSelesai} WIB',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.gray700,
                ),
              ),
              const Spacer(),
              _buildStatusPill(sched.status),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            sched.counseleeName,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.gray900,
            ),
          ),
          Text(
            '${sched.jenisPengaduan} • ${sched.metode.toUpperCase()} (${sched.lokasi})',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.gray600,
            ),
          ),
          const Divider(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showScheduleDetailModal(sched),
                  icon: const Icon(Icons.info_outline_rounded, size: 16),
                  label: const Text('Detail Sesi'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.gray800,
                    side: const BorderSide(color: AppColors.gray200),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              if (sched.complaintId != null) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pushNamed(
                        AppRoutes.konselorComplaintDetail,
                        arguments: sched.complaintId,
                      );
                    },
                    icon: const Icon(Icons.description_outlined, size: 16),
                    label: const Text('Buka Aduan'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill(String status) {
    final s = status.toLowerCase();
    Color bg = const Color(0xFFFEF3C7);
    Color fg = const Color(0xFFB45309);
    String label = 'Menunggu';

    if (s == 'approved') {
      bg = const Color(0xFFEEF2FF);
      fg = const Color(0xFF4338CA);
      label = 'Disetujui';
    } else if (s == 'completed') {
      bg = const Color(0xFFECFDF5);
      fg = const Color(0xFF047857);
      label = 'Selesai';
    } else if (s == 'cancelled' || s == 'rejected') {
      bg = const Color(0xFFFFF1F2);
      fg = const Color(0xFFBE123C);
      label = 'Dibatalkan';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          color: fg,
        ),
      ),
    );
  }
}

