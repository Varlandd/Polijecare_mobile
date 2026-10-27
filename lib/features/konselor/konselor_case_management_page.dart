import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../app/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/launcher.dart';
import '../../data/services/konselor_portal_service.dart';
import 'konselor_shell_page.dart';

/// Halaman Manajemen Kasus Satgas (`/konselor/case-management` & `/konselor/pengaduan`).
/// Porting 1:1 dari `pages/konselor/case-management.jsx` di web PolijeCare.
class KonselorCaseManagementPage extends StatefulWidget {
  const KonselorCaseManagementPage({
    super.key,
    this.initialTab = 'today',
  });

  final String initialTab; // today | new | upcoming | active | archive

  @override
  State<KonselorCaseManagementPage> createState() =>
      _KonselorCaseManagementPageState();
}

class _KonselorCaseManagementPageState
    extends State<KonselorCaseManagementPage> {
  final TextEditingController _searchCtrl = TextEditingController();

  late String _activeTab;
  String _selectedUrgency = 'all';
  String _selectedStatus = 'all';
  String _dateFrom = '';
  String _dateTo = '';

  bool _loading = true;
  bool _actionLoading = false;

  Map<String, int> _stats = {
    'total': 0,
    'pending': 0,
    'approved': 0,
    'archived': 0,
    'today': 0,
    'upcoming': 0,
    'completed': 0,
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
      final results = await Future.wait([
        KonselorPortalService.instance.getCaseManagementStats(),
        KonselorPortalService.instance.getCounselors(),
      ]);
      if (!mounted) return;
      _stats = results[0] as Map<String, int>;
      _counselors = results[1] as List<SatgasCounselor>;
      await _fetchTabData();
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _fetchTabData() async {
    setState(() => _loading = true);
    try {
      final stats =
          await KonselorPortalService.instance.getCaseManagementStats();
      if (_activeTab == 'today' || _activeTab == 'upcoming') {
        final scheds = await KonselorPortalService.instance.getSchedules(
          tab: _activeTab,
          search: _searchCtrl.text,
          status: _selectedStatus,
          dateFrom: _dateFrom,
          dateTo: _dateTo,
        );
        if (!mounted) return;
        setState(() {
          _stats = stats;
          _schedules = scheds;
        });
      } else {
        final comps = await KonselorPortalService.instance.getComplaints(
          tab: _activeTab,
          search: _searchCtrl.text,
          status: _selectedStatus,
          urgency: _selectedUrgency,
          dateFrom: _dateFrom,
          dateTo: _dateTo,
        );
        if (!mounted) return;
        setState(() {
          _stats = stats;
          _complaints = comps;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _resetFilters() {
    setState(() {
      _searchCtrl.clear();
      _selectedUrgency = 'all';
      _selectedStatus = 'all';
      _dateFrom = '';
      _dateTo = '';
    });
    _fetchTabData();
  }

  String _formatPhoneForWa(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'\D'), '');
    if (cleaned.isEmpty) return '';
    if (cleaned.startsWith('0')) {
      return '62${cleaned.substring(1)}';
    }
    return cleaned;
  }

  Future<void> _handleQuickApprove(int complaintId) async {
    setState(() => _actionLoading = true);
    try {
      await KonselorPortalService.instance.updateComplaintStatus(
        complaintId,
        status: 'approved',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kasus telah disetujui dan siap ditangani!'),
          backgroundColor: Color(0xFF059669),
        ),
      );
      await _fetchTabData();
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _showRejectModal(SatgasComplaintItem report) async {
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFE4E6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.cancel_outlined,
                color: Color(0xFFE11D48),
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Tolak Laporan',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFFE4E6)),
                ),
                child: Text(
                  'Anda akan menolak laporan #${report.reportId} (${report.title}). Pelapor akan menerima alasan penolakan ini.',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9F1239),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'ALASAN PENOLAKAN *',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.gray700,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: reasonCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText:
                      'Jelaskan alasan penolakan secara sopan dan jelas...',
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
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonCtrl.text.trim().isEmpty) {
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
              backgroundColor: const Color(0xFFE11D48),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Tolak Laporan'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _actionLoading = true);
      try {
        await KonselorPortalService.instance.updateComplaintStatus(
          report.id,
          status: 'rejected',
          rejectionReason: reasonCtrl.text.trim(),
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Laporan telah ditolak.'),
            backgroundColor: Color(0xFFE11D48),
          ),
        );
        await _fetchTabData();
      } finally {
        if (mounted) setState(() => _actionLoading = false);
      }
    }
  }

  Future<void> _showDelegateModal(SatgasComplaintItem report) async {
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
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.people_alt_outlined,
                    color: Color(0xFF4F46E5),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Delegasikan Kasus',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE0E7FF)),
                    ),
                    child: Text(
                      'Tetapkan Penanggung Jawab (PJ Utama), rekan pendamping, dan jadwal sesi pertama untuk kasus #${report.reportId}.',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF3730A3),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'PENANGGUNG JAWAB (PJ UTAMA) *',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.gray700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<int>(
                    initialValue: _counselors.any((c) => c.id == selectedCounselorId)
                        ? selectedCounselorId
                        : (_counselors.isNotEmpty ? _counselors.first.id : 2),
                    isExpanded: true,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.gray50,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
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
                  const SizedBox(height: 14),
                  const Text(
                    'REKAN SATGAS PENDAMPING (OPSIONAL)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.gray700,
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
                          activeColor: const Color(0xFF4F46E5),
                          title: Text(
                            c.name,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            c.email,
                            style: const TextStyle(fontSize: 11),
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
                  const SizedBox(height: 14),
                  const Text(
                    'JADWAL SESI PERTAMA *',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.gray700,
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
                          label: Text(
                            dateStr,
                            style: const TextStyle(fontSize: 12.5),
                          ),
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
                          label: Text(
                            '$timeStr WIB',
                            style: const TextStyle(fontSize: 12.5),
                          ),
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
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Simpan & Jadwalkan'),
              ),
            ],
          );
        },
      ),
    );

    if (saved == true) {
      setState(() => _actionLoading = true);
      try {
        final scheduleIso =
            '${DateFormat('yyyy-MM-dd').format(selectedDate)}T${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';
        await KonselorPortalService.instance.delegateOrScheduleComplaint(
          report.id,
          counselorId: selectedCounselorId,
          counselingSchedule: scheduleIso,
          coCounselors: selectedCoIds,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Penugasan & jadwal sesi berhasil disimpan!'),
            backgroundColor: Color(0xFF4F46E5),
          ),
        );
        await _fetchTabData();
      } finally {
        if (mounted) setState(() => _actionLoading = false);
      }
    }
  }

  Future<void> _showUpdateStatusModal(SatgasComplaintItem report) async {
    String newStatus = report.status;
    final reasonCtrl = TextEditingController(text: report.rejectionReason ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text(
            'Perbarui Status Kasus',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kasus #${report.reportId} — ${report.title}',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.gray600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 14),
                ...[
                  ('pending', 'Menunggu Verifikasi', const Color(0xFFD97706)),
                  ('approved', 'Dalam Penanganan (Diproses)', const Color(0xFF4F46E5)),
                  ('completed', 'Kasus Selesai', const Color(0xFF059669)),
                  ('rejected', 'Ditolak', const Color(0xFFE11D48)),
                ].map((opt) {
                  final active = newStatus == opt.$1;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => setModalState(() => newStatus = opt.$1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: active
                              ? opt.$3.withValues(alpha: 0.08)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: active ? opt.$3 : AppColors.gray200,
                            width: active ? 1.5 : 1,
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
                            Expanded(
                              child: Text(
                                opt.$2,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color:
                                      active ? opt.$3 : AppColors.gray800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                if (newStatus == 'rejected') ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: reasonCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Alasan Penolakan *',
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
                if (newStatus == 'rejected' &&
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
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Simpan Perubahan'),
            ),
          ],
        ),
      ),
    );

    if (saved == true) {
      setState(() => _actionLoading = true);
      try {
        await KonselorPortalService.instance.updateComplaintStatus(
          report.id,
          status: newStatus,
          rejectionReason:
              newStatus == 'rejected' ? reasonCtrl.text.trim() : null,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Status kasus berhasil diperbarui!'),
            backgroundColor: Color(0xFF4F46E5),
          ),
        );
        await _fetchTabData();
      } finally {
        if (mounted) setState(() => _actionLoading = false);
      }
    }
  }

  Future<void> _showExportModal() async {
    String expStatus = 'all';
    String expFrom = '';
    String expTo = '';
    String? csvPreview;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.download_rounded,
                  color: Color(0xFF059669),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Ekspor Data Kasus (CSV)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'STATUS LAPORAN',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.gray700,
                  ),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: expStatus,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.gray50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('Semua Status')),
                    DropdownMenuItem(
                        value: 'pending', child: Text('Menunggu Verifikasi')),
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
                const SizedBox(height: 12),
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
                if (csvPreview != null) ...[
                  const SizedBox(height: 14),
                  const Text(
                    'HASIL EKSPOR CSV:',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF059669),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxHeight: 160),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.gray900,
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
                final res =
                    await KonselorPortalService.instance.generateExportCsv(
                  status: expStatus,
                  dateFrom: expFrom,
                  dateTo: expTo,
                );
                setModalState(() => csvPreview = res);
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
    return KonselorShellPage(
      title: 'Manajemen Kasus',
      subtitle:
          'Kelola pengaduan dan penanganan kasus dengan alur yang efisien.',
      activePath: AppRoutes.konselorCaseManagement,
      body: Stack(
        children: [
          RefreshIndicator(
            color: const Color(0xFF4F46E5),
            onRefresh: _fetchTabData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderSection(),
                  const SizedBox(height: 16),
                  _buildStatsBar(),
                  const SizedBox(height: 16),
                  _buildUnifiedFilterBar(),
                  const SizedBox(height: 16),
                  _buildNavigationTabs(),
                  const SizedBox(height: 16),
                  _buildTabContent(),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
          if (_actionLoading)
            Container(
              color: Colors.black26,
              alignment: Alignment.center,
              child: const CircularProgressIndicator(
                color: Color(0xFF4F46E5),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Manajemen Kasus',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.gray900,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Kelola pengaduan dan penanganan kasus dengan alur yang efisien.',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.gray500,
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ElevatedButton.icon(
              onPressed: () async {
                await Navigator.of(context).pushNamed(
                  AppRoutes.konselorManualCounseling,
                );
                _fetchTabData();
              },
              icon: const Icon(Icons.add_rounded, size: 17),
              label: const Text(
                'PENANGANAN MANUAL',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                elevation: 2,
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
                'EKSPOR',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
                elevation: 1,
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
                foregroundColor: AppColors.gray600,
                backgroundColor: Colors.white,
                side: const BorderSide(color: AppColors.gray200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            IconButton(
              onPressed: _fetchTabData,
              tooltip: 'Muat Ulang',
              style: IconButton.styleFrom(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: AppColors.gray200),
                ),
              ),
              icon: const Icon(
                Icons.refresh_rounded,
                size: 18,
                color: AppColors.gray700,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsBar() {
    final total = _stats['total'] ?? 0;
    final pending = _stats['pending'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gray100),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE0E7FF)),
                  ),
                  child: const Icon(
                    Icons.shield_outlined,
                    color: Color(0xFF4F46E5),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'SATGAS AKTIF — TOTAL KASUS SAYA',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.gray400,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '$total',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: AppColors.gray900,
                            ),
                          ),
                          const SizedBox(width: 5),
                          const Text(
                            'Kasus',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.gray400,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: AppColors.gray100,
            margin: const EdgeInsets.symmetric(horizontal: 10),
          ),
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'BUTUH ATENSI',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.gray400,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$pending Baru',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFD97706),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: pending > 0
                      ? const Color(0xFFFEF3C7)
                      : AppColors.gray50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  size: 20,
                  color: pending > 0
                      ? const Color(0xFFD97706)
                      : AppColors.gray300,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUnifiedFilterBar() {
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
              hintText: 'Cari ID Laporan atau Kata kunci...',
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
                  initialValue: _selectedUrgency,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Urgensi',
                    labelStyle: const TextStyle(fontSize: 11.5),
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
                        child: Text('Semua Urgensi',
                            style: TextStyle(fontSize: 12))),
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
                        child:
                            Text('Darurat', style: TextStyle(fontSize: 12))),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => _selectedUrgency = v);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedStatus,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Status',
                    labelStyle: const TextStyle(fontSize: 11.5),
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
                        child: Text('Semua Status',
                            style: TextStyle(fontSize: 12))),
                    DropdownMenuItem(
                        value: 'pending',
                        child:
                            Text('Pending', style: TextStyle(fontSize: 12))),
                    DropdownMenuItem(
                        value: 'approved',
                        child:
                            Text('Ditangani', style: TextStyle(fontSize: 12))),
                    DropdownMenuItem(
                        value: 'completed',
                        child:
                            Text('Selesai', style: TextStyle(fontSize: 12))),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => _selectedStatus = v);
                  },
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _fetchTabData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gray900,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Terapkan',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationTabs() {
    final tabs = [
      (
        id: 'new',
        label: 'Laporan Baru',
        icon: Icons.error_outline_rounded,
        count: _stats['pending'] ?? 0,
      ),
      (
        id: 'today',
        label: 'Agenda Hari Ini',
        icon: Icons.access_time_rounded,
        count: _stats['today'] ?? 0,
      ),
      (
        id: 'upcoming',
        label: 'Jadwal Mendatang',
        icon: Icons.calendar_today_outlined,
        count: _stats['upcoming'] ?? 0,
      ),
      (
        id: 'active',
        label: 'Dalam Penanganan',
        icon: Icons.bolt_rounded,
        count: _stats['approved'] ?? 0,
      ),
      (
        id: 'archive',
        label: 'Riwayat Kasus',
        icon: Icons.check_circle_outline_rounded,
        count: _stats['archived'] ?? 0,
      ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppColors.gray100.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: tabs.map((tab) {
            final isActive = _activeTab == tab.id;
            return Padding(
              padding: const EdgeInsets.only(right: 4),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  setState(() => _activeTab = tab.id);
                  _fetchTabData();
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: isActive
                        ? const [
                            BoxShadow(
                              color: Color(0x0A000000),
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        tab.icon,
                        size: 16,
                        color: isActive
                            ? const Color(0xFF4F46E5)
                            : AppColors.gray500,
                      ),
                      const SizedBox(width: 7),
                      Text(
                        tab.label,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: isActive
                              ? const Color(0xFF4F46E5)
                              : AppColors.gray600,
                        ),
                      ),
                      if (tab.count > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: isActive
                                ? const Color(0xFF4F46E5)
                                : AppColors.gray200,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${tab.count}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color:
                                  isActive ? Colors.white : AppColors.gray700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    if (_loading) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 64),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.gray100),
        ),
        child: const Column(
          children: [
            CircularProgressIndicator(color: Color(0xFF4F46E5)),
            SizedBox(height: 14),
            Text(
              'MENYINGKRONKAN DATA SATGAS...',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.gray400,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      );
    }

    final isScheduleTab = _activeTab == 'today' || _activeTab == 'upcoming';
    if (isScheduleTab && _schedules.isEmpty ||
        !isScheduleTab && _complaints.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.gray100),
        ),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.gray50,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.inbox_outlined,
                size: 32,
                color: AppColors.gray300,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Tidak Ada Data Kasus',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.gray900,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Tidak ditemukan laporan atau jadwal pada kategori ini.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.gray500),
            ),
          ],
        ),
      );
    }

    if (isScheduleTab) {
      return Column(
        children: _schedules.map(_buildScheduleCaseCard).toList(),
      );
    }
    return Column(
      children: _complaints.map(_buildComplaintCaseCard).toList(),
    );
  }

  Widget _buildScheduleCaseCard(SatgasSessionRecord sched) {
    final waPhone = _formatPhoneForWa(sched.guestPhone);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
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
        children: [
          // Top ribbon
          Container(
            height: 5,
            decoration: const BoxDecoration(
              color: Color(0xFF4F46E5),
              borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
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
                          color: Color(0xFF4F46E5),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        sched.tanggal,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.gray500,
                        ),
                      ),
                    ),
                    _buildStatusChip(sched.status),
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
                    color: AppColors.gray900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  sched.keteranganPihak.isNotEmpty
                      ? sched.keteranganPihak
                      : 'Sesi pendampingan terjadwal bersama Satgas PPKPT.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.gray600,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                // Schedule box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF).withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE0E7FF)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.access_time_filled_rounded,
                        size: 16,
                        color: Color(0xFF4F46E5),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${sched.jamMulai} - ${sched.jamSelesai} WIB',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF312E81),
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        sched.metode == 'online'
                            ? Icons.videocam_outlined
                            : Icons.location_on_outlined,
                        size: 15,
                        color: const Color(0xFF4F46E5),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        sched.metode.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF4F46E5),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Reporter & WA
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppColors.gray100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        sched.counseleeName.isNotEmpty
                            ? sched.counseleeName[0].toUpperCase()
                            : 'P',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.gray700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sched.counseleeName,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.gray900,
                            ),
                          ),
                          Text(
                            'NIM/ID: ${sched.guestNim.isNotEmpty ? sched.guestNim : '-'} • PJ: ${sched.counselorName}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.gray500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (waPhone.isNotEmpty)
                      InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () =>
                            AppLauncher.openUrl('https://wa.me/$waPhone'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFD1FAE5)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline_rounded,
                                size: 13,
                                color: Color(0xFF059669),
                              ),
                              SizedBox(width: 4),
                              Text(
                                'HUBUNGI',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF059669),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                const Divider(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final targetId = sched.complaintId ?? 101;
                          await Navigator.of(context).pushNamed(
                            AppRoutes.konselorComplaintDetail,
                            arguments: targetId,
                          );
                          _fetchTabData();
                        },
                        icon: const Icon(Icons.visibility_outlined, size: 16),
                        label: const Text(
                          'Detail Lengkap',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.gray900,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
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
    );
  }

  Widget _buildComplaintCaseCard(SatgasComplaintItem item) {
    final urgencyMeta = _getUrgencyMeta(item.urgencyLevel);
    final waPhone = _formatPhoneForWa(item.userPhone);
    final dateFormatted =
        DateFormat('dd MMM yyyy', 'id_ID').format(item.incidentDate);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
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
        children: [
          // Urgency ribbon
          Container(
            height: 5,
            decoration: BoxDecoration(
              color: urgencyMeta.barColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(22)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row ID, Urgency, Status
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE0E7FF)),
                      ),
                      child: Text(
                        '#${item.reportId}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF4F46E5),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: urgencyMeta.bgColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'URGENSI: ${urgencyMeta.label.toUpperCase()}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: urgencyMeta.textColor,
                        ),
                      ),
                    ),
                    _buildStatusChip(item.status),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.gray900,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.gray600,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.folder_outlined,
                            size: 14, color: AppColors.gray400),
                        const SizedBox(width: 4),
                        Text(
                          item.categoryName,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.gray600,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.event_outlined,
                            size: 14, color: AppColors.gray400),
                        const SizedBox(width: 4),
                        Text(
                          dateFormatted,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.gray600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Pelapor & Satgas PJ box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.gray50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.gray100),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.gray200),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          item.userName.isNotEmpty
                              ? item.userName[0].toUpperCase()
                              : 'P',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.gray800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.userName,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.gray900,
                              ),
                            ),
                            Text(
                              'NIM: ${item.nimNip} • PJ: ${item.counselorName}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.gray500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (waPhone.isNotEmpty)
                        InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () =>
                              AppLauncher.openUrl('https://wa.me/$waPhone'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(10),
                              border:
                                  Border.all(color: const Color(0xFFD1FAE5)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  size: 13,
                                  color: Color(0xFF059669),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'HUBUNGI',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF059669),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Action Bar
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await Navigator.of(context).pushNamed(
                            AppRoutes.konselorComplaintDetail,
                            arguments: item.id,
                          );
                          _fetchTabData();
                        },
                        icon: const Icon(Icons.visibility_outlined, size: 16),
                        label: const Text(
                          'Detail Lengkap',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.gray900,
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
                        onPressed: () => _handleQuickApprove(item.id),
                        tooltip: 'Setujui & Tangani',
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFFECFDF5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: Color(0xFFD1FAE5)),
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
                        onPressed: () => _showRejectModal(item),
                        tooltip: 'Tolak Laporan',
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFFFFF1F2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: Color(0xFFFFE4E6)),
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
                      onPressed: () => _showDelegateModal(item),
                      tooltip: 'Delegasikan & Jadwalkan',
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFFEEF2FF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Color(0xFFE0E7FF)),
                        ),
                      ),
                      icon: const Icon(
                        Icons.people_outline_rounded,
                        size: 18,
                        color: Color(0xFF4F46E5),
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      onPressed: () => _showUpdateStatusModal(item),
                      tooltip: 'Perbarui Status',
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.gray50,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: AppColors.gray200),
                        ),
                      ),
                      icon: const Icon(
                        Icons.edit_note_rounded,
                        size: 18,
                        color: AppColors.gray700,
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

  Widget _buildStatusChip(String status) {
    final s = status.toLowerCase();
    Color bg = const Color(0xFFFEF3C7);
    Color fg = const Color(0xFFB45309);
    String label = 'Menunggu';

    if (s == 'approved') {
      bg = const Color(0xFFEEF2FF);
      fg = const Color(0xFF4338CA);
      label = 'Diproses';
    } else if (s == 'completed') {
      bg = const Color(0xFFECFDF5);
      fg = const Color(0xFF047857);
      label = 'Selesai';
    } else if (s == 'rejected') {
      bg = const Color(0xFFFFF1F2);
      fg = const Color(0xFFBE123C);
      label = 'Ditolak';
    } else if (s == 'cancelled') {
      bg = AppColors.gray100;
      fg = AppColors.gray600;
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

  ({String label, Color bgColor, Color textColor, Color barColor})
      _getUrgencyMeta(String level) {
    switch (level.toLowerCase()) {
      case 'critical':
        return (
          label: 'Darurat',
          bgColor: const Color(0xFFFFE4E6),
          textColor: const Color(0xFFBE123C),
          barColor: const Color(0xFFE11D48),
        );
      case 'high':
        return (
          label: 'Tinggi',
          bgColor: const Color(0xFFFFEDD5),
          textColor: const Color(0xFFC2410C),
          barColor: const Color(0xFFF97316),
        );
      case 'low':
        return (
          label: 'Rendah',
          bgColor: const Color(0xFFECFDF5),
          textColor: const Color(0xFF047857),
          barColor: const Color(0xFF10B981),
        );
      default:
        return (
          label: 'Sedang',
          bgColor: const Color(0xFFFEF3C7),
          textColor: const Color(0xFFB45309),
          barColor: const Color(0xFFF59E0B),
        );
    }
  }
}

