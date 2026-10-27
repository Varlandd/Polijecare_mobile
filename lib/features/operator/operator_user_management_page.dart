import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../data/services/operator_portal_service.dart';
import 'operator_shell_page.dart';

/// Halaman Manajemen Pengguna Super Admin — port 1:1 dari
/// `pages/operator/user-management.jsx`.
class OperatorUserManagementPage extends StatefulWidget {
  const OperatorUserManagementPage({super.key});

  @override
  State<OperatorUserManagementPage> createState() =>
      _OperatorUserManagementPageState();
}

class _OperatorUserManagementPageState
    extends State<OperatorUserManagementPage> {
  final TextEditingController _searchController = TextEditingController();

  String _roleFilter = 'all';
  int _currentPage = 1;
  static const int _perPage = 8;

  bool _isLoading = true;
  String _errorMessage = '';

  Map<String, int> _stats = const {
    'total_users': 0,
    'operator': 0,
    'konselor': 0,
    'pengguna': 0,
  };
  List<OperatorManagedUser> _users = const [];
  int _totalPages = 1;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final results = await Future.wait([
        OperatorPortalService.instance.getUserStats(),
        OperatorPortalService.instance.getUsers(
          page: _currentPage,
          perPage: _perPage,
          search: _searchController.text,
          role: _roleFilter,
        ),
      ]);
      if (!mounted) return;
      final statsRes = results[0] as Map<String, int>;
      final usersRes = results[1]
          as ({List<OperatorManagedUser> users, int totalPages, int total});
      setState(() {
        _stats = statsRes;
        _users = usersRes.users;
        _totalPages = usersRes.totalPages < 1 ? 1 : usersRes.totalPages;
        if (_currentPage > _totalPages) {
          _currentPage = _totalPages;
        }
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Gagal mengambil data pengguna.';
        _isLoading = false;
      });
    }
  }

  String _formatDate(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    return '$d/$m/${dt.year}';
  }

  Future<void> _handleExportCsv() async {
    final messenger = ScaffoldMessenger.of(context);
    final csv = await OperatorPortalService.instance.exportUsersCsv(
      search: _searchController.text,
      role: _roleFilter,
    );
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.download_rounded, color: Color(0xFF059669)),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Ekspor CSV Pengguna',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Data direktori pengguna berhasil diformat ke CSV (users.csv):',
                style: TextStyle(fontSize: 12.5, color: AppColors.slate600),
              ),
              const SizedBox(height: 12),
              Container(
                constraints: const BoxConstraints(maxHeight: 220),
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.slate900,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    csv,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: Color(0xFFA7F3D0),
                      height: 1.45,
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
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: csv));
              if (ctx.mounted) Navigator.of(ctx).pop();
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('Data users.csv berhasil disalin ke clipboard!'),
                  backgroundColor: Color(0xFF059669),
                ),
              );
            },
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('Salin CSV'),
          ),
        ],
      ),
    );
  }

  Future<void> _openUserModal({OperatorManagedUser? user}) async {
    final isEdit = user != null;
    final nameCtrl = TextEditingController(text: user?.name ?? '');
    final emailCtrl = TextEditingController(text: user?.email ?? '');
    final nimCtrl = TextEditingController(text: user?.nim ?? '');
    final passwordCtrl = TextEditingController();
    String selectedRole = user?.role ?? 'user';
    bool showPassword = false;
    bool isSubmitting = false;
    String formError = '';

    final messenger = ScaffoldMessenger.of(context);

    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(height: 6, color: AppColors.indigo600),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(22, 18, 14, 14),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              isEdit ? 'EDIT PENGGUNA' : 'TAMBAH PENGGUNA',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.slate900,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: isSubmitting
                                ? null
                                : () => Navigator.of(ctx).pop(false),
                            icon: const Icon(
                              Icons.close_rounded,
                              color: AppColors.slate400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: AppColors.gray100),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(22),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (formError.isNotEmpty) ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF1F2),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                      color: const Color(0xFFFFE4E6)),
                                ),
                                child: Text(
                                  formError.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFFE11D48),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                            _ModalFieldLabel('NAMA LENGKAP *'),
                            const SizedBox(height: 6),
                            TextField(
                              controller: nameCtrl,
                              enabled: !isSubmitting,
                              decoration: _modalInputDecoration(
                                hint: 'Masukkan nama lengkap...',
                              ),
                            ),
                            const SizedBox(height: 14),
                            _ModalFieldLabel('EMAIL *'),
                            const SizedBox(height: 6),
                            TextField(
                              controller: emailCtrl,
                              enabled: !isSubmitting,
                              keyboardType: TextInputType.emailAddress,
                              decoration: _modalInputDecoration(
                                hint: 'nama@polije.ac.id',
                              ),
                            ),
                            const SizedBox(height: 14),
                            _ModalFieldLabel('PERAN'),
                            const SizedBox(height: 6),
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.slate200),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: selectedRole,
                                  isExpanded: true,
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'user',
                                      child: Text('User (Mahasiswa / Civitas)'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'konselor',
                                      child: Text('Satgas (Konselor PPKPT)'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'operator',
                                      child: Text('Operator (Super Admin)'),
                                    ),
                                  ],
                                  onChanged: isSubmitting
                                      ? null
                                      : (val) {
                                          if (val != null) {
                                            setModalState(
                                                () => selectedRole = val);
                                          }
                                        },
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            _ModalFieldLabel('NIM / IDENTITAS'),
                            const SizedBox(height: 6),
                            TextField(
                              controller: nimCtrl,
                              enabled: !isSubmitting,
                              decoration: _modalInputDecoration(
                                hint: 'NIM / NIP (opsional)',
                              ),
                            ),
                            const SizedBox(height: 14),
                            _ModalFieldLabel(
                              isEdit
                                  ? 'PASSWORD (KOSONGKAN JIKA TIDAK DIUBAH)'
                                  : 'PASSWORD *',
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: passwordCtrl,
                              enabled: !isSubmitting,
                              obscureText: !showPassword,
                              decoration: _modalInputDecoration(
                                hint: isEdit
                                    ? 'Kosongkan bila tetap'
                                    : 'Minimal 6 karakter',
                                suffixIcon: IconButton(
                                  onPressed: () => setModalState(
                                      () => showPassword = !showPassword),
                                  icon: Icon(
                                    showPassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    size: 19,
                                    color: AppColors.slate400,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 22),
                            Row(
                              children: [
                                Expanded(
                                  child: TextButton(
                                    onPressed: isSubmitting
                                        ? null
                                        : () => Navigator.of(ctx).pop(false),
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 14),
                                    ),
                                    child: const Text(
                                      'BATAL',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.0,
                                        color: AppColors.slate600,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 2,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.indigo600,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 15),
                                      shape: const StadiumBorder(),
                                      elevation: 2,
                                    ),
                                    onPressed: isSubmitting
                                        ? null
                                        : () async {
                                            final name = nameCtrl.text.trim();
                                            final email = emailCtrl.text.trim();
                                            final pw = passwordCtrl.text;

                                            if (name.isEmpty || email.isEmpty) {
                                              setModalState(() => formError =
                                                  'Nama dan Email wajib diisi');
                                              return;
                                            }
                                            if (!isEdit && pw.isEmpty) {
                                              setModalState(() => formError =
                                                  'Password wajib diisi');
                                              return;
                                            }

                                            setModalState(() {
                                              isSubmitting = true;
                                              formError = '';
                                            });

                                            try {
                                              if (isEdit) {
                                                await OperatorPortalService
                                                    .instance
                                                    .updateUser(
                                                  user.id,
                                                  name: name,
                                                  email: email,
                                                  password: pw,
                                                  role: selectedRole,
                                                  nim: nimCtrl.text.trim(),
                                                );
                                              } else {
                                                await OperatorPortalService
                                                    .instance
                                                    .createUser(
                                                  name: name,
                                                  email: email,
                                                  password: pw,
                                                  role: selectedRole,
                                                  nim: nimCtrl.text.trim(),
                                                );
                                              }
                                              if (ctx.mounted) {
                                                Navigator.of(ctx).pop(true);
                                              }
                                            } catch (_) {
                                              setModalState(() {
                                                isSubmitting = false;
                                                formError =
                                                    'Gagal menyimpan pengguna.';
                                              });
                                            }
                                          },
                                    icon: isSubmitting
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Icon(Icons.save_outlined,
                                            size: 17),
                                    label: Text(
                                      isSubmitting ? 'MENYIMPAN...' : 'SIMPAN',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );

    nameCtrl.dispose();
    emailCtrl.dispose();
    nimCtrl.dispose();
    passwordCtrl.dispose();

    if (saved == true) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            isEdit
                ? 'Data pengguna berhasil diperbarui!'
                : 'Pengguna baru berhasil ditambahkan!',
          ),
          backgroundColor: AppColors.indigo600,
        ),
      );
      _fetchData();
    }
  }

  Future<void> _confirmDeleteUser(OperatorManagedUser user) async {
    final messenger = ScaffoldMessenger.of(context);
    bool isDeleting = false;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF1F2),
                      borderRadius: BorderRadius.circular(26),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      size: 34,
                      color: Color(0xFFE11D48),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'HAPUS USER?',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.slate900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${user.name} (${user.email})',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.slate600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'AKSI INI TIDAK DAPAT DIBATALKAN',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                      color: AppColors.slate400,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: isDeleting
                              ? null
                              : () => Navigator.of(ctx).pop(false),
                          child: const Text(
                            'BATAL',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                              color: AppColors.slate400,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE11D48),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: const StadiumBorder(),
                          ),
                          onPressed: isDeleting
                              ? null
                              : () async {
                                  setModalState(() => isDeleting = true);
                                  await OperatorPortalService.instance
                                      .deleteUser(user.id);
                                  if (ctx.mounted) {
                                    Navigator.of(ctx).pop(true);
                                  }
                                },
                          child: Text(
                            isDeleting ? 'MENGHAPUS...' : 'HAPUS',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (confirmed == true) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Pengguna berhasil dihapus.'),
          backgroundColor: Color(0xFFE11D48),
        ),
      );
      _fetchData();
    }
  }

  InputDecoration _modalInputDecoration({
    required String hint,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13, color: AppColors.slate400),
      filled: true,
      fillColor: Colors.white,
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.slate200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.slate200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.indigo600, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return OperatorShellPage(
      title: 'Manajemen Pengguna',
      subtitle: 'Direktori & Akses Kontrol PolijeCare',
      activePath: AppRoutes.operatorUserManagement,
      body: RefreshIndicator(
        color: AppColors.indigo600,
        onRefresh: _fetchData,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            // ── 4 Stat Cards ──
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.85,
              children: [
                _UserStatCard(
                  title: 'TOTAL USER',
                  value: '${_stats['total_users'] ?? 0}',
                  icon: Icons.people_alt_rounded,
                  iconBg: AppColors.indigo600,
                ),
                _UserStatCard(
                  title: 'OPERATOR',
                  value: '${_stats['operator'] ?? 0}',
                  icon: Icons.shield_outlined,
                  iconBg: const Color(0xFF059669),
                ),
                _UserStatCard(
                  title: 'SATGAS',
                  value: '${_stats['konselor'] ?? 0}',
                  icon: Icons.chat_bubble_outline_rounded,
                  iconBg: const Color(0xFF2563EB),
                ),
                _UserStatCard(
                  title: 'PENGGUNA',
                  value: '${_stats['pengguna'] ?? 0}',
                  icon: Icons.person_outline_rounded,
                  iconBg: const Color(0xFFE11D48),
                ),
              ],
            ),
            const SizedBox(height: 18),

            if (_errorMessage.isNotEmpty) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        color: AppColors.red, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ── Main Directory Card ──
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: AppColors.gray100),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x08000000),
                    blurRadius: 18,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Filter & Action Toolbar
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.gray50.withValues(alpha: 0.6),
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(26)),
                      border: const Border(
                        bottom: BorderSide(color: AppColors.gray100),
                      ),
                    ),
                    child: Column(
                      children: [
                        TextField(
                          controller: _searchController,
                          onChanged: (_) {
                            _currentPage = 1;
                            _fetchData();
                          },
                          decoration: InputDecoration(
                            hintText: 'Cari pengguna (nama, email, NIM)...',
                            hintStyle: const TextStyle(
                                fontSize: 13, color: AppColors.slate400),
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              size: 19,
                              color: AppColors.slate400,
                            ),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.close_rounded,
                                        size: 17),
                                    onPressed: () {
                                      _searchController.clear();
                                      _currentPage = 1;
                                      _fetchData();
                                    },
                                  )
                                : null,
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 11),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide:
                                  const BorderSide(color: AppColors.slate200),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide:
                                  const BorderSide(color: AppColors.slate200),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                  color: AppColors.indigo600, width: 1.4),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 42,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(13),
                                  border: Border.all(color: AppColors.slate200),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _roleFilter,
                                    isExpanded: true,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.slate700,
                                    ),
                                    items: const [
                                      DropdownMenuItem(
                                          value: 'all',
                                          child: Text('Semua Peran')),
                                      DropdownMenuItem(
                                          value: 'konselor',
                                          child: Text('Satgas')),
                                      DropdownMenuItem(
                                          value: 'operator',
                                          child: Text('Operator')),
                                      DropdownMenuItem(
                                          value: 'user', child: Text('User')),
                                    ],
                                    onChanged: (val) {
                                      if (val == null) return;
                                      setState(() {
                                        _roleFilter = val;
                                        _currentPage = 1;
                                      });
                                      _fetchData();
                                    },
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Material(
                              color: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(13),
                                side: const BorderSide(
                                    color: AppColors.slate200),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(13),
                                onTap: _handleExportCsv,
                                child: const SizedBox(
                                  width: 42,
                                  height: 42,
                                  child: Icon(
                                    Icons.download_rounded,
                                    size: 19,
                                    color: Color(0xFF059669),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: () => _openUserModal(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.indigo600,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(0, 42),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(13),
                                ),
                                elevation: 1,
                              ),
                              icon: const Icon(
                                  Icons.person_add_alt_1_rounded,
                                  size: 17),
                              label: const Text(
                                'Tambah',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // User Rows
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.indigo600,
                        ),
                      ),
                    )
                  else if (_users.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 48, horizontal: 24),
                      child: Column(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: AppColors.slate50,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Icon(
                              Icons.people_outline_rounded,
                              size: 30,
                              color: AppColors.slate400,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Tidak ada pengguna ditemukan',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.slate800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Sesuaikan kata kunci pencarian atau filter peran di atas.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: AppColors.slate500,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _users.length,
                      separatorBuilder: (_, _) =>
                          const Divider(height: 1, color: AppColors.slate100),
                      itemBuilder: (context, index) {
                        final u = _users[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: AppColors.slate100,
                                  borderRadius: BorderRadius.circular(15),
                                  border:
                                      Border.all(color: AppColors.gray200),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  u.initial,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.indigo600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            u.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.slate900,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        _RoleBadge(role: u.role),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      u.email,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.slate500,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            'ID: ${u.nim.isNotEmpty ? u.nim : 'N/A'}  •  ${_formatDate(u.createdAt)}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.slate400,
                                            ),
                                          ),
                                        ),
                                        InkWell(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          onTap: () => _openUserModal(user: u),
                                          child: Container(
                                            padding: const EdgeInsets.all(7),
                                            decoration: BoxDecoration(
                                              color: AppColors.slate50,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: const Icon(
                                              Icons.edit_outlined,
                                              size: 16,
                                              color: AppColors.indigo600,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        InkWell(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          onTap: () => _confirmDeleteUser(u),
                                          child: Container(
                                            padding: const EdgeInsets.all(7),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFFF1F2),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: const Icon(
                                              Icons.delete_outline_rounded,
                                              size: 16,
                                              color: Color(0xFFE11D48),
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
                      },
                    ),

                  // Pagination Footer
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.gray50.withValues(alpha: 0.6),
                      borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(26)),
                      border: const Border(
                        top: BorderSide(color: AppColors.gray100),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'HALAMAN $_currentPage DARI $_totalPages',
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                            color: AppColors.slate400,
                          ),
                        ),
                        Row(
                          children: [
                            _PageIconBtn(
                              icon: Icons.chevron_left_rounded,
                              enabled: _currentPage > 1,
                              onTap: () {
                                setState(() => _currentPage--);
                                _fetchData();
                              },
                            ),
                            const SizedBox(width: 8),
                            _PageIconBtn(
                              icon: Icons.chevron_right_rounded,
                              enabled: _currentPage < _totalPages,
                              onTap: () {
                                setState(() => _currentPage++);
                                _fetchData();
                              },
                            ),
                          ],
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
    );
  }
}

class _UserStatCard extends StatelessWidget {
  const _UserStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconBg,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color iconBg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: AppColors.slate400,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.slate900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role});

  final String role;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    final Color border;
    final String label;

    if (role == 'operator') {
      bg = const Color(0xFFEEF2FF);
      fg = AppColors.indigo600;
      border = const Color(0xFFE0E7FF);
      label = 'OPERATOR';
    } else if (role == 'konselor') {
      bg = const Color(0xFFECFDF5);
      fg = const Color(0xFF059669);
      border = const Color(0xFFD1FAE5);
      label = 'SATGAS';
    } else {
      bg = AppColors.slate100;
      fg = AppColors.slate600;
      border = AppColors.slate200;
      label = 'USER';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.7,
          color: fg,
        ),
      ),
    );
  }
}

class _PageIconBtn extends StatelessWidget {
  const _PageIconBtn({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: AppColors.gray200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: enabled ? onTap : null,
        child: Opacity(
          opacity: enabled ? 1.0 : 0.35,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(icon, size: 20, color: AppColors.slate700),
          ),
        ),
      ),
    );
  }
}

class _ModalFieldLabel extends StatelessWidget {
  const _ModalFieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.9,
          color: AppColors.slate600,
        ),
      ),
    );
  }
}

