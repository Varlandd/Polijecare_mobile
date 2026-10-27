import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/user_complaint.dart';
import '../../data/services/user_portal_service.dart';
import 'user_shell_page.dart';

/// Halaman Ajukan Jadwal Penanganan Satgas (`/user/counseling-request`)
/// — port 1:1 dari `pages/user/counseling-request.jsx`.
class CounselingRequestPage extends StatefulWidget {
  const CounselingRequestPage({super.key});

  @override
  State<CounselingRequestPage> createState() => _CounselingRequestPageState();
}

class _CounselingRequestPageState extends State<CounselingRequestPage> {
  List<CounselorOption> _counselors = const [];
  int? _selectedCounselorId;
  String _selectedDate = '';
  List<TimeSlotOption> _availableSlots = const [];
  TimeSlotOption? _selectedSlot;
  String _method = 'online'; // 'online' | 'offline'
  final _meetingLinkCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _complaintIdCtrl = TextEditingController();
  final _jenisPengaduanCtrl = TextEditingController();

  bool _loading = false;
  String _error = '';
  String _success = '';

  @override
  void initState() {
    super.initState();
    _loadCounselors();
  }

  @override
  void dispose() {
    _meetingLinkCtrl.dispose();
    _locationCtrl.dispose();
    _complaintIdCtrl.dispose();
    _jenisPengaduanCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCounselors() async {
    setState(() => _loading = true);
    final list = await UserPortalService.instance.getCounselors();
    if (!mounted) return;
    setState(() {
      _counselors = list;
      if (list.isNotEmpty) {
        _selectedCounselorId = list.first.id;
      }
      _loading = false;
    });
  }

  Future<void> _loadSlots() async {
    if (_selectedCounselorId == null || _selectedDate.isEmpty) {
      setState(() {
        _availableSlots = const [];
        _selectedSlot = null;
      });
      return;
    }
    setState(() => _loading = true);
    final slots = await UserPortalService.instance.getAvailableSlots(
      _selectedCounselorId!,
      _selectedDate,
    );
    if (!mounted) return;
    setState(() {
      _availableSlots = slots;
      _selectedSlot = null;
      _loading = false;
    });
  }

  void _resetForm() {
    setState(() {
      _selectedDate = '';
      _availableSlots = const [];
      _selectedSlot = null;
      _method = 'online';
      _meetingLinkCtrl.clear();
      _locationCtrl.clear();
      _complaintIdCtrl.clear();
      _jenisPengaduanCtrl.clear();
      _error = '';
    });
  }

  Future<void> _handleSubmit() async {
    if (_selectedCounselorId == null ||
        _selectedDate.isEmpty ||
        _selectedSlot == null) {
      setState(() {
        _error = 'Harap lengkapi semua field yang wajib diisi';
      });
      return;
    }
    if (_method == 'offline' && _locationCtrl.text.trim().isEmpty) {
      setState(() {
        _error = 'Harap isi lokasi untuk penanganan offline';
      });
      return;
    }
    if (_method == 'online' && _meetingLinkCtrl.text.trim().isEmpty) {
      _meetingLinkCtrl.text =
          UserPortalService.instance.generateMeetingLink();
    }

    setState(() {
      _loading = true;
      _error = '';
      _success = '';
    });

    final counselorName = _counselors
            .where((c) => c.id == _selectedCounselorId)
            .firstOrNull
            ?.name ??
        'Satgas PolijeCare';

    final ok = await UserPortalService.instance.requestCounselingSchedule(
      counselorId: _selectedCounselorId!,
      counselorName: counselorName,
      complaintId: _complaintIdCtrl.text.trim(),
      jenisPengaduan: _jenisPengaduanCtrl.text.trim(),
      tanggal: _selectedDate,
      jamMulai: _selectedSlot!.jamMulai,
      jamSelesai: _selectedSlot!.jamSelesai,
      metode: _method,
      lokasi: _locationCtrl.text.trim(),
      meetingLink: _meetingLinkCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() {
      _loading = false;
      if (ok) {
        _success = 'Permintaan jadwal penanganan berhasil dikirim!';
        _resetForm();
      } else {
        _error = 'Gagal mengirim permintaan';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return UserShellPage(
      title: 'Ajukan Penanganan',
      subtitle: 'Jadwalkan sesi pendampingan bersama Satgas',
      activePath: AppRoutes.userDashboard,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ajukan Jadwal Penanganan Satgas',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.gray900,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Pilih anggota Satgas, tanggal, dan waktu untuk sesi penanganan Anda',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.gray600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDBEAFE),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 14,
                        color: Color(0xFF1D4ED8),
                      ),
                      SizedBox(width: 5),
                      Text(
                        'Langkah 1 dari 3',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1D4ED8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // ── Alerts ──
            if (_error.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        color: Color(0xFFDC2626), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _error,
                        style: const TextStyle(
                          color: Color(0xFFB91C1C),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(() => _error = ''),
                      icon: const Icon(Icons.close_rounded, size: 18),
                    ),
                  ],
                ),
              ),

            if (_success.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle_outline_rounded,
                        color: Color(0xFF16A34A), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _success,
                            style: const TextStyle(
                              color: Color(0xFF15803D),
                              fontWeight: FontWeight.bold,
                              fontSize: 13.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Notifikasi telah dikirim ke tim Satgas dan operator. Anda akan menerima konfirmasi via email.',
                            style: TextStyle(
                              color: Color(0xFF16A34A),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(() => _success = ''),
                      icon: const Icon(Icons.close_rounded, size: 18),
                    ),
                  ],
                ),
              ),

            // ── Main Form Card ──
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.gray100),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0D000000),
                    blurRadius: 18,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Step 1: Pilih Satgas Pendamping
                  const _StepTitle(
                    icon: Icons.person_outline_rounded,
                    iconBg: Color(0xFFDBEAFE),
                    iconColor: Color(0xFF2563EB),
                    title: 'Pilih Satgas Pendamping',
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Satgas Pendamping *',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.gray700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<int>(
                    initialValue: _selectedCounselorId,
                    isExpanded: true,
                    hint: const Text('Pilih Anggota Satgas'),
                    items: [
                      for (final c in _counselors)
                        DropdownMenuItem(
                          value: c.id,
                          child: Text('${c.name} - ${c.email}'),
                        ),
                    ],
                    onChanged: (v) {
                      setState(() => _selectedCounselorId = v);
                      _loadSlots();
                    },
                    decoration: _fieldDecoration(),
                  ),
                  const SizedBox(height: 24),

