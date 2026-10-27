import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/launcher.dart';
import '../../data/models/edu_material.dart';
import '../../data/models/user_complaint.dart';
import '../../data/services/konselor_portal_service.dart';
import '../../data/services/material_service.dart';
import 'konselor_shell_page.dart';

/// Halaman Pusat Edukasi Satgas (`/konselor/materi`).
/// Porting 1:1 dari `pages/konselor/materi.jsx` di web PolijeCare.
class KonselorMateriPage extends StatefulWidget {
  const KonselorMateriPage({super.key});

  @override
  State<KonselorMateriPage> createState() => _KonselorMateriPageState();
}

class _KonselorMateriPageState extends State<KonselorMateriPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedKategori = 'all';
  String _selectedTipe = 'all';

  bool _loading = true;
  List<EduMaterial> _materials = [];
  List<ViolenceCategoryItem> _categories = [];

  @override
  void initState() {
    super.initState();
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
      final cats = await KonselorPortalService.instance.getCategories();
      if (!mounted) return;
      _categories = cats;
      await _fetchMaterials();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _fetchMaterials() async {
    setState(() => _loading = true);
    try {
      final list = await KonselorPortalService.instance.getKonselorMaterials(
        search: _searchCtrl.text,
        kategori: _selectedKategori,
        tipe: _selectedTipe,
      );
      if (!mounted) return;
      setState(() => _materials = list);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<String> get _categoryNames {
    if (_categories.isNotEmpty) {
      return _categories.map((e) => e.name).toList();
    }
    return const [
      'Kekerasan Seksual',
      'Pelecehan Verbal & Psikis',
      'Perundungan (Bullying)',
      'Kekerasan Fisik',
    ];
  }

  Future<void> _showAddMaterialModal() async {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final linkCtrl = TextEditingController();
    String kategori = _categoryNames.first;
    String tipe = 'file'; // file | link
    String? pickedFileName;
    List<int>? pickedFileBytes;

    final saved = await showDialog<bool>(
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
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.library_add_outlined,
                  color: Color(0xFF4F46E5),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Tambah Materi Edukasi',
                  style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800),
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
                  'JUDUL MATERI *',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.gray700,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: titleCtrl,
                  decoration: InputDecoration(
                    hintText: 'Masukkan judul materi atau pedoman...',
                    filled: true,
                    fillColor: AppColors.gray50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'DESKRIPSI SINGKAT',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.gray700,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Ringkasan isi materi edukasi...',
                    filled: true,
                    fillColor: AppColors.gray50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'KATEGORI *',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.gray700,
                  ),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: kategori,
                  isExpanded: true,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.gray50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: _categoryNames
                      .map((c) => DropdownMenuItem(
                            value: c,
                            child:
                                Text(c, style: const TextStyle(fontSize: 13)),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setModalState(() => kategori = v);
                  },
                ),
                const SizedBox(height: 12),
                const Text(
                  'TIPE MATERI *',
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
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => setModalState(() => tipe = 'file'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: tipe == 'file'
                                ? const Color(0xFFEEF2FF)
                                : AppColors.gray50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: tipe == 'file'
                                  ? const Color(0xFF4F46E5)
                                  : AppColors.gray200,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'File Upload',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: tipe == 'file'
                                  ? const Color(0xFF4F46E5)
                                  : AppColors.gray600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => setModalState(() => tipe = 'link'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: tipe == 'link'
                                ? const Color(0xFFEEF2FF)
                                : AppColors.gray50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: tipe == 'link'
                                  ? const Color(0xFF4F46E5)
                                  : AppColors.gray200,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Tautan Link',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: tipe == 'link'
                                  ? const Color(0xFF4F46E5)
                                  : AppColors.gray600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (tipe == 'file') ...[
                  OutlinedButton.icon(
                    onPressed: () async {
                      try {
                        final res = await FilePicker.platform.pickFiles(
                          type: FileType.custom,
                          allowedExtensions: const [
                            'pdf',
                            'doc',
                            'docx',
                            'ppt',
                            'pptx'
                          ],
                          withData: true,
                        );
                        if (res != null && res.files.isNotEmpty) {
                          setModalState(() {
                            pickedFileName = res.files.first.name;
                            pickedFileBytes = res.files.first.bytes;
                          });
                        }
                      } catch (_) {}
                    },
                    icon: const Icon(Icons.upload_file_rounded, size: 16),
                    label: Text(
                      pickedFileName ?? 'Pilih Dokumen PDF / Word',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ] else ...[
                  TextField(
                    controller: linkCtrl,
                    decoration: InputDecoration(
                      hintText: 'https://...',
                      filled: true,
                      fillColor: AppColors.gray50,
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
                if (titleCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content: Text('Judul materi wajib diisi!'),
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
              child: const Text('Simpan Materi'),
            ),
          ],
        ),
      ),
    );

    if (saved == true) {
      await KonselorPortalService.instance.createKonselorMaterial(
        judul: titleCtrl.text.trim(),
        deskripsi: descCtrl.text.trim(),
        kategori: kategori,
        tipe: tipe,
        link: tipe == 'link' ? linkCtrl.text.trim() : null,
        fileName: pickedFileName,
        fileBytes: pickedFileBytes,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Materi edukasi berhasil ditambahkan!'),
          backgroundColor: Color(0xFF059669),
        ),
      );
      await _fetchMaterials();
    }
  }

  Future<void> _showEditMaterialModal(EduMaterial item) async {
    final titleCtrl = TextEditingController(text: item.judul);
    final descCtrl = TextEditingController(text: item.deskripsi ?? '');
    String kategori = _categoryNames.contains(item.kategori)
        ? item.kategori
        : _categoryNames.first;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text(
            'Edit Materi Edukasi',
            style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: InputDecoration(
                    labelText: 'Judul Materi *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Deskripsi',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: kategori,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Kategori',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: _categoryNames
                      .map((c) => DropdownMenuItem(
                            value: c,
                            child:
                                Text(c, style: const TextStyle(fontSize: 13)),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setModalState(() => kategori = v);
                  },
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
              child: const Text('Simpan Perubahan'),
            ),
          ],
        ),
      ),
    );

    if (saved == true) {
      await KonselorPortalService.instance.updateKonselorMaterial(
        uniqueId: item.uniqueId,
        judul: titleCtrl.text.trim(),
        deskripsi: descCtrl.text.trim(),
        kategori: kategori,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Materi edukasi berhasil diperbarui!'),
          backgroundColor: Color(0xFF4F46E5),
        ),
      );
      await _fetchMaterials();
    }
  }

  Future<void> _confirmDeleteMaterial(EduMaterial item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Hapus Materi?',
          style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800),
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus materi "${item.judul}"?',
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
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await KonselorPortalService.instance
          .deleteKonselorMaterial(item.uniqueId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Materi telah dihapus.'),
          backgroundColor: Color(0xFFE11D48),
        ),
      );
      await _fetchMaterials();
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = _materials.length;
    final fileCount = _materials.where((m) => m.isFile).length;
    final linkCount = _materials.where((m) => !m.isFile).length;
    final catCount = _materials
        .map((m) => m.kategori)
        .where((s) => s.isNotEmpty)
        .toSet()
        .length;

    return KonselorShellPage(
      title: 'Pusat Edukasi',
      subtitle: 'Kelola materi edukasi & pencegahan kekerasan.',
      activePath: AppRoutes.konselorMateri,
      body: RefreshIndicator(
        color: const Color(0xFF4F46E5),
        onRefresh: _fetchMaterials,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pusat Edukasi Satgas',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.gray900,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Kelola modul, pedoman SOP, dan tautan edukasi publik.',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: AppColors.gray500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _showAddMaterialModal,
                    icon: const Icon(Icons.add_rounded, size: 17),
                    label: const Text(
                      'Tambah Materi',
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w800),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 11),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // 4 Stats
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.85,
                children: [
                  _buildStatBox(
                    label: 'Total Materi',
                    value: '$total',
                    icon: Icons.menu_book_rounded,
                    color: const Color(0xFF4F46E5),
                  ),
                  _buildStatBox(
                    label: 'File Upload',
                    value: '$fileCount',
                    icon: Icons.picture_as_pdf_outlined,
                    color: const Color(0xFFE11D48),
                  ),
                  _buildStatBox(
                    label: 'Tautan Link',
                    value: '$linkCount',
                    icon: Icons.link_rounded,
                    color: const Color(0xFF059669),
                  ),
                  _buildStatBox(
                    label: 'Kategori Aktif',
                    value: '$catCount',
                    icon: Icons.category_outlined,
                    color: const Color(0xFFD97706),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Filter bar
              Container(
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
                      onSubmitted: (_) => _fetchMaterials(),
                      decoration: InputDecoration(
                        hintText: 'Cari judul atau deskripsi materi...',
                        hintStyle: const TextStyle(fontSize: 13),
                        prefixIcon:
                            const Icon(Icons.search_rounded, size: 19),
                        filled: true,
                        fillColor: AppColors.gray50,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
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
                            initialValue: _selectedKategori,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: 'Kategori',
                              filled: true,
                              fillColor: AppColors.gray50,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 8),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            items: [
                              const DropdownMenuItem(
                                value: 'all',
                                child: Text('Semua Kategori',
                                    style: TextStyle(fontSize: 12)),
                              ),
                              ..._categoryNames.map(
                                (c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(c,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 12)),
                                ),
                              ),
                            ],
                            onChanged: (v) {
                              if (v == null) return;
                              setState(() => _selectedKategori = v);
                              _fetchMaterials();
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedTipe,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: 'Tipe',
                              filled: true,
                              fillColor: AppColors.gray50,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 8),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(
                                  value: 'all',
                                  child: Text('Semua Tipe',
                                      style: TextStyle(fontSize: 12))),
                              DropdownMenuItem(
                                  value: 'file',
                                  child: Text('File Upload',
                                      style: TextStyle(fontSize: 12))),
                              DropdownMenuItem(
                                  value: 'link',
                                  child: Text('Tautan Link',
                                      style: TextStyle(fontSize: 12))),
                            ],
                            onChanged: (v) {
                              if (v == null) return;
                              setState(() => _selectedTipe = v);
                              _fetchMaterials();
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (_loading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(36),
                    child:
                        CircularProgressIndicator(color: Color(0xFF4F46E5)),
                  ),
                )
              else if (_materials.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(36),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: AppColors.gray100),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.menu_book_outlined,
                          size: 40, color: AppColors.gray300),
                      SizedBox(height: 10),
                      Text(
                        'Belum Ada Materi Edukasi',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                )
              else
                ..._materials.map(_buildMaterialCard),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatBox({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.gray100),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 19),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: AppColors.gray900,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.gray500,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialCard(EduMaterial item) {
    final isFile = item.isFile;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gray100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isFile
                      ? const Color(0xFFFFF1F2)
                      : const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isFile ? 'FILE DOKUMEN' : 'TAUTAN LINK',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: isFile
                        ? const Color(0xFFE11D48)
                        : const Color(0xFF059669),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (item.kategori.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item.kategori,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF4F46E5),
                    ),
                  ),
                ),
              const Spacer(),
              Text(
                '#${item.uniqueId}',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.gray400,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            item.judul,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.gray900,
            ),
          ),
          if ((item.deskripsi ?? '').isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              item.deskripsi!,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.gray600,
                height: 1.4,
              ),
            ),
          ],
          const Divider(height: 22),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    final targetUrl = isFile
                        ? MaterialService.instance.getFileUrl(item.filePath)
                        : (item.link ?? '');
                    if (targetUrl.isNotEmpty) {
                      AppLauncher.openUrl(targetUrl);
                    }
                  },
                  icon: Icon(
                    isFile
                        ? Icons.download_rounded
                        : Icons.open_in_new_rounded,
                    size: 16,
                  ),
                  label: Text(
                    isFile ? 'Unduh Dokumen' : 'Buka Tautan',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => _showEditMaterialModal(item),
                tooltip: 'Edit Materi',
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.gray50,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppColors.gray200),
                  ),
                ),
                icon: const Icon(
                  Icons.edit_outlined,
                  size: 18,
                  color: AppColors.gray700,
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                onPressed: () => _confirmDeleteMaterial(item),
                tooltip: 'Hapus Materi',
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFFFF1F2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Color(0xFFFFE4E6)),
                  ),
                ),
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  size: 18,
                  color: Color(0xFFE11D48),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
