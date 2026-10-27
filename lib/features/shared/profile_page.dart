import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../core/constants/polije_data.dart';
import '../../core/theme/app_colors.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/user_portal_service.dart';
import '../konselor/konselor_shell_page.dart';
import '../operator/operator_shell_page.dart';
import '../user/user_shell_page.dart';

/// Halaman Profil Saya (`/profile`) — port 1:1 dari `pages/shared/Profile.jsx`.
/// Otomatis membungkus konten dengan Shell & Sidebar sesuai role yang sedang login.
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isEditing = false;
  bool _isSaving = false;
  bool _statsLoading = true;
  int _totalContribution = 0;
  String _statsLabel = 'Kontribusi';

  final _nameCtrl = TextEditingController();
  final _nimCtrl = TextEditingController();
  final _semesterCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String _gender = '';
  String _unit = '';
  String _prodi = '';
  final _prodiManualCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _syncFromUser();
    _loadStats();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _nimCtrl.dispose();
    _semesterCtrl.dispose();
    _phoneCtrl.dispose();
    _prodiManualCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  void _syncFromUser() {
    final user = AuthService.instance.user;
    _nameCtrl.text = user?.name ?? '';
    _nimCtrl.text = user?.nim ?? '';
    _semesterCtrl.text = user?.semester ?? '';
    _phoneCtrl.text = user?.phone ?? '';
    _gender = user?.gender ?? '';
    _unit = user?.unit ?? '';
    _prodi = user?.prodi ?? '';
    _prodiManualCtrl.text = user?.prodi ?? '';
    _bioCtrl.text = user?.bio ?? '';
  }

  Future<void> _loadStats() async {
    final stats = await UserPortalService.instance.getProfileStats();
    if (!mounted) return;
    setState(() {
      _totalContribution =
          (stats['total_contribution'] as num?)?.toInt() ?? 0;
      _statsLabel = stats['label']?.toString() ?? 'Kontribusi';
      _statsLoading = false;
    });
  }

  Future<void> _handleSave() async {
    if (_nameCtrl.text.trim().isEmpty || _gender.isEmpty || _unit.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nama, Jenis Kelamin, dan Jurusan/Unit wajib diisi!'),
          backgroundColor: Color(0xFFE11D48),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    final prodiOptions = PolijeData.getProdiByJurusan(_unit);
    final resolvedProdi = prodiOptions.isNotEmpty
        ? _prodi
        : _prodiManualCtrl.text.trim();

    await UserPortalService.instance.updateProfile(
      name: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      gender: _gender,
      unit: _unit,
      prodi: resolvedProdi,
      nim: _nimCtrl.text.trim(),
      semester: _semesterCtrl.text.trim(),
      bio: _bioCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() {
      _isSaving = false;
      _isEditing = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Profil berhasil diperbarui!'),
        backgroundColor: Color(0xFF059669),
      ),
    );
  }

  Future<void> _handleLogout() async {
    await AuthService.instance.logout();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.login,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.user;
    final role = user?.normalizedRole ?? 'user';

    // Role theme sesuai `getRoleTheme()` di `Profile.jsx`
    List<Color> gradientColors;
    Color accentColor;
    Color iconBg;
    String roleBadge;
    if (role == 'operator' || role == 'admin') {
      gradientColors = const [Color(0xFF2563EB), Color(0xFF4338CA)];
      accentColor = const Color(0xFF2563EB);
      iconBg = const Color(0xFFDBEAFE);
      roleBadge = 'Satgas Admin';
    } else if (role == 'konselor') {
      gradientColors = const [Color(0xFF9333EA), Color(0xFF6D28D9)];
      accentColor = const Color(0xFF9333EA);
      iconBg = const Color(0xFFF3E8FF);
      roleBadge = 'Tim Satgas PPKPT';
    } else {
      gradientColors = const [Color(0xFF059669), Color(0xFF0F766E)];
      accentColor = const Color(0xFF059669);
      iconBg = const Color(0xFFD1FAE5);
      roleBadge = 'Pelapor';
    }

    final isProfileIncomplete = role == 'user' &&
        ((user?.gender?.isEmpty ?? true) ||
            (user?.unit?.isEmpty ?? true) ||
            (user?.name.isEmpty ?? true));

    final prodiOptions = PolijeData.getProdiByJurusan(_unit);

    final content = SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header / Banner (`Profile.jsx`) ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                // Avatar
                Container(
                  width: 96,
                  height: 96,
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33000000),
                        blurRadius: 20,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: gradientColors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(23),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      user?.initial ?? 'U',
                      style: const TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                if (_isEditing)
                  SizedBox(
                    width: 280,
                    child: TextField(
                      controller: _nameCtrl,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Nama Lengkap',
                        hintStyle: const TextStyle(color: Colors.white70),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.2),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Colors.white54),
                        ),
                      ),
                    ),
                  )
                else
                  Text(
                    user?.name ?? 'Pengguna PolijeCare',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.35)),
                  ),
                  child: Text(
                    roleBadge,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.mail_outline_rounded,
                      color: Colors.white70,
                      size: 15,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      user?.email ?? '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                if (!_isEditing) ...[
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      _syncFromUser();
                      setState(() => _isEditing = true);
                    },
                    icon: const Icon(Icons.settings_outlined, size: 16),
                    label: const Text(
                      'Edit Profil',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.slate900,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isProfileIncomplete) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 18),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                          color: const Color(0xFFFDE68A), width: 1.5),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.info_outline_rounded,
                            color: Color(0xFFD97706),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Profil Belum Lengkap!',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF78350F),
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Mohon lengkapi Jenis Kelamin dan Unit sebelum dapat membuat laporan baru.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF92400E),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // ── Informasi Dasar Card ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: AppColors.gray100),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: iconBg,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              Icons.person_outline_rounded,
                              color: accentColor,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Informasi Dasar',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.gray900,
                                ),
                              ),
                              Text(
                                'DETAIL IDENTITAS POLIJECARE',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.gray400,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // NIM / ID PETUGAS
                      _ProfileFieldItem(
                        icon: Icons.tag_rounded,
                        iconColor: AppColors.indigo600,
                        label: 'NIM / ID PETUGAS',
                        isEditing: _isEditing,
                        displayValue: user?.nim ?? '—',
                        editChild: TextField(
                          controller: _nimCtrl,
                          decoration: _editInputDecoration('Masukkan NIM / ID'),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // SEMESTER
                      _ProfileFieldItem(
                        icon: Icons.calendar_today_outlined,
                        iconColor: const Color(0xFFF59E0B),
                        label: 'SEMESTER',
                        isEditing: _isEditing,
                        displayValue: (user?.semester?.isNotEmpty ?? false)
                            ? 'Semester ${user!.semester}'
                            : 'Belum diisi',
                        editChild: TextField(
                          controller: _semesterCtrl,
                          keyboardType: TextInputType.number,
                          decoration: _editInputDecoration('Contoh: 4'),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // NOMOR WHATSAPP
                      _ProfileFieldItem(
                        icon: Icons.phone_outlined,
                        iconColor: const Color(0xFF10B981),
                        label: 'NOMOR WHATSAPP',
                        isEditing: _isEditing,
                        displayValue: (user?.phone?.isNotEmpty ?? false)
                            ? user!.phone!
                            : 'Belum diisi',
                        editChild: TextField(
                          controller: _phoneCtrl,
                          keyboardType: TextInputType.phone,
                          decoration:
                              _editInputDecoration('Contoh: 08123456789'),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // JENIS KELAMIN
                      _ProfileFieldItem(
                        icon: Icons.wc_rounded,
                        iconColor: const Color(0xFF9333EA),
                        label: 'JENIS KELAMIN',
                        isEditing: _isEditing,
                        displayValue: (user?.gender?.isNotEmpty ?? false)
                            ? user!.gender!
                            : 'Belum diisi',
                        editChild: DropdownButtonFormField<String>(
                          initialValue: _gender.isEmpty ? null : _gender,
                          hint: const Text('Pilih Jenis Kelamin'),
                          items: const [
                            DropdownMenuItem(
                                value: 'Laki-laki', child: Text('Laki-laki')),
                            DropdownMenuItem(
                                value: 'Perempuan', child: Text('Perempuan')),
                          ],
                          onChanged: (v) =>
                              setState(() => _gender = v ?? ''),
                          decoration: _editInputDecoration(''),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // JURUSAN
                      _ProfileFieldItem(
                        icon: Icons.work_outline_rounded,
                        iconColor: const Color(0xFFF43F5E),
                        label: 'JURUSAN',
                        isEditing: _isEditing,
                        displayValue: (user?.unit?.isNotEmpty ?? false)
                            ? user!.unit!
                            : 'Belum diisi',
                        editChild: DropdownButtonFormField<String>(
                          initialValue: (_unit.isNotEmpty &&
                                  (PolijeData.jurusanList.contains(_unit) ||
                                      _unit == 'Lainnya'))
                              ? _unit
                              : null,
                          isExpanded: true,
                          hint: const Text('-- Pilih Jurusan --'),
                          items: [
                            for (final j in PolijeData.jurusanList)
                              DropdownMenuItem(value: j, child: Text(j)),
                            const DropdownMenuItem(
                              value: 'Lainnya',
                              child: Text('Lainnya / Non-Jurusan'),
                            ),
                          ],
                          onChanged: (v) {
                            setState(() {
                              _unit = v ?? '';
                              _prodi = '';
                            });
                          },
                          decoration: _editInputDecoration(''),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // PROGRAM STUDI
                      _ProfileFieldItem(
                        icon: Icons.school_outlined,
                        iconColor: const Color(0xFF0EA5E9),
                        label: 'PROGRAM STUDI',
                        isEditing: _isEditing,
                        displayValue: (user?.prodi?.isNotEmpty ?? false)
                            ? user!.prodi!
                            : 'Belum diisi',
                        editChild: prodiOptions.isNotEmpty
                            ? DropdownButtonFormField<String>(
                                initialValue:
                                    prodiOptions.contains(_prodi)
                                        ? _prodi
                                        : null,
                                isExpanded: true,
                                hint: const Text('-- Pilih Program Studi --'),
                                items: [
                                  for (final p in prodiOptions)
                                    DropdownMenuItem(value: p, child: Text(p)),
                                ],
                                onChanged: (v) =>
                                    setState(() => _prodi = v ?? ''),
                                decoration: _editInputDecoration(''),
                              )
                            : TextField(
                                controller: _prodiManualCtrl,
                                decoration: _editInputDecoration(
                                    'Tulis program studi...'),
                              ),
                      ),
                      const SizedBox(height: 16),

                      // BIOGRAFI / CATATAN
                      _ProfileFieldItem(
                        icon: Icons.info_outline_rounded,
                        iconColor: const Color(0xFF3B82F6),
                        label: 'BIOGRAFI / CATATAN',
                        isEditing: _isEditing,
                        displayValue: (user?.bio?.isNotEmpty ?? false)
                            ? user!.bio!
                            : 'Tidak ada biografi.',
                        editChild: TextField(
                          controller: _bioCtrl,
                          maxLines: 3,
                          decoration: _editInputDecoration(
                              'Tuliskan sedikit tentang Anda...'),
                        ),
                      ),

                      if (_isEditing) ...[
                        const SizedBox(height: 22),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () =>
                                    setState(() => _isEditing = false),
                                style: OutlinedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: const Text('Batal'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton(
                                onPressed: _isSaving ? null : _handleSave,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF10B981),
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: Text(
                                  _isSaving
                                      ? 'Menyimpan...'
                                      : 'Simpan Perubahan',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── Ringkasan / Statistik Penggunaan (`Profile.jsx`) ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: AppColors.gray100),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEF2FF),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.insights_rounded,
                              color: AppColors.indigo600,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ringkasan',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.gray900,
                                ),
                              ),
                              Text(
                                'STATISTIK PENGGUNAAN',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.gray400,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Contribution Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          gradient: const LinearGradient(
                            colors: [Color(0xFFEEF2FF), Color(0xFFEFF6FF)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border.all(color: const Color(0xFFE0E7FF)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _statsLabel.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF818CF8),
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  _statsLoading ? '...' : '$_totalContribution',
                                  style: const TextStyle(
                                    fontSize: 42,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.indigo600,
                                    height: 1.0,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Padding(
                                  padding: EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    'Item',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF818CF8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Verification Card
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppColors.gray50,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: AppColors.gray100),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'VERIFIKASI',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.gray400,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Email Kampus',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.gray900,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFFD1FAE5),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.check_circle_outline_rounded,
                                color: Color(0xFF059669),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Info Box
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFFEF3C7)),
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
                              child: Text(
                                'Data identitas ditarik langsung dari sistem keanggotaan Polije. Untuk perubahan nama atau ID, harap hubungi administrator.',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: Color(0xFFB45309),
                                  height: 1.4,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── Keamanan & Layanan Dark Card (`Profile.jsx`) ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: AppColors.slate900,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: const Color(0x336366F1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.settings_outlined,
                              color: Color(0xFF818CF8),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Keamanan & Layanan',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Butuh bantuan teknis atau ingin memperbarui keamanan akun? Silakan hubungi tim IT Satgas atau gunakan tombol logout di bawah.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.slate400,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _handleLogout,
                          icon: const Icon(Icons.logout_rounded, size: 18),
                          label: const Text(
                            'KELUAR AKUN',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                              fontSize: 12.5,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF43F5E),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
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
        ],
      ),
    );

    if (role == 'konselor') {
      return KonselorShellPage(
        title: 'Profil Saya',
        subtitle: 'Pengaturan profil & keamanan akun Satgas',
        activePath: AppRoutes.profile,
        body: content,
      );
    } else if (role == 'operator' || role == 'admin') {
      return OperatorShellPage(
        title: 'Profil Saya',
        subtitle: 'Pengaturan profil & keamanan akun',
        activePath: AppRoutes.profile,
        body: content,
      );
    } else {
      return UserShellPage(
        title: 'Profil Saya',
        subtitle: 'Pengaturan profil & keamanan akun Mahasiswa',
        activePath: AppRoutes.profile,
        body: content,
      );
    }
  }

  InputDecoration _editInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: AppColors.gray50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.gray200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.gray200),
      ),
    );
  }
}

class _ProfileFieldItem extends StatelessWidget {
  const _ProfileFieldItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.isEditing,
    required this.displayValue,
    required this.editChild,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final bool isEditing;
  final String displayValue;
  final Widget editChild;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: iconColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppColors.gray400,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (isEditing)
          editChild
        else
          Text(
            displayValue,
            style: const TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w600,
              color: AppColors.gray900,
            ),
          ),
        const SizedBox(height: 8),
        const Divider(color: AppColors.gray100, height: 1),
      ],
    );
  }
}

