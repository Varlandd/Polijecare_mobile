import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/konselor_portal_service.dart';
import 'konselor_shell_page.dart';

/// Hari Libur Nasional statis sesuai `STATIC_HOLIDAYS` di `CounselingCalendar.jsx`.
const Map<String, String> _kStaticHolidays = {
  '2025-01-01': 'Tahun Baru Masehi',
  '2025-01-27': 'Isra Miraj Nabi Muhammad SAW',
  '2025-01-29': 'Tahun Baru Imlek',
  '2025-03-29': 'Hari Suci Nyepi',
  '2025-03-31': 'Hari Raya Idul Fitri',
  '2025-04-01': 'Hari Raya Idul Fitri',
  '2025-04-18': 'Wafat Isa Al-Masih',
  '2025-05-01': 'Hari Buruh',
  '2025-05-12': 'Hari Raya Waisak',
  '2025-05-29': 'Kenaikan Isa Al-Masih',
  '2025-06-01': 'Hari Lahir Pancasila',
  '2025-06-06': 'Hari Raya Idul Adha',
  '2025-06-27': 'Tahun Baru Hijriyah',
  '2025-08-17': 'Hari Kemerdekaan RI',
  '2025-09-05': 'Maulid Nabi Muhammad SAW',
  '2025-12-25': 'Hari Natal',
  '2026-01-01': 'Tahun Baru Masehi',
  '2026-01-16': 'Isra Miraj Nabi Muhammad SAW',
  '2026-02-17': 'Tahun Baru Imlek',
  '2026-03-19': 'Hari Suci Nyepi',
  '2026-03-20': 'Hari Raya Idul Fitri',
  '2026-03-21': 'Hari Raya Idul Fitri',
  '2026-04-03': 'Wafat Isa Al-Masih',
  '2026-05-01': 'Hari Buruh',
  '2026-05-14': 'Kenaikan Isa Al-Masih',
  '2026-05-16': 'Hari Raya Waisak',
  '2026-05-27': 'Hari Raya Idul Adha',
  '2026-06-01': 'Hari Lahir Pancasila',
  '2026-06-17': 'Tahun Baru Hijriyah',
  '2026-08-17': 'Hari Kemerdekaan RI',
  '2026-08-26': 'Maulid Nabi Muhammad SAW',
  '2026-12-25': 'Hari Natal',
};

const List<String> _kMonthNamesId = [
  'Januari',
  'Februari',
  'Maret',
  'April',
  'Mei',
  'Juni',
  'Juli',
  'Agustus',
  'September',
  'Oktober',
  'November',
  'Desember',
];

const List<String> _kDayNamesId = [
  'Min',
  'Sen',
  'Sel',
  'Rab',
  'Kam',
  'Jum',
  'Sab',
];

/// Halaman Dashboard Satgas / Konselor (`/konselor/dashboard`) —
/// Port 1:1 dari `pages/konselor/dashboard.jsx` + `SummaryCard.jsx` +
/// `ChartSection.jsx` + `CounselingCalendar.jsx` + `ActivityList.jsx`.
class KonselorDashboardPage extends StatefulWidget {
  const KonselorDashboardPage({super.key});

  @override
  State<KonselorDashboardPage> createState() => _KonselorDashboardPageState();
}

class _KonselorDashboardPageState extends State<KonselorDashboardPage> {
  bool _loading = true;
  Map<String, dynamic> _stats = const {};

  // Chart state
  String _selectedYear = '2026';
  String _selectedMonth = 'Semua';
  String _genderTab = 'terlapor'; // terlapor | pelapor | korban
  bool _chartsLoading = true;
  List<Map<String, dynamic>> _categoryDist = const [];
  Map<String, dynamic> _genderDist = const {};
  List<Map<String, dynamic>> _deptDist = const [];

  // Calendar state
  late int _calYear;
  late int _calMonth; // 1..12
  String? _selectedDateStr;
  List<SatgasSessionRecord> _sessions = const [];
  List<ExternalCalendarAgenda> _externalAgendas = const [];

