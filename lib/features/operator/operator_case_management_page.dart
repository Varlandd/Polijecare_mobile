import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../app/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/launcher.dart';
import '../../data/services/konselor_portal_service.dart';
import '../../data/services/operator_portal_service.dart';
import 'operator_shell_page.dart';

/// Halaman Manajemen Kasus Terpadu Super Admin (`/operator/case-management`).
/// Porting 1:1 dari `pages/operator/case-management.jsx` di web PolijeCare.
class OperatorCaseManagementPage extends StatefulWidget {
  const OperatorCaseManagementPage({
    super.key,
    this.initialTab = 'new',
  });

  final String initialTab; // new | today | upcoming | active | archive

  @override
  State<OperatorCaseManagementPage> createState() =>
      _OperatorCaseManagementPageState();
}

class _OperatorCaseManagementPageState
    extends State<OperatorCaseManagementPage> {
  final TextEditingController _searchCtrl = TextEditingController();

  late String _activeTab;
  String _urgencyFilter = 'all';
  String _statusFilter = 'all';
  String _dateFrom = '';
  String _dateTo = '';

  bool _loading = true;
  bool _submitting = false;

  Map<String, int> _stats = {
    'total': 0,
    'pending': 0,
    'approved': 0,
    'completed': 0,
    'archived': 0,
    'today': 0,
    'upcoming': 0,
  };

  List<SatgasComplaintItem> _complaints = [];
  List<SatgasSessionRecord> _schedules = [];
  List<SatgasCounselor> _counselors = [];

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTab;
    _loadInitial();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadInitial() async {
    setState(() => _loading = true);
    try {
      final couns = await OperatorPortalService.instance.getOperatorCounselors();
      if (!mounted) return;
      _counselors = couns;
      await _fetchTabData();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _fetchTabData() async {
    setState(() => _loading = true);
    try {
      final summary =
          await OperatorPortalService.instance.getOperatorDashboardSummary();
      if (_activeTab == 'today' || _activeTab == 'upcoming') {
        final scheds =
            await OperatorPortalService.instance.getOperatorSchedules(
          tab: _activeTab,
          search: _searchCtrl.text,
          status: _statusFilter,
          dateFrom: _dateFrom,
          dateTo: _dateTo,
        );
        if (!mounted) return;
        setState(() {
          _stats = summary;
          _schedules = scheds;
        });
      } else {
        final comps =
            await OperatorPortalService.instance.getOperatorComplaints(
          tab: _activeTab,
          search: _searchCtrl.text,
          status: _statusFilter,
          urgency: _urgencyFilter,
          dateFrom: _dateFrom,
          dateTo: _dateTo,
        );
        if (!mounted) return;
        setState(() {
          _stats = summary;
          _complaints = comps;
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _resetFilters() {
    setState(() {
      _searchCtrl.clear();
      _urgencyFilter = 'all';
      _statusFilter = 'all';
      _dateFrom = '';
      _dateTo = '';
    });
    _fetchTabData();
  }

  String _formatPhoneForWa(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'\D'), '');
    if (cleaned.isEmpty) return '';
    if (cleaned.startsWith('0')) return '62${cleaned.substring(1)}';
    return cleaned;
  }

  Future<void> _handleQuickApprove(SatgasComplaintItem report) async {
    if (report.counselorId != null &&
        report.counselingSchedule != null &&
        report.counselingSchedule!.isNotEmpty) {
      setState(() => _submitting = true);
      try {
        await OperatorPortalService.instance.updateOperatorComplaintStatus(
          report.id,
          status: 'approved',
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Laporan disetujui!'),
            backgroundColor: Color(0xFF059669),
          ),
        );
        await _fetchTabData();
      } finally {
        if (mounted) setState(() => _submitting = false);
      }
    } else {
      await _showScheduleAndAssignModal(report);
    }
  }

  Future<void> _showScheduleAndAssignModal(SatgasComplaintItem report) async {
    int selectedCounselorId = report.counselorId ??
        (_counselors.isNotEmpty ? _counselors.first.id : 2);
    final selectedCoIds = List<int>.from(report.coCounselors);
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedTime = const TimeOfDay(hour: 9, minute: 0);

    if (report.counselingSchedule != null &&
        report.counselingSchedule!.isNotEmpty) {
      final parsed = DateTime.tryParse(report.counselingSchedule!);
      if (parsed != null) {
        selectedDate = parsed;
        selectedTime = TimeOfDay(hour: parsed.hour, minute: parsed.minute);
      }
    }

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
          final timeStr =
              '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';

          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Row(
              children: [
                Icon(Icons.shield_outlined, color: AppColors.indigo600),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Ploting Satgas & Jadwal Sesi',
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
                  Text(
                    'Kasus #${report.reportId} — ${report.title}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.slate600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'SATGAS PJ UTAMA *',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.slate700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<int>(
                    key: ValueKey('counselor_$selectedCounselorId'),
                    initialValue: _counselors.any((c) => c.id == selectedCounselorId)
                        ? selectedCounselorId
                        : (_counselors.isNotEmpty ? _counselors.first.id : 2),
                    isExpanded: true,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.gray50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: _counselors
                        .map(
                          (c) => DropdownMenuItem<int>(
                            value: c.id,
                            child: Text(
                              '${c.name} (${c.email})',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val == null) return;
                      setModalState(() {
                        selectedCounselorId = val;
                        selectedCoIds.remove(val);
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'REKAN SATGAS PENDAMPING (OPSIONAL)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.slate700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.gray50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.gray200),
                    ),
                    child: Column(
                      children: _counselors
                          .where((c) => c.id != selectedCounselorId)
                          .map((c) {
                        final checked = selectedCoIds.contains(c.id);
                        return CheckboxListTile(
                          dense: true,
                          value: checked,
                          activeColor: AppColors.indigo600,
                          title: Text(
                            c.name,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          onChanged: (v) {
                            setModalState(() {
                              if (v == true) {
                                selectedCoIds.add(c.id);
                              } else {
                                selectedCoIds.remove(c.id);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'JADWAL SESI PERTAMA *',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.slate700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: ctx,
                              initialDate: selectedDate,
                              firstDate: DateTime(2024),
                              lastDate: DateTime(2030),
                            );
                            if (picked != null) {
                              setModalState(() => selectedDate = picked);
                            }
                          },
                          icon: const Icon(Icons.calendar_today, size: 15),
                          label: Text(dateStr,
                              style: const TextStyle(fontSize: 12)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: ctx,
                              initialTime: selectedTime,
                            );
                            if (picked != null) {
                              setModalState(() => selectedTime = picked);
                            }
                          },
                          icon: const Icon(Icons.access_time, size: 15),
                          label: Text('$timeStr WIB',
                              style: const TextStyle(fontSize: 12)),
                        ),
                      ),
                    ],
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
                onPressed: () => Navigator.of(ctx).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.indigo600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Approve & Jadwalkan'),
              ),
            ],
          );
        },
      ),
    );

    if (saved == true) {
      setState(() => _submitting = true);
      try {
        final scheduleIso =
            '${DateFormat('yyyy-MM-dd').format(selectedDate)}T${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';
        await OperatorPortalService.instance.scheduleOperatorComplaint(
          report.id,
          counselorId: selectedCounselorId,
          counselingSchedule: scheduleIso,
          coCounselors: selectedCoIds,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Jadwal dan Tim Satgas berhasil di-approve!'),
            backgroundColor: AppColors.indigo600,
          ),
        );
        await _fetchTabData();
      } finally {
        if (mounted) setState(() => _submitting = false);
      }
    }
  }

  Future<void> _showStatusModal(
    SatgasComplaintItem report, {
    bool rejectOnly = false,
  }) async {
    String selectedStatus = rejectOnly ? 'rejected' : report.status;
    final reasonCtrl = TextEditingController(text: report.rejectionReason ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            rejectOnly ? 'Tolak Laporan' : 'Perbarui Status Kasus',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '#${report.reportId} — ${report.title}',
                  style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.slate600,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 14),
                if (!rejectOnly)
                  ...[
                    ('pending', 'Menunggu Verifikasi', const Color(0xFFD97706)),
                    ('approved', 'Dalam Penanganan', const Color(0xFF4F46E5)),
                    ('completed', 'Kasus Selesai', const Color(0xFF059669)),
                    ('rejected', 'Ditolak', const Color(0xFFE11D48)),
                  ].map((opt) {
                    final active = selectedStatus == opt.$1;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () =>
                            setModalState(() => selectedStatus = opt.$1),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 11),
                          decoration: BoxDecoration(
                            color: active
                                ? opt.$3.withValues(alpha: 0.08)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: active ? opt.$3 : AppColors.gray200,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                active
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_off,
                                color: active ? opt.$3 : AppColors.gray400,
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                opt.$2,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: active ? opt.$3 : AppColors.slate800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                if (selectedStatus == 'rejected') ...[
                  const SizedBox(height: 6),
                  TextField(
                    controller: reasonCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Alasan Penolakan *',
                      hintText: 'Jelaskan alasan penolakan laporan...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
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
                if (selectedStatus == 'rejected' &&
                    reasonCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content: Text('Harap isi alasan penolakan!'),
                      backgroundColor: Color(0xFFE11D48),
                    ),
                  );
                  return;
                }
                Navigator.of(ctx).pop(true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: rejectOnly
                    ? const Color(0xFFE11D48)
                    : AppColors.indigo600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(rejectOnly ? 'Tolak Laporan' : 'Simpan'),
            ),
          ],
        ),
      ),
    );

    if (saved == true) {
      setState(() => _submitting = true);
      try {
        await OperatorPortalService.instance.updateOperatorComplaintStatus(
          report.id,
          status: selectedStatus,
          rejectionReason:
              selectedStatus == 'rejected' ? reasonCtrl.text.trim() : null,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Status berhasil diperbarui!'),
            backgroundColor: AppColors.indigo600,
          ),
        );
        await _fetchTabData();
      } finally {
        if (mounted) setState(() => _submitting = false);
      }
    }
  }

  Future<void> _showExportModal() async {
    String expStatus = 'all';
    String expFrom = '';
    String expTo = '';
    final selectedCols = <String>[
      'report_id',
      'created_at',
      'category',
      'urgency',
      'status',
      'victim_name',
      'title',
      'chronology',
    ];
    String? csvPreview;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Row(
            children: [
              Icon(Icons.download_rounded, color: Color(0xFF059669)),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Ekspor Data Kasus (CSV)',
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
                DropdownButtonFormField<String>(
                  key: ValueKey('exp_status_$expStatus'),
                  initialValue: expStatus,
                  decoration: InputDecoration(
                    labelText: 'Filter Status',
                    filled: true,
                    fillColor: AppColors.gray50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('Semua Status')),
                    DropdownMenuItem(
                        value: 'pending', child: Text('Laporan Baru')),
                    DropdownMenuItem(
                        value: 'approved', child: Text('Dalam Penanganan')),
                    DropdownMenuItem(
                        value: 'completed', child: Text('Selesai')),
                    DropdownMenuItem(value: 'rejected', child: Text('Ditolak')),
                  ],
                  onChanged: (v) {
                    if (v != null) setModalState(() => expStatus = v);
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2024),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            setModalState(() {
                              expFrom = DateFormat('yyyy-MM-dd').format(picked);
                            });
                          }
                        },
                        icon: const Icon(Icons.date_range, size: 15),
                        label: Text(
                          expFrom.isEmpty ? 'Dari Tanggal' : expFrom,
                          style: const TextStyle(fontSize: 11.5),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2024),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            setModalState(() {
                              expTo = DateFormat('yyyy-MM-dd').format(picked);
                            });
                          }
                        },
                        icon: const Icon(Icons.event, size: 15),
                        label: Text(
                          expTo.isEmpty ? 'Sampai Tanggal' : expTo,
                          style: const TextStyle(fontSize: 11.5),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'PILIH KOLOM EKSPOR:',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.slate600,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: OperatorPortalService.exportColumnsCatalog.map((c) {
                    final active = selectedCols.contains(c.id);
                    return FilterChip(
                      selected: active,
                      selectedColor: const Color(0xFFD1FAE5),
                      checkmarkColor: const Color(0xFF059669),
                      label: Text(
                        c.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: active
                              ? const Color(0xFF047857)
                              : AppColors.slate700,
                        ),
                      ),
                      onSelected: (v) {
                        setModalState(() {
                          if (v) {
                            selectedCols.add(c.id);
                          } else if (selectedCols.length > 1) {
                            selectedCols.remove(c.id);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                if (csvPreview != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxHeight: 140),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.slate900,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SingleChildScrollView(
                      child: SelectableText(
                        csvPreview!,
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontFamily: 'monospace',
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Tutup'),
            ),
            if (csvPreview != null)
              OutlinedButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: csvPreview!));
                  if (!ctx.mounted) return;
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content: Text('Data CSV berhasil disalin ke Clipboard!'),
                      backgroundColor: Color(0xFF059669),
                    ),
                  );
                },
                icon: const Icon(Icons.copy_rounded, size: 15),
                label: const Text('Salin CSV'),
              ),
            ElevatedButton.icon(
              onPressed: () async {
                final csv = await OperatorPortalService.instance
                    .generateOperatorCasesCsv(
                  status: expStatus,
                  dateFrom: expFrom,
                  dateTo: expTo,
                  selectedColumns: selectedCols,
                );
                setModalState(() => csvPreview = csv);
              },
              icon: const Icon(Icons.file_download_outlined, size: 16),
              label: const Text('Buat CSV'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return OperatorShellPage(
      title: 'Manajemen Kasus',
      subtitle: 'Kelola laporan & penanganan pengaduan',
      activePath: AppRoutes.operatorCaseManagement,
      body: Stack(
        children: [
          RefreshIndicator(
            color: AppColors.indigo600,
            onRefresh: _fetchTabData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTopActions(),
                  const SizedBox(height: 16),
                  _buildFilterCard(),
                  const SizedBox(height: 16),
                  _buildTabsBar(),
                  const SizedBox(height: 16),
                  _buildDataList(),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
          if (_submitting)
            Container(
              color: Colors.black26,
              alignment: Alignment.center,
              child: const CircularProgressIndicator(color: AppColors.indigo600),
            ),
        ],
      ),
    );
  }

  Widget _buildTopActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Manajemen Kasus Terpadu',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.slate900,
          ),
        ),
        const SizedBox(height: 3),
        const Text(
          'Pusat kendali pengaduan, verifikasi, dan penugasan Tim Satgas.',
          style: TextStyle(fontSize: 12.5, color: AppColors.slate500),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context)
                    .pushNamed(AppRoutes.operatorManualCounseling);
              },
              icon: const Icon(Icons.add_rounded, size: 17),
              label: const Text(
                'Penanganan Manual',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.indigo600,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: _showExportModal,
              icon: const Icon(Icons.download_rounded, size: 16),
              label: const Text(
                'Ekspor CSV',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: _resetFilters,
              icon: const Icon(Icons.filter_alt_off_outlined, size: 16),
              label: const Text(
                'Reset',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.slate700,
                side: const BorderSide(color: AppColors.gray200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterCard() {
    return Container(
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
            onSubmitted: (_) => _fetchTabData(),
            decoration: InputDecoration(
              hintText: 'Cari ID Laporan, pelapor, atau judul kasus...',
              hintStyle: const TextStyle(fontSize: 13),
              prefixIcon: const Icon(Icons.search_rounded, size: 19),
              filled: true,
              fillColor: AppColors.gray50,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                  key: ValueKey('urg_$_urgencyFilter'),
                  initialValue: _urgencyFilter,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Urgensi',
                    filled: true,
                    fillColor: AppColors.gray50,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: 'all',
                        child:
                            Text('Semua', style: TextStyle(fontSize: 12))),
                    DropdownMenuItem(
                        value: 'low',
                        child:
                            Text('Ringan', style: TextStyle(fontSize: 12))),
                    DropdownMenuItem(
                        value: 'medium',
                        child:
                            Text('Sedang', style: TextStyle(fontSize: 12))),
                    DropdownMenuItem(
                        value: 'high',
                        child: Text('Berat', style: TextStyle(fontSize: 12))),
                    DropdownMenuItem(
                        value: 'critical',
                        child: Text('Sangat Berat',
                            style: TextStyle(fontSize: 12))),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => _urgencyFilter = v);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  key: ValueKey('sts_$_statusFilter'),
                  initialValue: _statusFilter,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Status',
                    filled: true,
                    fillColor: AppColors.gray50,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: 'all',
                        child:
                            Text('Semua', style: TextStyle(fontSize: 12))),
                    DropdownMenuItem(
                        value: 'pending',
                        child:
                            Text('Pending', style: TextStyle(fontSize: 12))),
                    DropdownMenuItem(
                        value: 'approved',
                        child: Text('Penanganan',
                            style: TextStyle(fontSize: 12))),
                    DropdownMenuItem(
                        value: 'completed',
                        child:
                            Text('Selesai', style: TextStyle(fontSize: 12))),
                    DropdownMenuItem(
                        value: 'rejected',
                        child:
                            Text('Ditolak', style: TextStyle(fontSize: 12))),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => _statusFilter = v);
                  },
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _fetchTabData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.slate900,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Cari',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabsBar() {
    final tabs = [
      (
        id: 'new',
        label: 'Laporan Baru',
        count: _stats['pending'] ?? 0,
        activeColor: const Color(0xFFE11D48),
      ),
      (
        id: 'today',
        label: 'Hari Ini',
        count: _stats['today'] ?? 0,
        activeColor: const Color(0xFF4F46E5),
      ),
      (
        id: 'upcoming',
        label: 'Mendatang',
        count: _stats['upcoming'] ?? 0,
        activeColor: const Color(0xFF2563EB),
      ),
      (
        id: 'active',
        label: 'Penanganan',
        count: _stats['approved'] ?? 0,
        activeColor: const Color(0xFF059669),
      ),
      (
        id: 'archive',
        label: 'Arsip Selesai',
        count: _stats['archived'] ?? 0,
        activeColor: const Color(0xFF1E293B),
      ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: tabs.map((t) {
          final active = _activeTab == t.id;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                setState(() => _activeTab = t.id);
                _fetchTabData();
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
                decoration: BoxDecoration(
                  color: active ? t.activeColor : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: active ? t.activeColor : AppColors.gray200,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      t.label,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: active ? Colors.white : AppColors.slate700,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: active
                            ? Colors.white.withValues(alpha: 0.22)
                            : AppColors.gray100,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${t.count}',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: active ? Colors.white : AppColors.slate700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDataList() {
    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(42),
          child: CircularProgressIndicator(color: AppColors.indigo600),
        ),
      );
    }

    final isScheduleTab = _activeTab == 'today' || _activeTab == 'upcoming';
    if (isScheduleTab && _schedules.isEmpty ||
        !isScheduleTab && _complaints.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(36),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.gray100),
        ),
        child: const Column(
          children: [
            Icon(Icons.inbox_outlined, size: 42, color: AppColors.gray300),
            SizedBox(height: 10),
            Text(
              'Tidak Ada Data pada Kategori Ini',
              style: TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w800,
                color: AppColors.slate900,
              ),
            ),
          ],
        ),
      );
    }

    if (isScheduleTab) {
      return Column(
        children: _schedules.map(_buildScheduleCard).toList(),
      );
    }
    return Column(
      children: _complaints.map(_buildComplaintCard).toList(),
    );
  }

  Widget _buildScheduleCard(SatgasSessionRecord sched) {
    final wa = _formatPhoneForWa(sched.guestPhone);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
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
                  sched.reportReference.isNotEmpty
                      ? '#${sched.reportReference}'
                      : '#SESI-${sched.id}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.indigo600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${sched.tanggal} • ${sched.jamMulai}-${sched.jamSelesai} WIB',
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.slate600,
                ),
              ),
              const Spacer(),
              _buildStatusPill(sched.status),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            sched.complaintTitle.isNotEmpty
                ? sched.complaintTitle
                : sched.jenisPengaduan,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.slate900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Pelapor: ${sched.counseleeName} • Satgas: ${sched.counselorName}',
            style: const TextStyle(fontSize: 12, color: AppColors.slate600),
          ),
          const Divider(height: 22),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await Navigator.of(context).pushNamed(
                      AppRoutes.operatorComplaintDetail,
                      arguments: sched.complaintId ?? 101,
                    );
                    _fetchTabData();
                  },
                  icon: const Icon(Icons.visibility_outlined, size: 16),
                  label: const Text('Detail Lengkap'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.slate900,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              if (wa.isNotEmpty) ...[
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => AppLauncher.openUrl('https://wa.me/$wa'),
                  icon: const Icon(Icons.chat_bubble_outline_rounded,
                      size: 15, color: Color(0xFF059669)),
                  label: const Text(
                    'WA',
                    style: TextStyle(
                      color: Color(0xFF059669),
                      fontWeight: FontWeight.w800,
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

  Widget _buildComplaintCard(SatgasComplaintItem item) {
    final urg = _urgencyMeta(item.urgencyLevel);
    final wa = _formatPhoneForWa(item.userPhone);
    final dateStr = DateFormat('dd MMM yyyy', 'id_ID').format(item.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.gray100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 5,
            decoration: BoxDecoration(
              color: urg.color,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(22)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '#${item.reportId}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.indigo600,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: urg.color,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        urg.label,
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    _buildStatusPill(item.status),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.slate900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.slate600,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '${item.categoryName} • Dilaporkan $dateStr',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.slate500,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.gray50,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pelapor: ${item.userName} (${item.nimNip})',
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.slate900,
                              ),
                            ),
                            Text(
                              'Satgas PJ: ${item.counselorName}',
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: AppColors.slate500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (wa.isNotEmpty)
                        InkWell(
                          onTap: () => AppLauncher.openUrl('https://wa.me/$wa'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'HUBUNGI WA',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF059669),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await Navigator.of(context).pushNamed(
                            AppRoutes.operatorComplaintDetail,
                            arguments: item.id,
                          );
                          _fetchTabData();
                        },
                        icon: const Icon(Icons.visibility_outlined, size: 16),
                        label: const Text(
                          'Detail Lengkap',
                          style: TextStyle(
                              fontSize: 12.5, fontWeight: FontWeight.w700),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.slate900,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (item.status == 'pending') ...[
                      IconButton(
                        onPressed: () => _handleQuickApprove(item),
                        tooltip: 'Setujui Laporan',
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFFECFDF5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(
                          Icons.check_rounded,
                          size: 18,
                          color: Color(0xFF059669),
                        ),
                      ),
                      const SizedBox(width: 6),
                      IconButton(
                        onPressed: () =>
                            _showStatusModal(item, rejectOnly: true),
                        tooltip: 'Tolak Laporan',
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFFFFF1F2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: Color(0xFFE11D48),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    IconButton(
                      onPressed: () => _showScheduleAndAssignModal(item),
                      tooltip: 'Ploting Satgas & Jadwal',
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFFEEF2FF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(
                        Icons.people_alt_outlined,
                        size: 18,
                        color: AppColors.indigo600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      onPressed: () => _showStatusModal(item),
                      tooltip: 'Ubah Status',
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.gray100,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(
                        Icons.edit_note_rounded,
                        size: 18,
                        color: AppColors.slate700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  ({String label, Color color}) _urgencyMeta(String level) {
    switch (level.toLowerCase()) {
      case 'critical':
        return (label: 'Sangat Berat', color: const Color(0xFFF43F5E));
      case 'high':
        return (label: 'Berat', color: const Color(0xFFF97316));
      case 'medium':
        return (label: 'Sedang', color: const Color(0xFFF59E0B));
      case 'low':
        return (label: 'Ringan', color: const Color(0xFF3B82F6));
      default:
        return (label: 'Belum Dinilai', color: AppColors.slate500);
    }
  }

  Widget _buildStatusPill(String status) {
    final s = status.toLowerCase();
    Color bg = const Color(0xFFFEF3C7);
    Color fg = const Color(0xFFB45309);
    String label = 'Menunggu';

    if (s == 'approved') {
      bg = const Color(0xFFEEF2FF);
      fg = const Color(0xFF4338CA);
      label = 'Penanganan';
    } else if (s == 'completed') {
      bg = const Color(0xFFECFDF5);
      fg = const Color(0xFF047857);
      label = 'Selesai';
    } else if (s == 'rejected') {
      bg = const Color(0xFFFFF1F2);
      fg = const Color(0xFFBE123C);
      label = 'Ditolak';
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
