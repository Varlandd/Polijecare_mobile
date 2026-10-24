import 'package:flutter/material.dart';

import '../../../app/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/launcher.dart';
import '../../../data/models/edu_material.dart';
import '../../../data/services/material_service.dart';
import 'common.dart';

/// Section Pusat Unduhan & Edukasi (setara `components/Materials.jsx`).
/// Menampilkan 3 materi terbaru.
class MaterialsSection extends StatefulWidget {
  const MaterialsSection({super.key, this.refreshSeed = 0});

  final int refreshSeed;

  @override
  State<MaterialsSection> createState() => _MaterialsSectionState();
}

class _MaterialsSectionState extends State<MaterialsSection> {
  late Future<List<EduMaterial>> _future;

  Future<List<EduMaterial>> _load() async {
    final list = await MaterialService.instance.getPublicMaterials();
    return list.take(3).toList();
  }

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void didUpdateWidget(covariant MaterialsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshSeed != widget.refreshSeed) {
      setState(() => _future = _load());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.slate50,
      padding: const EdgeInsets.fromLTRB(20, 56, 20, 56),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE0E7FF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.menu_book_outlined,
                color: AppColors.indigo600, size: 26),
          ),
          const SizedBox(height: 14),
          const SectionTitle(
            first: 'Pusat',
            highlight: 'Unduhan & Edukasi',
            fontSize: 28,
            gradient: LinearGradient(
              colors: [AppColors.indigo600, AppColors.purple600],
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Akses cepat ke berbagai modul edukasi, Standar Operasional Prosedur (SOP), dan buku saku penanganan kasus.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: AppColors.slate500, height: 1.6),
          ),
          const SizedBox(height: 32),
          FutureBuilder<List<EduMaterial>>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 30),
                  child: CircularProgressIndicator(color: AppColors.indigo600),
                );
              }
              if (snap.hasError) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1F2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'Gagal memuat materi edukasi',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFFF43F5E)),
                  ),
                );
              }
              final items = snap.data ?? const [];
              if (items.isEmpty) return const _EmptyMaterials();
              return Column(
                children: [
                  for (var i = 0; i < items.length; i++)
                    FadeSlideIn(
                      delay: Duration(milliseconds: 100 * i),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: MaterialCard(material: items[i]),
                      ),
                    ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () =>
                        Navigator.of(context).pushNamed(AppRoutes.edukasi),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.gray700,
                      side: const BorderSide(color: AppColors.gray200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 15),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      textStyle: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Lihat Semua Materi Edukasi'),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded, size: 18),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _EmptyMaterials extends StatelessWidget {
  const _EmptyMaterials();

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: const BoxDecoration(
              color: Color(0xFFEEF2FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.menu_book_outlined,
                size: 32, color: Color(0xFFA5B4FC)),
          ),
          const SizedBox(height: 14),
          const Text(
            'Belum ada materi edukasi',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.slate800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Kami sedang menyiapkan materi berkualitas untuk Anda.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.slate500),
          ),
        ],
      ),
    );
  }
}

/// Kartu materi — juga akan dipakai ulang di halaman Pusat Edukasi.
class MaterialCard extends StatelessWidget {
  const MaterialCard({super.key, required this.material});

  final EduMaterial material;

  @override
  Widget build(BuildContext context) {
    final isFile = material.isFile;
    final accent = isFile ? const Color(0xFFEF4444) : AppColors.emerald;
    final actionColor = isFile ? AppColors.indigo600 : const Color(0xFF059669);

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.slate100),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -24,
            bottom: -24,
            child: Icon(
              isFile ? Icons.description_outlined : Icons.link_rounded,
              size: 150,
              color: Colors.black.withValues(alpha: 0.03),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isFile
                              ? const [Color(0xFFFFF1F2), Color(0xFFFEF2F2)]
                              : const [Color(0xFFECFDF5), Color(0xFFF0FDFA)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isFile
                              ? const Color(0xFFFEE2E2)
                              : const Color(0xFFD1FAE5),
                        ),
                      ),
                      child: Icon(
                        isFile
                            ? Icons.description_outlined
                            : Icons.link_rounded,
                        color: accent,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.slate100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              material.kategori.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                                color: AppColors.slate600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            material.judul,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.slate800,
                              height: 1.25,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  (material.deskripsi?.isNotEmpty ?? false)
                      ? material.deskripsi!
                      : 'Tidak ada deskripsi tersedia untuk dokumen ini.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.slate500, height: 1.5),
                ),
                const SizedBox(height: 14),
                const Divider(height: 1, color: AppColors.slate50),
                const SizedBox(height: 10),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () =>
                          openExternal(context, material.openUrl),
                      style: TextButton.styleFrom(
                        foregroundColor: actionColor,
                        padding: EdgeInsets.zero,
                        textStyle: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13.5),
                      ),
                      iconAlignment: IconAlignment.end,
                      icon: const Icon(Icons.open_in_new_rounded, size: 16),
                      label: Text(isFile ? 'Baca Dokumen' : 'Buka Tautan'),
                    ),
                    const Spacer(),
                    if (isFile)
                      Material(
                        color: AppColors.slate50,
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () =>
                              openExternal(context, material.fileUrl),
                          child: const Padding(
                            padding: EdgeInsets.all(9),
                            child: Icon(Icons.download_rounded,
                                size: 18, color: AppColors.slate600),
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
  }
}

