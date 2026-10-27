import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../app/routes.dart';
import '../../core/config/api_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/launcher.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/konselor_portal_service.dart';
import '../operator/operator_shell_page.dart';
import 'konselor_shell_page.dart';

/// Halaman Detail Pengaduan & Penanganan Kasus Satgas (`/konselor/complaint-detail`).
/// Porting 1:1 dari `pages/konselor/complaint-detail.jsx` & `pages/operator/complaint-detail.jsx`.
class KonselorComplaintDetailPage extends StatefulWidget {
  const KonselorComplaintDetailPage({
    super.key,
    required this.complaintId,
    this.isCounselor = true,
  });

  final int complaintId;
  final bool isCounselor;

  @override
  State<KonselorComplaintDetailPage> createState() =>
      _KonselorComplaintDetailPageState();
}

class _KonselorComplaintDetailPageState
    extends State<KonselorComplaintDetailPage> {
  bool _loading = true;
  bool _submitting = false;

  SatgasComplaintItem? _complaint;
  List<SatgasCounselor> _counselors = [];

  // Form Catatan Perkembangan / Selesaikan Sesi
  int? _activeSessionId;
  String _counseleeType = 'pelapor';
  final TextEditingController _counseleeNameCtrl = TextEditingController();
  final TextEditingController _keteranganCtrl = TextEditingController();
  final TextEditingController _saranCtrl = TextEditingController();
  String? _pickedAttachmentName;
  List<int>? _pickedAttachmentBytes;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _counseleeNameCtrl.dispose();
    _keteranganCtrl.dispose();
    _saranCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        KonselorPortalService.instance.getComplaintDetail(
          widget.complaintId,
          isCounselor: widget.isCounselor,
        ),
        KonselorPortalService.instance.getCounselors(),
      ]);
      if (!mounted) return;
      final comp = results[0] as SatgasComplaintItem?;
      final couns = results[1] as List<SatgasCounselor>;
      setState(() {
        _complaint = comp;
        _counselors = couns;
        if (comp != null && _counseleeNameCtrl.text.isEmpty) {
          _counseleeNameCtrl.text = comp.userName;
        }
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _formatPhoneForWa(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'\D'), '');
    if (cleaned.isEmpty) return '';
    if (cleaned.startsWith('0')) {
      return '62${cleaned.substring(1)}';
    }
    return cleaned;
  }

  Future<void> _pickSessionAttachment() async {
    try {
      final res = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx'],
        withData: true,
      );
      if (res != null && res.files.isNotEmpty) {
        final file = res.files.first;
        setState(() {
          _pickedAttachmentName = file.name;
          _pickedAttachmentBytes = file.bytes;
        });
      }
    } catch (_) {}
  }

  Future<void> _handleSaveProgressNote() async {
    final comp = _complaint;
    if (comp == null) return;
    if (_keteranganCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap isi Keterangan / Pengakuan pihak!'),
          backgroundColor: Color(0xFFE11D48),
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await KonselorPortalService.instance.submitProgressNote(
        complaintId: comp.id,
        activeSessionId: _activeSessionId,
        counseleeType: _counseleeType,
        counseleeName: _counseleeNameCtrl.text.trim(),
        keteranganPihak: _keteranganCtrl.text.trim(),
        saranKonselor: _saranCtrl.text.trim(),
        attachmentName: _pickedAttachmentName,
        attachmentBytes: _pickedAttachmentBytes,
      );
      if (!mounted) return;
      setState(() {
        _activeSessionId = null;
        _keteranganCtrl.clear();
        _saranCtrl.clear();
        _pickedAttachmentName = null;
        _pickedAttachmentBytes = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Catatan perkembangan kasus berhasil disimpan!'),
          backgroundColor: Color(0xFF059669),
        ),
      );
      await _loadData();
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _handleQuickTeamAction(String action) async {
    final comp = _complaint;
    final user = AuthService.instance.user;
    if (comp == null || user == null) return;

    int? nextMainId = comp.counselorId;
    final nextCoIds = List<int>.from(comp.coCounselors);

    if (action == 'claim_main') {
      nextMainId = user.id;
      nextCoIds.remove(user.id);
    } else if (action == 'join_co') {
      if (!nextCoIds.contains(user.id)) {
        nextCoIds.add(user.id);
      }
    } else if (action == 'leave_co') {
      nextCoIds.remove(user.id);
    }

    setState(() => _submitting = true);
    try {
      await KonselorPortalService.instance.assignTeam(
        comp.id,
        counselorId: nextMainId,
        coCounselors: nextCoIds,
        isCounselor: widget.isCounselor,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tim Satgas berhasil diperbarui!'),
          backgroundColor: Color(0xFF4F46E5),
        ),
      );
      await _loadData();
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _showAssignTeamModal() async {
    final comp = _complaint;
    if (comp == null) return;

    int? selectedMain = comp.counselorId ??
        (_counselors.isNotEmpty ? _counselors.first.id : 2);
    final selectedCo = List<int>.from(comp.coCounselors);

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text(
            'Atur Tim Satgas Pendamping',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PJ UTAMA PENDAMPINGAN',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.gray700,
                  ),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<int>(
                  initialValue: _counselors.any((c) => c.id == selectedMain)
                      ? selectedMain
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
                            c.name,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    setModalState(() {
                      selectedMain = v;
                      selectedCo.remove(v);
                    });
                  },
                ),
                const SizedBox(height: 14),
                const Text(
                  'REKAN PENDAMPING (CO-COUNSELOR)',
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
                        .where((c) => c.id != selectedMain)
                        .map((c) {
                      final checked = selectedCo.contains(c.id);
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
                              selectedCo.add(c.id);
                            } else {
                              selectedCo.remove(c.id);
                            }
                          });
                        },
                      );
                    }).toList(),
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
              onPressed: () => Navigator.of(ctx).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Simpan Tim'),
            ),
          ],
        ),
      ),
    );

    if (saved == true) {
      setState(() => _submitting = true);
      try {
        await KonselorPortalService.instance.assignTeam(
          comp.id,
          counselorId: selectedMain,
          coCounselors: selectedCo,
          isCounselor: widget.isCounselor,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Susunan Tim Satgas berhasil disimpan!'),
            backgroundColor: Color(0xFF4F46E5),
          ),
        );
        await _loadData();
      } finally {
        if (mounted) setState(() => _submitting = false);
      }
    }
  }

  Future<void> _showEditUrgencyModal() async {
    final comp = _complaint;
    if (comp == null) return;
    String selected = comp.urgencyLevel;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text(
            'Edit Tingkat Pelanggaran / Urgensi',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ('low', 'Ringan (Low)', const Color(0xFF059669)),
              ('medium', 'Sedang (Medium)', const Color(0xFFD97706)),
              ('high', 'Berat (High)', const Color(0xFFEA580C)),
              ('critical', 'Darurat (Critical)', const Color(0xFFE11D48)),
            ].map((opt) {
              final active = selected == opt.$1;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => setModalState(() => selected = opt.$1),
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
                        Text(
                          opt.$2,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: active ? opt.$3 : AppColors.gray800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
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
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );

    if (saved == true) {
      setState(() => _submitting = true);
      try {
        await KonselorPortalService.instance.updateComplaintStatus(
          comp.id,
          urgencyLevel: selected,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tingkat urgensi berhasil diperbarui!'),
            backgroundColor: Color(0xFF4F46E5),
          ),
        );
        await _loadData();
      } finally {
        if (mounted) setState(() => _submitting = false);
      }
    }
  }

  Future<void> _showEditStatusModal() async {
    final comp = _complaint;
    if (comp == null) return;
    String selected = comp.status;
    final reasonCtrl = TextEditingController(text: comp.rejectionReason ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text(
            'Ubah Status Laporan',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ...[
                  ('pending', 'Menunggu Verifikasi', const Color(0xFFD97706)),
                  ('approved', 'Dalam Penanganan', const Color(0xFF4F46E5)),
                  ('completed', 'Kasus Selesai', const Color(0xFF059669)),
                  ('rejected', 'Ditolak', const Color(0xFFE11D48)),
                ].map((opt) {
                  final active = selected == opt.$1;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => setModalState(() => selected = opt.$1),
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
                            Text(
                              opt.$2,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: active ? opt.$3 : AppColors.gray800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                if (selected == 'rejected') ...[
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
                if (selected == 'rejected' &&
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
              child: const Text('Simpan Status'),
            ),
          ],
        ),
      ),
    );

    if (saved == true) {
      setState(() => _submitting = true);
      try {
        await KonselorPortalService.instance.updateComplaintStatus(
          comp.id,
          status: selected,
          rejectionReason:
              selected == 'rejected' ? reasonCtrl.text.trim() : null,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Status laporan berhasil diperbarui!'),
            backgroundColor: Color(0xFF4F46E5),
          ),
        );
        await _loadData();
      } finally {
        if (mounted) setState(() => _submitting = false);
      }
    }
  }

  Future<void> _showBeritaAcaraModal() async {
    final comp = _complaint;
    if (comp == null) return;

    final templates = [
      (
        id: 'ba_pelaporan',
        title: 'BA Pelaporan Kasus',
        desc: 'Berita Acara Penerimaan Pengaduan Awal Satgas PPKPT',
      ),
      (
        id: 'ba_kesediaan',
        title: 'BA Kesediaan Penanganan',
        desc: 'Persetujuan Pelapor/Korban untuk Pendampingan Satgas',
      ),
      (
        id: 'rujukan_konseling',
        title: 'Formulir Rujukan Konseling',
        desc: 'Surat Rujukan Pendampingan Psikologis / Medis',
      ),
      (
        id: 'ba_saksi',
        title: 'BA Pemeriksaan Saksi',
        desc: 'Berita Acara Keterangan Saksi Kejadian',
      ),
      (
        id: 'ba_terlapor',
        title: 'BA Pemeriksaan Terlapor',
        desc: 'Berita Acara Klarifikasi Pihak Terlapor',
      ),
      (
        id: 'surat_selesai',
        title: 'Surat Penyelesaian Kasus',
        desc: 'Dokumen Resmi Penutupan & Rekomendasi Akhir Kasus',
      ),
    ];

    String selectedTpl = templates.first.id;

    String buildDocText(String tplId) {
      final nowStr =
          DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(DateTime.now());
      final tplTitle =
          templates.firstWhere((t) => t.id == tplId).title.toUpperCase();
      return '''
KEMENTERIAN PENDIDIKAN TINGGI, SAINS, DAN TEKNOLOGI
POLITEKNIK NEGERI JEMBER
SATUAN TUGAS PENCEGAHAN DAN PENANGANAN KEKERASAN (SATGAS PPKPT)
Jl. Mastrip Kotak Pos 164 Jember 68101
================================================================

$tplTitle
Nomor Kasus : ${comp.reportId}
Tanggal     : $nowStr

I. IDENTITAS PIHAK PELAPOR / KORBAN
- Nama Lengkap     : ${comp.userName}
- NIM / NIP / NIK  : ${comp.nimNip}
- Status / Unit    : ${comp.reporterStatus} / ${comp.victimAffiliation}
- No. Telepon      : ${comp.userPhone}

II. IDENTITAS PIHAK TERLAPOR
- Nama Terlapor    : ${comp.suspectName}
- Status / Unit    : ${comp.suspectStatus} / ${comp.suspectAffiliation}

III. URAIAN KEJADIAN & PENANGANAN
- Kategori Kasus   : ${comp.categoryName}
- Lokasi Kejadian  : ${comp.location}
- Kronologi        : ${comp.chronology}
- PJ Utama Satgas  : ${comp.counselorName}

Demikian Berita Acara ini dibuat dengan sebenar-benarnya untuk dipergunakan sebagaimana mestinya dalam proses penanganan Satgas PPKPT Politeknik Negeri Jember.
''';
    }

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final docContent = buildDocText(selectedTpl);
          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Row(
              children: [
                Icon(Icons.picture_as_pdf_outlined, color: Color(0xFF4F46E5)),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Export PDF / Berita Acara Satgas',
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
                    'PILIH DOKUMEN RESMI SATGAS PPKPT:',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.gray600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...templates.map((t) {
                    final active = selectedTpl == t.id;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => setModalState(() => selectedTpl = t.id),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: active
                                ? const Color(0xFFEEF2FF)
                                : AppColors.gray50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: active
                                  ? const Color(0xFF4F46E5)
                                  : AppColors.gray200,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                active
                                    ? Icons.check_circle_rounded
                                    : Icons.description_outlined,
                                size: 18,
                                color: active
                                    ? const Color(0xFF4F46E5)
                                    : AppColors.gray500,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      t.title,
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w800,
                                        color: active
                                            ? const Color(0xFF312E81)
                                            : AppColors.gray800,
                                      ),
                                    ),
                                    Text(
                                      t.desc,
                                      style: const TextStyle(
                                        fontSize: 10.5,
                                        color: AppColors.gray500,
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
                  }),
                  const SizedBox(height: 10),
                  const Text(
                    'PRATINJAU NASKAH BERITA ACARA:',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.gray600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxHeight: 180),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.gray50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.gray200),
                    ),
                    child: SingleChildScrollView(
                      child: SelectableText(
                        docContent,
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontFamily: 'monospace',
                          color: AppColors.gray800,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Tutup'),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: docContent));
                  if (!ctx.mounted) return;
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Naskah Berita Acara berhasil disalin & siap dicetak!'),
                      backgroundColor: Color(0xFF4F46E5),
                    ),
                  );
                },
                icon: const Icon(Icons.copy_rounded, size: 16),
                label: const Text('Salin & Unduh Naskah'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmDeleteComplaint() async {
    final comp = _complaint;
    if (comp == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Hapus Laporan Ini?',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus laporan #${comp.reportId} (${comp.title}) secara permanen?',
          style: const TextStyle(fontSize: 13, color: AppColors.gray600),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE11D48),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Ya, Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await KonselorPortalService.instance.deleteComplaint(comp.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Laporan telah dihapus.'),
          backgroundColor: Color(0xFFE11D48),
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = _buildBody();
    if (widget.isCounselor) {
      return KonselorShellPage(
        title: 'Detail Kasus Satgas',
        subtitle: 'Informasi lengkap pengaduan & progres pendampingan.',
        activePath: AppRoutes.konselorCaseManagement,
        body: content,
      );
    }
    return OperatorShellPage(
      title: 'Detail Kasus',
      subtitle: 'Informasi lengkap pengaduan & progres pendampingan.',
      activePath: AppRoutes.operatorCaseManagement,
      body: content,
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(48),
          child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
        ),
      );
    }

    final comp = _complaint;
    if (comp == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  size: 48, color: AppColors.gray400),
              const SizedBox(height: 12),
              const Text(
                'Data Laporan Tidak Ditemukan',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Kembali'),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        RefreshIndicator(
          color: const Color(0xFF4F46E5),
          onRefresh: _loadData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopBar(comp),
                if (comp.status == 'rejected' &&
                    (comp.rejectionReason ?? '').isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _buildRejectionBanner(comp.rejectionReason!),
                ],
                const SizedBox(height: 16),
                _buildReporterCard(comp),
                const SizedBox(height: 16),
                _buildSuspectCard(comp),
                const SizedBox(height: 16),
                _buildIncidentCard(comp),
                const SizedBox(height: 16),
                _buildTeamAndScheduleCard(comp),
                const SizedBox(height: 16),
                _buildProgressNotesCard(comp),
                const SizedBox(height: 16),
                _buildTimelineCard(comp),
                const SizedBox(height: 16),
                _buildQuickActionsCard(comp),
                const SizedBox(height: 28),
              ],
            ),
          ),
        ),
        if (_submitting)
          Container(
            color: Colors.black26,
            alignment: Alignment.center,
            child: const CircularProgressIndicator(color: Color(0xFF4F46E5)),
          ),
      ],
    );
  }

  Widget _buildTopBar(SatgasComplaintItem comp) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gray100),
      ),
      child: Row(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.gray50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.gray200),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                size: 18,
                color: AppColors.gray700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '#${comp.reportId}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF4F46E5),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  comp.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.gray900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _buildStatusBadge(comp.status),
        ],
      ),
    );
  }

  Widget _buildRejectionBanner(String reason) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFE4E6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Color(0xFFE11D48),
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ALASAN PENOLAKAN LAPORAN:',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF9F1239),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  reason,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFFBE123C),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReporterCard(SatgasComplaintItem comp) {
    final wa = _formatPhoneForWa(comp.userPhone);
    return _buildSectionCard(
      icon: Icons.person_outline_rounded,
      iconColor: const Color(0xFF4F46E5),
      iconBg: const Color(0xFFEEF2FF),
      title: 'Pihak Pelapor & Korban',
      child: Column(
        children: [
          _buildInfoRow('Nama Lengkap Pelapor', comp.userName),
          _buildInfoRow('NIM / NIP / NIK', comp.nimNip),
          _buildInfoRow(
              'Status & Gender Pelapor',
              '${comp.reporterStatus} • ${comp.reporterGender}'),
          _buildInfoRow('Tempat, Tanggal Lahir', comp.reporterPobDob),
          _buildInfoRow('Alamat Domisili', comp.reporterAddress),
          _buildInfoRow(
            'Nomor WhatsApp',
            comp.userPhone,
            trailing: wa.isNotEmpty
                ? InkWell(
                    onTap: () => AppLauncher.openUrl('https://wa.me/$wa'),
                    child: const Text(
                      'Hubungi WA',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF059669),
                      ),
                    ),
                  )
                : null,
          ),
          _buildInfoRow(
            'Email Aktif',
            comp.userEmail,
            trailing: comp.userEmail.contains('@')
                ? InkWell(
                    onTap: () =>
                        AppLauncher.openUrl('mailto:${comp.userEmail}'),
                    child: const Text(
                      'Kirim Email',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF4F46E5),
                      ),
                    ),
                  )
                : null,
          ),
          if (comp.victimType == 'other') ...[
            const Divider(height: 20),
            _buildInfoRow('Nama Korban (Dilaporkan Saksi)', comp.victimName),
            _buildInfoRow(
              'Status & Gender Korban',
              '${comp.victimStatus} • ${comp.victimGender}',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSuspectCard(SatgasComplaintItem comp) {
    final wa = _formatPhoneForWa(comp.suspectPhone);
    return _buildSectionCard(
      icon: Icons.gpp_maybe_outlined,
      iconColor: const Color(0xFFE11D48),
      iconBg: const Color(0xFFFFF1F2),
      title: 'Pihak Terlapor',
      child: Column(
        children: [
          _buildInfoRow('Nama Terlapor', comp.suspectName),
          _buildInfoRow('Jenis Kelamin', comp.suspectGender),
          _buildInfoRow('Status Terlapor', comp.suspectStatus),
          _buildInfoRow('NIM / NIP Terlapor', comp.suspectNimNip),
          _buildInfoRow(
            'No. Telepon Terlapor',
            comp.suspectPhone,
            trailing: wa.isNotEmpty
                ? InkWell(
                    onTap: () => AppLauncher.openUrl('https://wa.me/$wa'),
                    child: const Text(
                      'Hubungi WA',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF059669),
                      ),
                    ),
                  )
                : null,
          ),
          _buildInfoRow('Unit / Jurusan / Afiliasi', comp.suspectAffiliation),
        ],
      ),
    );
  }

  Widget _buildIncidentCard(SatgasComplaintItem comp) {
    final dateStr = DateFormat('EEEE, dd MMMM yyyy', 'id_ID')
        .format(comp.incidentDate);
    return _buildSectionCard(
      icon: Icons.description_outlined,
      iconColor: const Color(0xFFD97706),
      iconBg: const Color(0xFFFEF3C7),
      title: 'Informasi Kejadian',
      trailing: TextButton.icon(
        onPressed: _showEditUrgencyModal,
        icon: const Icon(Icons.edit_outlined, size: 15),
        label: Text(
          'Urgensi: ${comp.urgencyLevel.toUpperCase()}',
          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow('Judul Pengaduan', comp.title),
          _buildInfoRow('Kategori Kekerasan', comp.categoryName),
          _buildInfoRow('Tanggal Kejadian', dateStr),
          _buildInfoRow('Lokasi Kejadian', comp.location),
          if (comp.latitude != null && comp.longitude != null)
            _buildInfoRow(
              'Koordinat GPS',
              '${comp.latitude!.toStringAsFixed(5)}, ${comp.longitude!.toStringAsFixed(5)}',
              trailing: InkWell(
                onTap: () => AppLauncher.openUrl(
                  'https://www.google.com/maps?q=${comp.latitude},${comp.longitude}',
                ),
                child: const Text(
                  'Buka Peta',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF4F46E5),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 8),
          const Text(
            'KRONOLOGI KEJADIAN',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: AppColors.gray500,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.gray50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.gray100),
            ),
            child: Text(
              comp.chronology,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.gray800,
                height: 1.5,
              ),
            ),
          ),
          if (comp.alasanPengaduan.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text(
              'ALASAN PENGADUAN (FORM SATGAS)',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                color: AppColors.gray500,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            ...comp.alasanPengaduan.map(
              (a) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.check_circle_outline_rounded,
                      size: 15,
                      color: Color(0xFF4F46E5),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        a,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.gray700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (comp.attachments.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text(
              'LAMPIRAN BUKTI LAPORAN',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                color: AppColors.gray500,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            ...comp.attachments.map(
              (att) => Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.gray50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.gray200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.attach_file_rounded,
                        size: 16, color: Color(0xFF4F46E5)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        att.fileName,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.gray800,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        final url =
                            '${ApiConfig.storageBaseUrl}/${att.filePath}';
                        AppLauncher.openUrl(url);
                      },
                      child: const Text(
                        'Buka File',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTeamAndScheduleCard(SatgasComplaintItem comp) {
    final currentUser = AuthService.instance.user;
    final isMain = currentUser != null && comp.counselorId == currentUser.id;
    final isCo =
        currentUser != null && comp.coCounselors.contains(currentUser.id);
    final scheduledSessions =
        comp.counselingNotes.where((s) => !s.isRecordOnly).toList();

    return _buildSectionCard(
      icon: Icons.groups_outlined,
      iconColor: const Color(0xFF4F46E5),
      iconBg: const Color(0xFFEEF2FF),
      title: 'Tim Satgas & Jadwal Sesi',
      trailing: TextButton.icon(
        onPressed: _showAssignTeamModal,
        icon: const Icon(Icons.settings_outlined, size: 15),
        label: const Text(
          'Atur Tim',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF).withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE0E7FF)),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_user_outlined,
                    color: Color(0xFF4F46E5), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'PJ UTAMA PENDAMPINGAN',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF4F46E5),
                        ),
                      ),
                      Text(
                        comp.counselorName,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.gray900,
                        ),
                      ),
                    ],
                  ),
                ),
                if (comp.counselorId == null)
                  ElevatedButton(
                    onPressed: () => _handleQuickTeamAction('claim_main'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                    ),
                    child: const Text(
                      'Klaim PJ',
                      style: TextStyle(fontSize: 11.5),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'REKAN SATGAS PENDAMPING:',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.gray500,
                  ),
                ),
              ),
              if (!isMain)
                TextButton.icon(
                  onPressed: () => _handleQuickTeamAction(
                    isCo ? 'leave_co' : 'join_co',
                  ),
                  icon: Icon(
                    isCo
                        ? Icons.person_remove_outlined
                        : Icons.person_add_alt_1_outlined,
                    size: 15,
                    color: isCo
                        ? const Color(0xFFE11D48)
                        : const Color(0xFF059669),
                  ),
                  label: Text(
                    isCo ? 'Keluar dari Tim' : 'Gabung Pendampingan',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: isCo
                          ? const Color(0xFFE11D48)
                          : const Color(0xFF059669),
                    ),
                  ),
                ),
            ],
          ),
          if (comp.coCounselorsList.isEmpty)
            const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: Text(
                'Belum ada rekan Satgas pendamping.',
                style: TextStyle(fontSize: 12, color: AppColors.gray400),
              ),
            )
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: comp.coCounselorsList
                  .map(
                    (c) => Chip(
                      label: Text(
                        c.name,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      backgroundColor: AppColors.gray100,
                    ),
                  )
                  .toList(),
            ),
          const Divider(height: 22),
          const Text(
            'JADWAL SESI PENANGANAN',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: AppColors.gray500,
            ),
          ),
          const SizedBox(height: 8),
          if (scheduledSessions.isEmpty)
            const Text(
              'Belum ada jadwal sesi konseling yang dibuat.',
              style: TextStyle(fontSize: 12.5, color: AppColors.gray500),
            )
          else
            ...scheduledSessions.map((s) {
              final isCompleted = s.status == 'completed';
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.gray50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.gray200),
                ),
                child: Row(
                  children: [
                    Icon(
                      isCompleted
                          ? Icons.check_circle_rounded
                          : Icons.calendar_month_rounded,
                      color: isCompleted
                          ? const Color(0xFF059669)
                          : const Color(0xFF4F46E5),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${s.tanggal} • ${s.jamMulai} - ${s.jamSelesai} WIB',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.gray900,
                            ),
                          ),
                          Text(
                            '${s.metode.toUpperCase()} — ${s.lokasi}',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: AppColors.gray600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isCompleted)
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _activeSessionId = s.id;
                            _counseleeType = s.counseleeType;
                            _counseleeNameCtrl.text = s.counseleeName;
                            _keteranganCtrl.text = s.keteranganPihak;
                            _saranCtrl.text = s.saranKonselor;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Silakan lengkapi hasil sesi pada form Catatan Penanganan di bawah.'),
                              backgroundColor: Color(0xFF4F46E5),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF059669),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                        ),
                        child: const Text(
                          'Selesaikan Sesi',
                          style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                      ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildProgressNotesCard(SatgasComplaintItem comp) {
    return _buildSectionCard(
      icon: Icons.note_alt_outlined,
      iconColor: const Color(0xFF059669),
      iconBg: const Color(0xFFECFDF5),
      title: 'Catatan Penanganan Satgas',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _activeSessionId != null
                  ? const Color(0xFFECFDF5).withValues(alpha: 0.6)
                  : AppColors.gray50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _activeSessionId != null
                    ? const Color(0xFF10B981)
                    : AppColors.gray200,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _activeSessionId != null
                            ? 'FORM SELESAIKAN SESI TERJADWAL (#$_activeSessionId)'
                            : 'TAMBAH CATATAN PERKEMBANGAN BARU',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: _activeSessionId != null
                              ? const Color(0xFF047857)
                              : AppColors.gray700,
                        ),
                      ),
                    ),
                    if (_activeSessionId != null)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _activeSessionId = null;
                            _keteranganCtrl.clear();
                            _saranCtrl.clear();
                          });
                        },
                        child: const Text(
                          'Batal Sesi',
                          style: TextStyle(fontSize: 11),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _counseleeType,
                        decoration: InputDecoration(
                          labelText: 'Pihak Tertuju',
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 'pelapor',
                              child: Text('Pelapor / Korban',
                                  style: TextStyle(fontSize: 12.5))),
                          DropdownMenuItem(
                              value: 'terlapor',
                              child: Text('Pihak Terlapor',
                                  style: TextStyle(fontSize: 12.5))),
                          DropdownMenuItem(
                              value: 'saksi',
                              child: Text('Saksi',
                                  style: TextStyle(fontSize: 12.5))),
                        ],
                        onChanged: (v) {
                          if (v == null) return;
                          setState(() {
                            _counseleeType = v;
                            if (v == 'pelapor') {
                              _counseleeNameCtrl.text = comp.userName;
                            } else if (v == 'terlapor') {
                              _counseleeNameCtrl.text = comp.suspectName;
                            } else {
                              _counseleeNameCtrl.clear();
                            }
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _counseleeNameCtrl,
                        decoration: InputDecoration(
                          labelText: 'Nama Pihak',
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _keteranganCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Keterangan / Pengakuan Pihak *',
                    hintText:
                        'Tuliskan hasil pemeriksaan, pengakuan, atau kondisi psikologis pihak...',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _saranCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Saran / Tindak Lanjut Satgas',
                    hintText:
                        'Tuliskan rekomendasi atau tindak lanjut berikutnya...',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: _pickSessionAttachment,
                      icon: const Icon(Icons.upload_file_rounded, size: 16),
                      label: Text(
                        _pickedAttachmentName ?? 'Lampirkan Bukti Sesi',
                        style: const TextStyle(fontSize: 11.5),
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: _handleSaveProgressNote,
                      icon: const Icon(Icons.save_outlined, size: 16),
                      label: Text(
                        _activeSessionId != null
                            ? 'Selesaikan & Simpan'
                            : 'Simpan Catatan',
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w800),
                      ),
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
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'RIWAYAT CATATAN PERKEMBANGAN',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: AppColors.gray500,
            ),
          ),
          const SizedBox(height: 8),
          if (comp.counselingNotes.isEmpty)
            const Text(
              'Belum ada catatan perkembangan kasus.',
              style: TextStyle(fontSize: 12.5, color: AppColors.gray500),
            )
          else
            ...comp.counselingNotes.map(
              (note) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.gray200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF2FF),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            note.counseleeType.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF4F46E5),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            note.counseleeName,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppColors.gray900,
                            ),
                          ),
                        ),
                        Text(
                          '${note.tanggal} (${note.jamMulai})',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.gray500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      note.keteranganPihak.isNotEmpty
                          ? note.keteranganPihak
                          : '-',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.gray800,
                        height: 1.4,
                      ),
                    ),
                    if (note.saranKonselor.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Tindak Lanjut Satgas: ${note.saranKonselor}',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF047857),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      'Dicatat oleh: ${note.counselorName}',
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: AppColors.gray400,
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

  Widget _buildTimelineCard(SatgasComplaintItem comp) {
    final s = comp.status.toLowerCase();
    final isRejected = s == 'rejected';
    final steps = [
      (
        title: 'Laporan Dibuat',
        subtitle: DateFormat('dd MMM yyyy, HH:mm', 'id_ID')
            .format(comp.createdAt),
        done: true,
        color: const Color(0xFF059669),
      ),
      (
        title: isRejected ? 'Laporan Ditolak' : 'Verifikasi Satgas',
        subtitle: isRejected
            ? (comp.rejectionReason ?? 'Ditolak oleh Satgas')
            : (s == 'pending'
                ? 'Menunggu asesmen awal Satgas'
                : 'Diverifikasi oleh ${comp.counselorName}'),
        done: s != 'pending',
        color: isRejected
            ? const Color(0xFFE11D48)
            : const Color(0xFF4F46E5),
      ),
      (
        title: 'Dalam Penanganan & Pendampingan',
        subtitle: s == 'approved' || s == 'completed'
            ? '${comp.counselingNotes.length} Sesi / Catatan tercatat'
            : 'Menunggu proses pendampingan',
        done: s == 'approved' || s == 'completed',
        color: const Color(0xFF4F46E5),
      ),
      (
        title: 'Kasus Selesai',
        subtitle: s == 'completed'
            ? 'Kasus telah dinyatakan selesai'
            : 'Belum selesai',
        done: s == 'completed',
        color: const Color(0xFF059669),
      ),
    ];

    return _buildSectionCard(
      icon: Icons.timeline_rounded,
      iconColor: const Color(0xFF4F46E5),
      iconBg: const Color(0xFFEEF2FF),
      title: 'Timeline Penanganan',
      child: Column(
        children: steps.map((st) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  st.done
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: st.done ? st.color : AppColors.gray300,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        st.title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: st.done
                              ? AppColors.gray900
                              : AppColors.gray400,
                        ),
                      ),
                      Text(
                        st.subtitle,
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
        }).toList(),
      ),
    );
  }

  Widget _buildQuickActionsCard(SatgasComplaintItem comp) {
    return _buildSectionCard(
      icon: Icons.bolt_rounded,
      iconColor: const Color(0xFFD97706),
      iconBg: const Color(0xFFFEF3C7),
      title: 'Aksi Cepat Satgas (Quick Actions)',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton.icon(
            onPressed: _showEditStatusModal,
            icon: const Icon(Icons.edit_note_rounded, size: 18),
            label: const Text('Edit Status Laporan'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _showBeritaAcaraModal,
            icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
            label: const Text('Export PDF / Berita Acara Satgas'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF4F46E5),
              side: const BorderSide(color: Color(0xFFC7D2FE)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _confirmDeleteComplaint,
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
            label: const Text('Hapus Laporan'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFE11D48),
              side: const BorderSide(color: Color(0xFFFFE4E6)),
              backgroundColor: const Color(0xFFFFF1F2),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.gray900,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
          const Divider(height: 24),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
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
              value.isNotEmpty ? value : '-',
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.gray900,
              ),
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing,
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
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
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: fg,
        ),
      ),
    );
  }
}
