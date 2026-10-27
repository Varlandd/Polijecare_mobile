import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../data/services/operator_portal_service.dart';
import 'operator_shell_page.dart';

/// Halaman Manajemen Kategori Kekerasan Super Admin — port 1:1 dari
/// `pages/operator/violence-categories-management.jsx`.
class OperatorCategoriesManagementPage extends StatefulWidget {
  const OperatorCategoriesManagementPage({super.key});

  @override
  State<OperatorCategoriesManagementPage> createState() =>
      _OperatorCategoriesManagementPageState();
}

class _OperatorCategoriesManagementPageState
    extends State<OperatorCategoriesManagementPage> {
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  String _errorMessage = '';
  List<OperatorCategoryItem> _categories = const [];

  static const List<String> _monthsId = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchCategories() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final list = await OperatorPortalService.instance.getOperatorCategories(
        search: _searchController.text,
      );
      if (!mounted) return;
      setState(() {
        _categories = list;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Gagal mengambil data kategori kekerasan.';
        _isLoading = false;
      });
    }
  }

  String _formatDateId(DateTime dt) {
    final monthName = _monthsId[(dt.month - 1).clamp(0, 11)];
    return '${dt.day} $monthName ${dt.year}';
  }

  Future<void> _openCategoryModal({OperatorCategoryItem? category}) async {
    final isEdit = category != null;
    final nameCtrl = TextEditingController(text: category?.name ?? '');
    final descCtrl = TextEditingController(text: category?.description ?? '');
    bool isSubmitting = false;
    String formError = '';

    final messenger = ScaffoldMessenger.of(context);

    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 18, 14, 14),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3E8FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.local_offer_outlined,
                          size: 20,
                          color: AppColors.purple600,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isEdit ? 'Edit Kategori' : 'Tambah Kategori',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: AppColors.slate900,
                              ),
                            ),
                            Text(
                              isEdit
                                  ? 'Perbarui data kategori #${category.uniqueId}'
                                  : 'Tambahkan klasifikasi laporan kekerasan baru',
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: AppColors.slate500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: isSubmitting
                            ? null
                            : () => Navigator.of(ctx).pop(false),
                        icon: const Icon(Icons.close_rounded,
                            color: AppColors.slate400),
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
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(12),
                              border:
                                  Border.all(color: const Color(0xFFFECACA)),
                            ),
                            child: Text(
                              formError,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.red,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],
                        const Text(
                          'Nama Kategori *',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.gray700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: nameCtrl,
                          enabled: !isSubmitting,
                          decoration: _inputDecoration(
                            'Contoh: Kekerasan Fisik',
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Deskripsi',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.gray700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: descCtrl,
                          enabled: !isSubmitting,
                          maxLines: 4,
                          decoration: _inputDecoration(
                            'Tambahkan deskripsi kategori (opsional)',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 1, color: AppColors.gray100),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 12, 22, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: isSubmitting
                            ? null
                            : () => Navigator.of(ctx).pop(false),
                        child: const Text('Batal'),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.purple600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                final name = nameCtrl.text.trim();
                                if (name.isEmpty) {
                                  setModalState(() =>
                                      formError = 'Nama kategori wajib diisi.');
                                  return;
                                }
                                setModalState(() {
                                  isSubmitting = true;
                                  formError = '';
                                });

                                if (isEdit) {
                                  await OperatorPortalService.instance
                                      .updateOperatorCategory(
                                    category.uniqueId,
                                    name: name,
                                    description: descCtrl.text.trim(),
                                  );
                                } else {
                                  await OperatorPortalService.instance
                                      .createOperatorCategory(
                                    name: name,
                                    description: descCtrl.text.trim(),
                                  );
                                }

                                if (ctx.mounted) {
                                  Navigator.of(ctx).pop(true);
                                }
                              },
                        child: Text(
                          isSubmitting
                              ? 'Menyimpan...'
                              : (isEdit
                                  ? 'Simpan Perubahan'
                                  : 'Tambah Kategori'),
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

    nameCtrl.dispose();
    descCtrl.dispose();

    if (saved == true) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            isEdit
                ? 'Kategori berhasil diperbarui!'
                : 'Kategori berhasil ditambahkan!',
          ),
          backgroundColor: const Color(0xFF059669),
        ),
      );
      _fetchCategories();
    }
  }

  Future<void> _confirmDeleteCategory(OperatorCategoryItem item) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text(
          'Hapus Kategori?',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus kategori "${item.name}" (#${item.uniqueId})? Aksi ini tidak dapat dibatalkan.',
          style: const TextStyle(fontSize: 13.5, color: AppColors.slate600),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await OperatorPortalService.instance
          .deleteOperatorCategory(item.uniqueId);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Kategori berhasil dihapus!'),
          backgroundColor: AppColors.red,
        ),
      );
      _fetchCategories();
    }
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13, color: AppColors.slate400),
      filled: true,
      fillColor: Colors.white,
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
        borderSide: const BorderSide(color: AppColors.purple600, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalRelatedReports = _categories.fold<int>(
      0,
      (sum, c) => sum + c.complaintsCount,
    );

    return OperatorShellPage(
      title: 'Kategori Kekerasan',
      subtitle: 'Kelola kategori kekerasan sistem pelaporan',
      activePath: AppRoutes.operatorCategoriesManagement,
      body: RefreshIndicator(
        color: AppColors.purple600,
        onRefresh: _fetchCategories,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            // ── Summary Cards ──
            Row(
              children: [
                Expanded(
                  child: _CatSummaryCard(
                    title: 'Total Kategori',
                    value: '${_categories.length}',
                    icon: Icons.local_offer_outlined,
                    iconBg: const Color(0xFFF3E8FF),
                    iconFg: AppColors.purple600,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _CatSummaryCard(
                    title: 'Laporan Terkait',
                    value: '$totalRelatedReports',
                    icon: Icons.description_outlined,
                    iconBg: const Color(0xFFEEF2FF),
                    iconFg: AppColors.indigo600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Search & Add Card ──
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
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
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: (_) => _fetchCategories(),
                    decoration: InputDecoration(
                      hintText: 'Cari kategori...',
                      hintStyle: const TextStyle(
                          fontSize: 13, color: AppColors.slate400),
                      prefixIcon: const Icon(Icons.search_rounded,
                          size: 19, color: AppColors.slate400),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              onPressed: () {
                                _searchController.clear();
                                _fetchCategories();
                              },
                              icon:
                                  const Icon(Icons.close_rounded, size: 17),
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 11),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: AppColors.gray200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: AppColors.gray200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: AppColors.purple600, width: 1.4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 42,
                    child: ElevatedButton.icon(
                      onPressed: () => _openCategoryModal(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.purple600,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text(
                        'Tambah Kategori',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (_errorMessage.isNotEmpty) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
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

            // ── Categories Table/List Card ──
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.gray100),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 20,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    height: 4,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF6366F1),
                          Color(0xFFA855F7),
                          Color(0xFFEC4899),
                        ],
                      ),
                    ),
                  ),
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.purple600,
                        ),
                      ),
                    )
                  else if (_categories.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(36),
                      child: Column(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: AppColors.gray50,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.local_offer_outlined,
                              size: 28,
                              color: AppColors.gray400,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Belum ada kategori kekerasan',
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.gray900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Tambahkan kategori kekerasan untuk digunakan pada formulir pelaporan.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: AppColors.gray500,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _categories.length,
                      separatorBuilder: (_, _) =>
                          const Divider(height: 1, color: AppColors.gray100),
                      itemBuilder: (context, index) {
                        final item = _categories[index];
                        final desc = item.description.trim();

                        return Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF3E8FF),
                                      borderRadius: BorderRadius.circular(7),
                                    ),
                                    child: Text(
                                      '#${item.uniqueId}',
                                      style: const TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.purple600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 9, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEEF2FF),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      '${item.complaintsCount} Laporan',
                                      style: const TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.indigo600,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    _formatDateId(item.createdAt),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.slate400,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.name,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.slate900,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          desc.isNotEmpty
                                              ? desc
                                              : 'Tidak ada deskripsi kategori.',
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            color: desc.isNotEmpty
                                                ? AppColors.slate600
                                                : AppColors.slate400,
                                            height: 1.4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      InkWell(
                                        borderRadius:
                                            BorderRadius.circular(10),
                                        onTap: () => _openCategoryModal(
                                            category: item),
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: AppColors.slate50,
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: const Icon(
                                            Icons.edit_outlined,
                                            size: 17,
                                            color: AppColors.indigo600,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      InkWell(
                                        borderRadius:
                                            BorderRadius.circular(10),
                                        onTap: () =>
                                            _confirmDeleteCategory(item),
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFFF1F2),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: const Icon(
                                            Icons.delete_outline_rounded,
                                            size: 17,
                                            color: Color(0xFFE11D48),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
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

class _CatSummaryCard extends StatelessWidget {
  const _CatSummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconBg,
    required this.iconFg,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color iconBg;
  final Color iconFg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.gray100),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: iconFg, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.slate500,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
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

