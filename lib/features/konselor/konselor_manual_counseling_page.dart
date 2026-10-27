import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/routes.dart';
import '../../core/constants/polije_data.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/user_complaint.dart';
import '../../data/services/konselor_portal_service.dart';
import 'konselor_shell_page.dart';

/// Halaman Tambah Sesi Penanganan Manual (`/konselor/manual-counseling`).
/// Porting 1:1 dari `pages/konselor/manual-counseling.jsx` di web PolijeCare.
class KonselorManualCounselingPage extends StatefulWidget {
  const KonselorManualCounselingPage({super.key});

  @override
  State<KonselorManualCounselingPage> createState() =>
      _KonselorManualCounselingPageState();
}

class _KonselorManualCounselingPageState
    extends State<KonselorManualCounselingPage> {
  final _formKey = GlobalKey<FormState>();

  bool _isRecordOnly = false; // false = JADWALKAN, true = ARSIP SELESAI
  bool _submitting = false;

  List<ViolenceCategoryItem> _categories = [];
  String _jenisPengaduan = 'Kekerasan Seksual';
  DateTime _tanggal = DateTime.now();
  String _jamMulai = '09:00';
  String _jamSelesai = '10:00';
  String _metode = 'offline'; // offline | online

  final TextEditingController _lokasiCtrl =
      TextEditingController(text: 'Kantor Satgas PPKPT Polije');
  final TextEditingController _meetingLinkCtrl = TextEditingController();

  // Data Pelapor / Korban
  final TextEditingController _counseleeNameCtrl = TextEditingController();
  final TextEditingController _guestNimCtrl = TextEditingController();
  final TextEditingController _guestEmailCtrl = TextEditingController();
  final TextEditingController _guestWaCtrl = TextEditingController();
  String _reporterGender = 'Perempuan';
  String _reporterStatus = 'Mahasiswa';
  String _victimGender = 'Perempuan';
  String _victimStatus = 'Mahasiswa';

  // Data Terlapor / Pelaku
  final TextEditingController _suspectNameCtrl = TextEditingController();
  final TextEditingController _suspectPhoneCtrl = TextEditingController();
  String _suspectGender = 'Laki-laki';
  String _suspectStatus = 'Mahasiswa';
  String _affiliationType = 'jurusan'; // jurusan | unit | manual
  String _selectedJurusan = PolijeData.jurusanList.first;
  String _selectedProdi = '';
  String _selectedUnit = PolijeData.unitLainnya.first;
  final TextEditingController _manualAffiliationCtrl = TextEditingController();

  // Kronologi & Catatan
  final TextEditingController _keteranganCtrl = TextEditingController();
  final TextEditingController _saranCtrl = TextEditingController();

  static const List<String> _hourOptions = [
    '08:00',
    '09:00',
    '10:00',
    '11:00',
    '12:00',
    '13:00',
    '14:00',
    '15:00',
    '16:00',
    '17:00',
  ];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _lokasiCtrl.dispose();
    _meetingLinkCtrl.dispose();
    _counseleeNameCtrl.dispose();
    _guestNimCtrl.dispose();
    _guestEmailCtrl.dispose();
    _guestWaCtrl.dispose();
    _suspectNameCtrl.dispose();
    _suspectPhoneCtrl.dispose();
    _manualAffiliationCtrl.dispose();
    _keteranganCtrl.dispose();
    _saranCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    final cats = await KonselorPortalService.instance.getCategories();
    if (!mounted) return;
    setState(() {
      _categories = cats;
      if (cats.isNotEmpty) {
        _jenisPengaduan = cats.first.name;
      }
    });
  }

  String _computeSuspectAffiliation() {
    if (_affiliationType == 'jurusan') {
      if (_selectedProdi.isNotEmpty) {
        return '$_selectedJurusan - $_selectedProdi';
      }
      return _selectedJurusan;
    } else if (_affiliationType == 'unit') {
      return _selectedUnit;
    } else {
      return _manualAffiliationCtrl.text.trim();
    }
  }

  Future<void> _handleSubmit() async {
    if (_counseleeNameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap isi Nama Lengkap Pelapor / Korban!'),
          backgroundColor: Color(0xFFE11D48),
        ),
      );
      return;
    }
    if (_keteranganCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap isi Deskripsi Kasus & Kronologi!'),
          backgroundColor: Color(0xFFE11D48),
        ),
      );
      return;
    }
    if (_isRecordOnly && _saranCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Harap isi Catatan Penanganan / Saran Satgas untuk arsip!'),
          backgroundColor: Color(0xFFE11D48),
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_tanggal);
      final payload = <String, dynamic>{
        'counselee_type': 'pelapor',
        'counselee_name': _counseleeNameCtrl.text.trim(),
        'guest_nim': _guestNimCtrl.text.trim(),
        'guest_email': _guestEmailCtrl.text.trim(),
        'guest_wa': _guestWaCtrl.text.trim(),
        'jenis_pengaduan': _jenisPengaduan,
        'tanggal': dateStr,
        'jam_mulai': _jamMulai,
        'jam_selesai': _jamSelesai,
        'metode': _metode,
        'lokasi': _metode == 'offline'
            ? _lokasiCtrl.text.trim()
            : 'Online Meeting',
        'meeting_link':
            _metode == 'online' ? _meetingLinkCtrl.text.trim() : '',
        'keterangan_pihak': _keteranganCtrl.text.trim(),
        'saran_konselor': _saranCtrl.text.trim(),
        'is_record_only': _isRecordOnly,
        'reporter_gender': _reporterGender,
        'reporter_status': _reporterStatus,
        'victim_gender': _victimGender,
        'victim_status': _victimStatus,
        'suspect_name': _suspectNameCtrl.text.trim(),
        'suspect_gender': _suspectGender,
        'suspect_status': _suspectStatus,
        'suspect_affiliation': _computeSuspectAffiliation(),
        'suspect_phone': _suspectPhoneCtrl.text.trim(),
      };

      await KonselorPortalService.instance.createManualCounseling(payload);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isRecordOnly
                ? 'Arsip penanganan manual berhasil disimpan!'
                : 'Sesi penanganan manual berhasil dijadwalkan!',
          ),
          backgroundColor: const Color(0xFF059669),
        ),
      );
      Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final prodiList = PolijeData.getProdiByJurusan(_selectedJurusan);

    return KonselorShellPage(
      title: 'Penanganan Manual',
      subtitle:
          'Catat atau jadwalkan sesi pendampingan langsung (walk-in) Satgas.',
      activePath: AppRoutes.konselorCaseManagement,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderCard(),
              const SizedBox(height: 16),
              _buildSectionCard(
                number: '01',
                title: 'INFORMASI SESI PENANGANAN',
                icon: Icons.calendar_month_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Kategori Masalah *'),
                    DropdownButtonFormField<String>(
                      initialValue: _categories.any((c) => c.name == _jenisPengaduan)
                          ? _jenisPengaduan
                          : (_categories.isNotEmpty
                              ? _categories.first.name
                              : 'Kekerasan Seksual'),
                      isExpanded: true,
                      decoration: _inputDecoration(),
                      items: (_categories.isNotEmpty
                              ? _categories.map((e) => e.name).toList()
                              : [
                                  'Kekerasan Seksual',
                                  'Pelecehan Verbal & Psikis',
                                  'Perundungan (Bullying)',
                                  'Kekerasan Fisik',
                                ])
                          .map(
                            (name) => DropdownMenuItem<String>(
                              value: name,
                              child: Text(name,
                                  style: const TextStyle(fontSize: 13)),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _jenisPengaduan = v);
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildFieldLabel('Tanggal Penanganan *'),
                    InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _tanggal,
                          firstDate: DateTime(2024),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setState(() => _tanggal = picked);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 13),
                        decoration: BoxDecoration(
                          color: AppColors.gray50,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.gray200),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.event_outlined,
                                size: 18, color: Color(0xFF4F46E5)),
                            const SizedBox(width: 10),
                            Text(
                              DateFormat('EEEE, dd MMMM yyyy', 'id_ID')
                                  .format(_tanggal),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.gray900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel('Jam Mulai *'),
                              DropdownButtonFormField<String>(
                                initialValue: _jamMulai,
                                decoration: _inputDecoration(),
                                items: _hourOptions
                                    .map((h) => DropdownMenuItem(
                                          value: h,
                                          child: Text('$h WIB',
                                              style: const TextStyle(
                                                  fontSize: 13)),
                                        ))
                                    .toList(),
                                onChanged: (v) {
                                  if (v == null) return;
                                  final idx = _hourOptions.indexOf(v);
                                  setState(() {
                                    _jamMulai = v;
                                    if (idx >= 0 &&
                                        idx + 1 < _hourOptions.length) {
                                      _jamSelesai = _hourOptions[idx + 1];
                                    }
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel('Jam Selesai *'),
                              DropdownButtonFormField<String>(
                                initialValue: _jamSelesai,
                                decoration: _inputDecoration(),
                                items: _hourOptions
                                    .map((h) => DropdownMenuItem(
                                          value: h,
                                          child: Text('$h WIB',
                                              style: const TextStyle(
                                                  fontSize: 13)),
                                        ))
                                    .toList(),
                                onChanged: (v) {
                                  if (v != null) {
                                    setState(() => _jamSelesai = v);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildFieldLabel('Metode Pertemuan *'),
                    Row(
                      children: [
                        Expanded(
                          child: _buildModeChip(
                            active: _metode == 'offline',
                            icon: Icons.location_on_outlined,
                            label: 'TATAP MUKA',
                            onTap: () => setState(() => _metode = 'offline'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildModeChip(
                            active: _metode == 'online',
                            icon: Icons.videocam_outlined,
                            label: 'ONLINE',
                            onTap: () => setState(() => _metode = 'online'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_metode == 'offline') ...[
                      _buildFieldLabel('Detail Lokasi Pertemuan *'),
                      TextField(
                        controller: _lokasiCtrl,
                        decoration: _inputDecoration(
                          hint: 'Contoh: Ruang Konseling Satgas PPKPT Lt. 1',
                        ),
                      ),
                    ] else ...[
                      _buildFieldLabel('Tautan Meeting Online (Zoom / GMeet)'),
                      TextField(
                        controller: _meetingLinkCtrl,
                        decoration: _inputDecoration(
                          hint: 'https://meet.google.com/...',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildSectionCard(
                number: '02',
                title: 'DATA PELAPOR / KORBAN',
                icon: Icons.person_outline_rounded,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Nama Lengkap Pelapor / Korban *'),
                    TextField(
                      controller: _counseleeNameCtrl,
                      decoration: _inputDecoration(
                        hint: 'Masukkan nama lengkap pelapor...',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel('NIM / NIP / NIK'),
                              TextField(
                                controller: _guestNimCtrl,
                                decoration: _inputDecoration(
                                  hint: 'Contoh: E41221001',
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
                              _buildFieldLabel('Nomor WhatsApp'),
                              TextField(
                                controller: _guestWaCtrl,
                                keyboardType: TextInputType.phone,
                                decoration: _inputDecoration(
                                  hint: '0812xxxx',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildFieldLabel('Email Aktif'),
                    TextField(
                      controller: _guestEmailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _inputDecoration(
                        hint: 'nama@student.polije.ac.id',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel('Gender Pelapor'),
                              DropdownButtonFormField<String>(
                                initialValue: _reporterGender,
                                decoration: _inputDecoration(),
                                items: const [
                                  DropdownMenuItem(
                                      value: 'Laki-laki',
                                      child: Text('Laki-laki',
                                          style: TextStyle(fontSize: 13))),
                                  DropdownMenuItem(
                                      value: 'Perempuan',
                                      child: Text('Perempuan',
                                          style: TextStyle(fontSize: 13))),
                                ],
                                onChanged: (v) {
                                  if (v != null) {
                                    setState(() {
                                      _reporterGender = v;
                                      _victimGender = v;
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel('Status Pelapor'),
                              DropdownButtonFormField<String>(
                                initialValue: _reporterStatus,
                                isExpanded: true,
                                decoration: _inputDecoration(),
                                items: PolijeData.statusOptions
                                    .map((s) => DropdownMenuItem(
                                          value: s,
                                          child: Text(s,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                  fontSize: 12.5)),
                                        ))
                                    .toList(),
                                onChanged: (v) {
                                  if (v != null) {
                                    setState(() {
                                      _reporterStatus = v;
                                      _victimStatus = v;
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildSectionCard(
                number: '03',
                title: 'DATA TERLAPOR / PELAKU (OPSIONAL)',
                icon: Icons.gpp_maybe_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Nama Terlapor / Inisial'),
                    TextField(
                      controller: _suspectNameCtrl,
                      decoration: _inputDecoration(
                        hint: 'Nama lengkap atau inisial terlapor...',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel('Gender Terlapor'),
                              DropdownButtonFormField<String>(
                                initialValue: _suspectGender,
                                decoration: _inputDecoration(),
                                items: const [
                                  DropdownMenuItem(
                                      value: 'Laki-laki',
                                      child: Text('Laki-laki',
                                          style: TextStyle(fontSize: 13))),
                                  DropdownMenuItem(
                                      value: 'Perempuan',
                                      child: Text('Perempuan',
                                          style: TextStyle(fontSize: 13))),
                                ],
                                onChanged: (v) {
                                  if (v != null) {
                                    setState(() => _suspectGender = v);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel('Status Terlapor'),
                              DropdownButtonFormField<String>(
                                initialValue: _suspectStatus,
                                isExpanded: true,
                                decoration: _inputDecoration(),
                                items: PolijeData.statusOptions
                                    .map((s) => DropdownMenuItem(
                                          value: s,
                                          child: Text(s,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                  fontSize: 12.5)),
                                        ))
                                    .toList(),
                                onChanged: (v) {
                                  if (v != null) {
                                    setState(() => _suspectStatus = v);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildFieldLabel('Unit / Jurusan Terlapor'),
                    Row(
                      children: [
                        Expanded(
                          child: _buildModeChip(
                            active: _affiliationType == 'jurusan',
                            label: 'Jurusan',
                            onTap: () =>
                                setState(() => _affiliationType = 'jurusan'),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: _buildModeChip(
                            active: _affiliationType == 'unit',
                            label: 'Unit Kampus',
                            onTap: () =>
                                setState(() => _affiliationType = 'unit'),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: _buildModeChip(
                            active: _affiliationType == 'manual',
                            label: 'Lainnya',
                            onTap: () =>
                                setState(() => _affiliationType = 'manual'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (_affiliationType == 'jurusan') ...[
                      DropdownButtonFormField<String>(
                        initialValue: _selectedJurusan,
                        isExpanded: true,
                        decoration: _inputDecoration(),
                        items: PolijeData.jurusanList
                            .map((j) => DropdownMenuItem(
                                  value: j,
                                  child: Text(j,
                                      style: const TextStyle(fontSize: 13)),
                                ))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) {
                            setState(() {
                              _selectedJurusan = v;
                              _selectedProdi = '';
                            });
                          }
                        },
                      ),
                      if (prodiList.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          initialValue: prodiList.contains(_selectedProdi)
                              ? _selectedProdi
                              : null,
                          hint: const Text('Pilih Program Studi (Opsional)',
                              style: TextStyle(fontSize: 12.5)),
                          isExpanded: true,
                          decoration: _inputDecoration(),
                          items: prodiList
                              .map((p) => DropdownMenuItem(
                                    value: p,
                                    child: Text(p,
                                        style: const TextStyle(fontSize: 13)),
                                  ))
                              .toList(),
                          onChanged: (v) {
                            setState(() => _selectedProdi = v ?? '');
                          },
                        ),
                      ],
                    ] else if (_affiliationType == 'unit') ...[
                      DropdownButtonFormField<String>(
                        initialValue: _selectedUnit,
                        isExpanded: true,
                        decoration: _inputDecoration(),
                        items: PolijeData.unitLainnya
                            .map((u) => DropdownMenuItem(
                                  value: u,
                                  child: Text(u,
                                      style: const TextStyle(fontSize: 13)),
                                ))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => _selectedUnit = v);
                        },
                      ),
                    ] else ...[
                      TextField(
                        controller: _manualAffiliationCtrl,
                        decoration: _inputDecoration(
                          hint: 'Tuliskan unit/instansi terlapor...',
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    _buildFieldLabel('Nomor Kontak / WA Terlapor'),
                    TextField(
                      controller: _suspectPhoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: _inputDecoration(
                        hint: '08xxxx (Jika diketahui)',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildSectionCard(
                number: '04',
                title: 'DESKRIPSI KASUS & KRONOLOGI',
                icon: Icons.notes_rounded,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Kronologi / Keterangan Awal Kasus *'),
                    TextField(
                      controller: _keteranganCtrl,
                      maxLines: 4,
                      decoration: _inputDecoration(
                        hint:
                            'Jelaskan secara rinci kronologi kejadian atau keluhan yang disampaikan pelapor...',
                      ),
                    ),
                    if (_isRecordOnly) ...[
                      const SizedBox(height: 14),
                      _buildFieldLabel(
                          'Catatan Penanganan / Saran Satgas (Arsip Selesai) *'),
                      TextField(
                        controller: _saranCtrl,
                        maxLines: 3,
                        decoration: _inputDecoration(
                          hint:
                              'Tuliskan hasil tindakan pendampingan, kesepakatan, atau rekomendasi Satgas...',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _submitting ? null : _handleSubmit,
                  icon: _submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          _isRecordOnly
                              ? Icons.archive_outlined
                              : Icons.calendar_today_outlined,
                          size: 18,
                        ),
                  label: Text(
                    _isRecordOnly
                        ? 'SIMPAN ARSIP PENANGANAN SELESAI'
                        : 'JADWALKAN SESI PENANGANAN',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
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
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.all(9),
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
                      _isRecordOnly
                          ? 'Arsip Penanganan Selesai'
                          : 'Jadwalkan Penanganan Manual',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.gray900,
                      ),
                    ),
                    const Text(
                      'Input laporan walk-in atau pendampingan langsung Satgas.',
                      style: TextStyle(fontSize: 12, color: AppColors.gray500),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: AppColors.gray100,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => setState(() => _isRecordOnly = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color:
                            !_isRecordOnly ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'JADWALKAN SESI',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: !_isRecordOnly
                              ? const Color(0xFF4F46E5)
                              : AppColors.gray600,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => setState(() => _isRecordOnly = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color:
                            _isRecordOnly ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'ARSIP SELESAI',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: _isRecordOnly
                              ? const Color(0xFF059669)
                              : AppColors.gray600,
                        ),
                      ),
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

  Widget _buildSectionCard({
    required String number,
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
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
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  number,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF4F46E5),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Icon(icon, size: 18, color: const Color(0xFF4F46E5)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.gray900,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          child,
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: AppColors.gray700,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 12.5, color: AppColors.gray400),
      filled: true,
      fillColor: AppColors.gray50,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.gray200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.gray200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
      ),
    );
  }

  Widget _buildModeChip({
    required bool active,
    required String label,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 10),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFEEF2FF) : AppColors.gray50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active ? const Color(0xFF4F46E5) : AppColors.gray200,
            width: active ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: active ? const Color(0xFF4F46E5) : AppColors.gray500,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: active ? const Color(0xFF4F46E5) : AppColors.gray600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
