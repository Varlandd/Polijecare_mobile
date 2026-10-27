import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/konselor_portal_service.dart';
import '../../data/services/operator_portal_service.dart';
import 'operator_shell_page.dart';

/// Halaman Dashboard Super Admin (`/operator/dashboard`).
/// Porting 1:1 dari `pages/operator/dashboard.jsx` + `ChartSection.jsx` + `CounselingCalendar.jsx`.
class OperatorDashboardPage extends StatefulWidget {
  const OperatorDashboardPage({super.key});

  @override
  State<OperatorDashboardPage> createState() => _OperatorDashboardPageState();
}

class _OperatorDashboardPageState extends State<OperatorDashboardPage> {
  bool _loading = true;

  Map<String, int> _summary = {
    'total': 0,
    'approved': 0,
    'completed': 0,
    'pending': 0,
    'new': 0,
  };

  // Filter Chart
  String _selectedYear = '2026';
  String _selectedMonth = 'Semua';
  String _genderSubjectTab = 'terlapor'; // terlapor | pelapor | korban

  List<Map<String, dynamic>> _categoryDist = [];
  Map<String, dynamic> _genderDist = {};
  List<Map<String, dynamic>> _deptDist = [];

  // Calendar state
  DateTime _focusedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _selectedDay = DateTime.now();
  List<SatgasSessionRecord> _allSchedules = [];
  List<ExternalCalendarAgenda> _externalAgendas = [];

  static const Map<String, String> _nationalHolidays = {
    '01-01': 'Tahun Baru Masehi',
    '05-01': 'Hari Buruh Internasional',
    '06-01': 'Hari Lahir Pancasila',
    '08-17': 'Hari Kemerdekaan RI',
    '12-25': 'Hari Raya Natal',
  };

