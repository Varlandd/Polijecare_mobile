import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/routes.dart';
import '../../core/config/api_config.dart';
import '../../core/constants/polije_data.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/launcher.dart';
import '../../data/models/user_complaint.dart';
import '../../data/services/public_complaint_service.dart';

/// Halaman Lapor Tanpa Login / Pengaduan Publik (`/lapor-umum`)
/// — port 1:1 dari `pages/public/LaporUmum.jsx`.
class LaporUmumPage extends StatefulWidget {
  const LaporUmumPage({super.key});

  @override
  State<LaporUmumPage> createState() => _LaporUmumPageState();
}

class _LaporUmumPageState extends State<LaporUmumPage> {
  static const Color _purple = Color(0xFF8B5CF6);
  static const Color _purpleLight = Color(0xFFEDE9FE);

  // State
  List<ViolenceCategoryItem> _categories = const [];
  List<String> _bookedSlots = const [];
  bool _loading = false;
  bool _success = false;
  String _submitError = '';
  String _reportId = '';
  String _trackingCode = '';
  String _satgasWa = '';

  // ── Data Pelapor ──
  final _guestNameCtrl = TextEditingController();
  final _guestNikCtrl = TextEditingController();
  final _guestPhoneCtrl = TextEditingController();
  final _guestEmailCtrl = TextEditingController();
  String _guestCountryCode = '+62';
  String _reporterGender = '';
  String _reporterStatus = '';
  String _pobChoice = '';
  final _pobCustomCtrl = TextEditingController();
  String _dobStr = '';
  final _reporterAddressCtrl = TextEditingController();
  String? _ktpPath;
  String? _ktpFileName;
  bool _isCheckingKTP = false;

  // ── Tipe Kejadian & Korban ──
  String _victimType = 'self';
  String _victimGender = '';
  final _victimNameCtrl = TextEditingController();
  final _victimRelationshipCtrl = TextEditingController();
  String _victimStatus = '';

  // ── Data Terlapor ──
  final _suspectNameCtrl = TextEditingController();
  String _suspectGender = '';
  String _suspectStatus = 'Mahasiswa';
  String _suspectAfiliasiMode = 'jurusan';
  String _suspectJurusan = '';
  String _suspectSubSelection = '';
  final _suspectManualAffiliationCtrl = TextEditingController();
  String _suspectCountryCode = '+62';
  final _suspectWhatsappCtrl = TextEditingController();
  final _suspectNimNipCtrl = TextEditingController();

  // ── Alasan Pengaduan ──
  final Set<String> _selectedAlasan = {};
  final _alasanLainnyaCtrl = TextEditingController();

  // ── Usulan Jadwal ──
  String _proposedDate = '';
  String _proposedTime = '08:00';

  // ── Informasi Kejadian ──
  String _selectedCategoryId = '';
  final _titleCtrl = TextEditingController();
  final _chronologyCtrl = TextEditingController();

  // ── Lokasi & Waktu ──
  String _locationMode = 'pilih';
  String _locationArea = '';
  String _locationLab = '';
  final _locationManualCtrl = TextEditingController();
  String _incidentDate = '';

  // ── Lampiran ──
  final List<PlatformFile> _attachments = [];

