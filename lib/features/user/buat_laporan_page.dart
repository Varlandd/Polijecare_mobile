import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/routes.dart';
import '../../core/constants/polije_data.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/launcher.dart';
import '../../data/models/user_complaint.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/user_portal_service.dart';
import 'user_shell_page.dart';

/// Halaman Buat Laporan Pengaduan (`/user/buat-laporan` & `/user/report/create`)
/// — port 1:1 dari `pages/user/buat-laporan.jsx`.
class BuatLaporanPage extends StatefulWidget {
  const BuatLaporanPage({super.key});

  @override
  State<BuatLaporanPage> createState() => _BuatLaporanPageState();
}

class _BuatLaporanPageState extends State<BuatLaporanPage> {
  static const Color _purple = Color(0xFF8B5CF6);

  List<ViolenceCategoryItem> _categories = const [];
  List<String> _bookedSlots = const [];
  bool _submitting = false;
  bool _success = false;
  String _createdReportId = '';

  // Data Pelapor
  String _reporterGender = 'Laki-laki';
  String _reporterStatus = 'Mahasiswa';
  String _guestCountryCode = '+62';
  final _guestPhoneCtrl = TextEditingController();
  final _guestEmailCtrl = TextEditingController();
  String _pobChoice = 'Jember';
  final _pobCustomCtrl = TextEditingController();
  String _dobStr = '2003-05-15';
  final _reporterAddressCtrl = TextEditingController();

  // Tipe Kejadian & Korban
  String _victimType = 'self'; // 'self' | 'other'
  String _victimGender = 'Laki-laki';
  final _victimNameCtrl = TextEditingController();
  final _victimRelationshipCtrl = TextEditingController();
  String _victimStatus = 'Mahasiswa';

  // Data Terlapor
  final _suspectNameCtrl = TextEditingController();
  String _suspectGender = 'Laki-laki';
  String _suspectStatus = 'Mahasiswa';
  String _suspectAfiliasiMode = 'jurusan'; // 'jurusan' | 'lab' | 'unit' | 'manual'
  String _suspectJurusan = '';
  String _suspectSubSelection = '';
  final _suspectManualAffiliationCtrl = TextEditingController();
  String _suspectCountryCode = '+62';
  final _suspectWhatsappCtrl = TextEditingController();
  final _suspectNimNipCtrl = TextEditingController();

  // Alasan Pengaduan
  final Set<String> _selectedAlasan = {
    'Saya seorang korban yang memerlukan bantuan pemulihan.',
  };
  final _alasanLainnyaCtrl = TextEditingController();

  // Usulan Jadwal Penanganan
  String _proposedDate = '';
  String _proposedTime = '';

  // Informasi Tambahan & Lokasi
  String _selectedCategoryId = '';
  final _titleCtrl = TextEditingController();
  final _chronologyCtrl = TextEditingController();
  String _locationMode = 'pilih'; // 'pilih' | 'manual'
  String _locationArea = '';
  String _locationLab = '';
  final _locationManualCtrl = TextEditingController();
  String _incidentDate = '';

  // Lampiran
  final List<String> _attachmentNames = [];

  // Error pesan validasi
  final Map<String, String> _errors = {};

  @override
  void initState() {
    super.initState();
    final user = AuthService.instance.user;
    if (user != null) {
      if (user.gender != null && user.gender!.isNotEmpty) {
        _reporterGender = user.gender!;
        _victimGender = user.gender!;
      }
      if (user.phone != null && user.phone!.isNotEmpty) {
        var ph = user.phone!.replaceAll(RegExp(r'\D'), '');
        if (ph.startsWith('0')) ph = ph.substring(1);
        if (ph.startsWith('62')) ph = ph.substring(2);
        _guestPhoneCtrl.text = ph;
      }
      _guestEmailCtrl.text = user.email;
    }

    // Default tanggal kejadian = hari ini, usulan jadwal = hari kerja terdekat (Senin-Kamis)
    final now = DateTime.now();
    _incidentDate = DateFormat('yyyy-MM-dd').format(now);
    var nextWorkday = now.add(const Duration(days: 1));
    while (nextWorkday.weekday >= 5) {
      nextWorkday = nextWorkday.add(const Duration(days: 1));
    }
    _proposedDate = DateFormat('yyyy-MM-dd').format(nextWorkday);
    _proposedTime = '09:00';

    _loadInitialData();
  }

  @override
  void dispose() {
    _guestPhoneCtrl.dispose();
    _guestEmailCtrl.dispose();
    _pobCustomCtrl.dispose();
    _reporterAddressCtrl.dispose();
    _victimNameCtrl.dispose();
    _victimRelationshipCtrl.dispose();
    _suspectNameCtrl.dispose();
    _suspectManualAffiliationCtrl.dispose();
    _suspectWhatsappCtrl.dispose();
    _suspectNimNipCtrl.dispose();
    _alasanLainnyaCtrl.dispose();
    _titleCtrl.dispose();
    _chronologyCtrl.dispose();
    _locationManualCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    final cats = await UserPortalService.instance.getCategories();
    if (!mounted) return;
    setState(() {
      _categories = cats;
      if (cats.isNotEmpty && _selectedCategoryId.isEmpty) {
        _selectedCategoryId = cats.first.uniqueId;
      }
    });
    if (_proposedDate.isNotEmpty) {
      _loadBookedSlots(_proposedDate);
    }
  }