  // Activity state
  List<SatgasComplaintItem> _activities = const [];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _calYear = now.year;
    _calMonth = now.month;
    _selectedDateStr = _fmtDate(now);
    _loadAll();
  }

  String _fmtDate(DateTime dt) {
    return '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      KonselorPortalService.instance.getDashboardStats(),
      KonselorPortalService.instance.getSchedules(),
      KonselorPortalService.instance.getExternalAgendas(),
      KonselorPortalService.instance.getComplaints(),
    ]);
    await _loadCharts();
    if (!mounted) return;
    final allComplaints = results[3] as List<SatgasComplaintItem>;
    final activeList = allComplaints
        .where((c) => c.status == 'pending' || c.status == 'approved')
        .toList();
    setState(() {
      _stats = results[0] as Map<String, dynamic>;
      _sessions = results[1] as List<SatgasSessionRecord>;
      _externalAgendas = results[2] as List<ExternalCalendarAgenda>;
      _activities = activeList;
      _loading = false;
    });
  }

  Future<void> _loadCharts() async {
    setState(() => _chartsLoading = true);
    final results = await Future.wait([
      KonselorPortalService.instance.getCategoryDistribution(
        year: _selectedYear,
        month: _selectedMonth,
      ),
      KonselorPortalService.instance.getGenderDistribution(
        year: _selectedYear,
        month: _selectedMonth,
      ),
      KonselorPortalService.instance.getDepartmentDistribution(
        year: _selectedYear,
        month: _selectedMonth,
      ),
    ]);
    if (!mounted) return;
    setState(() {
      _categoryDist = results[0] as List<Map<String, dynamic>>;
      _genderDist = results[1] as Map<String, dynamic>;
      _deptDist = results[2] as List<Map<String, dynamic>>;
      _chartsLoading = false;
    });
  }

  void _showNotificationSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3E8FF),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.notifications_active_outlined,
                        color: Color(0xFF7C3AED),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Notifikasi Penanganan Satgas',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.gray900,
                            ),
                          ),
                          Text(
                            'Kasus & jadwal yang membutuhkan perhatian Anda',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: AppColors.gray500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (_activities.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        'Tidak ada notifikasi kasus baru.',
                        style: TextStyle(color: AppColors.gray500),
                      ),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _activities.take(5).length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (_, idx) {
                        final item = _activities[idx];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: item.status == 'pending'
                                ? const Color(0xFFFEF3C7)
                                : const Color(0xFFEDE9FE),
                            child: Icon(
                              Icons.description_outlined,
                              size: 18,
                              color: item.status == 'pending'
                                  ? const Color(0xFFD97706)
                                  : const Color(0xFF7C3AED),
                            ),
                          ),
                          title: Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            '${item.reportId} • ${item.userName}',
                            style: const TextStyle(fontSize: 11.5),
                          ),
                          trailing: const Icon(
                            Icons.chevron_right_rounded,
                            size: 18,
                          ),
                          onTap: () {
                            Navigator.of(ctx).pop();
                            Navigator.of(context)
                                .pushNamed(
                                  AppRoutes.konselorComplaintDetail,
                                  arguments: item.id,
                                )
                                .then((_) => _loadAll());
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showAddExternalAgendaDialog({String? initialDate}) async {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String dateVal =
        initialDate ?? _selectedDateStr ?? _fmtDate(DateTime.now());
    String timeVal = '09:00';

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              title: const Text(
                'Tambah Agenda Eksternal',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.gray900,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'JUDUL AGENDA *',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.gray500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: titleCtrl,
                      decoration: InputDecoration(
                        hintText: 'Contoh: Penanganan Individu - Mahasiswa X',
                        filled: true,
                        fillColor: AppColors.gray50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppColors.gray200),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'TANGGAL *',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.gray500,
                                ),
                              ),
                              const SizedBox(height: 6),
                              InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: ctx,
                                    initialDate:
                                        DateTime.tryParse(dateVal) ??
                                            DateTime.now(),
                                    firstDate: DateTime(2024),
                                    lastDate: DateTime(2030),
                                  );
                                  if (picked != null) {
                                    setDialogState(() {
                                      dateVal = _fmtDate(picked);
                                    });
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.gray50,
                                    borderRadius: BorderRadius.circular(14),
                                    border:
                                        Border.all(color: AppColors.gray200),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.calendar_today_outlined,
                                        size: 14,
                                        color: AppColors.indigo600,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          dateVal,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'JAM (WIB)',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.gray500,
                                ),
                              ),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                initialValue: timeVal,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: AppColors.gray50,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(
                                        color: AppColors.gray200),
                                  ),
                                ),
                                items: const [
                                  '08:00',
                                  '09:00',
                                  '10:00',
                                  '11:00',
                                  '13:00',
                                  '14:00',
                                  '15:00',
                                ]
                                    .map(
                                      (t) => DropdownMenuItem(
                                        value: t,
                                        child: Text(
                                          t,
                                          style: const TextStyle(fontSize: 12.5),
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) {
                                  if (v != null) {
                                    setDialogState(() => timeVal = v);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'DESKRIPSI (OPSIONAL)',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.gray500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: descCtrl,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Catatan singkat terkait agenda ini',
                        filled: true,
                        fillColor: AppColors.gray50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppColors.gray200),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (titleCtrl.text.trim().isEmpty) return;
                    final next =
                        await KonselorPortalService.instance.addExternalAgenda(
                      title: titleCtrl.text.trim(),
                      date: dateVal,
                      time: timeVal,
                      description: descCtrl.text.trim(),
                    );
                    if (!ctx.mounted) return;
                    Navigator.of(ctx).pop();
                    setState(() {
                      _externalAgendas = next;
                      _selectedDateStr = dateVal;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.indigo600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Simpan Agenda'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.user;
    final j = (_stats['jadwal'] is Map)
        ? Map<String, dynamic>.from(_stats['jadwal'] as Map)
        : const <String, dynamic>{};
    final pendingCount = (j['pending'] as num?)?.toInt() ?? 0;
    final approvedCount = (j['approved'] as num?)?.toInt() ?? 0;
    final completedCount = (j['completed'] as num?)?.toInt() ?? 0;
    final totalCount = (j['total'] as num?)?.toInt() ?? 0;
    final todayCount = (j['today'] as num?)?.toInt() ?? 0;
    final upcomingCount = (j['upcoming'] as num?)?.toInt() ?? 0;
    final materiCount = (_stats['materi'] as num?)?.toInt() ?? 0;

    return KonselorShellPage(
      title: 'Ringkasan Statistik',
      subtitle: 'Ringkasan aktivitas pengaduan dan jadwal konseling hari ini.',
      activePath: AppRoutes.konselorDashboard,
      body: RefreshIndicator(
        onRefresh: _loadAll,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Welcome Banner (`pages/konselor/dashboard.jsx`) ──
              _buildWelcomeBanner(user?.firstName ?? 'Konselor', pendingCount),
              const SizedBox(height: 20),

              // ── 4 Summary Cards (`SummaryCard.jsx`) ──
              GridView.count(
                crossAxisCount: MediaQuery.of(context).size.width > 700 ? 4 : 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.32,
                children: [
                  _SummaryCardWidget(
                    title: 'Jadwal Menunggu',
                    value: _loading ? '...' : '$pendingCount',
                    description: '$pendingCount perlu konfirmasi',
                    icon: Icons.note_add_outlined,
                    iconColor: const Color(0xFF9333EA),
                    iconBg: const Color(0xFFFAF5FF),
                  ),
                  _SummaryCardWidget(
                    title: 'Jadwal Disetujui',
                    value: _loading ? '...' : '$approvedCount',
                    description: '$approvedCount jadwal aktif',
                    icon: Icons.event_available_outlined,
                    iconColor: const Color(0xFF2563EB),
                    iconBg: const Color(0xFFEFF6FF),
                  ),
                  _SummaryCardWidget(
                    title: 'Sesi Selesai',
                    value: _loading ? '...' : '$completedCount',
                    description: '$completedCount telah diselesaikan',
                    icon: Icons.check_circle_outline_rounded,
                    iconColor: const Color(0xFF16A34A),
                    iconBg: const Color(0xFFF0FDF4),
                  ),
                  _SummaryCardWidget(
                    title: 'Total Jadwal',
                    value: _loading ? '...' : '$totalCount',
                    description: '$totalCount total jadwal',
                    icon: Icons.description_outlined,
                    iconColor: const Color(0xFF7E22CE),
                    iconBg: const Color(0xFFF3E8FF),
                  ),
                ],
              ),
              const SizedBox(height: 22),

              // ── Charts Section (`ChartSection.jsx`) ──
              _buildChartSection(),
              const SizedBox(height: 22),

              // ── Counseling Calendar (`CounselingCalendar.jsx`) ──
              _buildCounselingCalendar(),
              const SizedBox(height: 22),

              // ── Activity List (`ActivityList.jsx`) ──
              _buildActivityList(),
              const SizedBox(height: 22),

              // ── Quick Stats Footer (`pages/konselor/dashboard.jsx`) ──
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.gray100),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x08000000),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            '$todayCount',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF6666DE),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Sesi Hari Ini',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.gray600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: AppColors.gray100,
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            '$upcomingCount',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors.green,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Jadwal Mendatang',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.gray600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: AppColors.gray100,
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            '$materiCount',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Total Materi Saya',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.gray600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeBanner(String firstName, int pendingCount) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.gray900,
                          height: 1.25,
                        ),
                        children: [
                          const TextSpan(text: 'Selamat Datang, '),
                          TextSpan(
                            text: 'Satgas $firstName!',
                            style: const TextStyle(color: Color(0xFF6666DE)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text.rich(
                      TextSpan(
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.gray600,
                          height: 1.5,
                        ),
                        children: [
                          const TextSpan(text: 'Anda memiliki '),
                          TextSpan(
                            text: '$pendingCount jadwal menunggu konfirmasi',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.gray900,
                            ),
                          ),
                          const TextSpan(
                            text:
                                ' yang membutuhkan perhatian segera. Pantau aktivitas penanganan dan kelola jadwal dengan efisien.',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Notification & Refresh buttons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: _showNotificationSheet,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.gray50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.gray200),
                          ),
                          child: const Icon(
                            Icons.notifications_none_rounded,
                            size: 20,
                            color: AppColors.gray700,
                          ),
                        ),
                      ),
                      if (_activities.isNotEmpty)
                        Positioned(
                          right: -3,
                          top: -3,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE11D48),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '${_activities.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: _loading ? null : _loadAll,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.gray200),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.refresh_rounded,
                            size: 16,
                            color: AppColors.gray700,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Refresh',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.gray700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pushReplacementNamed(
                    AppRoutes.konselorCounselingDashboard,
                  );
                },
                icon: const Icon(
                  Icons.calendar_today_outlined,
                  size: 15,
                  color: Colors.white,
                ),
                label: const Text(
                  'Lihat Jadwal',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6666DE),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).pushReplacementNamed(
                    AppRoutes.konselorPengaduan,
                  );
                },
                icon: const Icon(
                  Icons.description_outlined,
                  size: 15,
                  color: Color(0xFF6666DE),
                ),
                label: const Text(
                  'Lihat Pengaduan',
                  style: TextStyle(
                    color: Color(0xFF6666DE),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: AppColors.gray200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartSection() {
    final totalCategoryReports = _categoryDist.fold<int>(
      0,
      (sum, e) => sum + ((e['jumlah'] as num?)?.toInt() ?? 0),
    );
    Map<String, dynamic>? highestCat;
    for (final item in _categoryDist) {
      if (highestCat == null ||
          ((item['jumlah'] as num?)?.toInt() ?? 0) >
              ((highestCat['jumlah'] as num?)?.toInt() ?? 0)) {
        highestCat = item;
      }
    }

    final totalDeptReports = _deptDist.fold<int>(
      0,
      (sum, e) => sum + ((e['value'] as num?)?.toInt() ?? 0),
    );

    final activeGenderMap = (_genderDist[_genderTab] is Map)
        ? Map<String, dynamic>.from(_genderDist[_genderTab] as Map)
        : const <String, dynamic>{};
    final genderItems = (activeGenderMap['gender'] is List)
        ? (activeGenderMap['gender'] as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList()
        : const <Map<String, dynamic>>[];
    final statusItems = (activeGenderMap['status'] is List)
        ? (activeGenderMap['status'] as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList()
        : const <Map<String, dynamic>>[];

    return Column(
      children: [
        // ── Chart 1: Sebaran Kekerasan per Kategori ──
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.gray100),
            boxShadow: const [
              BoxShadow(
                color: Color(0x08000000),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAF5FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.pie_chart_outline_rounded,
                      color: Color(0xFF9333EA),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sebaran Kekerasan per Kategori',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.gray900,
                          ),
                        ),
                        Text(
                          'Distribusi jenis laporan kekerasan',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.gray500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Filter Tahun & Bulan
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.gray50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.gray200),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedYear,
                          isExpanded: true,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.gray700,
                          ),
                          items: const ['Semua', '2024', '2025', '2026']
                              .map(
                                (y) => DropdownMenuItem(
                                  value: y,
                                  child: Text(
                                    y == 'Semua' ? 'Semua Tahun' : y,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (v) {
                            if (v != null) {
                              setState(() => _selectedYear = v);
                              _loadCharts();
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.gray50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.gray200),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedMonth,
                          isExpanded: true,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.gray700,
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: 'Semua',
                              child: Text('Semua Bulan'),
                            ),
                            for (int i = 0; i < _kMonthNamesId.length; i++)
                              DropdownMenuItem(
                                value: '${i + 1}',
                                child: Text(_kMonthNamesId[i]),
                              ),
                          ],
                          onChanged: (v) {
                            if (v != null) {
                              setState(() => _selectedMonth = v);
                              _loadCharts();
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_chartsLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else ...[
                for (int i = 0; i < _categoryDist.length; i++) ...[
                  Builder(
                    builder: (_) {
                      final item = _categoryDist[i];
                      final count = (item['jumlah'] as num?)?.toInt() ?? 0;
                      final pct = totalCategoryReports > 0
                          ? ((count / totalCategoryReports) * 100).round()
                          : 0;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          color: i == 0
                                              ? const Color(0xFF7C3AED)
                                              : const Color(0xFFA78BFA),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          item['kategori']?.toString() ?? '-',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.gray900,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '$pct% ($count laporan)',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.gray700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: (pct / 100).clamp(0.0, 1.0),
                                minHeight: 22,
                                backgroundColor: AppColors.gray100,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  i == 0
                                      ? const Color(0xFF7C3AED)
                                      : const Color(0xFF9333EA),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
                if (highestCat != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAF5FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.gray700,
                              ),
                              children: [
                                const TextSpan(text: 'Kategori tertinggi: '),
                                TextSpan(
                                  text: '${highestCat['kategori']}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF7E22CE),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Text(
                          'Total: $totalCategoryReports kasus',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.gray500,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Chart 2: Distribusi Gender & Status (Terlapor / Pelapor / Korban) ──
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.gray100),
            boxShadow: const [
              BoxShadow(
                color: Color(0x08000000),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.people_outline_rounded,
                      color: Color(0xFF2563EB),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Distribusi Gender & Status',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.gray900,
                          ),
                        ),
                        Text(
                          'Breakdown per Terlapor, Pelapor, dan Korban',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.gray500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.gray100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    for (final entry in const [
                      ('terlapor', '🔴 Terlapor'),
                      ('pelapor', '🔵 Pelapor'),
                      ('korban', '🟣 Korban'),
                    ])
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _genderTab = entry.$1),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            decoration: BoxDecoration(
                              color: _genderTab == entry.$1
                                  ? Colors.white
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(9),
                              boxShadow: _genderTab == entry.$1
                                  ? const [
                                      BoxShadow(
                                        color: Color(0x12000000),
                                        blurRadius: 4,
                                      ),
                                    ]
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              entry.$2,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _genderTab == entry.$1
                                    ? AppColors.gray900
                                    : AppColors.gray500,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.gray50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.gray100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'GENDER',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.gray500,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _HorizontalBarGroup(
                      items: genderItems,
                      primaryColor: const Color(0xFF3B82F6),
                      secondaryColor: const Color(0xFF8B5CF6),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.gray50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.gray100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'STATUS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.gray500,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _HorizontalBarGroup(
                      items: statusItems,
                      primaryColor: const Color(0xFF7C3AED),
                      secondaryColor: const Color(0xFF10B981),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Chart 3: Sebaran Kekerasan Seksual per Jurusan ──
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.gray100),
            boxShadow: const [
              BoxShadow(
                color: Color(0x08000000),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.bar_chart_rounded,
                      color: Color(0xFFDC2626),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sebaran Kekerasan Seksual per Jurusan',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.gray900,
                          ),
                        ),
                        Text(
                          'Data Seluruh Jurusan - Peringkat Kasus',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.gray500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'Total: $totalDeptReports kasus',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.gray900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_deptDist.isNotEmpty) ...[
                Builder(
                  builder: (_) {
                    final top = _deptDist.first;
                    final topVal = (top['value'] as num?)?.toInt() ?? 0;
                    final topPct = totalDeptReports > 0
                        ? ((topVal / totalDeptReports) * 100).round()
                        : 0;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFEF2F2), Color(0xFFFFF7ED)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFFECACA)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'JURUSAN DENGAN KASUS TERTINGGI',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.slate500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  top['name']?.toString() ?? '-',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.slate900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '$topPct%',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.slate900,
                                ),
                              ),
                              Text(
                                '$topVal dari $totalDeptReports kasus',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.slate500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
                for (int i = 0; i < _deptDist.length; i++) ...[
                  Builder(
                    builder: (_) {
                      final item = _deptDist[i];
                      final val = (item['value'] as num?)?.toInt() ?? 0;
                      final pct = totalDeptReports > 0
                          ? ((val / totalDeptReports) * 100).round()
                          : 0;
                      final isFirst = i == 0;
                      final isSecond = i == 1;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color: isFirst
                                        ? const Color(0xFFFEE2E2)
                                        : (isSecond
                                            ? const Color(0xFFFFEDD5)
                                            : AppColors.gray100),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '${i + 1}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: isFirst
                                          ? const Color(0xFFB91C1C)
                                          : (isSecond
                                              ? const Color(0xFFC2410C)
                                              : AppColors.gray700),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['name']?.toString() ?? '-',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.gray900,
                                        ),
                                      ),
                                      Text(
                                        '$val kasus • $pct% dari total',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.gray500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '$pct%',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.gray900,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: (pct / 100).clamp(0.0, 1.0),
                                minHeight: 16,
                                backgroundColor: AppColors.gray100,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  isFirst
                                      ? const Color(0xFFEF4444)
                                      : (isSecond
                                          ? const Color(0xFFF97316)
                                          : const Color(0xFFF59E0B)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ],
            ],
          ),
        ),
      ],
    );
  }

  Map<String, List<Map<String, dynamic>>> _buildCalendarEventMap() {
    final map = <String, List<Map<String, dynamic>>>{};

    for (final s in _sessions) {
      if (s.tanggal.isEmpty) continue;
      final d = s.tanggal;
      map.putIfAbsent(d, () => []);
      map[d]!.add({
        'id': 's-${s.id}',
        'complaintId': s.complaintId,
        'title': s.jenisPengaduan,
        'time': '${s.jamMulai} WIB',
        'status': s.status,
        'nama': s.counseleeName,
        'counselorName': s.counselorName,
        'isExternal': false,
        'isHoliday': false,
      });
    }

    for (final a in _externalAgendas) {
      map.putIfAbsent(a.date, () => []);
      map[a.date]!.add({
        'id': a.id,
        'title': a.title,
        'time': '${a.time} WIB',
        'status': 'external',
        'nama': '',
        'description': a.description,
        'isExternal': true,
        'isHoliday': false,
      });
    }

    _kStaticHolidays.forEach((hDate, hName) {
      map.putIfAbsent(hDate, () => []);
      map[hDate]!.add({
        'id': 'holiday-$hDate',
        'title': hName,
        'time': '',
        'status': 'holiday',
        'nama': '',
        'description': 'Hari Libur Nasional',
        'isExternal': false,
        'isHoliday': true,
      });
    });

    return map;
  }

  Color _calendarStatusColor(String status) {
    switch (status) {
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'approved':
        return const Color(0xFF22C55E);
      case 'completed':
        return const Color(0xFF3B82F6);
      case 'rejected':
        return const Color(0xFFF97316);
      case 'external':
        return const Color(0xFF8B5CF6);
      case 'holiday':
        return const Color(0xFFEF4444);
      default:
        return AppColors.gray400;
    }
  }

  String _calendarStatusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Menunggu Persetujuan';
      case 'approved':
        return 'Disetujui';
      case 'completed':
        return 'Selesai';
      case 'rejected':
        return 'Jadwalkan Ulang';
      case 'external':
        return 'Agenda Eksternal';
      case 'holiday':
        return 'Hari Libur Nasional';
      default:
        return status;
    }
  }

  Widget _buildCounselingCalendar() {
    final eventMap = _buildCalendarEventMap();
    final firstDayOfMonth = DateTime(_calYear, _calMonth, 1);
    final firstWeekdayIndex = firstDayOfMonth.weekday % 7; // Min = 0
    final daysInMonth = DateTime(_calYear, _calMonth + 1, 0).day;
    final todayStr = _fmtDate(DateTime.now());

    final cells = <int?>[];
    for (int i = 0; i < firstWeekdayIndex; i++) {
      cells.add(null);
    }
    for (int d = 1; d <= daysInMonth; d++) {
      cells.add(d);
    }

    final selectedEvents = _selectedDateStr != null
        ? (eventMap[_selectedDateStr!] ?? const <Map<String, dynamic>>[])
        : const <Map<String, dynamic>>[];

    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Kalender Penanganan
          Container(
            padding: const EdgeInsets.all(18),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFEEF2FF), Colors.white, Color(0xFFFAF5FF)],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(bottom: BorderSide(color: AppColors.gray100)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.indigo600,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Icon(
                        Icons.calendar_month_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kalender Penanganan',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.slate900,
                            ),
                          ),
                          Text(
                            'Sesi dari sistem + agenda eksternal',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.slate500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context)
                            .pushNamed(AppRoutes.konselorManualCounseling)
                            .then((_) => _loadAll());
                      },
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: const Text(
                        'Tambah Agenda',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.indigo600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Navigasi Bulan & Tahun
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () {
                        setState(() {
                          if (_calMonth == 1) {
                            _calMonth = 12;
                            _calYear--;
                          } else {
                            _calMonth--;
                          }
                        });
                      },
                      icon: const Icon(Icons.chevron_left_rounded),
                    ),
                    Text(
                      '${_kMonthNamesId[_calMonth - 1]} $_calYear',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.slate900,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          if (_calMonth == 12) {
                            _calMonth = 1;
                            _calYear++;
                          } else {
                            _calMonth++;
                          }
                        });
                      },
                      icon: const Icon(Icons.chevron_right_rounded),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Grid Hari
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Row(
                  children: [
                    for (final d in _kDayNamesId)
                      Expanded(
                        child: Center(
                          child: Text(
                            d,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.gray400,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 4,
                    crossAxisSpacing: 4,
                    childAspectRatio: 0.95,
                  ),
                  itemCount: cells.length,
                  itemBuilder: (_, idx) {
                    final day = cells[idx];
                    if (day == null) return const SizedBox.shrink();
                    final dateStr =
                        '$_calYear-${_calMonth.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
                    final dayEvents = eventMap[dateStr] ?? const [];
                    final isToday = dateStr == todayStr;
                    final isSelected = _selectedDateStr == dateStr;

                    return InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => setState(() => _selectedDateStr = dateStr),
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFEEF2FF)
                              : (isToday
                                  ? const Color(0xFFF5F3FF)
                                  : Colors.white),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.indigo600
                                : AppColors.gray100,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$day',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: isToday
                                    ? AppColors.indigo600
                                    : AppColors.slate700,
                              ),
                            ),
                            const Spacer(),
                            if (dayEvents.isNotEmpty)
                              Wrap(
                                spacing: 3,
                                runSpacing: 3,
                                children: [
                                  for (final ev in dayEvents.take(3))
                                    Container(
                                      width: 7,
                                      height: 7,
                                      decoration: BoxDecoration(
                                        color: _calendarStatusColor(
                                          ev['status']?.toString() ?? 'pending',
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                // Legend
                Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  children: [
                    for (final item in const [
                      ('pending', 'Menunggu Persetujuan'),
                      ('approved', 'Disetujui'),
                      ('completed', 'Selesai'),
                      ('rejected', 'Jadwalkan Ulang'),
                      ('external', 'Agenda Eksternal'),
                    ])
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _calendarStatusColor(item.$1),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            item.$2,
                            style: const TextStyle(
                              fontSize: 10.5,
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

          // Detail Panel Tanggal Terpilih
          if (_selectedDateStr != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.gray50,
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(24)),
                border: Border(top: BorderSide(color: AppColors.gray100)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Agenda Tanggal $_selectedDateStr',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.gray800,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _showAddExternalAgendaDialog(
                          initialDate: _selectedDateStr,
                        ),
                        icon: const Icon(Icons.add_rounded, size: 15),
                        label: const Text(
                          'Agenda Eksternal',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (selectedEvents.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'Belum ada sesi terjadwal untuk tanggal ini.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.gray500,
                        ),
                      ),
                    )
                  else
                    for (final ev in selectedEvents)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.gray200),
                        ),
                        child: InkWell(
                          onTap: () {
                            final cid = ev['complaintId'] as int?;
                            if (cid != null) {
                              Navigator.of(context)
                                  .pushNamed(
                                    AppRoutes.konselorComplaintDetail,
                                    arguments: cid,
                                  )
                                  .then((_) => _loadAll());
                            }
                          },
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      ev['title']?.toString() ?? '-',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.gray900,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 4,
                                      children: [
                                        if ((ev['time']?.toString() ?? '')
                                            .isNotEmpty)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 7,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFEEF2FF),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              ev['time'].toString(),
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.indigo600,
                                              ),
                                            ),
                                          ),
                                        if ((ev['nama']?.toString() ?? '')
                                            .isNotEmpty)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 7,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.slate100,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              ev['nama'].toString(),
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.slate600,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _calendarStatusColor(
                                    ev['status']?.toString() ?? 'pending',
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _calendarStatusLabel(
                                    ev['status']?.toString() ?? 'pending',
                                  ),
                                  style: const TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              if (ev['isExternal'] == true)
                                IconButton(
                                  onPressed: () async {
                                    final next = await KonselorPortalService
                                        .instance
                                        .deleteExternalAgenda(
                                      ev['id'].toString(),
                                    );
                                    if (!mounted) return;
                                    setState(() => _externalAgendas = next);
                                  },
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                    size: 18,
                                    color: AppColors.red,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActivityList() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gray100),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF5FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.access_time_rounded,
                    color: Color(0xFF9333EA),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Aktivitas Terbaru',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.gray900,
                        ),
                      ),
                      Text(
                        '5 laporan terbaru yang perlu perhatian',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.gray500,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushReplacementNamed(
                      AppRoutes.konselorCaseManagement,
                    );
                  },
                  icon: const Text(
                    'Lihat Semua',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6666DE),
                    ),
                  ),
                  label: const Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: Color(0xFF6666DE),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.gray100),
          if (_activities.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'Tidak ada aktivitas terbaru',
                  style: TextStyle(color: AppColors.gray500),
                ),
              ),
            )
          else
            for (final act in _activities.take(5)) ...[
              InkWell(
                onTap: () {
                  Navigator.of(context)
                      .pushNamed(
                        AppRoutes.konselorComplaintDetail,
                        arguments: act.id,
                      )
                      .then((_) => _loadAll());
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 6),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: act.status == 'pending'
                              ? const Color(0xFFF97316)
                              : const Color(0xFF9333EA),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              act.title,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.gray900,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 12,
                              runSpacing: 4,
                              children: [
                                Text(
                                  'ID: ${act.reportId}',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: AppColors.gray500,
                                  ),
                                ),
                                Text(
                                  act.userName,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: AppColors.gray500,
                                  ),
                                ),
                                Text(
                                  DateFormat('dd MMM yyyy • HH:mm')
                                      .format(act.createdAt),
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: AppColors.gray500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: act.status == 'pending'
                              ? const Color(0xFFFFEDD5)
                              : const Color(0xFFF3E8FF),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          act.status == 'pending' ? 'Baru' : 'Diproses',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: act.status == 'pending'
                                ? const Color(0xFFEA580C)
                                : const Color(0xFF9333EA),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1, color: AppColors.gray100),
            ],
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: AppColors.gray50,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: Text(
              'Total laporan aktif: ${_activities.length} laporan membutuhkan tindakan',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.gray600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCardWidget extends StatelessWidget {
  const _SummaryCardWidget({
    required this.title,
    required this.value,
    required this.description,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
  });

  final String title;
  final String value;
  final String description;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.gray100),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.gray500,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.gray900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Text(
            description,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.gray400,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _HorizontalBarGroup extends StatelessWidget {
  const _HorizontalBarGroup({
    required this.items,
    required this.primaryColor,
    required this.secondaryColor,
  });

  final List<Map<String, dynamic>> items;
  final Color primaryColor;
  final Color secondaryColor;

  @override
  Widget build(BuildContext context) {
    final total = items.fold<int>(
      0,
      (sum, e) => sum + ((e['value'] as num?)?.toInt() ?? 0),
    );
    if (items.isEmpty) {
      return const Text(
        'Belum ada data',
        style: TextStyle(fontSize: 12, color: AppColors.gray400),
      );
    }
    return Column(
      children: [
        for (int i = 0; i < items.length; i++) ...[
          Builder(
            builder: (_) {
              final item = items[i];
              final val = (item['value'] as num?)?.toInt() ?? 0;
              final pct = total > 0 ? ((val / total) * 100).round() : 0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item['name']?.toString() ?? '-',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.gray700,
                          ),
                        ),
                        Text(
                          '$val ($pct%)',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.gray500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: (pct / 100).clamp(0.0, 1.0),
                        minHeight: 16,
                        backgroundColor: AppColors.gray200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          i.isEven ? primaryColor : secondaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ],
    );
  }
}

