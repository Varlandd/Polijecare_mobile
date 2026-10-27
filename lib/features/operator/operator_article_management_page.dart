import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/image_url.dart';
import '../../data/services/operator_portal_service.dart';
import 'operator_shell_page.dart';

/// Halaman Manajemen Artikel Super Admin — port 1:1 dari
/// `pages/operator/article-management.jsx`.
class OperatorArticleManagementPage extends StatefulWidget {
  const OperatorArticleManagementPage({super.key});

  @override
  State<OperatorArticleManagementPage> createState() =>
      _OperatorArticleManagementPageState();
}

class _OperatorArticleManagementPageState
    extends State<OperatorArticleManagementPage> {
  final TextEditingController _searchController = TextEditingController();

  String _statusFilter = 'all';
  bool _isLoading = true;
  String _errorMessage = '';
  int? _togglingId;

  List<OperatorArticleItem> _articles = const [];
  List<OperatorArticleItem> _allForStats = const [];

  static const List<String> _shortMonths = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];

  @override
  void initState() {
    super.initState();
    _fetchArticles();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchArticles() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final results = await Future.wait([
        OperatorPortalService.instance.getOperatorArticles(
          search: _searchController.text,
          status: _statusFilter,
        ),
        OperatorPortalService.instance.getOperatorArticles(),
      ]);
      if (!mounted) return;
      setState(() {
        _articles = results[0];
        _allForStats = results[1];
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Gagal mengambil data artikel.';
        _isLoading = false;
      });
    }
  }

  String _fmtDate(DateTime? dt) {
    if (dt == null) return '-';
    final d = dt.day.toString().padLeft(2, '0');
    final m = _shortMonths[(dt.month - 1).clamp(0, 11)];
    return '$d $m ${dt.year}';
  }

  String _fmtDateTime(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = _shortMonths[(dt.month - 1).clamp(0, 11)];
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$d $m ${dt.year}, $hh:$mm WIB';
  }

  Future<void> _handleToggle(OperatorArticleItem article) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _togglingId = article.id);
    try {
      await OperatorPortalService.instance.toggleOperatorArticle(article.id);
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            article.isActive
                ? 'Artikel disembunyikan (Nonaktif).'
                : 'Artikel diaktifkan ke publik!',
          ),
          backgroundColor: const Color(0xFF059669),
        ),
      );
      await _fetchArticles();
    } finally {
      if (mounted) {
        setState(() => _togglingId = null);
      }
    }
  }

  Future<void> _openArticleModal({OperatorArticleItem? article}) async {
    final isEdit = article != null;
    final titleCtrl = TextEditingController(text: article?.title ?? '');
    final contentCtrl = TextEditingController(text: article?.content ?? '');
    DateTime? publishedAt = article?.publishedAt?.toLocal();
    bool isActive = article?.isActive ?? true;

    String? existingImageUrl = normalizeImageUrl(article?.image);
    String? pickedImageName;
    Uint8List? pickedImageBytes;

    bool isSubmitting = false;
    String? titleError;
    String? contentError;
    String? imageError;
    String? generalError;

    final messenger = ScaffoldMessenger.of(context);

    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 18, 14, 14),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isEdit ? 'Edit Artikel' : 'Tambah Artikel',
                                style: const TextStyle(
                                  fontSize: 17.5,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.gray900,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isEdit
                                    ? 'Edit: ${article.title}'
                                    : 'Isi data artikel baru',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.gray500,
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
                              color: AppColors.gray400),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: AppColors.gray100),

                  // Body
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (generalError != null) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF2F2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: const Color(0xFFFECACA)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline_rounded,
                                      size: 18, color: AppColors.red),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      generalError!,
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        color: AppColors.red,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                          ],

                          // Judul
                          const _ArticleLabel(text: 'Judul', requiredField: true),
                          const SizedBox(height: 6),
                          TextField(
                            controller: titleCtrl,
                            enabled: !isSubmitting,
                            decoration: _articleFieldDecoration(
                              hint: 'Judul artikel...',
                              errorText: titleError,
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Upload Gambar
                          const _ArticleLabel(
                              text: 'Gambar (JPG/PNG, maks 2MB)'),
                          const SizedBox(height: 6),
                          if (pickedImageBytes != null ||
                              existingImageUrl != null)
                            Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: Container(
                                    height: 145,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                          color: AppColors.gray200),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: pickedImageBytes != null
                                        ? Image.memory(
                                            pickedImageBytes!,
                                            fit: BoxFit.cover,
                                          )
                                        : Image.network(
                                            existingImageUrl!,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, _, _) =>
                                                Container(
                                              color: AppColors.gray100,
                                              alignment: Alignment.center,
                                              child: const Icon(
                                                Icons.image_outlined,
                                                color: AppColors.gray400,
                                                size: 32,
                                              ),
                                            ),
                                          ),
                                  ),
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Material(
                                    color: Colors.white.withValues(alpha: 0.92),
                                    shape: const CircleBorder(),
                                    elevation: 2,
                                    child: InkWell(
                                      customBorder: const CircleBorder(),
                                      onTap: isSubmitting
                                          ? null
                                          : () {
                                              setModalState(() {
                                                pickedImageBytes = null;
                                                pickedImageName = null;
                                                existingImageUrl = null;
                                                imageError = null;
                                              });
                                            },
                                      child: const Padding(
                                        padding: EdgeInsets.all(6),
                                        child: Icon(
                                          Icons.close_rounded,
                                          size: 16,
                                          color: AppColors.red,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          else
                            InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: isSubmitting
                                  ? null
                                  : () async {
                                      final res =
                                          await FilePicker.platform.pickFiles(
                                        type: FileType.custom,
                                        allowedExtensions: const [
                                          'jpg',
                                          'jpeg',
                                          'png',
                                        ],
                                        withData: true,
                                      );
                                      if (res != null &&
                                          res.files.isNotEmpty) {
                                        final f = res.files.single;
                                        if (f.size > 2 * 1024 * 1024) {
                                          setModalState(() => imageError =
                                              'Ukuran gambar maksimal 2MB');
                                          return;
                                        }
                                        setModalState(() {
                                          imageError = null;
                                          pickedImageName = f.name;
                                          pickedImageBytes = f.bytes;
                                        });
                                      }
                                    },
                              child: Container(
                                height: 112,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFAF5FF),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: const Color(0xFFD8B4FE),
                                  ),
                                ),
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.image_outlined,
                                      size: 26,
                                      color: AppColors.purple600,
                                    ),
                                    SizedBox(height: 6),
                                    Text(
                                      'Ketuk untuk upload gambar cover',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        color: AppColors.gray600,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          if (imageError != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              imageError!,
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: AppColors.red,
                              ),
                            ),
                          ],
                          const SizedBox(height: 14),

                          // Konten
                          const _ArticleLabel(
                              text: 'Konten', requiredField: true),
                          const SizedBox(height: 6),
                          TextField(
                            controller: contentCtrl,
                            enabled: !isSubmitting,
                            maxLines: 6,
                            decoration: _articleFieldDecoration(
                              hint: 'Tulis konten artikel di sini...',
                              errorText: contentError,
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Tanggal Publish
                          const _ArticleLabel(text: 'Tanggal Publish'),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: isSubmitting
                                      ? null
                                      : () async {
                                          final base =
                                              publishedAt ?? DateTime.now();
                                          final pickedDate =
                                              await showDatePicker(
                                            context: ctx,
                                            initialDate: base,
                                            firstDate: DateTime(2024),
                                            lastDate: DateTime(2030),
                                          );
                                          if (pickedDate == null ||
                                              !ctx.mounted) {
                                            return;
                                          }
                                          final pickedTime =
                                              await showTimePicker(
                                            context: ctx,
                                            initialTime:
                                                TimeOfDay.fromDateTime(base),
                                          );
                                          final t = pickedTime ??
                                              TimeOfDay.fromDateTime(base);
                                          setModalState(() {
                                            publishedAt = DateTime(
                                              pickedDate.year,
                                              pickedDate.month,
                                              pickedDate.day,
                                              t.hour,
                                              t.minute,
                                            );
                                          });
                                        },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.slate800,
                                    side: const BorderSide(
                                        color: AppColors.gray300),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  icon: const Icon(
                                    Icons.calendar_today_outlined,
                                    size: 16,
                                    color: AppColors.purple600,
                                  ),
                                  label: Text(
                                    publishedAt != null
                                        ? _fmtDateTime(publishedAt!)
                                        : 'Draft (Belum Dijadwalkan)',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              if (publishedAt != null) ...[
                                const SizedBox(width: 8),
                                IconButton(
                                  tooltip: 'Kosongkan (Jadikan Draft)',
                                  onPressed: isSubmitting
                                      ? null
                                      : () => setModalState(
                                          () => publishedAt = null),
                                  icon: const Icon(
                                    Icons.close_rounded,
                                    size: 18,
                                    color: AppColors.gray500,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Kosongkan = Draft  •  Tanggal masa depan = Terjadwal',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.gray400,
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Status Artikel Toggle
                          const _ArticleLabel(text: 'Status Artikel'),
                          const SizedBox(height: 6),
                          InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: isSubmitting
                                ? null
                                : () => setModalState(
                                    () => isActive = !isActive),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? const Color(0xFFF0FDF4)
                                    : AppColors.gray100,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isActive
                                      ? const Color(0xFF86EFAC)
                                      : AppColors.gray300,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    isActive
                                        ? 'Aktif (Tampil ke Publik)'
                                        : 'Nonaktif (Disembunyikan)',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: isActive
                                          ? const Color(0xFF15803D)
                                          : AppColors.gray500,
                                    ),
                                  ),
                                  Icon(
                                    isActive
                                        ? Icons.toggle_on_rounded
                                        : Icons.toggle_off_outlined,
                                    size: 28,
                                    color: isActive
                                        ? const Color(0xFF16A34A)
                                        : AppColors.gray400,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Divider(height: 1, color: AppColors.gray100),
                  // Footer
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: isSubmitting
                              ? null
                              : () => Navigator.of(ctx).pop(false),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.gray700,
                            side: const BorderSide(color: AppColors.gray300),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Batal'),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.purple600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: isSubmitting
                              ? null
                              : () async {
                                  final t = titleCtrl.text.trim();
                                  final c = contentCtrl.text.trim();
                                  setModalState(() {
                                    titleError =
                                        t.isEmpty ? 'Judul wajib diisi' : null;
                                    contentError = c.isEmpty
                                        ? 'Konten wajib diisi'
                                        : null;
                                    generalError = null;
                                  });
                                  if (t.isEmpty || c.isEmpty) return;

                                  setModalState(() => isSubmitting = true);
                                  try {
                                    if (isEdit) {
                                      await OperatorPortalService.instance
                                          .updateOperatorArticle(
                                        article.id,
                                        title: t,
                                        content: c,
                                        publishedAt: publishedAt,
                                        isActive: isActive,
                                        imageName: pickedImageName,
                                        imageBytes: pickedImageBytes,
                                      );
                                    } else {
                                      await OperatorPortalService.instance
                                          .createOperatorArticle(
                                        title: t,
                                        content: c,
                                        publishedAt: publishedAt,
                                        isActive: isActive,
                                        imageName: pickedImageName,
                                        imageBytes: pickedImageBytes,
                                      );
                                    }
                                    if (ctx.mounted) {
                                      Navigator.of(ctx).pop(true);
                                    }
                                  } catch (_) {
                                    setModalState(() {
                                      isSubmitting = false;
                                      generalError =
                                          'Terjadi kesalahan saat menyimpan artikel.';
                                    });
                                  }
                                },
                          child: Text(
                            isSubmitting ? 'Menyimpan...' : 'Simpan',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    titleCtrl.dispose();
    contentCtrl.dispose();

    if (saved == true) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            isEdit
                ? 'Artikel berhasil diperbarui!'
                : 'Artikel berhasil dibuat!',
          ),
          backgroundColor: const Color(0xFF16A34A),
        ),
      );
      _fetchArticles();
    }
  }

  Future<void> _confirmDeleteArticle(OperatorArticleItem article) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text(
          'Hapus Artikel?',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus artikel "${article.title}"? Artikel yang dihapus tidak dapat dikembalikan.',
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
      await OperatorPortalService.instance.deleteOperatorArticle(article.id);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Artikel berhasil dihapus'),
          backgroundColor: AppColors.red,
        ),
      );
      _fetchArticles();
    }
  }

  InputDecoration _articleFieldDecoration({
    required String hint,
    String? errorText,
  }) {
    return InputDecoration(
      hintText: hint,
      errorText: errorText,
      hintStyle: const TextStyle(fontSize: 13, color: AppColors.gray400),
      filled: true,
      fillColor: errorText != null ? const Color(0xFFFEF2F2) : Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.gray300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.gray300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.purple600, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final source = _allForStats.isNotEmpty ? _allForStats : _articles;
    final totalCount = source.length;
    final publishCount =
        source.where((a) => a.statusLabel == 'Publish').length;
    final draftCount = source.where((a) => a.statusLabel == 'Draft').length;
    final inactiveCount =
        source.where((a) => a.statusLabel == 'Nonaktif').length;

    return OperatorShellPage(
      title: 'Manajemen Artikel',
      subtitle: 'Kelola artikel & pengumuman publik',
      activePath: AppRoutes.operatorArticleManagement,
      body: RefreshIndicator(
        color: AppColors.purple600,
        onRefresh: _fetchArticles,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            if (_errorMessage.isNotEmpty && !_isLoading) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(12),
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

            // ── 4 Stats Cards ──
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.72,
              children: [
                _ArticleStatCard(
                  title: 'Total Artikel',
                  value: _isLoading ? '—' : '$totalCount',
                  barColors: const [Color(0xFFA855F7), Color(0xFF9333EA)],
                ),
                _ArticleStatCard(
                  title: 'Aktif / Publish',
                  value: _isLoading ? '—' : '$publishCount',
                  barColors: const [Color(0xFF22C55E), Color(0xFF16A34A)],
                ),
                _ArticleStatCard(
                  title: 'Draft',
                  value: _isLoading ? '—' : '$draftCount',
                  barColors: const [Color(0xFFEAB308), Color(0xFFCA8A04)],
                ),
                _ArticleStatCard(
                  title: 'Nonaktif',
                  value: _isLoading ? '—' : '$inactiveCount',
                  barColors: const [Color(0xFF6B7280), Color(0xFF4B5563)],
                ),
              ],
            ),
            const SizedBox(height: 18),

            // ── Premium Article List Card ──
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

                  // Filter Bar
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        TextField(
                          controller: _searchController,
                          onChanged: (_) => _fetchArticles(),
                          decoration: InputDecoration(
                            hintText: 'Cari judul artikel...',
                            hintStyle: const TextStyle(
                                fontSize: 13, color: AppColors.gray400),
                            prefixIcon: const Icon(Icons.search_rounded,
                                size: 19, color: AppColors.gray400),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    onPressed: () {
                                      _searchController.clear();
                                      _fetchArticles();
                                    },
                                    icon: const Icon(Icons.close_rounded,
                                        size: 17),
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
                              child: Container(
                                height: 42,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.gray200),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _statusFilter,
                                    isExpanded: true,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.gray700,
                                    ),
                                    items: const [
                                      DropdownMenuItem(
                                          value: 'all',
                                          child: Text('Semua Status')),
                                      DropdownMenuItem(
                                          value: 'published',
                                          child: Text('Publish')),
                                      DropdownMenuItem(
                                          value: 'scheduled',
                                          child: Text('Terjadwal')),
                                      DropdownMenuItem(
                                          value: 'draft', child: Text('Draft')),
                                      DropdownMenuItem(
                                          value: 'inactive',
                                          child: Text('Nonaktif')),
                                    ],
                                    onChanged: (val) {
                                      if (val == null) return;
                                      setState(() => _statusFilter = val);
                                      _fetchArticles();
                                    },
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: () => _openArticleModal(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.purple600,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(0, 42),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.add_rounded, size: 18),
                              label: const Text(
                                'Tambah Artikel',
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
                  const Divider(height: 1, color: AppColors.gray100),

                  // Article Items
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.purple600,
                        ),
                      ),
                    )
                  else if (_articles.isEmpty)
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
                              Icons.article_outlined,
                              size: 30,
                              color: AppColors.gray400,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Belum ada artikel ditemukan',
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.gray900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Buat artikel atau pengumuman baru untuk halaman depan PolijeCare.',
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
                      itemCount: _articles.length,
                      separatorBuilder: (_, _) =>
                          const Divider(height: 1, color: AppColors.gray100),
                      itemBuilder: (context, index) {
                        final article = _articles[index];
                        final isToggling = _togglingId == article.id;

                        return Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      width: 72,
                                      height: 54,
                                      decoration: BoxDecoration(
                                        color: AppColors.gray100,
                                        border: Border.all(
                                            color: AppColors.gray200),
                                      ),
                                      child: Image.network(
                                        article.imageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, _, _) => const Center(
                                          child: Icon(
                                            Icons.image_outlined,
                                            size: 20,
                                            color: AppColors.gray400,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          article.title,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.gray900,
                                            height: 1.25,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          article.excerpt.isNotEmpty
                                              ? article.excerpt
                                              : 'Tidak ada ringkasan',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 11.5,
                                            color: AppColors.gray500,
                                            height: 1.35,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  _StatusBadge(label: article.statusLabel),
                                  const SizedBox(width: 8),
                                  InkWell(
                                    borderRadius: BorderRadius.circular(7),
                                    onTap: isToggling
                                        ? null
                                        : () => _handleToggle(article),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: article.isActive
                                            ? const Color(0xFFECFDF5)
                                            : AppColors.gray50,
                                        borderRadius: BorderRadius.circular(7),
                                        border: Border.all(
                                          color: article.isActive
                                              ? const Color(0xFFA7F3D0)
                                              : AppColors.gray200,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (isToggling)
                                            const SizedBox(
                                              width: 10,
                                              height: 10,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 1.6,
                                              ),
                                            )
                                          else
                                            Container(
                                              width: 6,
                                              height: 6,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: article.isActive
                                                    ? const Color(0xFF10B981)
                                                    : AppColors.gray400,
                                              ),
                                            ),
                                          const SizedBox(width: 5),
                                          Text(
                                            article.isActive
                                                ? 'PUBLIK'
                                                : 'SEMBUNYIKAN',
                                            style: TextStyle(
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.w800,
                                              color: article.isActive
                                                  ? const Color(0xFF047857)
                                                  : AppColors.gray500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    _fmtDate(article.publishedAt),
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.gray600,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  InkWell(
                                    borderRadius: BorderRadius.circular(10),
                                    onTap: () =>
                                        _openArticleModal(article: article),
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
                                    borderRadius: BorderRadius.circular(10),
                                    onTap: () =>
                                        _confirmDeleteArticle(article),
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

class _ArticleStatCard extends StatelessWidget {
  const _ArticleStatCard({
    required this.title,
    required this.value,
    required this.barColors,
  });

  final String title;
  final String value;
  final List<Color> barColors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.gray500,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.gray900,
            ),
          ),
          Container(
            height: 4,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: LinearGradient(colors: barColors),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    switch (label) {
      case 'Publish':
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF166534);
        break;
      case 'Terjadwal':
        bg = const Color(0xFFDBEAFE);
        fg = const Color(0xFF1E40AF);
        break;
      case 'Draft':
        bg = const Color(0xFFFEF9C3);
        fg = const Color(0xFF854D0E);
        break;
      default:
        bg = AppColors.gray100;
        fg = AppColors.gray500;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}

class _ArticleLabel extends StatelessWidget {
  const _ArticleLabel({
    required this.text,
    this.requiredField = false,
  });

  final String text;
  final bool requiredField;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.gray700,
        ),
        children: [
          TextSpan(text: text),
          if (requiredField)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: AppColors.red500),
            ),
        ],
      ),
    );
  }
}