  Future<void> _loadBookedSlots(String date) async {
    final slots = await UserPortalService.instance.getBookedSlots(date);
    if (!mounted) return;
    setState(() => _bookedSlots = slots);
  }

  String get _computedSuspectAffiliation {
    if (_suspectAfiliasiMode == 'manual') {
      return _suspectManualAffiliationCtrl.text.trim();
    }
    if (_suspectAfiliasiMode == 'unit') {
      return _suspectSubSelection;
    }
    if (_suspectAfiliasiMode == 'lab') {
      return _suspectSubSelection;
    }
    if (_suspectJurusan.isEmpty) return '';
    if (_suspectSubSelection.isNotEmpty) {
      return '$_suspectJurusan - $_suspectSubSelection';
    }
    return _suspectJurusan;
  }

  String get _computedLocation {
    if (_locationMode == 'manual') {
      return _locationManualCtrl.text.trim();
    }
    if (_locationArea.isEmpty) return '';
    if (_locationLab.isNotEmpty) {
      return '$_locationArea - $_locationLab';
    }
    return _locationArea;
  }

  bool get _isProposedWeekendOrFriday {
    final dt = DateTime.tryParse(_proposedDate);
    if (dt == null) return false;
    return dt.weekday >= 5; // Jumat(5), Sabtu(6), Minggu(7)
  }

  int _timeToMinutes(String t) {
    final parts = t.split(':');
    if (parts.length < 2) return 0;
    return (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
  }

  bool _isSlotBooked(String slot) {
    final slotMin = _timeToMinutes(slot);
    for (final b in _bookedSlots) {
      final bMin = _timeToMinutes(b);
      if ((slotMin - bMin).abs() < 60) return true;
    }
    return false;
  }

  Future<void> _pickDate({
    required String current,
    required ValueChanged<String> onPicked,
    DateTime? firstDate,
    DateTime? lastDate,
  }) async {
    final initial = DateTime.tryParse(current) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate ?? DateTime(1970),
      lastDate: lastDate ?? DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      onPicked(DateFormat('yyyy-MM-dd').format(picked));
    }
  }