  // Validation errors
  final Map<String, String> _errors = {};

  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final svc = PublicComplaintService.instance;
    final cats = await svc.fetchCategories();
    final wa = await svc.fetchSatgasWhatsapp();
    if (!mounted) return;
    setState(() {
      _categories = cats;
      _satgasWa = wa;
    });
  }

  Future<void> _fetchBookedSlots(String date) async {
    final slots = await PublicComplaintService.instance.fetchBookedSlots(date);
    if (!mounted) return;
    setState(() => _bookedSlots = slots);
  }

  @override
  void dispose() {
    _guestNameCtrl.dispose();
    _guestNikCtrl.dispose();
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
    _scrollCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ──

  String _computePobDob() {
    final place =
        _pobChoice == 'Lainnya' ? _pobCustomCtrl.text.trim() : _pobChoice;
    if (place.isEmpty || _dobStr.isEmpty) return '';
    return '$place, ${_formatIndonesianDate(_dobStr)}';
  }

  String _formatIndonesianDate(String dateStr) {
    if (dateStr.isEmpty) return '';
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
    ];
    final parts = dateStr.split('-');
    if (parts.length != 3) return dateStr;
    final year = parts[0];
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (month == null || day == null || month < 1 || month > 12) return dateStr;
    return '$day ${months[month - 1]} $year';
  }

  String _computeSuspectAffiliation() {
    switch (_suspectAfiliasiMode) {
      case 'manual':
        return _suspectManualAffiliationCtrl.text.trim();
      case 'unit':
        return _suspectSubSelection;
      case 'lab':
        if (_suspectSubSelection.isNotEmpty) return _suspectSubSelection;
        return _suspectJurusan;
      case 'jurusan':
      default:
        if (_suspectSubSelection.isNotEmpty) {
          return '$_suspectJurusan - $_suspectSubSelection';
        }
        return _suspectJurusan;
    }
  }

  String _computeLocation() {
    if (_locationMode == 'manual') return _locationManualCtrl.text.trim();
    if (_locationLab.isNotEmpty) return '$_locationArea - $_locationLab';
    return _locationArea;
  }

  int _timeToMinutes(String t) {
    final parts = t.split(':');
    if (parts.length != 2) return 0;
    return (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
  }

  bool _isSlotBooked(String time) {
    final slotMin = _timeToMinutes(time);
    return _bookedSlots.any((b) => (_timeToMinutes(b) - slotMin).abs() < 60);
  }

  // ── Validation ──
  bool _validate() {
    _errors.clear();
    if (_guestNameCtrl.text.trim().isEmpty) {
      _errors['guest_name'] = 'Nama lengkap wajib diisi';
    }
    if (_guestNikCtrl.text.trim().isEmpty) {
      _errors['guest_nik'] = 'NIK wajib diisi';
    }
    if (_guestPhoneCtrl.text.trim().isEmpty) {
      _errors['guest_phone'] = 'Nomor WhatsApp wajib diisi';
    }
    if (_guestEmailCtrl.text.trim().isEmpty) {
      _errors['guest_email'] = 'Email wajib diisi';
    }
    if (_computePobDob().isEmpty) {
      _errors['pob_dob'] = 'Tempat, tanggal lahir wajib diisi';
    }
    if (_reporterAddressCtrl.text.trim().isEmpty) {
      _errors['reporter_address'] = 'Alamat domisili wajib diisi';
    }
    if (_reporterGender.isEmpty) {
      _errors['reporter_gender'] = 'Gender pelapor wajib dipilih';
    }
    if (_reporterStatus.isEmpty) {
      _errors['reporter_status'] = 'Status pelapor wajib dipilih';
    }
    if (_ktpPath == null || _ktpPath!.isEmpty) {
      _errors['ktp'] = 'Foto KTP wajib diunggah';
    }
    if (_victimType == 'self') {
      if (_victimGender.isEmpty && _reporterGender.isEmpty) {
        _errors['victim_gender'] = 'Jenis kelamin wajib dipilih';
      }
    } else {
      if (_victimNameCtrl.text.trim().isEmpty) {
        _errors['victim_name'] = 'Nama korban wajib diisi';
      }
      if (_victimGender.isEmpty) {
        _errors['victim_gender'] = 'Jenis kelamin korban wajib dipilih';
      }
      if (_victimRelationshipCtrl.text.trim().isEmpty) {
        _errors['victim_relationship'] = 'Hubungan dengan korban wajib diisi';
      }
    }
    if (_selectedCategoryId.isEmpty) {
      _errors['category'] = 'Kategori wajib dipilih';
    }
    if (_titleCtrl.text.trim().isEmpty) {
      _errors['title'] = 'Judul laporan wajib diisi';
    }
    if (_chronologyCtrl.text.trim().isEmpty) {
      _errors['chronology'] = 'Kronologi kejadian wajib diisi';
    } else if (_chronologyCtrl.text.length < 250) {
      _errors['chronology'] = 'Kronologi minimal 250 karakter';
    }
    if (_computeLocation().isEmpty) {
      _errors['location'] = 'Lokasi kejadian wajib diisi';
    }
    if (_incidentDate.isEmpty) {
      _errors['incident_date'] = 'Tanggal kejadian wajib diisi';
    }
    if (_proposedDate.isEmpty) {
      _errors['proposed_date'] = 'Tanggal usulan wajib dipilih';
    }
    if (_proposedTime.isEmpty) {
      _errors['proposed_time'] = 'Jam usulan wajib dipilih';
    }
    setState(() {});
    return _errors.isEmpty;
  }

  // ── Submit ──
  Future<void> _handleSubmit() async {
    if (_loading) return;
    if (!_validate()) {
      _scrollCtrl.animateTo(0,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mohon lengkapi seluruh data yang wajib diisi.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() {
      _loading = true;
      _submitError = '';
    });

    try {
      final vGender =
          _victimType == 'self' ? _reporterGender : _victimGender;
      final phone = '$_guestCountryCode${_guestPhoneCtrl.text.trim()}';

      // Build alasan list
      final alasanList = _selectedAlasan.toList();
      for (int i = 0; i < alasanList.length; i++) {
        if (alasanList[i] == 'Lainnya' &&
            _alasanLainnyaCtrl.text.trim().isNotEmpty) {
          alasanList[i] = 'Lainnya: ${_alasanLainnyaCtrl.text.trim()}';
        }
      }

      final suspectWa = _suspectWhatsappCtrl.text.trim().isNotEmpty
          ? '$_suspectCountryCode${_suspectWhatsappCtrl.text.trim()}'
          : '';

      final result =
          await PublicComplaintService.instance.submitPublicComplaint(
        guestName: _guestNameCtrl.text.trim(),
        guestEmail: _guestEmailCtrl.text.trim(),
        guestPhone: phone,
        guestNik: _guestNikCtrl.text.trim(),
        victimType: _victimType,
        victimGender: vGender,
        victimName:
            _victimType == 'other' ? _victimNameCtrl.text.trim() : null,
        victimRelationship: _victimType == 'other'
            ? _victimRelationshipCtrl.text.trim()
            : null,
        victimStatus:
            _victimType == 'other' ? _victimStatus : _reporterStatus,
        suspectName: _suspectNameCtrl.text.trim(),
        suspectGender: _suspectGender,
        suspectStatus: _suspectStatus,
        suspectAffiliation: _computeSuspectAffiliation(),
        suspectPhone: suspectWa,
        suspectNimNip: _suspectNimNipCtrl.text.trim(),
        reporterGender: _reporterGender,
        reporterStatus: _reporterStatus,
        reporterPobDob: _computePobDob(),
        reporterAddress: _reporterAddressCtrl.text.trim(),
        alasanPengaduan: alasanList,
        categoryId: _selectedCategoryId,
        title: _titleCtrl.text.trim(),
        chronology: _chronologyCtrl.text.trim(),
        location: _computeLocation(),
        incidentDate: _incidentDate,
        proposedDate: _proposedDate,
        proposedTime: _proposedTime,
        attachmentPaths: _attachments.map((f) => f.path!).toList(),
        ktpPath: _ktpPath,
      );

      if (!mounted) return;
      setState(() {
        _reportId = result['report_id'] ?? 'ID-LAPORAN';
        _trackingCode = result['tracking_code'] ?? '';
        _success = true;
      });
      _scrollCtrl.animateTo(0,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitError = e.toString().replaceAll('Exception: ', ''));
      _scrollCtrl.animateTo(0,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Pick KTP ──
  Future<void> _pickKTP() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    setState(() {
      _ktpPath = file.path;
      _ktpFileName = file.name;
      _errors.remove('ktp');
    });
  }

  // ── Pick Attachments ──
  Future<void> _pickAttachments() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      allowMultiple: true,
    );
    if (result == null) return;
    setState(() => _attachments.addAll(result.files));
  }

  // ── Pick Date Helper ──
  Future<void> _pickDate({
    required String current,
    required ValueChanged<String> onPicked,
    DateTime? firstDate,
    DateTime? lastDate,
  }) async {
    final now = DateTime.now();
    DateTime initial = now;
    if (current.isNotEmpty) {
      initial = DateTime.tryParse(current) ?? now;
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(firstDate ?? DateTime(2000))
          ? (firstDate ?? DateTime(2000))
          : initial,
      firstDate: firstDate ?? DateTime(2000),
      lastDate: lastDate ?? DateTime(2100),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(primary: _purple),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      onPicked(DateFormat('yyyy-MM-dd').format(picked));
    }
  }

  // ══════════════════════════════════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollCtrl,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: _success ? _buildSuccessView() : _buildForm(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ──
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context)
                .pushNamedAndRemoveUntil(AppRoutes.landing, (_) => false),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.arrow_back_rounded,
                    size: 20, color: AppColors.gray600),
                const SizedBox(width: 6),
                Text('Kembali ke Beranda',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.gray600)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Text('Layanan Pengaduan Publik',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827))),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFDBEAFE)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.shield_rounded,
                    size: 18, color: Color(0xFF1E40AF)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Identitas Anda akan dirahasiakan. Masyarakat umum dapat melaporkan kejadian melalui formulir ini.',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E40AF)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  //  SUCCESS VIEW
  // ══════════════════════════════════════════════════════════════════════

  Widget _buildSuccessView() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: AppColors.emerald.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFD1FAE5),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_rounded,
                size: 48, color: AppColors.emerald),
          ),
          const SizedBox(height: 20),
          const Text('Laporan Berhasil Terkirim!',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827)),
              textAlign: TextAlign.center),
          const SizedBox(height: 20),
          // Info box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFA7F3D0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        size: 18, color: AppColors.emerald),
                    const SizedBox(width: 8),
                    Text('Simpan Informasi Berikut:',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF065F46))),
                  ],
                ),
                const SizedBox(height: 12),
                _buildInfoRow('Nomor Laporan:', _reportId),
                const SizedBox(height: 8),
                _buildTrackingCodeRow(),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Warning box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.warning_amber_rounded,
                    size: 18, color: Colors.amber.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                          fontSize: 11,
                          color: const Color(0xFF92400E),
                          height: 1.5),
                      children: const [
                        TextSpan(
                            text: 'Penting: ',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                        TextSpan(
                            text:
                                'Jangan berikan Kode Akses kepada siapapun. Tim Satgas PPKPT tidak akan pernah meminta kode akses Anda.'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Buttons
          if (_satgasWa.isNotEmpty)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  final catName = _categories
                      .where((c) => c.uniqueId == _selectedCategoryId)
                      .map((c) => c.name)
                      .firstOrNull ?? '-';
                  final msg =
                      '🚨 *KONFIRMASI LAPORAN PENGADUAN* 🚨\n\n'
                      "Assalamu'alaikum, saya ingin mengkonfirmasi laporan pengaduan yang telah saya kirim melalui website PolijeCare.\n\n"
                      '📋 *No. Laporan:* $_reportId\n'
                      '👤 *Nama Pelapor:* ${_guestNameCtrl.text}\n'
                      '📁 *Kategori:* $catName\n'
                      '📌 *Judul:* ${_titleCtrl.text}\n'
                      '📍 *Lokasi:* ${_computeLocation()}\n'
                      '📅 *Jadwal Konseling:* $_proposedDate pukul $_proposedTime WIB\n\n'
                      'Mohon untuk segera ditindaklanjuti. Terima kasih. 🙏';
                  AppLauncher.openUrl(
                      'https://wa.me/$_satgasWa?text=${Uri.encodeComponent(msg)}');
                },
                icon: const Icon(Icons.message_rounded, size: 18),
                label: const Text('Konfirmasi via WhatsApp'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  textStyle: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14),
                ),
              ),
            ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context)
                  .pushNamedAndRemoveUntil(AppRoutes.landing, (_) => false),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                side: BorderSide(color: AppColors.gray300),
              ),
              child: Text('Kembali ke Beranda',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.gray600,
                      fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFA7F3D0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(fontSize: 12, color: AppColors.gray500)),
          Text(value,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.emerald)),
        ],
      ),
    );
  }

  Widget _buildTrackingCodeRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFA7F3D0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Kode Akses (Rahasia):',
                    style: TextStyle(fontSize: 12, color: AppColors.gray500)),
                Text(
                  '*Gunakan kode ini untuk melacak status laporan',
                  style: TextStyle(fontSize: 9, color: AppColors.emerald),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFA7F3D0)),
            ),
            child: Text(
              _trackingCode,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.emerald,
                letterSpacing: 2,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  //  FORM
  // ══════════════════════════════════════════════════════════════════════

  Widget _buildForm() {
    return Column(
      children: [
        // Error banner
        if (_submitError.isNotEmpty) _buildErrorBanner(),
        // Komitmen kerahasiaan
        _buildConfidentialityNotice(),
        const SizedBox(height: 12),
        // Section 1: Data Pelapor
        _buildSectionDataPelapor(),
        const SizedBox(height: 12),
        // Section 2: Tipe Kejadian
        _buildSectionTipeKejadian(),
        const SizedBox(height: 12),
        // Section 3: Data Terlapor
        _buildSectionDataTerlapor(),
        const SizedBox(height: 12),
        // Section 4: Alasan Pengaduan
        _buildSectionAlasanPengaduan(),
        const SizedBox(height: 12),
        // Section 5: Usulan Jadwal
        _buildSectionUsulanJadwal(),
        const SizedBox(height: 12),
        // Section 6: Informasi Kejadian
        _buildSectionInformasiKejadian(),
        const SizedBox(height: 12),
        // Section 7: Lokasi & Waktu
        _buildSectionLokasiWaktu(),
        const SizedBox(height: 12),
        // Section 8: Lampiran
        _buildSectionLampiran(),
        const SizedBox(height: 16),
        // Submit button
        _buildSubmitButton(),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 18, color: AppColors.red),
          const SizedBox(width: 10),
          Expanded(
            child: Text(_submitError,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFB91C1C))),
          ),
        ],
      ),
    );
  }

  Widget _buildConfidentialityNotice() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEFF6FF), Color(0xFFEEF2FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFDBEAFE),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.shield_rounded,
                size: 18, color: Color(0xFF2563EB)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Komitmen Kerahasiaan Satgas PPKPT',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E40AF))),
                const SizedBox(height: 4),
                RichText(
                  text: const TextSpan(
                    style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF1D4ED8),
                        height: 1.5),
                    children: [
                      TextSpan(text: 'Berdasarkan '),
                      TextSpan(
                        text:
                            'Permendikbudristek No. 55 Tahun 2024 Pasal 30 ayat (1) huruf b',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      TextSpan(
                          text:
                              ', Satuan Tugas PPKPT berkewajiban merahasiakan identitas Anda.'),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_rounded,
                          size: 14, color: AppColors.emerald),
                      const SizedBox(width: 4),
                      const Text('Data Anda Terlindungi Secara Hukum',
                          style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1D4ED8),
                              letterSpacing: 0.5)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  //  SECTION BUILDERS
  // ══════════════════════════════════════════════════════════════════════

  Widget _sectionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    required Widget child,
    Widget? footer,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.gray50.withValues(alpha: 0.5),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              border:
                  Border(bottom: BorderSide(color: AppColors.gray100)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 18, color: iconColor),
                    const SizedBox(width: 8),
                    Text(title,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1F2937))),
                  ],
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Padding(
                    padding: const EdgeInsets.only(left: 26),
                    child: Text(subtitle,
                        style: TextStyle(
                            fontSize: 11, color: AppColors.gray400)),
                  ),
                ],
              ],
            ),
          ),
          // Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
          if (footer != null) footer,
        ],
      ),
    );
  }

  // ── Section 1: Data Pelapor ──
  Widget _buildSectionDataPelapor() {
    return _sectionCard(
      icon: Icons.person_rounded,
      iconColor: _purple,
      title: 'Identitas Pelapor (Masyarakat Umum)',
      subtitle: 'Lengkapi data diri Anda sebagai pelapor pengaduan.',
      child: Column(
        children: [
          _buildTextField(
            label: 'Nama Lengkap *',
            controller: _guestNameCtrl,
            hint: 'Sesuai KTP',
            errorKey: 'guest_name',
          ),
          const SizedBox(height: 12),
          _buildTextField(
            label: 'NIK (KTP) *',
            controller: _guestNikCtrl,
            hint: '16 digit NIK',
            errorKey: 'guest_nik',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          _buildPhoneField(
            label: 'WA Aktif *',
            controller: _guestPhoneCtrl,
            countryCode: _guestCountryCode,
            onCountryChanged: (v) =>
                setState(() => _guestCountryCode = v),
            errorKey: 'guest_phone',
          ),
          const SizedBox(height: 12),
          _buildTextField(
            label: 'Email Aktif *',
            controller: _guestEmailCtrl,
            hint: 'contoh@gmail.com',
            errorKey: 'guest_email',
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          // Tempat, Tanggal Lahir
          _buildPobDobField(),
          const SizedBox(height: 12),
          _buildTextField(
            label: 'Alamat Domisili Pelapor *',
            controller: _reporterAddressCtrl,
            hint: 'Alamat lengkap saat ini...',
            errorKey: 'reporter_address',
          ),
        ],
      ),
      footer: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: _purpleLight.withValues(alpha: 0.3),
          border: Border(top: BorderSide(color: AppColors.gray100)),
          borderRadius:
              const BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
        child: Column(
          children: [
            _buildGenderToggle(
              label: 'Gender Pelapor *',
              value: _reporterGender,
              onChanged: (v) {
                setState(() {
                  _reporterGender = v;
                  if (_victimType == 'self') _victimGender = v;
                });
              },
              errorKey: 'reporter_gender',
            ),
            const SizedBox(height: 12),
            _buildDropdownField(
              label: 'Status Pelapor *',
              value: _reporterStatus.isEmpty ? null : _reporterStatus,
              items: PolijeData.statusOptions,
              hint: '-- Pilih --',
              onChanged: (v) =>
                  setState(() => _reporterStatus = v ?? ''),
              errorKey: 'reporter_status',
            ),
            const SizedBox(height: 12),
            // Upload KTP
            _buildKTPUpload(),
          ],
        ),
      ),
    );
  }

  // ── Section 2: Tipe Kejadian ──
  Widget _buildSectionTipeKejadian() {
    return _sectionCard(
      icon: Icons.description_rounded,
      iconColor: _purple,
      title: 'Tipe Kejadian',
      subtitle: 'Pilih siapa yang menjadi korban dalam kejadian ini.',
      child: Column(
        children: [
          // Radio: self
          _buildVictimTypeRadio(
            label: 'Kejadian yang saya alami sendiri',
            value: 'self',
          ),
          const SizedBox(height: 8),
          _buildVictimTypeRadio(
            label: 'Kejadian dialami orang lain',
            value: 'other',
          ),
          // If self — show gender
          if (_victimType == 'self') ...[
            const SizedBox(height: 16),
            _buildGenderToggle(
              label: 'Jenis Kelamin Anda *',
              value: _victimGender.isNotEmpty
                  ? _victimGender
                  : _reporterGender,
              onChanged: (v) => setState(() {
                _victimGender = v;
                _reporterGender = v;
              }),
              errorKey: 'victim_gender',
            ),
          ],
          // If other — show victim fields
          if (_victimType == 'other') ...[
            const SizedBox(height: 16),
            _buildGenderToggle(
              label: 'Jenis Kelamin Korban *',
              value: _victimGender,
              onChanged: (v) => setState(() => _victimGender = v),
              errorKey: 'victim_gender',
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _purpleLight.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE9D5FF)),
              ),
              child: Column(
                children: [
                  _buildTextField(
                    label: 'Nama Korban *',
                    controller: _victimNameCtrl,
                    errorKey: 'victim_name',
                  ),
                  const SizedBox(height: 10),
                  _buildTextField(
                    label: 'Hubungan *',
                    controller: _victimRelationshipCtrl,
                    hint: 'Teman, Saudara, dll',
                    errorKey: 'victim_relationship',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _buildDropdownField(
              label: 'Status Korban *',
              value: _victimStatus.isEmpty ? null : _victimStatus,
              items: PolijeData.statusOptions,
              hint: '-- Pilih --',
              onChanged: (v) =>
                  setState(() => _victimStatus = v ?? ''),
            ),
          ],
        ],
      ),
    );
  }

  // ── Section 3: Data Terlapor ──
  Widget _buildSectionDataTerlapor() {
    return _sectionCard(
      icon: Icons.person_rounded,
      iconColor: Colors.red.shade400,
      title: 'Data Terlapor (Pelaku)',
      subtitle:
          'Data Terlapor adalah orang yang diduga melakukan tindakan kekerasan.',
      child: Column(
        children: [
          _buildTextField(
            label: 'Nama Terlapor *',
            controller: _suspectNameCtrl,
            hint: 'Bisa inisial jika tidak tahu',
          ),
          const SizedBox(height: 12),
          _buildGenderToggle(
            label: 'Jenis Kelamin',
            value: _suspectGender,
            onChanged: (v) => setState(() => _suspectGender = v),
            required: false,
          ),
          const SizedBox(height: 12),
          _buildDropdownField(
            label: 'Status *',
            value: _suspectStatus,
            items: PolijeData.statusOptions,
            onChanged: (v) =>
                setState(() => _suspectStatus = v ?? 'Mahasiswa'),
          ),
          const SizedBox(height: 14),
          // Afiliasi
          _buildAfiliasiTerlapor(),
          const SizedBox(height: 12),
          _buildPhoneField(
            label: 'WhatsApp Terlapor (Opsional)',
            controller: _suspectWhatsappCtrl,
            countryCode: _suspectCountryCode,
            onCountryChanged: (v) =>
                setState(() => _suspectCountryCode = v),
            hint: '8123xxxx (Opsional)',
          ),
          const SizedBox(height: 12),
          _buildTextField(
            label: 'NIM/NIP Terlapor (Opsional)',
            controller: _suspectNimNipCtrl,
            hint: 'NIM/NIP Terlapor',
          ),
        ],
      ),
    );
  }

  // ── Section 4: Alasan Pengaduan ──
  Widget _buildSectionAlasanPengaduan() {
    return _sectionCard(
      icon: Icons.description_rounded,
      iconColor: _purple,
      title: 'Alasan Pengaduan',
      subtitle:
          'Pilih alasan pengaduan Anda (dapat memilih lebih dari satu).',
      child: Column(
        children: [
          for (final option in PolijeData.alasanPengaduanOptions) ...[
            _buildAlasanCheckbox(option),
            if (option == 'Lainnya' && _selectedAlasan.contains('Lainnya'))
              Padding(
                padding: const EdgeInsets.only(left: 28, top: 4, bottom: 4),
                child: TextField(
                  controller: _alasanLainnyaCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Tuliskan alasan lainnya secara singkat...',
                    hintStyle:
                        TextStyle(fontSize: 12, color: AppColors.gray400),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppColors.gray200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppColors.gray200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: _purple),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }

  // ── Section 5: Usulan Jadwal ──
  Widget _buildSectionUsulanJadwal() {
    return _sectionCard(
      icon: Icons.calendar_month_rounded,
      iconColor: _purple,
      title: 'Usulan Jadwal Penanganan',
      subtitle:
          'Tim Satgas akan menghubungi Anda sesuai jadwal yang diusulkan.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 16, color: Colors.amber.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ketentuan Jadwal:',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF92400E))),
                      const SizedBox(height: 2),
                      Text(
                          '• Layanan Konseling: Senin - Kamis (08:00 - 16:00 WIB)\n'
                          '• Hari Jumat - Minggu hanya untuk pengiriman laporan.',
                          style: TextStyle(
                              fontSize: 10.5, color: const Color(0xFF92400E))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Date picker
          _buildLabel('Pilih Tanggal *'),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () => _pickDate(
              current: _proposedDate,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
              onPicked: (v) {
                setState(() => _proposedDate = v);
                _fetchBookedSlots(v);
              },
            ),
            child: _buildDateDisplay(
                _proposedDate, 'Pilih tanggal...', 'proposed_date'),
          ),
          const SizedBox(height: 14),
          // Time grid
          _buildLabel('Pilih Jam (24 Jam) *'),
          const SizedBox(height: 8),
          _buildTimeGrid(),
          if (_errors.containsKey('proposed_time'))
            _buildErrorText(_errors['proposed_time']!),
        ],
      ),
    );
  }

  // ── Section 6: Informasi Kejadian ──
  Widget _buildSectionInformasiKejadian() {
    return _sectionCard(
      icon: Icons.description_rounded,
      iconColor: _purple,
      title: 'Informasi Kejadian & Detail',
      child: Column(
        children: [
          _buildDropdownField(
            label: 'Kategori Kekerasan *',
            value:
                _selectedCategoryId.isEmpty ? null : _selectedCategoryId,
            items: _categories.map((c) => c.uniqueId).toList(),
            itemLabels: _categories.map((c) => c.name).toList(),
            hint: '-- Pilih --',
            onChanged: (v) =>
                setState(() => _selectedCategoryId = v ?? ''),
            errorKey: 'category',
          ),
          const SizedBox(height: 12),
          _buildTextField(
            label: 'Judul Laporan *',
            controller: _titleCtrl,
            hint: 'Contoh: Pelecehan Verbal di Kelas',
            errorKey: 'title',
          ),
          const SizedBox(height: 12),
          _buildLabel('Kronologi Kejadian * (Min 250 Karakter)'),
          const SizedBox(height: 2),
          Text(
            'Ceritakan secara detail urutan kejadiannya agar mempermudah investigasi Tim Satgas.',
            style: TextStyle(fontSize: 10, color: AppColors.gray400),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _chronologyCtrl,
            maxLines: 6,
            decoration: InputDecoration(
              hintText: 'Ceritakan urutan kejadiannya secara lengkap...',
              hintStyle: TextStyle(fontSize: 13, color: AppColors.gray400),
              filled: true,
              fillColor: AppColors.gray50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.gray200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.gray200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _purple),
              ),
              contentPadding: const EdgeInsets.all(14),
              counterText:
                  '${_chronologyCtrl.text.length}/250 karakter minimum',
              counterStyle:
                  TextStyle(fontSize: 10, color: AppColors.gray400),
            ),
            style: const TextStyle(fontSize: 13),
            onChanged: (_) => setState(() {}),
          ),
          if (_errors.containsKey('chronology'))
            _buildErrorText(_errors['chronology']!),
        ],
      ),
    );
  }

  // ── Section 7: Lokasi & Waktu ──
  Widget _buildSectionLokasiWaktu() {
    return _sectionCard(
      icon: Icons.location_on_rounded,
      iconColor: _purple,
      title: 'Lokasi & Waktu Kejadian',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Location mode toggle
          Row(
            children: [
              Expanded(
                child: _buildLabel('Lokasi Detail *'),
              ),
              _buildMiniToggle(
                options: const ['Pilih', 'Manual'],
                values: const ['pilih', 'manual'],
                selected: _locationMode,
                onChanged: (v) => setState(() {
                  _locationMode = v;
                  _locationArea = '';
                  _locationLab = '';
                  _locationManualCtrl.clear();
                }),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_locationMode == 'pilih') ...[
            _buildDropdownField(
              label: '',
              value: _locationArea.isEmpty ? null : _locationArea,
              items: [
                ...PolijeData.jurusanList,
                ...PolijeData.unitLainnya,
              ],
              hint: '-- Pilih Area / Jurusan --',
              onChanged: (v) => setState(() {
                _locationArea = v ?? '';
                _locationLab = '';
              }),
            ),
            if (_locationArea.isNotEmpty &&
                PolijeData.getLabByJurusan(_locationArea).isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildDropdownField(
                label: '',
                value: _locationLab.isEmpty ? null : _locationLab,
                items: PolijeData.getLabByJurusan(_locationArea),
                hint: '-- Spesifik Lab (opsional) --',
                onChanged: (v) =>
                    setState(() => _locationLab = v ?? ''),
              ),
            ],
            if (_computeLocation().isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.check_circle_rounded,
                      size: 14, color: _purple),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text('Lokasi: ${_computeLocation()}',
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _purple)),
                  ),
                ],
              ),
            ],
          ] else ...[
            _buildTextField(
              label: '',
              controller: _locationManualCtrl,
              hint: 'Gedung, Lantai, atau Ruangan Spesifik',
              errorKey: 'location',
            ),
          ],
          if (_errors.containsKey('location') && _locationMode == 'pilih')
            _buildErrorText(_errors['location']!),
          const SizedBox(height: 14),
          // Tanggal Kejadian
          _buildLabel('Tanggal Kejadian *'),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () => _pickDate(
              current: _incidentDate,
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
              onPicked: (v) => setState(() => _incidentDate = v),
            ),
            child: _buildDateDisplay(
                _incidentDate, 'Pilih tanggal kejadian...', 'incident_date'),
          ),
        ],
      ),
    );
  }

  // ── Section 8: Lampiran ──
  Widget _buildSectionLampiran() {
    return _sectionCard(
      icon: Icons.attach_file_rounded,
      iconColor: AppColors.gray600,
      title: 'Lampiran Bukti Pendukung (Opsional)',
      child: Column(
        children: [
          GestureDetector(
            onTap: _pickAttachments,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 28),
              decoration: BoxDecoration(
                border: Border.all(
                    color: AppColors.gray200,
                    width: 2,
                    strokeAlign: BorderSide.strokeAlignInside),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  Icon(Icons.attach_file_rounded,
                      size: 28, color: AppColors.gray400),
                  const SizedBox(height: 6),
                  Text('Ketuk untuk memilih file bukti',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.gray500)),
                  const SizedBox(height: 2),
                  Text('Maksimal 10MB (JPG/PNG/PDF)',
                      style:
                          TextStyle(fontSize: 10, color: AppColors.gray400)),
                ],
              ),
            ),
          ),
          if (_attachments.isNotEmpty) ...[
            const SizedBox(height: 10),
            for (int i = 0; i < _attachments.length; i++)
              Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.gray50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.gray100),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(_attachments[i].name,
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF4B5563)),
                          overflow: TextOverflow.ellipsis),
                    ),
                    GestureDetector(
                      onTap: () =>
                          setState(() => _attachments.removeAt(i)),
                      child: const Icon(Icons.close_rounded,
                          size: 18, color: AppColors.red),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  // ── Submit Button ──
  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _loading ? null : _handleSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: _purple,
          disabledBackgroundColor: _purple.withValues(alpha: 0.5),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 4,
          shadowColor: _purple.withValues(alpha: 0.3),
        ),
        child: _loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: Colors.white))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.send_rounded, size: 18),
                  SizedBox(width: 8),
                  Text('Kirim Laporan Pengaduan',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w800)),
                ],
              ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  //  REUSABLE FIELD WIDGETS
  // ══════════════════════════════════════════════════════════════════════

  Widget _buildLabel(String text) {
    return Text(text,
        style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6B7280)));
  }

  Widget _buildErrorText(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(text,
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.red)),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? hint,
    String? errorKey,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          _buildLabel(label),
          const SizedBox(height: 4),
        ],
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(fontSize: 13, color: AppColors.gray400),
            filled: true,
            fillColor: AppColors.gray50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: errorKey != null && _errors.containsKey(errorKey)
                      ? AppColors.red
                      : AppColors.gray200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: errorKey != null && _errors.containsKey(errorKey)
                      ? AppColors.red
                      : AppColors.gray200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _purple),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
          style: const TextStyle(fontSize: 13),
          onChanged: (_) {
            if (errorKey != null && _errors.containsKey(errorKey)) {
              setState(() => _errors.remove(errorKey));
            }
          },
        ),
        if (errorKey != null && _errors.containsKey(errorKey))
          _buildErrorText(_errors[errorKey]!),
      ],
    );
  }

  Widget _buildPhoneField({
    required String label,
    required TextEditingController controller,
    required String countryCode,
    required ValueChanged<String> onCountryChanged,
    String? errorKey,
    String hint = '8123xxxx',
  }) {
    const codes = ['+62', '+60', '+65', '+673', '+1'];
    const flags = ['🇮🇩', '🇲🇾', '🇸🇬', '🇧🇳', '🇺🇸'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: AppColors.gray50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: errorKey != null && _errors.containsKey(errorKey)
                    ? AppColors.red
                    : AppColors.gray200),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  border: Border(
                      right: BorderSide(color: AppColors.gray200)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: countryCode,
                    isDense: true,
                    items: [
                      for (int i = 0; i < codes.length; i++)
                        DropdownMenuItem(
                          value: codes[i],
                          child: Text('${flags[i]} ${codes[i]}',
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700)),
                        ),
                    ],
                    onChanged: (v) {
                      if (v != null) onCountryChanged(v);
                    },
                  ),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle:
                        TextStyle(fontSize: 13, color: AppColors.gray400),
                    border: InputBorder.none,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  style: const TextStyle(fontSize: 13),
                  onChanged: (_) {
                    if (errorKey != null && _errors.containsKey(errorKey)) {
                      setState(() => _errors.remove(errorKey));
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        if (errorKey != null && _errors.containsKey(errorKey))
          _buildErrorText(_errors[errorKey]!),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    List<String>? itemLabels,
    String hint = '-- Pilih --',
    required ValueChanged<String?> onChanged,
    String? errorKey,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          _buildLabel(label),
          const SizedBox(height: 4),
        ],
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: AppColors.gray50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: errorKey != null && _errors.containsKey(errorKey)
                    ? AppColors.red
                    : AppColors.gray200),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              hint: Text(hint,
                  style: TextStyle(fontSize: 13, color: AppColors.gray400)),
              items: [
                for (int i = 0; i < items.length; i++)
                  DropdownMenuItem(
                    value: items[i],
                    child: Text(
                      itemLabels != null ? itemLabels[i] : items[i],
                      style: const TextStyle(fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (v) {
                onChanged(v);
                if (errorKey != null && _errors.containsKey(errorKey)) {
                  setState(() => _errors.remove(errorKey));
                }
              },
            ),
          ),
        ),
        if (errorKey != null && _errors.containsKey(errorKey))
          _buildErrorText(_errors[errorKey]!),
      ],
    );
  }

  Widget _buildGenderToggle({
    required String label,
    required String value,
    required ValueChanged<String> onChanged,
    String? errorKey,
    bool required = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: AppColors.gray100.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: AppColors.gray200.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              _buildGenderOption('Laki-laki', value, onChanged),
              _buildGenderOption('Perempuan', value, onChanged),
            ],
          ),
        ),
        if (errorKey != null && _errors.containsKey(errorKey))
          _buildErrorText(_errors[errorKey]!),
      ],
    );
  }

  Widget _buildGenderOption(
      String option, String selected, ValueChanged<String> onChanged) {
    final isSelected = selected == option;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(option),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4)
                  ]
                : null,
            border: isSelected
                ? Border.all(
                    color: AppColors.gray200.withValues(alpha: 0.4))
                : null,
          ),
          child: Text(
            option,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isSelected ? _purple : AppColors.gray500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVictimTypeRadio({
    required String label,
    required String value,
  }) {
    final isSelected = _victimType == value;
    return GestureDetector(
      onTap: () => setState(() {
        _victimType = value;
        if (value == 'self' && _reporterGender.isNotEmpty) {
          _victimGender = _reporterGender;
        }
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? _purple : AppColors.gray200,
            width: isSelected ? 2 : 1,
          ),
          color: isSelected ? _purpleLight : Colors.white,
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              size: 20,
              color: isSelected ? _purple : AppColors.gray400,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? const Color(0xFF1F2937)
                        : AppColors.gray600,
                  )),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlasanCheckbox(String option) {
    final isChecked = _selectedAlasan.contains(option);
    final displayLabel = option == 'Lainnya'
        ? 'Lainnya (Sebutkan alasan lainnya jika ada)'
        : option;
    return GestureDetector(
      onTap: () => setState(() {
        if (isChecked) {
          _selectedAlasan.remove(option);
        } else {
          _selectedAlasan.add(option);
        }
      }),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isChecked ? _purple : AppColors.gray100,
            width: isChecked ? 2 : 1,
          ),
          color: isChecked
              ? _purpleLight.withValues(alpha: 0.4)
              : Colors.white,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              isChecked
                  ? Icons.check_box_rounded
                  : Icons.check_box_outline_blank_rounded,
              size: 20,
              color: isChecked ? _purple : AppColors.gray400,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(displayLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gray700,
                    height: 1.4,
                  )),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPobDobField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Tempat, Tanggal Lahir Pelapor *'),
        const SizedBox(height: 4),
        // Place of birth dropdown
        _buildDropdownField(
          label: '',
          value: _pobChoice.isEmpty ? null : _pobChoice,
          items: [...PolijeData.commonCities, 'Lainnya'],
          hint: '-- Pilih Tempat Lahir --',
          onChanged: (v) => setState(() => _pobChoice = v ?? ''),
        ),
        if (_pobChoice == 'Lainnya') ...[
          const SizedBox(height: 6),
          _buildTextField(
            label: '',
            controller: _pobCustomCtrl,
            hint: 'Tulis tempat lahir...',
          ),
        ],
        const SizedBox(height: 8),
        // Date of birth
        _buildLabel('Tanggal Lahir'),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () => _pickDate(
            current: _dobStr,
            firstDate: DateTime(1950),
            lastDate: DateTime.now(),
            onPicked: (v) => setState(() => _dobStr = v),
          ),
          child: _buildDateDisplay(_dobStr, 'Pilih tanggal lahir...', ''),
        ),
        if (_errors.containsKey('pob_dob'))
          _buildErrorText(_errors['pob_dob']!),
      ],
    );
  }

  Widget _buildDateDisplay(
      String dateStr, String placeholder, String errorKey) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: errorKey.isNotEmpty && _errors.containsKey(errorKey)
                ? AppColors.red
                : AppColors.gray200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              dateStr.isNotEmpty
                  ? _formatIndonesianDate(dateStr)
                  : placeholder,
              style: TextStyle(
                fontSize: 13,
                color: dateStr.isNotEmpty
                    ? const Color(0xFF111827)
                    : AppColors.gray400,
              ),
            ),
          ),
          Icon(Icons.calendar_today_rounded,
              size: 16, color: AppColors.gray400),
        ],
      ),
    );
  }

  Widget _buildTimeGrid() {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final time in PolijeData.timeSlots)
          _buildTimeSlot(time),
      ],
    );
  }

  Widget _buildTimeSlot(String time) {
    final isBooked = _isSlotBooked(time);
    final isSelected = _proposedTime == time;
    return GestureDetector(
      onTap: isBooked ? null : () => setState(() => _proposedTime = time),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isBooked
              ? const Color(0xFFFEF2F2)
              : isSelected
                  ? _purple
                  : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isBooked
                ? const Color(0xFFFECACA)
                : isSelected
                    ? _purple
                    : AppColors.gray200,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.access_time_rounded,
              size: 13,
              color: isBooked
                  ? const Color(0xFFFCA5A5)
                  : isSelected
                      ? Colors.white
                      : AppColors.gray400,
            ),
            const SizedBox(width: 4),
            Text(
              time,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isBooked
                    ? const Color(0xFFFCA5A5)
                    : isSelected
                        ? Colors.white
                        : AppColors.gray700,
                decoration:
                    isBooked ? TextDecoration.lineThrough : null,
              ),
            ),
            if (isBooked) ...[
              const SizedBox(width: 2),
              Text('Penuh',
                  style: TextStyle(
                      fontSize: 8, color: const Color(0xFFFCA5A5))),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMiniToggle({
    required List<String> options,
    required List<String> values,
    required String selected,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppColors.gray100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < options.length; i++)
            GestureDetector(
              onTap: () => onChanged(values[i]),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: selected == values[i]
                      ? _purple
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  options[i],
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: selected == values[i]
                        ? Colors.white
                        : AppColors.gray500,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildKTPUpload() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Upload Foto KTP Pelapor *'),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: _isCheckingKTP ? null : _pickKTP,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.gray50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: _errors.containsKey('ktp')
                      ? AppColors.red
                      : AppColors.gray200),
            ),
            child: Row(
              children: [
                Icon(Icons.upload_file_rounded,
                    size: 18, color: AppColors.gray500),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _ktpFileName ?? 'Pilih foto KTP...',
                    style: TextStyle(
                        fontSize: 13,
                        color: _ktpFileName != null
                            ? const Color(0xFF111827)
                            : AppColors.gray400),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_ktpPath != null && !_isCheckingKTP)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text('✓ File KTP dipilih',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.green)),
          ),
        if (_errors.containsKey('ktp'))
          _buildErrorText(_errors['ktp']!),
      ],
    );
  }

  // ── Afiliasi Terlapor ──
  Widget _buildAfiliasiTerlapor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Afiliasi / Unit Terlapor *'),
        const SizedBox(height: 6),
        // Mode selector
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final entry in const [
                ['jurusan', 'Jurusan / Prodi'],
                ['lab', 'Laboratorium'],
                ['unit', 'Unit Lainnya'],
                ['manual', 'Tulis Manual'],
              ]) ...[
                _buildAfiliasiModeChip(entry[0], entry[1]),
                const SizedBox(width: 6),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Content per mode
        if (_suspectAfiliasiMode == 'jurusan') ...[
          _buildDropdownField(
            label: '',
            value: _suspectJurusan.isEmpty ? null : _suspectJurusan,
            items: PolijeData.jurusanList,
            hint: '-- Pilih Jurusan --',
            onChanged: (v) => setState(() {
              _suspectJurusan = v ?? '';
              _suspectSubSelection = '';
            }),
          ),
          if (_suspectJurusan.isNotEmpty &&
              PolijeData.getProdiByJurusan(_suspectJurusan).isNotEmpty) ...[
            const SizedBox(height: 6),
            _buildDropdownField(
              label: '',
              value: _suspectSubSelection.isEmpty
                  ? null
                  : _suspectSubSelection,
              items: PolijeData.getProdiByJurusan(_suspectJurusan),
              hint: '-- Pilih Prodi (opsional) --',
              onChanged: (v) =>
                  setState(() => _suspectSubSelection = v ?? ''),
            ),
          ],
        ],
        if (_suspectAfiliasiMode == 'lab') ...[
          _buildDropdownField(
            label: '',
            value: _suspectJurusan.isEmpty ? null : _suspectJurusan,
            items: PolijeData.jurusanList,
            hint: '-- Pilih Jurusan --',
            onChanged: (v) => setState(() {
              _suspectJurusan = v ?? '';
              _suspectSubSelection = '';
            }),
          ),
          if (_suspectJurusan.isNotEmpty) ...[
            const SizedBox(height: 6),
            _buildDropdownField(
              label: '',
              value: _suspectSubSelection.isEmpty
                  ? null
                  : _suspectSubSelection,
              items: PolijeData.getLabByJurusan(_suspectJurusan),
              hint: '-- Pilih Lab --',
              onChanged: (v) =>
                  setState(() => _suspectSubSelection = v ?? ''),
            ),
          ],
        ],
        if (_suspectAfiliasiMode == 'unit')
          _buildDropdownField(
            label: '',
            value: _suspectSubSelection.isEmpty
                ? null
                : _suspectSubSelection,
            items: PolijeData.unitLainnya,
            hint: '-- Pilih Unit --',
            onChanged: (v) =>
                setState(() => _suspectSubSelection = v ?? ''),
          ),
        if (_suspectAfiliasiMode == 'manual')
          _buildTextField(
            label: '',
            controller: _suspectManualAffiliationCtrl,
            hint: 'Tulis afiliasi/unit secara manual...',
          ),
        // Preview
        if (_computeSuspectAffiliation().isNotEmpty &&
            _suspectAfiliasiMode != 'manual') ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.check_circle_rounded, size: 14, color: _purple),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                    'Dipilih: ${_computeSuspectAffiliation()}',
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _purple)),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildAfiliasiModeChip(String mode, String label) {
    final isSelected = _suspectAfiliasiMode == mode;
    return GestureDetector(
      onTap: () => setState(() {
        _suspectAfiliasiMode = mode;
        _suspectJurusan = '';
        _suspectSubSelection = '';
        _suspectManualAffiliationCtrl.clear();
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? _purple : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: isSelected ? _purple : AppColors.gray200),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : AppColors.gray500,
          ),
        ),
      ),
    );
  }
}