  static const List<({String val, String label})> _months = [
    (val: 'Semua', label: 'Semua Bulan'),
    (val: '1', label: 'Januari'),
    (val: '2', label: 'Februari'),
    (val: '3', label: 'Maret'),
    (val: '4', label: 'April'),
    (val: '5', label: 'Mei'),
    (val: '6', label: 'Juni'),
    (val: '7', label: 'Juli'),
    (val: '8', label: 'Agustus'),
    (val: '9', label: 'September'),
    (val: '10', label: 'Oktober'),
    (val: '11', label: 'November'),
    (val: '12', label: 'Desember'),
  ];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        OperatorPortalService.instance.getOperatorDashboardSummary(),
        OperatorPortalService.instance.getCategoryDistribution(
          year: _selectedYear,
          month: _selectedMonth,
        ),
        OperatorPortalService.instance.getGenderDistribution(
          year: _selectedYear,
          month: _selectedMonth,
        ),
        OperatorPortalService.instance.getDepartmentDistribution(
          year: _selectedYear,
          month: _selectedMonth,
        ),
        OperatorPortalService.instance.getOperatorSchedules(),
        KonselorPortalService.instance.getExternalAgendas(),
      ]);
      if (!mounted) return;
      setState(() {
        _summary = results[0] as Map<String, int>;
        _categoryDist = results[1] as List<Map<String, dynamic>>;
        _genderDist = results[2] as Map<String, dynamic>;
        _deptDist = results[3] as List<Map<String, dynamic>>;
        _allSchedules = results[4] as List<SatgasSessionRecord>;
        _externalAgendas = results[5] as List<ExternalCalendarAgenda>;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _reloadCharts() async {
    final results = await Future.wait([
      OperatorPortalService.instance.getCategoryDistribution(
        year: _selectedYear,
        month: _selectedMonth,
      ),
      OperatorPortalService.instance.getGenderDistribution(
        year: _selectedYear,
        month: _selectedMonth,
      ),
      OperatorPortalService.instance.getDepartmentDistribution(
        year: _selectedYear,
        month: _selectedMonth,
      ),
    ]);
    if (!mounted) return;
    setState(() {
      _categoryDist = results[0] as List<Map<String, dynamic>>;
      _genderDist = results[1] as Map<String, dynamic>;
      _deptDist = results[2] as List<Map<String, dynamic>>;
    });
  }

  String _fmtDateKey(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  String? _holidayFor(DateTime d) {
    final mmdd =
        '${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    return _nationalHolidays[mmdd];
  }

  Future<void> _showAddAgendaModal() async {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    TimeOfDay selectedTime = const TimeOfDay(hour: 9, minute: 0);
    final dateStr = _fmtDateKey(_selectedDay);

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final timeStr =
              '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';
          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Text(
              'Tambah Agenda Kalender',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tanggal: ${DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(_selectedDay)}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.indigo600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: titleCtrl,
                    decoration: InputDecoration(
                      labelText: 'Judul Agenda *',
                      hintText: 'Contoh: Rapat Koordinasi Satgas PPKPT',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await showTimePicker(
                        context: ctx,
                        initialTime: selectedTime,
                      );
                      if (picked != null) {
                        setModalState(() => selectedTime = picked);
                      }
                    },
                    icon: const Icon(Icons.access_time_rounded, size: 16),
                    label: Text('Jam: $timeStr WIB'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Keterangan (Opsional)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (titleCtrl.text.trim().isEmpty) return;
                  Navigator.of(ctx).pop(true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.indigo600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Simpan Agenda'),
              ),
            ],
          );
        },
      ),
    );

    if (saved == true) {
      final timeStr =
          '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';
      final next = await KonselorPortalService.instance.addExternalAgenda(
        title: titleCtrl.text.trim(),
        date: dateStr,
        time: timeStr,
        description: descCtrl.text.trim(),
      );
      if (!mounted) return;
      setState(() => _externalAgendas = next);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.user;
    final systemDateStr =
        DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(DateTime.now());

    return OperatorShellPage(
      title: 'Dashboard',
      subtitle: 'Ringkasan Sistem PolijeCare',
      activePath: AppRoutes.operatorDashboard,
      body: RefreshIndicator(
        color: AppColors.indigo600,
        onRefresh: _loadAll,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeBanner(user?.firstName ?? 'Admin', systemDateStr),
              const SizedBox(height: 20),
              _buildStatCardsGrid(),
              const SizedBox(height: 22),
              _buildChartSection(),
              const SizedBox(height: 22),
              _buildCalendarSection(),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeBanner(String firstName, String systemDateStr) {
    final newCount = _summary['new'] ?? 0;

    return Column(
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
                        fontSize: 25,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        height: 1.2,
                      ),
                      children: [
                        const TextSpan(text: 'Selamat Datang, Satgas '),
                        TextSpan(
                          text: '$firstName!',
                          style: const TextStyle(color: AppColors.indigo600),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text.rich(
                    TextSpan(
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.slate500,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                      children: [
                        const TextSpan(text: 'Ada '),
                        TextSpan(
                          text: '$newCount laporan baru',
                          style: const TextStyle(
                            color: Color(0xFFE11D48),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const TextSpan(
                          text:
                              ' yang menunggu atensi Anda hari ini. Mari kelola pengaduan dengan sigap dan efisien.',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pushReplacementNamed(
                  AppRoutes.operatorCaseManagement,
                  arguments: const {'tab': 'new'},
                );
              },
              icon: const Icon(Icons.trending_up_rounded, size: 17),
              label: const Text(
                'Tinjau Laporan',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.indigo600,
                foregroundColor: Colors.white,
                elevation: 3,
                shadowColor: const Color(0x4D4F46E5),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.gray100),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.calendar_today_rounded,
                      size: 15,
                      color: AppColors.indigo600,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'WAKTU SISTEM',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.slate400,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        systemDateStr,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.slate800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCardsGrid() {
    final cards = [
      (
        label: 'TOTAL PENGADUAN',
        value: _summary['total'] ?? 0,
        icon: Icons.description_outlined,
        bg: const Color(0xFFEEF2FF),
        fg: const Color(0xFF4F46E5),
      ),
      (
        label: 'DALAM PENANGANAN',
        value: _summary['approved'] ?? 0,
        icon: Icons.access_time_rounded,
        bg: const Color(0xFFFEF3C7),
        fg: const Color(0xFFD97706),
      ),
      (
        label: 'SELESAI',
        value: _summary['completed'] ?? 0,
        icon: Icons.check_circle_outline_rounded,
        bg: const Color(0xFFECFDF5),
        fg: const Color(0xFF059669),
      ),
      (
        label: 'MENUNGGU ATENSI',
        value: _summary['pending'] ?? 0,
        icon: Icons.trending_up_rounded,
        bg: const Color(0xFFFFF1F2),
        fg: const Color(0xFFE11D48),
      ),
    ];

    return GridView.builder(
      itemCount: cards.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.35,
      ),
      itemBuilder: (context, index) {
        final c = cards[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.gray100),
            boxShadow: const [
              BoxShadow(
                color: Color(0x06000000),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: c.bg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(c.icon, color: c.fg, size: 22),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.slate400,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _loading ? '...' : '${c.value}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChartSection() {
    final totalCat = _categoryDist.fold<int>(
      0,
      (sum, item) => sum + ((item['jumlah'] as num?)?.toInt() ?? 0),
    );

    final subjectMap = _genderDist[_genderSubjectTab] is Map
        ? Map<String, dynamic>.from(_genderDist[_genderSubjectTab] as Map)
        : <String, dynamic>{};
    final genderList = (subjectMap['gender'] is List)
        ? (subjectMap['gender'] as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList()
        : <Map<String, dynamic>>[];
    final statusList = (subjectMap['status'] is List)
        ? (subjectMap['status'] as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList()
        : <Map<String, dynamic>>[];

    final totalDept = _deptDist.fold<int>(
      0,
      (sum, item) => sum + ((item['value'] as num?)?.toInt() ?? 0),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Filter Periode Analitik
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.gray100),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.pie_chart_outline_rounded,
                      size: 19, color: AppColors.indigo600),
                  SizedBox(width: 8),
                  Text(
                    'Analitik Laporan PolijeCare',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.slate900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      key: ValueKey('year_$_selectedYear'),
                      initialValue: _selectedYear,
                      decoration: InputDecoration(
                        labelText: 'Tahun',
                        filled: true,
                        fillColor: AppColors.gray50,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: const ['Semua', '2026', '2025', '2024']
                          .map((y) => DropdownMenuItem(
                                value: y,
                                child: Text(
                                  y == 'Semua' ? 'Semua Tahun' : y,
                                  style: const TextStyle(fontSize: 12.5),
                                ),
                              ))
                          .toList(),
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() => _selectedYear = v);
                        _reloadCharts();
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      key: ValueKey('month_$_selectedMonth'),
                      initialValue: _selectedMonth,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Bulan',
                        filled: true,
                        fillColor: AppColors.gray50,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: _months
                          .map((m) => DropdownMenuItem(
                                value: m.val,
                                child: Text(
                                  m.label,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12.5),
                                ),
                              ))
                          .toList(),
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() => _selectedMonth = v);
                        _reloadCharts();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Chart 1: Distribusi Kategori Kekerasan
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.gray100),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Distribusi Kategori Kekerasan',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.slate900,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Sebaran laporan pengaduan berdasarkan jenis kekerasan.',
                style: TextStyle(fontSize: 12, color: AppColors.slate500),
              ),
              const SizedBox(height: 14),
              if (_categoryDist.isEmpty)
                const Text(
                  'Belum ada data kategori.',
                  style: TextStyle(fontSize: 12.5, color: AppColors.slate400),
                )
              else
                ..._categoryDist.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final item = entry.value;
                  final name = (item['kategori'] ?? item['name'] ?? '-').toString();
                  final count = (item['jumlah'] as num?)?.toInt() ?? 0;
                  final ratio = totalCat > 0 ? count / totalCat : 0.0;
                  final palette = [
                    const Color(0xFF4F46E5),
                    const Color(0xFFE11D48),
                    const Color(0xFFD97706),
                    const Color(0xFF059669),
                    const Color(0xFF0284C7),
                  ];
                  final barColor = palette[idx % palette.length];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.slate800,
                                ),
                              ),
                            ),
                            Text(
                              '$count Kasus (${(ratio * 100).round()}%)',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: barColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: ratio,
                            minHeight: 8,
                            backgroundColor: AppColors.gray100,
                            valueColor: AlwaysStoppedAnimation<Color>(barColor),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Chart 2: Statistik Demografi Pihak (Terlapor / Pelapor / Korban)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.gray100),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Demografi Gender & Status Pihak',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.slate900,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.gray100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    ('terlapor', 'Terlapor'),
                    ('pelapor', 'Pelapor'),
                    ('korban', 'Korban'),
                  ].map((tab) {
                    final active = _genderSubjectTab == tab.$1;
                    return Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(9),
                        onTap: () =>
                            setState(() => _genderSubjectTab = tab.$1),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: active ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            tab.$2,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: active
                                  ? AppColors.indigo600
                                  : AppColors.slate600,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'BERDASARKAN JENIS KELAMIN',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.slate400,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: genderList.map((g) {
                  final label = (g['name'] ?? '-').toString();
                  final val = (g['value'] as num?)?.toInt() ?? 0;
                  final isFemale = label.toLowerCase().contains('perempuan');
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isFemale
                          ? const Color(0xFFFFF1F2)
                          : const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isFemale ? Icons.female_rounded : Icons.male_rounded,
                          size: 18,
                          color: isFemale
                              ? const Color(0xFFE11D48)
                              : const Color(0xFF4F46E5),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$label: $val',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: isFemale
                                ? const Color(0xFFBE123C)
                                : const Color(0xFF3730A3),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              const Text(
                'BERDASARKAN STATUS CIVITAS',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.slate400,
                ),
              ),
              const SizedBox(height: 8),
              ...statusList.map((st) {
                final name = (st['name'] ?? '-').toString();
                final val = (st['value'] as num?)?.toInt() ?? 0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.slate700,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.gray100,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '$val',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.slate800,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Chart 3: Ranking Jurusan / Unit
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.gray100),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sebaran Jurusan / Unit Terlapor',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.slate900,
                ),
              ),
              const SizedBox(height: 12),
              ..._deptDist.asMap().entries.map((entry) {
                final rank = entry.key + 1;
                final d = entry.value;
                final name = (d['name'] ?? '-').toString();
                final val = (d['value'] as num?)?.toInt() ?? 0;
                final ratio = totalDept > 0 ? val / totalDept : 0.0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: rank == 1
                              ? const Color(0xFFEEF2FF)
                              : AppColors.gray100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$rank',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: rank == 1
                                ? AppColors.indigo600
                                : AppColors.slate600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    name,
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.slate800,
                                    ),
                                  ),
                                ),
                                Text(
                                  '$val Laporan',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.indigo600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: LinearProgressIndicator(
                                value: ratio,
                                minHeight: 6,
                                backgroundColor: AppColors.gray100,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Color(0xFF6366F1),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarSection() {
    final firstDayOfMonth =
        DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final daysInMonth =
        DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    final leadingEmpty = (firstDayOfMonth.weekday % 7); // Minggu = 0

    final selectedKey = _fmtDateKey(_selectedDay);
    final daySessions =
        _allSchedules.where((s) => s.tanggal == selectedKey).toList();
    final dayExternals =
        _externalAgendas.where((a) => a.date == selectedKey).toList();
    final dayHoliday = _holidayFor(_selectedDay);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
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
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kalender Penanganan Satgas',
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.slate900,
                      ),
                    ),
                    Text(
                      'Monitor jadwal konseling & agenda kegiatan Super Admin.',
                      style: TextStyle(fontSize: 12, color: AppColors.slate500),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _focusedMonth = DateTime(
                      _focusedMonth.year,
                      _focusedMonth.month - 1,
                    );
                  });
                },
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Text(
                DateFormat('MMM yyyy', 'id_ID').format(_focusedMonth),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.slate900,
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _focusedMonth = DateTime(
                      _focusedMonth.year,
                      _focusedMonth.month + 1,
                    );
                  });
                },
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Weekday Header
          Row(
            children: const ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab']
                .map(
                  (d) => Expanded(
                    child: Center(
                      child: Text(
                        d,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.slate400,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: leadingEmpty + daysInMonth,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              childAspectRatio: 1.05,
            ),
            itemBuilder: (context, index) {
              if (index < leadingEmpty) {
                return const SizedBox.shrink();
              }
              final dayNum = index - leadingEmpty + 1;
              final date =
                  DateTime(_focusedMonth.year, _focusedMonth.month, dayNum);
              final key = _fmtDateKey(date);
              final isSelected = key == selectedKey;
              final hasSession = _allSchedules.any((s) => s.tanggal == key);
              final hasExt = _externalAgendas.any((a) => a.date == key);
              final isHol = _holidayFor(date) != null || date.weekday == DateTime.sunday;

              return InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => setState(() => _selectedDay = date),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.indigo600
                        : (hasSession
                            ? const Color(0xFFEEF2FF)
                            : Colors.transparent),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$dayNum',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? Colors.white
                              : (isHol
                                  ? const Color(0xFFE11D48)
                                  : AppColors.slate800),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (hasSession)
                            Container(
                              width: 5,
                              height: 5,
                              margin: const EdgeInsets.symmetric(horizontal: 1),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.indigo600,
                              ),
                            ),
                          if (hasExt)
                            Container(
                              width: 5,
                              height: 5,
                              margin: const EdgeInsets.symmetric(horizontal: 1),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected
                                    ? const Color(0xFFFDE68A)
                                    : const Color(0xFFD97706),
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
          const Divider(height: 24),
          Row(
            children: [
              Expanded(
                child: Text(
                  DateFormat('EEEE, dd MMMM yyyy', 'id_ID')
                      .format(_selectedDay),
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.slate900,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: _showAddAgendaModal,
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text(
                  'Tambah Agenda',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          if (dayHoliday != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Hari Libur Nasional: $dayHoliday',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFE11D48),
                ),
              ),
            ),
          if (daySessions.isEmpty && dayExternals.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Tidak ada sesi konseling atau agenda pada tanggal ini.',
                style: TextStyle(fontSize: 12.5, color: AppColors.slate400),
              ),
            ),
          ...daySessions.map(
            (s) => InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                if (s.complaintId != null) {
                  Navigator.of(context).pushNamed(
                    AppRoutes.operatorComplaintDetail,
                    arguments: s.complaintId,
                  );
                }
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.schedule_rounded,
                        size: 18, color: AppColors.indigo600),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${s.jamMulai} - ${s.jamSelesai} WIB • ${s.counseleeName}',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.slate900,
                            ),
                          ),
                          Text(
                            '${s.jenisPengaduan} (Satgas: ${s.counselorName})',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: AppColors.slate600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded,
                        size: 18, color: AppColors.indigo600),
                  ],
                ),
              ),
            ),
          ),
          ...dayExternals.map(
            (ag) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7).withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.event_note_rounded,
                      size: 18, color: Color(0xFFD97706)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${ag.time} WIB • ${ag.title}',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.slate900,
                          ),
                        ),
                        if (ag.description.isNotEmpty)
                          Text(
                            ag.description,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: AppColors.slate600,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () async {
                      final next = await KonselorPortalService.instance
                          .deleteExternalAgenda(ag.id);
                      if (!mounted) return;
                      setState(() => _externalAgendas = next);
                    },
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      size: 18,
                      color: Color(0xFFE11D48),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