                  // Step 2: Pilih Tanggal & Waktu
                  const _StepTitle(
                    icon: Icons.calendar_today_outlined,
                    iconBg: Color(0xFFF3E8FF),
                    iconColor: Color(0xFF9333EA),
                    title: 'Pilih Tanggal & Waktu',
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Tanggal *',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.gray700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () async {
                      final now = DateTime.now();
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: now,
                        firstDate: now,
                        lastDate: now.add(const Duration(days: 30)),
                      );
                      if (picked != null) {
                        setState(() {
                          _selectedDate =
                              DateFormat('yyyy-MM-dd').format(picked);
                        });
                        _loadSlots();
                      }
                    },
                    child: InputDecorator(
                      decoration: _fieldDecoration(),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _selectedDate.isEmpty
                                ? 'Pilih tanggal dalam 30 hari ke depan'
                                : _selectedDate,
                            style: TextStyle(
                              fontSize: 13.5,
                              color: _selectedDate.isEmpty
                                  ? AppColors.gray400
                                  : AppColors.gray900,
                            ),
                          ),
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 18,
                            color: AppColors.gray500,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  const Text(
                    'Waktu *',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.gray700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_availableSlots.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.gray50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _selectedCounselorId != null &&
                                _selectedDate.isNotEmpty
                            ? 'Memuat slot waktu...'
                            : 'Pilih anggota Satgas dan tanggal terlebih dahulu',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.gray500,
                        ),
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final slot in _availableSlots)
                          InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: slot.available
                                ? () => setState(() => _selectedSlot = slot)
                                : null,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: _selectedSlot?.jamMulai == slot.jamMulai
                                    ? const Color(0xFFEFF6FF)
                                    : slot.available
                                        ? Colors.white
                                        : AppColors.gray50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color:
                                      _selectedSlot?.jamMulai == slot.jamMulai
                                          ? const Color(0xFF3B82F6)
                                          : AppColors.gray200,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    slot.display,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.bold,
                                      color: _selectedSlot?.jamMulai ==
                                              slot.jamMulai
                                          ? const Color(0xFF1D4ED8)
                                          : AppColors.gray800,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    slot.available ? 'Tersedia' : 'Penuh',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                      color: slot.available
                                          ? const Color(0xFF16A34A)
                                          : const Color(0xFFDC2626),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  const SizedBox(height: 24),

                  // Step 3: Pilih Metode Penanganan
                  const _StepTitle(
                    icon: Icons.videocam_outlined,
                    iconBg: Color(0xFFDCFCE7),
                    iconColor: Color(0xFF16A34A),
                    title: 'Pilih Metode Penanganan',
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _MethodButton(
                          title: 'Online',
                          subtitle: 'Video call via link meeting',
                          icon: Icons.videocam_outlined,
                          selected: _method == 'online',
                          onTap: () => setState(() => _method = 'online'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _MethodButton(
                          title: 'Offline',
                          subtitle: 'Bertemu langsung di lokasi',
                          icon: Icons.location_on_outlined,
                          selected: _method == 'offline',
                          onTap: () => setState(() => _method = 'offline'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (_method == 'online') ...[
                    const Text(
                      'Link Meeting',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.gray700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _meetingLinkCtrl,
                            decoration: _fieldDecoration(
                              hint: 'https://meet.google.com/xxx-yyyy-zzz',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _meetingLinkCtrl.text = UserPortalService
                                  .instance
                                  .generateMeetingLink();
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFDBEAFE),
                            foregroundColor: const Color(0xFF1D4ED8),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Generate Link',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    const Text(
                      'Lokasi *',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.gray700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _locationCtrl,
                      decoration: _fieldDecoration(
                        hint: 'Ruangan Penanganan, Gedung A, Lantai 3',
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),

                  // Step 4: Informasi Tambahan (Opsional)
                  const _StepTitle(
                    icon: Icons.chevron_right_rounded,
                    iconBg: Color(0xFFFFEDD5),
                    iconColor: Color(0xFFEA580C),
                    title: 'Informasi Tambahan (Opsional)',
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'ID Pengaduan Terkait',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.gray700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _complaintIdCtrl,
                    decoration: _fieldDecoration(hint: 'Contoh: LP-2026-0101'),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Jenis Pengaduan',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.gray700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _jenisPengaduanCtrl,
                    decoration: _fieldDecoration(
                      hint: 'Contoh: Kekerasan Verbal, Pelecehan, dll',
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Submit & Reset
                  Row(
                    children: [
                      OutlinedButton(
                        onPressed: _loading ? null : _resetForm,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Reset Form'),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _loading ? null : _handleSubmit,
                          icon: const Icon(Icons.check_rounded, size: 18),
                          label: Text(
                            _loading
                                ? 'Mengirim...'
                                : 'Ajukan Jadwal Penanganan',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
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
      ),
    );
  }

  InputDecoration _fieldDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.gray300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.gray300),
      ),
    );
  }
}

class _StepTitle extends StatelessWidget {
  const _StepTitle({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: iconBg,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16.5,
              fontWeight: FontWeight.bold,
              color: AppColors.gray900,
            ),
          ),
        ),
      ],
    );
  }
}

class _MethodButton extends StatelessWidget {
  const _MethodButton({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEFF6FF) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? const Color(0xFF3B82F6) : AppColors.gray200,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: selected
                      ? const Color(0xFF2563EB)
                      : AppColors.gray600,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.gray900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11.5,
                color: AppColors.gray600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