  Future<void> _pickAttachments() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      );
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          for (final f in result.files) {
            if (f.name.isNotEmpty) {
              _attachmentNames.add(f.name);
            }
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _handleSubmit() async {
    if (_submitting) return;
    final errs = <String, String>{};

    if (_guestPhoneCtrl.text.trim().length < 8) {
      errs['guest_phone'] = 'Nomor WhatsApp minimal 8 digit.';
    }
    if (_guestEmailCtrl.text.trim().isEmpty) {
      errs['guest_email'] = 'Email aktif wajib diisi.';
    }
    if (_reporterStatus.isEmpty) {
      errs['reporter_status'] = 'Status pelapor wajib dipilih.';
    }
    if (_victimType == 'other') {
      if (_victimNameCtrl.text.trim().isEmpty) {
        errs['victim_name'] = 'Nama korban wajib diisi.';
      }
      if (_victimRelationshipCtrl.text.trim().isEmpty) {
        errs['victim_relationship'] = 'Hubungan dengan korban wajib diisi.';
      }
    }
    if (_suspectNameCtrl.text.trim().isEmpty) {
      errs['suspect_name'] = 'Nama terlapor wajib diisi.';
    }
    if (_computedSuspectAffiliation.isEmpty) {
      errs['suspect_affiliation'] = 'Afiliasi terlapor wajib dipilih/diisi.';
    }
    if (_proposedDate.isEmpty) {
      errs['proposed_date'] = 'Tanggal usulan jadwal wajib dipilih.';
    } else if (_isProposedWeekendOrFriday) {
      errs['proposed_date'] =
          'Penanganan (Konseling) hanya tersedia pada hari Senin sampai Kamis.';
    }
    if (_proposedTime.isEmpty) {
      errs['proposed_time'] = 'Jam usulan jadwal wajib dipilih.';
    }
    if (_selectedCategoryId.isEmpty) {
      errs['category'] = 'Kategori kekerasan wajib dipilih.';
    }
    if (_titleCtrl.text.trim().length < 5) {
      errs['title'] = 'Judul minimal 5 karakter.';
    }
    if (_chronologyCtrl.text.trim().length < 250) {
      errs['chronology'] =
          'Kronologi minimal 250 karakter. (saat ini ${_chronologyCtrl.text.trim().length} karakter)';
    }
    if (_computedLocation.isEmpty) {
      errs['location'] = 'Lokasi kejadian wajib diisi.';
    }
    if (_incidentDate.isEmpty) {
      errs['incident_date'] = 'Tanggal kejadian wajib diisi.';
    }

    setState(() {
      _errors
        ..clear()
        ..addAll(errs);
    });

    if (errs.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errs.values.first),
          backgroundColor: const Color(0xFFE11D48),
        ),
      );
      return;
    }

    setState(() => _submitting = true);

    final user = AuthService.instance.user;
    final place = _pobChoice == 'Lainnya'
        ? _pobCustomCtrl.text.trim()
        : _pobChoice;
    final pobDob = '$place, $_dobStr';

    final alasanList = _selectedAlasan.map((item) {
      if (item == 'Lainnya' && _alasanLainnyaCtrl.text.trim().isNotEmpty) {
        return 'Lainnya: ${_alasanLainnyaCtrl.text.trim()}';
      }
      return item;
    }).toList();

    final catName = _categories
            .where((c) => c.uniqueId == _selectedCategoryId)
            .firstOrNull
            ?.name ??
        'Laporan';

    final reportId = await UserPortalService.instance.submitReport(
      title: _titleCtrl.text.trim(),
      categoryId: _selectedCategoryId,
      categoryName: catName,
      victimType: _victimType,
      victimGender:
          _victimType == 'self' ? _reporterGender : _victimGender,
      victimName: _victimNameCtrl.text.trim(),
      victimRelationship: _victimRelationshipCtrl.text.trim(),
      victimStatus: _victimStatus,
      suspectName: _suspectNameCtrl.text.trim(),
      suspectGender: _suspectGender,
      suspectStatus: _suspectStatus,
      suspectAffiliation: _computedSuspectAffiliation,
      suspectPhone: _suspectWhatsappCtrl.text.trim().isNotEmpty
          ? '$_suspectCountryCode${_suspectWhatsappCtrl.text.trim()}'
          : null,
      suspectNimNip: _suspectNimNipCtrl.text.trim(),
      chronology: _chronologyCtrl.text.trim(),
      location: _computedLocation,
      incidentDate: _incidentDate,
      guestPhone: '$_guestCountryCode${_guestPhoneCtrl.text.trim()}',
      guestEmail: _guestEmailCtrl.text.trim(),
      guestNim: user?.nim,
      guestProdi: user?.prodi,
      guestUnit: user?.unit,
      reporterGender: _reporterGender,
      reporterStatus: _reporterStatus,
      reporterPobDob: pobDob,
      reporterAddress: _reporterAddressCtrl.text.trim(),
      alasanPengaduan: alasanList,
      proposedDate: _proposedDate,
      proposedTime: _proposedTime,
      attachmentNames: _attachmentNames,
    );

    if (!mounted) return;
    setState(() {
      _submitting = false;
      _createdReportId = reportId;
      _success = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.user;

    if (_success) {
      final catName = _categories
              .where((c) => c.uniqueId == _selectedCategoryId)
              .firstOrNull
              ?.name ??
          'Laporan';
      final waUrl = UserPortalService.instance.getWhatsappConfirmUrl(
        reportId: _createdReportId,
        reporterName: user?.name ?? 'Mahasiswa',
        categoryName: catName,
        title: _titleCtrl.text.trim(),
        proposedDate: _proposedDate,
        proposedTime: _proposedTime,
      );

      return UserShellPage(
        title: 'Laporan Terkirim',
        subtitle: 'Formulir pengaduan PolijeCare',
        activePath: AppRoutes.userBuatLaporan,
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 460),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 24,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 120,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.check_circle_outline_rounded,
                      color: Colors.white,
                      size: 64,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
                    child: Column(
                      children: [
                        const Text(
                          'Laporan Terkirim!',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: AppColors.gray900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text.rich(
                          TextSpan(
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.gray500,
                            ),
                            children: [
                              const TextSpan(text: 'Nomor registrasi: '),
                              TextSpan(
                                text: _createdReportId,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _purple,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => AppLauncher.openUrl(waUrl),
                            icon: const Icon(Icons.chat_outlined, size: 18),
                            label: const Text(
                              'Konfirmasi via WhatsApp',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF25D366),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context)
                                .pushReplacementNamed(
                                    AppRoutes.userHistoriPengaduan),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              side: const BorderSide(
                                  color: AppColors.gray200, width: 1.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              'Lihat Riwayat',
                              style: TextStyle(
                                color: AppColors.gray600,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final chronoLen = _chronologyCtrl.text.trim().length;

    return UserShellPage(
      title: 'Buat Laporan',
      subtitle: 'Formulir pengaduan aman & rahasia PolijeCare',
      activePath: AppRoutes.userBuatLaporan,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header + Tombol Kembali ──
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => Navigator.of(context)
                  .pushReplacementNamed(AppRoutes.userDashboard),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.arrow_back_rounded,
                      size: 16,
                      color: AppColors.gray500,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Kembali',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.gray500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Buat Laporan Pengaduan',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.gray900,
              ),
            ),
            const SizedBox(height: 16),

            // ── Komitmen Kerahasiaan Satgas PPKPT (`buat-laporan.jsx`) ──
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: const LinearGradient(
                  colors: [Color(0xFFEFF6FF), Color(0xFFEEF2FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDBEAFE),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.shield_outlined,
                      color: Color(0xFF2563EB),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Komitmen Kerahasiaan Satgas PPKPT',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E40AF),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Berdasarkan Permendikbudristek No. 55 Tahun 2024 Pasal 30 ayat (1) huruf b, Satuan Tugas PPKPT berkewajiban merahasiakan identitas Anda dan seluruh pihak yang terkait dengan laporan ini.',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF1D4ED8),
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: const Color(0xFFBFDBFE)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_rounded,
                                size: 14,
                                color: Color(0xFF10B981),
                              ),
                              SizedBox(width: 4),
                              Text(
                                'DATA ANDA TERLINDUNGI SECARA HUKUM',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1D4ED8),
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // ── SECTION 1: DATA PELAPOR ──
            _SectionCard(
              icon: Icons.person_outline_rounded,
              iconColor: _purple,
              title: 'Data Pelapor',
              subtitle:
                  'Data pelapor adalah orang yang melaporkan kejadian (bisa diri Anda sendiri sebagai korban, atau orang lain yang melihat kejadian).',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Readonly grid
                  Wrap(
                    spacing: 16,
                    runSpacing: 12,
                    children: [
                      _ReadonlyInfo(
                          label: 'Nama', value: user?.name ?? '-'),
                      _ReadonlyInfo(
                          label: 'NIM/NIP', value: user?.nim ?? '-'),
                      _ReadonlyInfo(
                          label: 'Prodi', value: user?.prodi ?? '-'),
                      _ReadonlyInfo(
                          label: 'Semester', value: user?.semester ?? '-'),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(color: AppColors.gray100, height: 1),
                  ),

                  const _FieldLabel('Gender Pelapor', requiredField: true),
                  _GenderSegmentToggle(
                    value: _reporterGender,
                    onChanged: (v) {
                      setState(() {
                        _reporterGender = v;
                        if (_victimType == 'self') _victimGender = v;
                      });
                    },
                  ),
                  const SizedBox(height: 14),

                  const _FieldLabel('Status Pelapor', requiredField: true),
                  DropdownButtonFormField<String>(
                    initialValue: _reporterStatus,
                    items: [
                      for (final s in PolijeData.statusOptions)
                        DropdownMenuItem(value: s, child: Text(s)),
                    ],
                    onChanged: (v) =>
                        setState(() => _reporterStatus = v ?? 'Mahasiswa'),
                    decoration: _inputDecoration(),
                  ),
                  const SizedBox(height: 14),

                  const _FieldLabel('WA Aktif', requiredField: true),
                  Row(
                    children: [
                      SizedBox(
                        width: 100,
                        child: DropdownButtonFormField<String>(
                          initialValue: _guestCountryCode,
                          items: const [
                            DropdownMenuItem(
                                value: '+62', child: Text('🇮🇩 +62')),
                            DropdownMenuItem(
                                value: '+60', child: Text('🇲🇾 +60')),
                            DropdownMenuItem(
                                value: '+65', child: Text('🇸🇬 +65')),
                          ],
                          onChanged: (v) =>
                              setState(() => _guestCountryCode = v ?? '+62'),
                          decoration: _inputDecoration(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _guestPhoneCtrl,
                          keyboardType: TextInputType.phone,
                          decoration: _inputDecoration(
                            hint: '8123xxxx',
                            error: _errors['guest_phone'],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  const _FieldLabel('Email Aktif', requiredField: true),
                  TextField(
                    controller: _guestEmailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _inputDecoration(
                      hint: 'email@student.polije.ac.id',
                      error: _errors['guest_email'],
                    ),
                  ),
                  const SizedBox(height: 14),

                  const _FieldLabel(
                    'Tempat, Tanggal Lahir Pelapor',
                    requiredField: true,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _pobChoice,
                          isExpanded: true,
                          items: [
                            for (final c in PolijeData.commonCities)
                              DropdownMenuItem(value: c, child: Text(c)),
                            const DropdownMenuItem(
                              value: 'Lainnya',
                              child: Text('Lainnya (Tulis Sendiri)'),
                            ),
                          ],
                          onChanged: (v) =>
                              setState(() => _pobChoice = v ?? 'Jember'),
                          decoration: _inputDecoration(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: InkWell(
                          onTap: () => _pickDate(
                            current: _dobStr,
                            lastDate: DateTime.now(),
                            onPicked: (d) => setState(() => _dobStr = d),
                          ),
                          child: InputDecorator(
                            decoration: _inputDecoration(),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _dobStr,
                                  style: const TextStyle(fontSize: 13.5),
                                ),
                                const Icon(
                                  Icons.calendar_today_outlined,
                                  size: 16,
                                  color: AppColors.gray400,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_pobChoice == 'Lainnya') ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: _pobCustomCtrl,
                      decoration:
                          _inputDecoration(hint: 'Tulis tempat lahir...'),
                    ),
                  ],
                  const SizedBox(height: 14),

                  const _FieldLabel(
                    'Alamat Domisili Pelapor',
                    requiredField: true,
                  ),
                  TextField(
                    controller: _reporterAddressCtrl,
                    decoration:
                        _inputDecoration(hint: 'Alamat lengkap saat ini...'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // ── SECTION 2: TIPE KEJADIAN ──
            _SectionCard(
              icon: Icons.description_outlined,
              iconColor: _purple,
              title: 'Tipe Kejadian',
              subtitle: 'Pilih siapa yang menjadi korban dalam kejadian ini.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _RadioOptionTile(
                    title: 'Kejadian yang saya alami sendiri',
                    selected: _victimType == 'self',
                    onTap: () => setState(() => _victimType = 'self'),
                  ),
                  const SizedBox(height: 10),
                  _RadioOptionTile(
                    title: 'Kejadian dialami orang lain',
                    selected: _victimType == 'other',
                    onTap: () => setState(() => _victimType = 'other'),
                  ),
                  if (_victimType == 'other') ...[
                    const SizedBox(height: 16),
                    const _FieldLabel(
                      'Jenis Kelamin Korban',
                      requiredField: true,
                    ),
                    _GenderSegmentToggle(
                      value: _victimGender,
                      onChanged: (v) => setState(() => _victimGender = v),
                    ),
                    const SizedBox(height: 14),
                    const _FieldLabel('Nama Korban', requiredField: true),
                    TextField(
                      controller: _victimNameCtrl,
                      decoration: _inputDecoration(
                        hint: 'Nama lengkap korban',
                        error: _errors['victim_name'],
                      ),
                    ),
                    const SizedBox(height: 14),
                    const _FieldLabel('Hubungan', requiredField: true),
                    TextField(
                      controller: _victimRelationshipCtrl,
                      decoration: _inputDecoration(
                        hint: 'Contoh: Teman sekelas / Rekan organisasi',
                        error: _errors['victim_relationship'],
                      ),
                    ),
                    const SizedBox(height: 14),
                    const _FieldLabel('Status Korban', requiredField: true),
                    DropdownButtonFormField<String>(
                      initialValue: _victimStatus,
                      items: [
                        for (final s in PolijeData.statusOptions)
                          DropdownMenuItem(value: s, child: Text(s)),
                      ],
                      onChanged: (v) =>
                          setState(() => _victimStatus = v ?? 'Mahasiswa'),
                      decoration: _inputDecoration(),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),

            // ── SECTION 3: DATA TERLAPOR ──
            _SectionCard(
              icon: Icons.person_outline_rounded,
              iconColor: const Color(0xFFF43F5E),
              title: 'Data Terlapor',
              subtitle:
                  'Data Terlapor adalah orang yang diadukan atau diduga melakukan tindakan kekerasan/perundungan.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _FieldLabel('Nama Terlapor', requiredField: true),
                  TextField(
                    controller: _suspectNameCtrl,
                    decoration: _inputDecoration(
                      hint: 'Nama terlapor',
                      error: _errors['suspect_name'],
                    ),
                  ),
                  const SizedBox(height: 14),

                  const _FieldLabel('Jenis Kelamin'),
                  _GenderSegmentToggle(
                    value: _suspectGender,
                    onChanged: (v) => setState(() => _suspectGender = v),
                  ),
                  const SizedBox(height: 14),

                  const _FieldLabel('Status', requiredField: true),
                  DropdownButtonFormField<String>(
                    initialValue: _suspectStatus,
                    items: [
                      for (final s in PolijeData.statusOptions)
                        DropdownMenuItem(value: s, child: Text(s)),
                    ],
                    onChanged: (v) =>
                        setState(() => _suspectStatus = v ?? 'Mahasiswa'),
                    decoration: _inputDecoration(),
                  ),
                  const SizedBox(height: 16),

                  const _FieldLabel(
                    'Afiliasi / Unit Terlapor',
                    requiredField: true,
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final entry in const [
                        ['jurusan', 'Jurusan / Prodi'],
                        ['lab', 'Laboratorium'],
                        ['unit', 'Unit Lainnya'],
                        ['manual', 'Tulis Manual'],
                      ])
                        ChoiceChip(
                          label: Text(entry[1]),
                          selected: _suspectAfiliasiMode == entry[0],
                          selectedColor: _purple,
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _suspectAfiliasiMode == entry[0]
                                ? Colors.white
                                : AppColors.gray600,
                          ),
                          onSelected: (_) {
                            setState(() {
                              _suspectAfiliasiMode = entry[0];
                              _suspectJurusan = '';
                              _suspectSubSelection = '';
                            });
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (_suspectAfiliasiMode == 'jurusan') ...[
                    DropdownButtonFormField<String>(
                      initialValue:
                          _suspectJurusan.isEmpty ? null : _suspectJurusan,
                      hint: const Text('-- Pilih Jurusan --'),
                      isExpanded: true,
                      items: [
                        for (final j in PolijeData.jurusanList)
                          DropdownMenuItem(value: j, child: Text(j)),
                      ],
                      onChanged: (v) {
                        setState(() {
                          _suspectJurusan = v ?? '';
                          _suspectSubSelection = '';
                        });
                      },
                      decoration: _inputDecoration(
                          error: _errors['suspect_affiliation']),
                    ),
                    if (_suspectJurusan.isNotEmpty &&
                        PolijeData.getProdiByJurusan(_suspectJurusan)
                            .isNotEmpty) ...[
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        initialValue: _suspectSubSelection.isEmpty
                            ? null
                            : _suspectSubSelection,
                        hint: const Text('-- Pilih Prodi (opsional) --'),
                        isExpanded: true,
                        items: [
                          for (final p in PolijeData.getProdiByJurusan(
                              _suspectJurusan))
                            DropdownMenuItem(value: p, child: Text(p)),
                        ],
                        onChanged: (v) =>
                            setState(() => _suspectSubSelection = v ?? ''),
                        decoration: _inputDecoration(),
                      ),
                    ],
                  ] else if (_suspectAfiliasiMode == 'lab') ...[
                    DropdownButtonFormField<String>(
                      initialValue:
                          _suspectJurusan.isEmpty ? null : _suspectJurusan,
                      hint: const Text('-- Pilih Jurusan --'),
                      isExpanded: true,
                      items: [
                        for (final j in PolijeData.jurusanList)
                          DropdownMenuItem(value: j, child: Text(j)),
                      ],
                      onChanged: (v) {
                        setState(() {
                          _suspectJurusan = v ?? '';
                          _suspectSubSelection = '';
                        });
                      },
                      decoration: _inputDecoration(),
                    ),
                    if (_suspectJurusan.isNotEmpty &&
                        PolijeData.getLabByJurusan(_suspectJurusan)
                            .isNotEmpty) ...[
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        initialValue: _suspectSubSelection.isEmpty
                            ? null
                            : _suspectSubSelection,
                        hint: const Text('-- Pilih Lab --'),
                        isExpanded: true,
                        items: [
                          for (final l
                              in PolijeData.getLabByJurusan(_suspectJurusan))
                            DropdownMenuItem(value: l, child: Text(l)),
                        ],
                        onChanged: (v) =>
                            setState(() => _suspectSubSelection = v ?? ''),
                        decoration: _inputDecoration(
                            error: _errors['suspect_affiliation']),
                      ),
                    ],
                  ] else if (_suspectAfiliasiMode == 'unit') ...[
                    DropdownButtonFormField<String>(
                      initialValue: _suspectSubSelection.isEmpty
                          ? null
                          : _suspectSubSelection,
                      hint: const Text('-- Pilih Unit --'),
                      isExpanded: true,
                      items: [
                        for (final u in PolijeData.unitLainnya)
                          DropdownMenuItem(value: u, child: Text(u)),
                      ],
                      onChanged: (v) =>
                          setState(() => _suspectSubSelection = v ?? ''),
                      decoration: _inputDecoration(
                          error: _errors['suspect_affiliation']),
                    ),
                  ] else ...[
                    TextField(
                      controller: _suspectManualAffiliationCtrl,
                      onChanged: (_) => setState(() {}),
                      decoration: _inputDecoration(
                        hint: 'Tulis afiliasi/unit secara manual...',
                        error: _errors['suspect_affiliation'],
                      ),
                    ),
                  ],
                  if (_computedSuspectAffiliation.isNotEmpty &&
                      _suspectAfiliasiMode != 'manual') ...[
                    const SizedBox(height: 6),
                    Text(
                      '✓ Dipilih: $_computedSuspectAffiliation',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _purple,
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),

                  const _FieldLabel('WhatsApp Terlapor'),
                  Row(
                    children: [
                      SizedBox(
                        width: 100,
                        child: DropdownButtonFormField<String>(
                          initialValue: _suspectCountryCode,
                          items: const [
                            DropdownMenuItem(
                                value: '+62', child: Text('🇮🇩 +62')),
                            DropdownMenuItem(
                                value: '+60', child: Text('🇲🇾 +60')),
                          ],
                          onChanged: (v) =>
                              setState(() => _suspectCountryCode = v ?? '+62'),
                          decoration: _inputDecoration(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _suspectWhatsappCtrl,
                          keyboardType: TextInputType.phone,
                          decoration: _inputDecoration(
                            hint: '8123xxxx (Opsional)',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  const _FieldLabel('NIM/NIP Terlapor'),
                  TextField(
                    controller: _suspectNimNipCtrl,
                    decoration: _inputDecoration(
                      hint: 'NIM/NIP Terlapor (Opsional)',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // ── SECTION 4: ALASAN PENGADUAN ──
            _SectionCard(
              icon: Icons.fact_check_outlined,
              iconColor: _purple,
              title: 'Alasan Pengaduan',
              subtitle:
                  'Pilih alasan pengaduan Anda (dapat memilih lebih dari satu sesuai kebutuhan Satgas).',
              child: Column(
                children: [
                  for (final option in PolijeData.alasanPengaduanOptions) ...[
                    Builder(
                      builder: (context) {
                        final checked = _selectedAlasan.contains(option);
                        return Column(
                          children: [
                            InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () {
                                setState(() {
                                  if (checked) {
                                    _selectedAlasan.remove(option);
                                  } else {
                                    _selectedAlasan.add(option);
                                  }
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: checked
                                      ? const Color(0xFFFAF5FF)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: checked
                                        ? _purple
                                        : AppColors.gray200,
                                    width: checked ? 1.8 : 1,
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      checked
                                          ? Icons.check_box_rounded
                                          : Icons
                                              .check_box_outline_blank_rounded,
                                      color:
                                          checked ? _purple : AppColors.gray400,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        option == 'Lainnya'
                                            ? 'Lainnya (Sebutkan alasan lainnya jika ada)'
                                            : option,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.gray700,
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (option == 'Lainnya' && checked) ...[
                              const SizedBox(height: 8),
                              TextField(
                                controller: _alasanLainnyaCtrl,
                                maxLines: 2,
                                decoration: _inputDecoration(
                                  hint:
                                      'Tuliskan alasan lainnya secara singkat...',
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                          ],
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),

            // ── SECTION 5: USULAN JADWAL PENANGANAN ──
            _SectionCard(
              icon: Icons.calendar_today_outlined,
              iconColor: _purple,
              title: 'Usulan Jadwal Penanganan',
              subtitle:
                  'Tim Satgas akan menghubungi Anda sesuai jadwal yang diusulkan.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: Color(0xFFD97706),
                          size: 18,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ketentuan Jadwal:',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF92400E),
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                '• Layanan Konseling: Senin - Kamis (08:00 - 16:00 WIB)\n• Hari Jumat - Minggu hanya untuk pengiriman laporan.',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: Color(0xFF92400E),
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  const _FieldLabel('Pilih Tanggal', requiredField: true),
                  InkWell(
                    onTap: () => _pickDate(
                      current: _proposedDate,
                      firstDate: DateTime.now(),
                      onPicked: (d) {
                        setState(() => _proposedDate = d);
                        _loadBookedSlots(d);
                      },
                    ),
                    child: InputDecorator(
                      decoration: _inputDecoration(
                          error: _errors['proposed_date']),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _proposedDate.isEmpty
                                ? 'Pilih tanggal...'
                                : _proposedDate,
                            style: const TextStyle(fontSize: 14),
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
                  if (_isProposedWeekendOrFriday) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF1F2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFFECDD3)),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            color: Color(0xFFE11D48),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Maaf, layanan konseling Satgas hanya tersedia hari Senin sampai Kamis. Silakan pilih tanggal lain.',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF9F1239),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),

                  const _FieldLabel('Pilih Jam (24 Jam)', requiredField: true),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final slot in PolijeData.timeSlots)
                        Builder(
                          builder: (context) {
                            final booked = _isSlotBooked(slot);
                            final active = _proposedTime == slot;
                            return InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: booked
                                  ? null
                                  : () => setState(() => _proposedTime = slot),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: booked
                                      ? const Color(0xFFFEF2F2)
                                      : active
                                          ? _purple
                                          : AppColors.gray50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: booked
                                        ? const Color(0xFFFECACA)
                                        : active
                                            ? _purple
                                            : AppColors.gray200,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.access_time_rounded,
                                      size: 14,
                                      color: booked
                                          ? const Color(0xFFFCA5A5)
                                          : active
                                              ? Colors.white
                                              : AppColors.gray500,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      booked ? '$slot (Penuh)' : slot,
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.bold,
                                        color: booked
                                            ? const Color(0xFFFCA5A5)
                                            : active
                                                ? Colors.white
                                                : AppColors.gray700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // ── SECTION 6: INFORMASI TAMBAHAN (KATEGORI, JUDUL, KRONOLOGI) ──
            _SectionCard(
              icon: Icons.edit_note_rounded,
              iconColor: _purple,
              title: 'Informasi Laporan & Kronologi',
              subtitle:
                  'Pilih kategori kekerasan, judul singkat, dan ceritakan urutan kejadian secara detail.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _FieldLabel('Kategori Kekerasan', requiredField: true),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCategoryId.isEmpty
                        ? null
                        : _selectedCategoryId,
                    hint: const Text('-- Pilih Kategori --'),
                    isExpanded: true,
                    items: [
                      for (final c in _categories)
                        DropdownMenuItem(
                          value: c.uniqueId,
                          child: Text(c.name),
                        ),
                    ],
                    onChanged: (v) =>
                        setState(() => _selectedCategoryId = v ?? ''),
                    decoration: _inputDecoration(error: _errors['category']),
                  ),
                  const SizedBox(height: 14),

                  const _FieldLabel('Judul Laporan', requiredField: true),
                  TextField(
                    controller: _titleCtrl,
                    decoration: _inputDecoration(
                      hint: 'Judul singkat...',
                      error: _errors['title'],
                    ),
                  ),
                  const SizedBox(height: 14),

                  const _FieldLabel(
                    'Kronologi (Min 250 Karakter)',
                    requiredField: true,
                  ),
                  const Text(
                    'Kronologi adalah urutan kejadian yang menjelaskan bagaimana peristiwa tersebut berlangsung dari awal hingga akhir secara detail.',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: AppColors.gray400,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _chronologyCtrl,
                    maxLines: 5,
                    onChanged: (_) => setState(() {}),
                    decoration: _inputDecoration(
                      hint: 'Ceritakan secara detail urutan kejadiannya...',
                      error: _errors['chronology'],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '$chronoLen/250 karakter',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: chronoLen >= 250
                            ? const Color(0xFF10B981)
                            : AppColors.gray400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // ── SECTION 7: LOKASI & WAKTU KEJADIAN ──
            _SectionCard(
              icon: Icons.location_on_outlined,
              iconColor: _purple,
              title: 'Lokasi & Waktu Kejadian',
              subtitle:
                  'Berikan detail lokasi dan waktu peristiwa secara manual',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const _FieldLabel('Lokasi Detail', requiredField: true),
                      Row(
                        children: [
                          ChoiceChip(
                            label: const Text('Pilih Kampus'),
                            selected: _locationMode == 'pilih',
                            selectedColor: _purple,
                            labelStyle: TextStyle(
                              fontSize: 11,
                              color: _locationMode == 'pilih'
                                  ? Colors.white
                                  : AppColors.gray600,
                            ),
                            onSelected: (_) =>
                                setState(() => _locationMode = 'pilih'),
                          ),
                          const SizedBox(width: 6),
                          ChoiceChip(
                            label: const Text('Tulis Manual'),
                            selected: _locationMode == 'manual',
                            selectedColor: _purple,
                            labelStyle: TextStyle(
                              fontSize: 11,
                              color: _locationMode == 'manual'
                                  ? Colors.white
                                  : AppColors.gray600,
                            ),
                            onSelected: (_) =>
                                setState(() => _locationMode = 'manual'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (_locationMode == 'pilih') ...[
                    DropdownButtonFormField<String>(
                      initialValue:
                          _locationArea.isEmpty ? null : _locationArea,
                      hint: const Text('-- Pilih Area / Jurusan --'),
                      isExpanded: true,
                      items: [
                        for (final j in PolijeData.jurusanList)
                          DropdownMenuItem(value: j, child: Text(j)),
                        for (final u in PolijeData.unitLainnya)
                          DropdownMenuItem(value: u, child: Text(u)),
                      ],
                      onChanged: (v) {
                        setState(() {
                          _locationArea = v ?? '';
                          _locationLab = '';
                        });
                      },
                      decoration:
                          _inputDecoration(error: _errors['location']),
                    ),
                    if (_locationArea.isNotEmpty &&
                        PolijeData.getLabByJurusan(_locationArea)
                            .isNotEmpty) ...[
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        initialValue:
                            _locationLab.isEmpty ? null : _locationLab,
                        hint: const Text('-- Spesifik Lab (opsional) --'),
                        isExpanded: true,
                        items: [
                          for (final l
                              in PolijeData.getLabByJurusan(_locationArea))
                            DropdownMenuItem(value: l, child: Text(l)),
                        ],
                        onChanged: (v) =>
                            setState(() => _locationLab = v ?? ''),
                        decoration: _inputDecoration(),
                      ),
                    ],
                  ] else ...[
                    TextField(
                      controller: _locationManualCtrl,
                      decoration: _inputDecoration(
                        hint: 'Contoh: Gedung JTI Lantai 2, Ruang Kelas 05',
                        error: _errors['location'],
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),

                  const _FieldLabel('Tanggal Kejadian', requiredField: true),
                  InkWell(
                    onTap: () => _pickDate(
                      current: _incidentDate,
                      lastDate: DateTime.now(),
                      onPicked: (d) => setState(() => _incidentDate = d),
                    ),
                    child: InputDecorator(
                      decoration:
                          _inputDecoration(error: _errors['incident_date']),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _incidentDate,
                            style: const TextStyle(fontSize: 14),
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
                ],
              ),
            ),
            const SizedBox(height: 18),

            // ── SECTION 8: LAMPIRAN BUKTI ──
            _SectionCard(
              icon: Icons.attach_file_rounded,
              iconColor: _purple,
              title: 'Bukti Pendukung (Opsional)',
              subtitle: 'Format yang didukung: JPG, PNG, PDF (Maks. 10MB)',
              child: Column(
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: _pickAttachments,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 28),
                      decoration: BoxDecoration(
                        color: AppColors.gray50,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: AppColors.gray200,
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: const Column(
                        children: [
                          Icon(
                            Icons.attach_file_rounded,
                            size: 30,
                            color: AppColors.gray400,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Klik untuk memilih file bukti',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.gray700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_attachmentNames.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    for (int i = 0; i < _attachmentNames.length; i++)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.gray50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.gray100),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _attachmentNames[i],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                setState(() => _attachmentNames.removeAt(i));
                              },
                              icon: const Icon(
                                Icons.close_rounded,
                                size: 18,
                                color: Color(0xFFE11D48),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── TOMBOL AKSI ──
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context)
                        .pushReplacementNamed(AppRoutes.userDashboard),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: AppColors.gray200),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Batal',
                      style: TextStyle(
                        color: AppColors.gray600,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _purple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _submitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Kirim Laporan & Jadwal',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({String? hint, String? error}) {
    return InputDecoration(
      hintText: hint,
      errorText: error,
      filled: true,
      fillColor: AppColors.gray50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.gray200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.gray200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _purple, width: 1.5),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.gray100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFFFAFAFA),
              borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
              border: Border(bottom: BorderSide(color: AppColors.gray100)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: iconColor, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.gray800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.gray400,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _ReadonlyInfo extends StatelessWidget {
  const _ReadonlyInfo({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.gray500,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
              color: AppColors.gray900,
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text, {this.requiredField = false});
  final String text;
  final bool requiredField;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text.rich(
        TextSpan(
          text: text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.gray700,
          ),
          children: [
            if (requiredField)
              const TextSpan(
                text: ' *',
                style: TextStyle(color: Color(0xFFEF4444)),
              ),
          ],
        ),
      ),
    );
  }
}

class _GenderSegmentToggle extends StatelessWidget {
  const _GenderSegmentToggle({
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.gray100,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          for (final g in const ['Laki-laki', 'Perempuan'])
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(g),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: value == g ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    g,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: value == g
                          ? const Color(0xFF8B5CF6)
                          : AppColors.gray500,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RadioOptionTile extends StatelessWidget {
  const _RadioOptionTile({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF8B5CF6);
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFAF5FF) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? purple : AppColors.gray200,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: selected ? purple : AppColors.gray400,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.gray800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

