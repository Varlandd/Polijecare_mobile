import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/launcher.dart';
import '../../data/models/edu_material.dart';
import '../../data/services/material_service.dart';
import '../../data/services/operator_portal_service.dart';
import 'operator_shell_page.dart';

/// Halaman Pusat Edukasi Super Admin — port 1:1 dari
/// `pages/operator/materials-management.jsx`.
class OperatorMaterialsManagementPage extends StatefulWidget {
  const OperatorMaterialsManagementPage({super.key});

  @override
  State<OperatorMaterialsManagementPage> createState() =>
      _OperatorMaterialsManagementPageState();
}

class _OperatorMaterialsManagementPageState
    extends State<OperatorMaterialsManagementPage> {
  final TextEditingController _searchController = TextEditingController();

  String _kategoriFilter = 'all';
  String _tipeFilter = 'all';

  bool _isLoading = true;
  String _errorMessage = '';

  List<EduMaterial> _materials = const [];
  List<OperatorCategoryItem> _categories = const [];

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitial() async {
    await Future.wait([
      _fetchCategories(),
      _fetchMaterials(),
    ]);
  }

  Future<void> _fetchCategories() async {
    try {
      final cats = await OperatorPortalService.instance.getOperatorCategories();
      if (!mounted) return;
      setState(() => _categories = cats);
    } catch (_) {}
  }

  Future<void> _fetchMaterials() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final list = await OperatorPortalService.instance.getOperatorMaterials(
        search: _searchController.text,
        kategori: _kategoriFilter,
        tipe: _tipeFilter,
      );
      if (!mounted) return;
      setState(() {
        _materials = list;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Gagal mengambil data materi edukasi.';
        _isLoading = false;
      });
    }
  }

  List<String> get _categoryNameOptions {
    final set = <String>{
      for (final c in _categories)
        if (c.name.trim().isNotEmpty) c.name.trim(),
      for (final m in _materials)
        if (m.kategori.trim().isNotEmpty) m.kategori.trim(),
    };
    if (set.isEmpty) {
      set.addAll(const [
        'Kekerasan Seksual',
        'Pelecehan Verbal & Psikis',
        'Kekerasan Fisik',
        'Perundungan (Bullying)',
      ]);
    }
    return set.toList();
  }

  void _openMaterialUrl(EduMaterial item) {
    final url = item.isFile
        ? MaterialService.instance.getFileUrl(item.filePath)
        : (item.link ?? '');
    if (url.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tautan atau berkas materi belum tersedia.'),
        ),
      );
      return;
    }
    openExternal(context, url);
  }

  Future<void> _openAddModal() async {
    final judulCtrl = TextEditingController();
    final deskripsiCtrl = TextEditingController();
    final linkCtrl = TextEditingController();
    final options = _categoryNameOptions;
    String selectedKategori = options.first;
    String selectedTipe = 'file';
    String? pickedFileName;
    List<int>? pickedFileBytes;
    bool isSubmitting = false;
    String formError = '';

    final messenger = ScaffoldMessenger.of(context);

    final created = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
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
                          Icons.menu_book_rounded,
                          size: 20,
                          color: AppColors.purple600,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tambah Edukasi',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: AppColors.slate900,
                              ),
                            ),
                            Text(
                              'Unggah dokumen SOP/buku saku atau tautan edukasi',
                              style: TextStyle(
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
                        const _FieldLabel('Judul Edukasi *'),
                        const SizedBox(height: 6),
                        TextField(
                          controller: judulCtrl,
                          enabled: !isSubmitting,
                          decoration: _fieldDecoration(
                            'Contoh: Buku Saku Satgas PPKPT 2026',
                          ),
                        ),
                        const SizedBox(height: 14),
                        const _FieldLabel('Kategori *'),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.gray200),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: options.contains(selectedKategori)
                                  ? selectedKategori
                                  : options.first,
                              isExpanded: true,
                              items: options
                                  .map(
                                    (k) => DropdownMenuItem<String>(
                                      value: k,
                                      child: Text(
                                        k,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 13.5),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: isSubmitting
                                  ? null
                                  : (val) {
                                      if (val != null) {
                                        setModalState(
                                            () => selectedKategori = val);
                                      }
                                    },
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        const _FieldLabel('Tipe Materi *'),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: _TypeChoiceTile(
                                label: 'File Upload',
                                icon: Icons.upload_file_rounded,
                                selected: selectedTipe == 'file',
                                onTap: () => setModalState(
                                    () => selectedTipe = 'file'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _TypeChoiceTile(
                                label: 'Tautan Link',
                                icon: Icons.link_rounded,
                                selected: selectedTipe == 'link',
                                onTap: () => setModalState(
                                    () => selectedTipe = 'link'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        if (selectedTipe == 'file') ...[
                          const _FieldLabel(
                              'Pilih Dokumen (PDF / DOC / PPT) *'),
                          const SizedBox(height: 6),
                          InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: isSubmitting
                                ? null
                                : () async {
                                    final res =
                                        await FilePicker.platform.pickFiles(
                                      type: FileType.custom,
                                      allowedExtensions: const [
                                        'pdf',
                                        'doc',
                                        'docx',
                                        'ppt',
                                        'pptx',
                                      ],
                                      withData: true,
                                    );
                                    if (res != null && res.files.isNotEmpty) {
                                      final f = res.files.single;
                                      setModalState(() {
                                        pickedFileName = f.name;
                                        pickedFileBytes = f.bytes;
                                      });
                                    }
                                  },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 18),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFAF5FF),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0xFFD8B4FE),
                                ),
                              ),
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.upload_file_rounded,
                                    color: AppColors.purple600,
                                    size: 28,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    pickedFileName ??
                                        'Ketuk untuk memilih berkas dokumen',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: pickedFileName != null
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: pickedFileName != null
                                          ? AppColors.purple600
                                          : AppColors.slate600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ] else ...[
                          const _FieldLabel('URL Tautan Edukasi *'),
                          const SizedBox(height: 6),
                          TextField(
                            controller: linkCtrl,
                            enabled: !isSubmitting,
                            keyboardType: TextInputType.url,
                            decoration: _fieldDecoration(
                              'https://merdekadarikekerasan.kemdikbud.go.id',
                            ),
                          ),
                        ],
                        const SizedBox(height: 14),
                        const _FieldLabel('Deskripsi (Opsional)'),
                        const SizedBox(height: 6),
                        TextField(
                          controller: deskripsiCtrl,
                          enabled: !isSubmitting,
                          maxLines: 3,
                          decoration: _fieldDecoration(
                            'Ringkasan singkat isi materi edukasi...',
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
                      ElevatedButton.icon(
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
                                final judul = judulCtrl.text.trim();
                                final link = linkCtrl.text.trim();
                                if (judul.isEmpty) {
                                  setModalState(() =>
                                      formError = 'Judul edukasi wajib diisi.');
                                  return;
                                }
                                if (selectedTipe == 'link' && link.isEmpty) {
                                  setModalState(() => formError =
                                      'URL tautan materi wajib diisi.');
                                  return;
                                }

                                setModalState(() {
                                  isSubmitting = true;
                                  formError = '';
                                });

                                await OperatorPortalService.instance
                                    .createOperatorMaterial(
                                  judul: judul,
                                  deskripsi: deskripsiCtrl.text.trim(),
                                  kategori: selectedKategori,
                                  tipe: selectedTipe,
                                  link: selectedTipe == 'link' ? link : null,
                                  fileName: pickedFileName,
                                  fileBytes: pickedFileBytes,
                                );

                                if (ctx.mounted) {
                                  Navigator.of(ctx).pop(true);
                                }
                              },
                        icon: isSubmitting
                            ? const SizedBox(
                                width: 15,
                                height: 15,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.add_rounded, size: 18),
                        label: Text(
                          isSubmitting ? 'Menyimpan...' : 'Simpan Edukasi',
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

    judulCtrl.dispose();
    deskripsiCtrl.dispose();
    linkCtrl.dispose();

    if (created == true) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Materi berhasil ditambahkan!'),
          backgroundColor: Color(0xFF059669),
        ),
      );
      _fetchMaterials();
    }
  }

  Future<void> _openEditModal(EduMaterial item) async {
    final judulCtrl = TextEditingController(text: item.judul);
    final deskripsiCtrl = TextEditingController(text: item.deskripsi ?? '');
    final options = <String>{
      ..._categoryNameOptions,
      if (item.kategori.trim().isNotEmpty) item.kategori.trim(),
    }.toList();
    String selectedKategori =
        item.kategori.trim().isNotEmpty ? item.kategori.trim() : options.first;
    bool isSubmitting = false;
    String formError = '';

    final messenger = ScaffoldMessenger.of(context);

    final updated = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 18, 14, 14),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Edit Materi Edukasi',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.slate900,
                          ),
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
                            ),
                            child: Text(
                              formError,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.red,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],
                        const _FieldLabel('Judul Edukasi *'),
                        const SizedBox(height: 6),
                        TextField(
                          controller: judulCtrl,
                          enabled: !isSubmitting,
                          decoration: _fieldDecoration('Judul materi...'),
                        ),
                        const SizedBox(height: 14),
                        const _FieldLabel('Kategori *'),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.gray200),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: options.contains(selectedKategori)
                                  ? selectedKategori
                                  : options.first,
                              isExpanded: true,
                              items: options
                                  .map(
                                    (k) => DropdownMenuItem<String>(
                                      value: k,
                                      child: Text(
                                        k,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 13.5),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: isSubmitting
                                  ? null
                                  : (val) {
                                      if (val != null) {
                                        setModalState(
                                            () => selectedKategori = val);
                                      }
                                    },
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        const _FieldLabel('Deskripsi'),
                        const SizedBox(height: 6),
                        TextField(
                          controller: deskripsiCtrl,
                          enabled: !isSubmitting,
                          maxLines: 3,
                          decoration: _fieldDecoration('Deskripsi materi...'),
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
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                final judul = judulCtrl.text.trim();
                                if (judul.isEmpty) {
                                  setModalState(() =>
                                      formError = 'Judul materi wajib diisi.');
                                  return;
                                }
                                setModalState(() => isSubmitting = true);
                                await OperatorPortalService.instance
                                    .updateOperatorMaterial(
                                  uniqueId: item.uniqueId,
                                  judul: judul,
                                  deskripsi: deskripsiCtrl.text.trim(),
                                  kategori: selectedKategori,
                                );
                                if (ctx.mounted) Navigator.of(ctx).pop(true);
                              },
                        child: Text(
                          isSubmitting ? 'Menyimpan...' : 'Simpan Perubahan',
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

    judulCtrl.dispose();
    deskripsiCtrl.dispose();

    if (updated == true) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Materi berhasil diperbarui!'),
          backgroundColor: Color(0xFF059669),
        ),
      );
      _fetchMaterials();
    }
  }

  Future<void> _confirmDeleteMaterial(EduMaterial item) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text(
          'Hapus Materi?',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus materi "${item.judul}"? Tindakan ini tidak dapat dibatalkan.',
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
          .deleteOperatorMaterial(item.uniqueId);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Materi berhasil dihapus!'),
          backgroundColor: AppColors.red,
        ),
      );
      _fetchMaterials();
    }
  }

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13, color: AppColors.slate400),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
        borderSide: const BorderSide(color: AppColors.purple600, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fileCount = _materials.where((m) => m.tipe == 'file').length;
    final linkCount = _materials.where((m) => m.tipe == 'link').length;
    final activeCatCount = _materials
        .map((m) => m.kategori.trim())
        .where((k) => k.isNotEmpty)
        .toSet()
        .length;
    final filterCategories = _categoryNameOptions;

    return OperatorShellPage(
      title: 'Pusat Edukasi',
      subtitle: 'Kelola buku saku, SOP, dan materi edukasi',
      activePath: AppRoutes.operatorMaterialsManagement,
      body: RefreshIndicator(
        color: AppColors.purple600,
        onRefresh: _loadInitial,
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
                _EduStatCard(
                  label: 'Total Edukasi',
                  value: '${_materials.length}',
                  icon: Icons.insert_drive_file_outlined,
                  iconBg: const Color(0xFFF3E8FF),
                  iconFg: AppColors.purple600,
                ),
                _EduStatCard(
                  label: 'File Upload',
                  value: '$fileCount',
                  icon: Icons.upload_file_rounded,
                  iconBg: const Color(0xFFDBEAFE),
                  iconFg: const Color(0xFF2563EB),
                ),
                _EduStatCard(
                  label: 'Link',
                  value: '$linkCount',
                  icon: Icons.link_rounded,
                  iconBg: const Color(0xFFDCFCE7),
                  iconFg: AppColors.green,
                ),
                _EduStatCard(
                  label: 'Kategori',
                  value: '$activeCatCount',
                  icon: Icons.filter_list_rounded,
                  iconBg: const Color(0xFFFFEDD5),
                  iconFg: const Color(0xFFEA580C),
                ),
              ],
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

            // ── Controls Card ──
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
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
                    onChanged: (_) => _fetchMaterials(),
                    decoration: InputDecoration(
                      hintText: 'Cari judul atau kategori...',
                      hintStyle: const TextStyle(
                          fontSize: 13, color: AppColors.slate400),
                      prefixIcon: const Icon(Icons.search_rounded,
                          size: 19, color: AppColors.slate400),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              onPressed: () {
                                _searchController.clear();
                                _fetchMaterials();
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
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Container(
                          height: 42,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.gray200),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _kategoriFilter == 'all' ||
                                      filterCategories
                                          .contains(_kategoriFilter)
                                  ? _kategoriFilter
                                  : 'all',
                              isExpanded: true,
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.slate700,
                              ),
                              items: [
                                const DropdownMenuItem(
                                  value: 'all',
                                  child: Text('Semua Kategori'),
                                ),
                                ...filterCategories.map(
                                  (k) => DropdownMenuItem(
                                    value: k,
                                    child: Text(
                                      k,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ],
                              onChanged: (val) {
                                if (val == null) return;
                                setState(() => _kategoriFilter = val);
                                _fetchMaterials();
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: Container(
                          height: 42,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.gray200),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _tipeFilter,
                              isExpanded: true,
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.slate700,
                              ),
                              items: const [
                                DropdownMenuItem(
                                    value: 'all', child: Text('Semua Tipe')),
                                DropdownMenuItem(
                                    value: 'file', child: Text('File')),
                                DropdownMenuItem(
                                    value: 'link', child: Text('Link')),
                              ],
                              onChanged: (val) {
                                if (val == null) return;
                                setState(() => _tipeFilter = val);
                                _fetchMaterials();
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 42,
                    child: ElevatedButton.icon(
                      onPressed: _openAddModal,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.purple600,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text(
                        'Tambah Edukasi',
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

            // ── Materials Card Container ──
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
                  else if (_materials.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(36),
                      child: Column(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: AppColors.gray50,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: AppColors.gray100),
                            ),
                            child: const Icon(
                              Icons.insert_drive_file_outlined,
                              size: 30,
                              color: AppColors.gray400,
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'Belum ada materi edukasi',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.gray900,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Mulai dengan menambahkan materi pertama untuk bahan edukasi atau panduan.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: AppColors.gray500,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _openAddModal,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.purple600,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text('Tambah Edukasi'),
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _materials.length,
                      separatorBuilder: (_, _) =>
                          const Divider(height: 1, color: AppColors.gray100),
                      itemBuilder: (context, index) {
                        final item = _materials[index];
                        final isFile = item.isFile;
                        final desc = (item.deskripsi ?? '').trim();

                        return Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.slate100,
                                      borderRadius: BorderRadius.circular(7),
                                    ),
                                    child: Text(
                                      '#${item.uniqueId}',
                                      style: const TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.slate600,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: isFile
                                          ? const Color(0xFFDBEAFE)
                                          : const Color(0xFFDCFCE7),
                                      borderRadius: BorderRadius.circular(7),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isFile
                                              ? Icons.insert_drive_file_outlined
                                              : Icons.link_rounded,
                                          size: 12,
                                          color: isFile
                                              ? const Color(0xFF1D4ED8)
                                              : AppColors.green,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          isFile ? 'FILE' : 'LINK',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            color: isFile
                                                ? const Color(0xFF1D4ED8)
                                                : AppColors.green,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (item.kategori.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF3E8FF),
                                        borderRadius: BorderRadius.circular(7),
                                      ),
                                      child: Text(
                                        item.kategori,
                                        style: const TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.purple600,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 9),
                              Text(
                                item.judul,
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.slate900,
                                ),
                              ),
                              if (desc.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  desc,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: AppColors.slate500,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: () => _openMaterialUrl(item),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.indigo600,
                                      side: const BorderSide(
                                          color: Color(0xFFC7D2FE)),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      minimumSize: const Size(0, 34),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10),
                                      ),
                                    ),
                                    icon: Icon(
                                      isFile
                                          ? Icons.download_rounded
                                          : Icons.open_in_new_rounded,
                                      size: 15,
                                    ),
                                    label: Text(
                                      isFile ? 'Buka Dokumen' : 'Buka Link',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  IconButton(
                                    tooltip: 'Edit Materi',
                                    onPressed: () => _openEditModal(item),
                                    icon: const Icon(
                                      Icons.edit_outlined,
                                      size: 19,
                                      color: AppColors.indigo600,
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Hapus Materi',
                                    onPressed: () =>
                                        _confirmDeleteMaterial(item),
                                    icon: const Icon(
                                      Icons.delete_outline_rounded,
                                      size: 19,
                                      color: AppColors.red,
                                    ),
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

class _EduStatCard extends StatelessWidget {
  const _EduStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconBg,
    required this.iconFg,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color iconBg;
  final Color iconFg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.gray600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: AppColors.gray800,
                  ),
                ),
              ],
            ),
          ),
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
        ],
      ),
    );
  }
}

class _TypeChoiceTile extends StatelessWidget {
  const _TypeChoiceTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFAF5FF) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.purple600 : AppColors.gray200,
            width: selected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 17,
              color: selected ? AppColors.purple600 : AppColors.slate500,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: selected ? AppColors.purple600 : AppColors.slate600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        color: AppColors.gray700,
      ),
    );
  }
}

