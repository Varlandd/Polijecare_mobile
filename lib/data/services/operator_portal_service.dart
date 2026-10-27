import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/network/api_client.dart';
import '../../core/utils/image_url.dart';
import '../models/edu_material.dart';
import 'konselor_portal_service.dart';

/// Model pengguna yang dikelola pada menu Manajemen Pengguna Super Admin (`/operator/users`).
class OperatorManagedUser {
  const OperatorManagedUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.nim = '',
    this.phone = '',
    required this.createdAt,
  });

  final int id;
  final String name;
  final String email;
  final String role; // operator | konselor | user
  final String nim;
  final String phone;
  final DateTime createdAt;

  String get initial => name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : 'U';

  String get roleDisplay => role == 'konselor'
      ? 'Satgas'
      : (role == 'operator' ? 'Operator' : 'User');

  OperatorManagedUser copyWith({
    String? name,
    String? email,
    String? role,
    String? nim,
    String? phone,
  }) {
    return OperatorManagedUser(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      nim: nim ?? this.nim,
      phone: phone ?? this.phone,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role,
        'nim': nim,
        'phone': phone,
        'created_at': createdAt.toIso8601String(),
      };

  factory OperatorManagedUser.fromJson(Map<String, dynamic> json) {
    return OperatorManagedUser(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] ?? 'Pengguna PolijeCare').toString(),
      email: (json['email'] ?? '').toString(),
      role: (json['role'] ?? 'user').toString().toLowerCase(),
      nim: (json['nim'] ?? json['nip'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()) ??
          DateTime.now(),
    );
  }
}

/// Model Kategori Kekerasan pada menu Super Admin (`/operator/categories`).
class OperatorCategoryItem {
  const OperatorCategoryItem({
    required this.uniqueId,
    required this.name,
    this.description = '',
    this.complaintsCount = 0,
    required this.createdAt,
  });

  final String uniqueId;
  final String name;
  final String description;
  final int complaintsCount;
  final DateTime createdAt;

  OperatorCategoryItem copyWith({
    String? name,
    String? description,
    int? complaintsCount,
  }) {
    return OperatorCategoryItem(
      uniqueId: uniqueId,
      name: name ?? this.name,
      description: description ?? this.description,
      complaintsCount: complaintsCount ?? this.complaintsCount,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'unique_id': uniqueId,
        'name': name,
        'description': description,
        'complaints_count': complaintsCount,
        'created_at': createdAt.toIso8601String(),
      };

  factory OperatorCategoryItem.fromJson(Map<String, dynamic> json) {
    return OperatorCategoryItem(
      uniqueId: (json['unique_id'] ?? json['id'] ?? 'CAT-01').toString(),
      name: (json['name'] ?? json['kategori'] ?? 'Kategori Kekerasan')
          .toString(),
      description: (json['description'] ?? '').toString(),
      complaintsCount: (json['complaints_count'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()) ??
          DateTime.now(),
    );
  }
}

/// Model Artikel pada menu Manajemen Artikel Super Admin (`/operator/admin/articles`).
class OperatorArticleItem {
  const OperatorArticleItem({
    required this.id,
    required this.title,
    required this.slug,
    this.image,
    this.excerpt = '',
    required this.content,
    this.isActive = true,
    this.publishedAt,
    required this.createdAt,
    String? statusLabelOverride,
  }) : _statusLabelOverride = statusLabelOverride;

  final int id;
  final String title;
  final String slug;
  final String? image;
  final String excerpt;
  final String content;
  final bool isActive;
  final DateTime? publishedAt;
  final DateTime createdAt;
  final String? _statusLabelOverride;

  /// Label status sesuai `ArticleResource.php` & `article-management.jsx`:
  /// `Publish` | `Terjadwal` | `Draft` | `Nonaktif`
  String get statusLabel {
    if (_statusLabelOverride != null && _statusLabelOverride.isNotEmpty) {
      return _statusLabelOverride;
    }
    if (!isActive) return 'Nonaktif';
    if (publishedAt == null) return 'Draft';
    if (publishedAt!.isAfter(DateTime.now())) return 'Terjadwal';
    return 'Publish';
  }

  String get imageUrl =>
      normalizeImageUrl(image) ??
      'https://picsum.photos/seed/$slug/800/400.jpg';

  OperatorArticleItem copyWith({
    String? title,
    String? slug,
    String? image,
    String? excerpt,
    String? content,
    bool? isActive,
    DateTime? publishedAt,
    bool clearPublishedAt = false,
    String? statusLabelOverride,
  }) {
    return OperatorArticleItem(
      id: id,
      title: title ?? this.title,
      slug: slug ?? this.slug,
      image: image ?? this.image,
      excerpt: excerpt ?? this.excerpt,
      content: content ?? this.content,
      isActive: isActive ?? this.isActive,
      publishedAt:
          clearPublishedAt ? null : (publishedAt ?? this.publishedAt),
      createdAt: createdAt,
      statusLabelOverride: statusLabelOverride,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'slug': slug,
        'image': image,
        'excerpt': excerpt,
        'content': content,
        'is_active': isActive,
        'published_at': publishedAt?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };

  factory OperatorArticleItem.fromJson(Map<String, dynamic> json) {
    final rawActive = json['is_active'];
    final active = rawActive == null
        ? true
        : (rawActive == true || rawActive == 1 || rawActive == '1');
    final contentStr = (json['content'] ?? '').toString();
    final excerptStr = (json['excerpt'] ?? '').toString();
    return OperatorArticleItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: (json['title'] ?? '').toString(),
      slug: (json['slug'] ?? 'artikel-polijecare').toString(),
      image: json['image']?.toString(),
      excerpt: excerptStr.isNotEmpty
          ? excerptStr
          : (contentStr.length > 120
              ? '${contentStr.substring(0, 120)}...'
              : contentStr),
      content: contentStr,
      isActive: active,
      publishedAt:
          DateTime.tryParse((json['published_at'] ?? '').toString()),
      createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()) ??
          DateTime.now(),
      statusLabelOverride: json['status_label']?.toString(),
    );
  }
}

/// Service terpusat untuk seluruh menu Super Admin (`role = operator`).
/// Menghubungkan endpoint `/operator/*` pada backend Laravel dengan fallback
/// penyimpanan lokal (`SharedPreferences`) agar seluruh fitur berjalan mulus.
class OperatorPortalService {
  OperatorPortalService._();
  static final OperatorPortalService instance = OperatorPortalService._();

  static const String _kUsersKey = 'polijecare_operator_users_v1';
  static const String _kCategoriesKey = 'polijecare_operator_categories_v1';
  static const String _kArticlesKey = 'polijecare_operator_articles_v1';
  static const String _kMaterialsKey = 'polijecare_konselor_materials_v1';

  // ── Seed Data Lokal ────────────────────────────────────────────────────────

  List<OperatorManagedUser> _buildDefaultUsers() {
    final now = DateTime.now();
    return [
      OperatorManagedUser(
        id: 1,
        name: 'Super Admin PolijeCare',
        email: 'operator@polije.ac.id',
        role: 'operator',
        nim: '198804122015041001',
        phone: '081133445500',
        createdAt: now.subtract(const Duration(days: 120)),
      ),
      OperatorManagedUser(
        id: 2,
        name: 'Dr. Siti Aminah, M.Psi.',
        email: 'konselor@polije.ac.id',
        role: 'konselor',
        nim: '198506182012122002',
        phone: '081234560001',
        createdAt: now.subtract(const Duration(days: 110)),
      ),
      OperatorManagedUser(
        id: 21,
        name: 'Dr. Hendra Wijaya, M.Psi., Psikolog',
        email: 'hendra.satgas@polije.ac.id',
        role: 'konselor',
        nim: '198209102010121003',
        phone: '081234560002',
        createdAt: now.subtract(const Duration(days: 95)),
      ),
      OperatorManagedUser(
        id: 22,
        name: 'Ns. Ratna Kusuma, S.Kep., M.Kes.',
        email: 'ratna.satgas@polije.ac.id',
        role: 'konselor',
        nim: '198911252018032001',
        phone: '081234560003',
        createdAt: now.subtract(const Duration(days: 90)),
      ),
      OperatorManagedUser(
        id: 3,
        name: 'Budi Santoso',
        email: 'budi.santoso@student.polije.ac.id',
        role: 'user',
        nim: 'E41221001',
        phone: '081234567890',
        createdAt: now.subtract(const Duration(days: 60)),
      ),
      OperatorManagedUser(
        id: 4,
        name: 'Nadia Putri Rahmawati',
        email: 'nadia.putri@student.polije.ac.id',
        role: 'user',
        nim: 'G41230812',
        phone: '085233445566',
        createdAt: now.subtract(const Duration(days: 45)),
      ),
      OperatorManagedUser(
        id: 5,
        name: 'Rizky Pratama',
        email: 'rizky.pratama@student.polije.ac.id',
        role: 'user',
        nim: 'B32220419',
        phone: '081355667788',
        createdAt: now.subtract(const Duration(days: 30)),
      ),
      OperatorManagedUser(
        id: 6,
        name: 'Dimas Aditya',
        email: 'dimas.aditya@student.polije.ac.id',
        role: 'user',
        nim: 'B32230109',
        phone: '082244556677',
        createdAt: now.subtract(const Duration(days: 15)),
      ),
    ];
  }

  List<OperatorCategoryItem> _buildDefaultCategories() {
    final now = DateTime.now();
    return [
      OperatorCategoryItem(
        uniqueId: 'CAT-01',
        name: 'Kekerasan Seksual',
        description:
            'Setiap perbuatan merendahkan, menghina, melecehkan, dan/atau menyerang tubuh atau fungsi reproduksi seseorang.',
        complaintsCount: 4,
        createdAt: now.subtract(const Duration(days: 120)),
      ),
      OperatorCategoryItem(
        uniqueId: 'CAT-02',
        name: 'Pelecehan Verbal & Psikis',
        description:
            'Tindakan intimidasi, ancaman, penghinaan lisan/tulisan, atau tekanan psikologis di lingkungan kampus.',
        complaintsCount: 3,
        createdAt: now.subtract(const Duration(days: 115)),
      ),
      OperatorCategoryItem(
        uniqueId: 'CAT-03',
        name: 'Kekerasan Fisik',
        description:
            'Tindakan kontak fisik dengan atau tanpa alat yang menimbulkan rasa sakit, luka, atau cedera pada korban.',
        complaintsCount: 1,
        createdAt: now.subtract(const Duration(days: 110)),
      ),
      OperatorCategoryItem(
        uniqueId: 'CAT-04',
        name: 'Perundungan (Bullying)',
        description:
            'Perilaku agresif atau pengucilan berulang yang menyalahgunakan ketimpangan relasi kuasa di kampus.',
        complaintsCount: 2,
        createdAt: now.subtract(const Duration(days: 105)),
      ),
      OperatorCategoryItem(
        uniqueId: 'CAT-05',
        name: 'Kekerasan Berbasis Elektronik (KSBE)',
        description:
            'Penyebaran konten intim tanpa persetujuan, penguntitan siber, atau pemerasan seksual daring.',
        complaintsCount: 2,
        createdAt: now.subtract(const Duration(days: 90)),
      ),
    ];
  }

  List<OperatorArticleItem> _buildDefaultArticles() {
    final now = DateTime.now();
    return [
      OperatorArticleItem(
        id: 1,
        title:
            'Mengenal Satgas PPKPT Polije: Layanan Aman dan Rahasia bagi Civitas Akademika',
        slug: 'mengenal-satgas-ppkpt-polije',
        content:
            'Satuan Tugas Pencegahan dan Penanganan Kekerasan di Perguruan Tinggi (Satgas PPKPT) Politeknik Negeri Jember hadir untuk menjamin ruang aman bagi seluruh mahasiswa, dosen, dan tenaga kependidikan. Setiap laporan yang masuk dijamin kerahasiaannya dan ditangani oleh tim pendamping profesional.',
        isActive: true,
        publishedAt: now.subtract(const Duration(days: 14)),
        createdAt: now.subtract(const Duration(days: 15)),
      ),
      OperatorArticleItem(
        id: 2,
        title:
            'Panduan Lengkap Melaporkan Tindak Kekerasan dan Perundungan Melalui PolijeCare',
        slug: 'panduan-lengkap-melaporkan-kekerasan-polijecare',
        content:
            'PolijeCare menyediakan kanal pelaporan terenkripsi 24 jam. Pelapor maupun saksi dapat melampirkan bukti kejadian, menentukan titik lokasi, serta memilih jadwal pendampingan konseling baik secara tatap muka maupun daring.',
        isActive: true,
        publishedAt: now.subtract(const Duration(days: 7)),
        createdAt: now.subtract(const Duration(days: 8)),
      ),
      OperatorArticleItem(
        id: 3,
        title:
            'Sosialisasi Kampus Merdeka dari Kekerasan bagi Mahasiswa Baru Tahun Akademik 2026',
        slug: 'sosialisasi-kampus-merdeka-dari-kekerasan-2026',
        content:
            'Kegiatan edukasi dan sosialisasi pencegahan kekerasan seksual serta perundungan akan diselenggarakan secara serentak pada seluruh jurusan di Politeknik Negeri Jember.',
        isActive: true,
        publishedAt: now.add(const Duration(days: 5)),
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      OperatorArticleItem(
        id: 4,
        title: 'Draf Pedoman Perlindungan Saksi dan Pendampingan Pemulihan Korban',
        slug: 'draf-pedoman-perlindungan-saksi',
        content:
            'Dokumen draf internal mengenai alur rujukan psikologis, medis, dan bantuan hukum bagi penyintas kekerasan di perguruan tinggi.',
        isActive: false,
        publishedAt: null,
        createdAt: now.subtract(const Duration(days: 1)),
      ),
    ];
  }

  static const List<EduMaterial> _defaultMaterials = [
    EduMaterial(
      uniqueId: 'MAT-SATGAS-001',
      judul: 'Buku Saku Satgas PPKPT Politeknik Negeri Jember 2026',
      deskripsi:
          'Pedoman lengkap prosedur penerimaan laporan, asesmen awal, dan pendampingan korban kekerasan di lingkungan kampus.',
      tipe: 'file',
      filePath: 'materials/buku-saku-satgas-ppkpt-2026.pdf',
      kategori: 'Kekerasan Seksual',
    ),
    EduMaterial(
      uniqueId: 'MAT-SATGAS-002',
      judul: 'SOP Pertolongan Pertama Psikologis (Psychological First Aid)',
      deskripsi:
          'Langkah standar penanganan krisis emosional dan trauma awal bagi penyintas kekerasan seksual dan perundungan.',
      tipe: 'file',
      filePath: 'materials/sop-pfa-satgas.pdf',
      kategori: 'Pelecehan Verbal & Psikis',
    ),
    EduMaterial(
      uniqueId: 'MAT-SATGAS-003',
      judul: 'Portal Regulasi Permendikbudristek PPKPT & Perlindungan Saksi',
      deskripsi:
          'Tautan resmi himpunan regulasi pencegahan dan penanganan kekerasan di perguruan tinggi.',
      tipe: 'link',
      link: 'https://merdekadarikekerasan.kemdikbud.go.id',
      kategori: 'Perundungan (Bullying)',
    ),
  ];

  // ── Local Storage Helpers ──────────────────────────────────────────────────

  Future<List<OperatorManagedUser>> _getLocalUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kUsersKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List && decoded.isNotEmpty) {
          return decoded
              .whereType<Map>()
              .map((e) =>
                  OperatorManagedUser.fromJson(Map<String, dynamic>.from(e)))
              .toList();
        }
      }
      final defaults = _buildDefaultUsers();
      await _saveLocalUsers(defaults);
      return defaults;
    } catch (_) {
      return _buildDefaultUsers();
    }
  }

  Future<void> _saveLocalUsers(List<OperatorManagedUser> list) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _kUsersKey,
        jsonEncode(list.map((e) => e.toJson()).toList()),
      );
    } catch (_) {}
  }

  Future<List<OperatorCategoryItem>> _getLocalCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kCategoriesKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List && decoded.isNotEmpty) {
          return decoded
              .whereType<Map>()
              .map((e) =>
                  OperatorCategoryItem.fromJson(Map<String, dynamic>.from(e)))
              .toList();
        }
      }
      final defaults = _buildDefaultCategories();
      await _saveLocalCategories(defaults);
      return defaults;
    } catch (_) {
      return _buildDefaultCategories();
    }
  }

  Future<void> _saveLocalCategories(List<OperatorCategoryItem> list) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _kCategoriesKey,
        jsonEncode(list.map((e) => e.toJson()).toList()),
      );
    } catch (_) {}
  }

  Future<List<OperatorArticleItem>> _getLocalArticles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kArticlesKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List && decoded.isNotEmpty) {
          return decoded
              .whereType<Map>()
              .map((e) =>
                  OperatorArticleItem.fromJson(Map<String, dynamic>.from(e)))
              .toList();
        }
      }
      final defaults = _buildDefaultArticles();
      await _saveLocalArticles(defaults);
      return defaults;
    } catch (_) {
      return _buildDefaultArticles();
    }
  }

  Future<void> _saveLocalArticles(List<OperatorArticleItem> list) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _kArticlesKey,
        jsonEncode(list.map((e) => e.toJson()).toList()),
      );
    } catch (_) {}
  }

  Future<List<EduMaterial>> _getLocalMaterials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kMaterialsKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List && decoded.isNotEmpty) {
          return decoded
              .whereType<Map>()
              .map((e) => EduMaterial.fromJson(Map<String, dynamic>.from(e)))
              .toList();
        }
      }
      await _saveLocalMaterials(_defaultMaterials);
      return List<EduMaterial>.from(_defaultMaterials);
    } catch (_) {
      return List<EduMaterial>.from(_defaultMaterials);
    }
  }

  Future<void> _saveLocalMaterials(List<EduMaterial> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _kMaterialsKey,
        jsonEncode(
          items
              .map((m) => {
                    'unique_id': m.uniqueId,
                    'judul': m.judul,
                    'deskripsi': m.deskripsi,
                    'tipe': m.tipe,
                    'file_path': m.filePath,
                    'link': m.link,
                    'kategori': m.kategori,
                  })
              .toList(),
        ),
      );
    } catch (_) {}
  }

  String _fmtDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  // ── 1. DASHBOARD & ANALYTICS (`/operator/dashboard`) ───────────────────────

  /// Statistik utama Dashboard & Manajemen Kasus Super Admin:
  /// `GET /counseling/statistics` + `GET /operator/complaints-stats`
  Future<Map<String, int>> getOperatorDashboardSummary() async {
    try {
      final results = await Future.wait([
        ApiClient.instance.dio.get('/counseling/statistics'),
        ApiClient.instance.dio.get('/operator/complaints-stats'),
      ]);
      final Object? sBody = results[0].data;
      final Object? cBody = results[1].data;
      if (sBody is Map &&
          sBody['data'] is Map &&
          cBody is Map &&
          cBody['data'] is Map) {
        final sMap = Map<String, dynamic>.from(sBody['data'] as Map);
        final cMap = Map<String, dynamic>.from(cBody['data'] as Map);
        final pending = (cMap['pending'] as num?)?.toInt() ?? 0;
        return {
          'total': (cMap['total'] as num?)?.toInt() ?? 0,
          'approved': (cMap['approved'] as num?)?.toInt() ??
              (sMap['approved'] as num?)?.toInt() ??
              0,
          'completed': (cMap['completed'] as num?)?.toInt() ??
              (sMap['completed'] as num?)?.toInt() ??
              0,
          'pending': pending,
          'new': pending,
          'archived': (cMap['archived'] as num?)?.toInt() ?? 0,
          'today': (sMap['today'] as num?)?.toInt() ?? 0,
          'upcoming': (sMap['upcoming'] as num?)?.toInt() ?? 0,
        };
      }
    } catch (_) {}

    final fallback =
        await KonselorPortalService.instance.getCaseManagementStats();
    return {
      ...fallback,
      'new': fallback['pending'] ?? 0,
    };
  }

  Future<List<Map<String, dynamic>>> getCategoryDistribution({
    String year = '2026',
    String month = 'Semua',
  }) async {
    try {
      final res = await ApiClient.instance.dio.get(
        '/operator/dashboard/report-category-distribution',
        queryParameters: {
          if (year != 'Semua') 'year': year,
          if (month != 'Semua') 'month': month,
        },
      );
      final Object? body = res.data;
      if (body is Map && body['success'] == true && body['data'] is List) {
        return (body['data'] as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    } catch (_) {}
    return KonselorPortalService.instance.getCategoryDistribution(
      year: year,
      month: month,
    );
  }

  Future<Map<String, dynamic>> getGenderDistribution({
    String year = '2026',
    String month = 'Semua',
  }) async {
    try {
      final res = await ApiClient.instance.dio.get(
        '/operator/dashboard/gender-distribution',
        queryParameters: {
          if (year != 'Semua') 'year': year,
          if (month != 'Semua') 'month': month,
        },
      );
      final Object? body = res.data;
      if (body is Map && body['success'] == true && body['data'] is Map) {
        return Map<String, dynamic>.from(body['data'] as Map);
      }
    } catch (_) {}
    return KonselorPortalService.instance.getGenderDistribution(
      year: year,
      month: month,
    );
  }

  Future<List<Map<String, dynamic>>> getDepartmentDistribution({
    String year = '2026',
    String month = 'Semua',
  }) async {
    try {
      final res = await ApiClient.instance.dio.get(
        '/operator/dashboard/department-distribution',
        queryParameters: {
          if (year != 'Semua') 'year': year,
          if (month != 'Semua') 'month': month,
        },
      );
      final Object? body = res.data;
      if (body is Map && body['success'] == true && body['data'] is List) {
        return (body['data'] as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    } catch (_) {}
    return KonselorPortalService.instance.getDepartmentDistribution(
      year: year,
      month: month,
    );
  }

  // ── 2. MANAJEMEN KASUS (`/operator/case-management`) ───────────────────────

  Future<List<SatgasCounselor>> getOperatorCounselors() async {
    try {
      final res =
          await ApiClient.instance.dio.get('/operator/counseling/counselors');
      final Object? body = res.data;
      if (body is Map && body['data'] is List) {
        final rawList = body['data'] as List;
        if (rawList.isNotEmpty) {
          return rawList
              .whereType<Map>()
              .map((e) =>
                  SatgasCounselor.fromJson(Map<String, dynamic>.from(e)))
              .toList();
        }
      }
    } catch (_) {}
    return KonselorPortalService.instance.getCounselors();
  }

  Future<List<SatgasComplaintItem>> getOperatorComplaints({
    String tab = 'new', // new | active | archive | all
    String search = '',
    String status = 'all',
    String urgency = 'all',
    String dateFrom = '',
    String dateTo = '',
  }) async {
    try {
      String? statusParam;
      if (tab == 'new') {
        statusParam = 'pending';
      } else if (tab == 'active') {
        statusParam = 'approved';
      } else if (tab == 'archive') {
        statusParam =
            status != 'all' ? status : 'completed,rejected,cancelled';
      } else if (status != 'all') {
        statusParam = status;
      }

      final res = await ApiClient.instance.dio.get(
        '/operator/complaints',
        queryParameters: {
          'page': 1,
          'per_page': 50,
          if (search.trim().isNotEmpty) 'search': search.trim(),
          if (statusParam != null && statusParam.isNotEmpty)
            'status': statusParam,
          if (urgency != 'all') 'urgency_level': urgency,
          if (dateFrom.isNotEmpty) 'date_from': dateFrom,
          if (dateTo.isNotEmpty) 'date_to': dateTo,
        },
      );
      final Object? body = res.data;
      List? rawList;
      if (body is Map && body['data'] is List) {
        rawList = body['data'] as List;
      } else if (body is Map &&
          body['data'] is Map &&
          (body['data'] as Map)['data'] is List) {
        rawList = (body['data'] as Map)['data'] as List;
      }
      if (rawList != null) {
        return rawList
            .whereType<Map>()
            .map((e) =>
                SatgasComplaintItem.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    } catch (_) {}

    return KonselorPortalService.instance.getComplaints(
      tab: tab,
      search: search,
      status: status,
      urgency: urgency,
      dateFrom: dateFrom,
      dateTo: dateTo,
    );
  }

  Future<List<SatgasSessionRecord>> getOperatorSchedules({
    String tab = 'all', // all | today | upcoming
    String search = '',
    String status = 'all',
    String dateFrom = '',
    String dateTo = '',
  }) async {
    final todayStr = _fmtDate(DateTime.now());
    final tomorrowStr =
        _fmtDate(DateTime.now().add(const Duration(days: 1)));

    try {
      final params = <String, dynamic>{
        'page': 1,
        'per_page': 50,
        if (search.trim().isNotEmpty) 'search': search.trim(),
      };
      if (tab == 'today') {
        params['status'] = 'approved';
        params['date_from'] = todayStr;
        params['date_to'] = todayStr;
      } else if (tab == 'upcoming') {
        params['status'] = 'approved';
        params['date_from'] = tomorrowStr;
      } else {
        if (status != 'all') params['status'] = status;
        if (dateFrom.isNotEmpty) params['date_from'] = dateFrom;
        if (dateTo.isNotEmpty) params['date_to'] = dateTo;
      }

      final res = await ApiClient.instance.dio.get(
        '/operator/counseling',
        queryParameters: params,
      );
      final Object? body = res.data;
      List? rawList;
      if (body is Map &&
          body['data'] is Map &&
          (body['data'] as Map)['data'] is List) {
        rawList = (body['data'] as Map)['data'] as List;
      } else if (body is Map && body['data'] is List) {
        rawList = body['data'] as List;
      }
      if (rawList != null) {
        return rawList
            .whereType<Map>()
            .map((e) =>
                SatgasSessionRecord.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    } catch (_) {}

    return KonselorPortalService.instance.getSchedules(
      tab: tab,
      search: search,
      status: status,
      dateFrom: dateFrom,
      dateTo: dateTo,
    );
  }

  Future<bool> updateOperatorComplaintStatus(
    int id, {
    String? status,
    String? rejectionReason,
    String? urgencyLevel,
  }) async {
    try {
      await ApiClient.instance.dio.patch(
        '/operator/complaints/$id/status',
        data: {
          'status': ?status,
          'rejection_reason': ?rejectionReason,
          'urgency_level': ?urgencyLevel,
        },
      );
    } catch (_) {}
    return KonselorPortalService.instance.updateComplaintStatus(
      id,
      status: status,
      rejectionReason: rejectionReason,
      urgencyLevel: urgencyLevel,
    );
  }

  Future<bool> scheduleOperatorComplaint(
    int id, {
    required int counselorId,
    required String counselingSchedule,
    List<int> coCounselors = const [],
  }) async {
    try {
      await ApiClient.instance.dio.patch(
        '/operator/complaints/$id/schedule',
        data: {
          'counselor_id': counselorId,
          'counseling_schedule': counselingSchedule,
          'co_counselors': coCounselors,
        },
      );
    } catch (_) {}
    return KonselorPortalService.instance.delegateOrScheduleComplaint(
      id,
      counselorId: counselorId,
      counselingSchedule: counselingSchedule,
      coCounselors: coCounselors,
    );
  }

  static const List<({String id, String label})> exportColumnsCatalog = [
    (id: 'report_id', label: 'ID Laporan'),
    (id: 'created_at', label: 'Tanggal Lapor'),
    (id: 'category', label: 'Kategori'),
    (id: 'urgency', label: 'Urgensi'),
    (id: 'status', label: 'Status'),
    (id: 'victim_name', label: 'Nama Korban'),
    (id: 'victim_gender', label: 'J.K Korban'),
    (id: 'victim_type', label: 'Tipe Korban'),
    (id: 'location', label: 'Lokasi'),
    (id: 'title', label: 'Judul'),
    (id: 'chronology', label: 'Kronologi'),
    (id: 'suspect_name', label: 'Terlapor'),
    (id: 'suspect_gender', label: 'J.K Terlapor'),
    (id: 'suspect_status', label: 'Status Terlapor'),
    (id: 'counselor', label: 'Satgas'),
    (id: 'schedule', label: 'Jadwal'),
    (id: 'rejection_reason', label: 'Alasan Tolak'),
  ];

  Future<String> generateOperatorCasesCsv({
    String status = 'all',
    String dateFrom = '',
    String dateTo = '',
    List<String>? selectedColumns,
  }) async {
    final cols = (selectedColumns != null && selectedColumns.isNotEmpty)
        ? exportColumnsCatalog
            .where((c) => selectedColumns.contains(c.id))
            .toList()
        : exportColumnsCatalog;

    final items = await getOperatorComplaints(
      tab: 'all',
      status: status,
      dateFrom: dateFrom,
      dateTo: dateTo,
    );

    String esc(String v) => '"${v.replaceAll('"', '""')}"';

    final buffer = StringBuffer();
    buffer.writeln(cols.map((c) => esc(c.label)).join(','));

    for (final c in items) {
      final row = cols.map((col) {
        switch (col.id) {
          case 'report_id':
            return esc(c.reportId);
          case 'created_at':
            return esc(_fmtDate(c.createdAt));
          case 'category':
            return esc(c.categoryName);
          case 'urgency':
            return esc(c.urgencyLevel.toUpperCase());
          case 'status':
            return esc(c.status.toUpperCase());
          case 'victim_name':
            return esc(c.victimName);
          case 'victim_gender':
            return esc(c.victimGender);
          case 'victim_type':
            return esc(c.victimType == 'other' ? 'Saksi/Orang Lain' : 'Diri Sendiri');
          case 'location':
            return esc(c.location);
          case 'title':
            return esc(c.title);
          case 'chronology':
            return esc(c.chronology);
          case 'suspect_name':
            return esc(c.suspectName);
          case 'suspect_gender':
            return esc(c.suspectGender);
          case 'suspect_status':
            return esc(c.suspectStatus);
          case 'counselor':
            return esc(c.counselorName);
          case 'schedule':
            return esc(c.counselingSchedule ?? '-');
          case 'rejection_reason':
            return esc(c.rejectionReason ?? '-');
          default:
            return '""';
        }
      }).join(',');
      buffer.writeln(row);
    }
    return buffer.toString();
  }

  // ── 3. MANAJEMEN PENGGUNA (`/operator/users`) ──────────────────────────────

  Future<Map<String, int>> getUserStats() async {
    try {
      final res = await ApiClient.instance.dio.get('/operator/users-stats');
      final Object? body = res.data;
      if (body is Map && body['success'] == true && body['data'] is Map) {
        final d = Map<String, dynamic>.from(body['data'] as Map);
        return {
          'total_users': (d['total_users'] as num?)?.toInt() ?? 0,
          'operator': (d['operator'] as num?)?.toInt() ?? 0,
          'konselor': (d['konselor'] as num?)?.toInt() ?? 0,
          'pengguna': (d['pengguna'] as num?)?.toInt() ?? 0,
        };
      }
    } catch (_) {}

    final all = await _getLocalUsers();
    return {
      'total_users': all.length,
      'operator': all.where((u) => u.role == 'operator').length,
      'konselor': all.where((u) => u.role == 'konselor').length,
      'pengguna': all.where((u) => u.role == 'user').length,
    };
  }

  Future<({List<OperatorManagedUser> users, int totalPages, int total})>
      getUsers({
    int page = 1,
    int perPage = 8,
    String search = '',
    String role = 'all',
  }) async {
    try {
      final res = await ApiClient.instance.dio.get(
        '/operator/users',
        queryParameters: {
          'page': page,
          'per_page': perPage,
          'search': search.trim(),
          'role': role,
        },
      );
      final Object? body = res.data;
      if (body is Map && body['success'] == true && body['data'] is Map) {
        final dataMap = Map<String, dynamic>.from(body['data'] as Map);
        final rawUsers = dataMap['users'];
        final pag = dataMap['pagination'] is Map
            ? Map<String, dynamic>.from(dataMap['pagination'] as Map)
            : <String, dynamic>{};
        if (rawUsers is List) {
          final parsed = rawUsers
              .whereType<Map>()
              .map((e) =>
                  OperatorManagedUser.fromJson(Map<String, dynamic>.from(e)))
              .toList();
          return (
            users: parsed,
            totalPages: (pag['total_pages'] as num?)?.toInt() ?? 1,
            total: (pag['total'] as num?)?.toInt() ?? parsed.length,
          );
        }
      }
    } catch (_) {}

    final all = await _getLocalUsers();
    final q = search.trim().toLowerCase();
    final filtered = all.where((u) {
      if (role != 'all' && u.role != role) return false;
      if (q.isNotEmpty) {
        final match = u.name.toLowerCase().contains(q) ||
            u.email.toLowerCase().contains(q) ||
            u.nim.toLowerCase().contains(q);
        if (!match) return false;
      }
      return true;
    }).toList();

    final total = filtered.length;
    final totalPages = total == 0 ? 1 : ((total + perPage - 1) ~/ perPage);
    final safePage = page.clamp(1, totalPages);
    final start = (safePage - 1) * perPage;
    final end = (start + perPage).clamp(0, total);
    final slice = start < total
        ? filtered.sublist(start, end)
        : <OperatorManagedUser>[];

    return (users: slice, totalPages: totalPages, total: total);
  }

  Future<void> createUser({
    required String name,
    required String email,
    required String password,
    required String role,
    String nim = '',
  }) async {
    try {
      await ApiClient.instance.dio.post(
        '/operator/users',
        data: {
          'name': name,
          'email': email,
          'password': password,
          'role': role,
          'nim': nim.trim().isNotEmpty ? nim.trim() : null,
        },
      );
    } catch (_) {}

    final current = await _getLocalUsers();
    final newUser = OperatorManagedUser(
      id: DateTime.now().millisecondsSinceEpoch % 100000,
      name: name,
      email: email,
      role: role,
      nim: nim.trim(),
      createdAt: DateTime.now(),
    );
    await _saveLocalUsers([newUser, ...current]);
  }

  Future<void> updateUser(
    int id, {
    required String name,
    required String email,
    String password = '',
    required String role,
    String nim = '',
  }) async {
    try {
      final payload = <String, dynamic>{
        'name': name,
        'email': email,
        'role': role,
        'nim': nim.trim().isNotEmpty ? nim.trim() : null,
        if (password.isNotEmpty) 'password': password,
      };
      await ApiClient.instance.dio.put('/operator/users/$id', data: payload);
    } catch (_) {}

    final current = await _getLocalUsers();
    final updated = current.map((u) {
      if (u.id == id) {
        return u.copyWith(
          name: name,
          email: email,
          role: role,
          nim: nim.trim(),
        );
      }
      return u;
    }).toList();
    await _saveLocalUsers(updated);
  }

  Future<void> deleteUser(int id) async {
    try {
      await ApiClient.instance.dio.delete('/operator/users/$id');
    } catch (_) {}

    final current = await _getLocalUsers();
    current.removeWhere((u) => u.id == id);
    await _saveLocalUsers(current);
  }

  Future<String> exportUsersCsv({
    String search = '',
    String role = 'all',
  }) async {
    final res = await getUsers(
      page: 1,
      perPage: 500,
      search: search,
      role: role,
    );
    String esc(String v) => '"${v.replaceAll('"', '""')}"';
    final buf = StringBuffer();
    buf.writeln('ID,Nama,Email,Role,NIM');
    for (final u in res.users) {
      buf.writeln([
        u.id.toString(),
        esc(u.name),
        esc(u.email),
        esc(u.role),
        esc(u.nim),
      ].join(','));
    }
    return buf.toString();
  }

  // ── 4. PUSAT EDUKASI (`/operator/materials`) ───────────────────────────────

  Future<List<EduMaterial>> getOperatorMaterials({
    String search = '',
    String kategori = 'all',
    String tipe = 'all',
  }) async {
    try {
      final res = await ApiClient.instance.dio.get(
        '/operator/materials',
        queryParameters: {
          'page': 1,
          'per_page': 50,
          if (search.trim().isNotEmpty) 'search': search.trim(),
          if (kategori != 'all') 'kategori': kategori,
          if (tipe != 'all') 'tipe': tipe,
        },
      );
      final Object? body = res.data;
      List? rawList;
      if (body is Map && body['materials'] is List) {
        rawList = body['materials'] as List;
      } else if (body is Map && body['data'] is List) {
        rawList = body['data'] as List;
      } else if (body is Map &&
          body['data'] is Map &&
          (body['data'] as Map)['materials'] is List) {
        rawList = (body['data'] as Map)['materials'] as List;
      }
      if (rawList != null) {
        return rawList
            .whereType<Map>()
            .map((e) => EduMaterial.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    } catch (_) {}

    final all = await _getLocalMaterials();
    final q = search.trim().toLowerCase();
    return all.where((m) {
      if (kategori != 'all' && m.kategori != kategori) return false;
      if (tipe != 'all' && m.tipe != tipe) return false;
      if (q.isNotEmpty) {
        final match = m.judul.toLowerCase().contains(q) ||
            (m.deskripsi ?? '').toLowerCase().contains(q) ||
            m.kategori.toLowerCase().contains(q);
        if (!match) return false;
      }
      return true;
    }).toList();
  }

  Future<void> createOperatorMaterial({
    required String judul,
    required String deskripsi,
    required String kategori,
    required String tipe,
    String? link,
    String? fileName,
    List<int>? fileBytes,
  }) async {
    try {
      final map = <String, dynamic>{
        'judul': judul,
        'deskripsi': deskripsi,
        'kategori': kategori,
        'tipe': tipe,
        if (tipe == 'link' && link != null) 'link': link,
      };
      if (tipe == 'file' && fileBytes != null && fileName != null) {
        map['file'] = MultipartFile.fromBytes(fileBytes, filename: fileName);
      }
      await ApiClient.instance.dio.post(
        '/operator/materials',
        data: FormData.fromMap(map),
      );
    } catch (_) {}

    final current = await _getLocalMaterials();
    final newItem = EduMaterial(
      uniqueId: 'MAT-${DateTime.now().millisecondsSinceEpoch % 100000}',
      judul: judul,
      deskripsi: deskripsi,
      tipe: tipe,
      kategori: kategori,
      filePath: tipe == 'file'
          ? 'materials/${fileName ?? 'edukasi-polijecare.pdf'}'
          : null,
      link: tipe == 'link' ? link : null,
    );
    await _saveLocalMaterials([newItem, ...current]);
  }

  Future<void> updateOperatorMaterial({
    required String uniqueId,
    required String judul,
    required String deskripsi,
    required String kategori,
  }) async {
    try {
      await ApiClient.instance.dio.put(
        '/operator/materials/$uniqueId',
        data: {
          'judul': judul,
          'deskripsi': deskripsi,
          'kategori': kategori,
        },
      );
    } catch (_) {}

    final current = await _getLocalMaterials();
    final updated = current.map((m) {
      if (m.uniqueId == uniqueId) {
        return EduMaterial(
          uniqueId: m.uniqueId,
          judul: judul,
          deskripsi: deskripsi,
          tipe: m.tipe,
          filePath: m.filePath,
          link: m.link,
          kategori: kategori,
        );
      }
      return m;
    }).toList();
    await _saveLocalMaterials(updated);
  }

  Future<void> deleteOperatorMaterial(String uniqueId) async {
    try {
      await ApiClient.instance.dio.delete('/operator/materials/$uniqueId');
    } catch (_) {}

    final current = await _getLocalMaterials();
    current.removeWhere((m) => m.uniqueId == uniqueId);
    await _saveLocalMaterials(current);
  }

  // ── 5. KATEGORI KEKERASAN (`/operator/categories`) ─────────────────────────

  Future<List<OperatorCategoryItem>> getOperatorCategories({
    String search = '',
  }) async {
    try {
      final res = await ApiClient.instance.dio.get(
        '/operator/categories',
        queryParameters: {
          'page': 1,
          'per_page': 50,
          if (search.trim().isNotEmpty) 'search': search.trim(),
        },
      );
      final Object? body = res.data;
      List? rawList;
      if (body is Map && body['categories'] is List) {
        rawList = body['categories'] as List;
      } else if (body is Map && body['data'] is List) {
        rawList = body['data'] as List;
      } else if (body is Map &&
          body['data'] is Map &&
          (body['data'] as Map)['categories'] is List) {
        rawList = (body['data'] as Map)['categories'] as List;
      }
      if (rawList != null) {
        return rawList
            .whereType<Map>()
            .map((e) =>
                OperatorCategoryItem.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    } catch (_) {}

    final all = await _getLocalCategories();
    final q = search.trim().toLowerCase();
    if (q.isEmpty) return all;
    return all.where((c) {
      return c.name.toLowerCase().contains(q) ||
          c.uniqueId.toLowerCase().contains(q) ||
          c.description.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> createOperatorCategory({
    required String name,
    String description = '',
  }) async {
    try {
      await ApiClient.instance.dio.post(
        '/operator/categories',
        data: {
          'name': name.trim(),
          'description': description.trim(),
        },
      );
    } catch (_) {}

    final current = await _getLocalCategories();
    final nextNum = (current.length + 1).toString().padLeft(2, '0');
    final item = OperatorCategoryItem(
      uniqueId: 'CAT-$nextNum',
      name: name.trim(),
      description: description.trim(),
      complaintsCount: 0,
      createdAt: DateTime.now(),
    );
    await _saveLocalCategories([item, ...current]);
  }

  Future<void> updateOperatorCategory(
    String uniqueId, {
    required String name,
    String description = '',
  }) async {
    try {
      await ApiClient.instance.dio.put(
        '/operator/categories/$uniqueId',
        data: {
          'name': name.trim(),
          'description': description.trim(),
        },
      );
    } catch (_) {}

    final current = await _getLocalCategories();
    final updated = current.map((c) {
      if (c.uniqueId == uniqueId) {
        return c.copyWith(
          name: name.trim(),
          description: description.trim(),
        );
      }
      return c;
    }).toList();
    await _saveLocalCategories(updated);
  }

  Future<void> deleteOperatorCategory(String uniqueId) async {
    try {
      await ApiClient.instance.dio.delete('/operator/categories/$uniqueId');
    } catch (_) {}

    final current = await _getLocalCategories();
    current.removeWhere((c) => c.uniqueId == uniqueId);
    await _saveLocalCategories(current);
  }

  // ── 6. MANAJEMEN ARTIKEL (`/operator/admin/articles`) ──────────────────────

  String _slugify(String input) {
    final s = input
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), '-');
    return s.isNotEmpty ? s : 'artikel-${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<List<OperatorArticleItem>> getOperatorArticles({
    String search = '',
    String status = 'all', // all | published | scheduled | draft | inactive
  }) async {
    try {
      final res = await ApiClient.instance.dio.get(
        '/operator/admin/articles',
        queryParameters: {
          'page': 1,
          'per_page': 50,
          if (search.trim().isNotEmpty) 'search': search.trim(),
          if (status != 'all') 'status': status,
        },
      );
      final Object? body = res.data;
      if (body is Map && body['success'] == true && body['data'] is Map) {
        final dataMap = Map<String, dynamic>.from(body['data'] as Map);
        final rawList = dataMap['articles'];
        if (rawList is List) {
          return rawList
              .whereType<Map>()
              .map((e) =>
                  OperatorArticleItem.fromJson(Map<String, dynamic>.from(e)))
              .toList();
        }
      }
    } catch (_) {}

    final all = await _getLocalArticles();
    final q = search.trim().toLowerCase();
    return all.where((a) {
      if (status != 'all') {
        final label = a.statusLabel;
        if (status == 'published' && label != 'Publish') return false;
        if (status == 'scheduled' && label != 'Terjadwal') return false;
        if (status == 'draft' && label != 'Draft') return false;
        if (status == 'inactive' && label != 'Nonaktif') return false;
      }
      if (q.isNotEmpty) {
        final match = a.title.toLowerCase().contains(q) ||
            a.content.toLowerCase().contains(q);
        if (!match) return false;
      }
      return true;
    }).toList();
  }

  Future<void> createOperatorArticle({
    required String title,
    required String content,
    DateTime? publishedAt,
    required bool isActive,
    String? imageName,
    List<int>? imageBytes,
  }) async {
    try {
      final map = <String, dynamic>{
        'title': title.trim(),
        'content': content.trim(),
        'published_at': publishedAt != null ? publishedAt.toUtc().toIso8601String() : '',
        'is_active': isActive ? '1' : '0',
      };
      if (imageBytes != null && imageName != null && imageName.isNotEmpty) {
        map['image'] = MultipartFile.fromBytes(imageBytes, filename: imageName);
      }
      await ApiClient.instance.dio.post(
        '/operator/admin/articles',
        data: FormData.fromMap(map),
      );
    } catch (_) {}

    final current = await _getLocalArticles();
    final cleanContent = content.trim();
    final item = OperatorArticleItem(
      id: DateTime.now().millisecondsSinceEpoch % 100000,
      title: title.trim(),
      slug: _slugify(title),
      content: cleanContent,
      excerpt: cleanContent.length > 120
          ? '${cleanContent.substring(0, 120)}...'
          : cleanContent,
      isActive: isActive,
      publishedAt: publishedAt,
      createdAt: DateTime.now(),
    );
    await _saveLocalArticles([item, ...current]);
  }

  Future<void> updateOperatorArticle(
    int id, {
    required String title,
    required String content,
    DateTime? publishedAt,
    required bool isActive,
    String? imageName,
    List<int>? imageBytes,
  }) async {
    try {
      final map = <String, dynamic>{
        'title': title.trim(),
        'content': content.trim(),
        'published_at': publishedAt != null ? publishedAt.toUtc().toIso8601String() : '',
        'is_active': isActive ? '1' : '0',
      };
      if (imageBytes != null && imageName != null && imageName.isNotEmpty) {
        map['image'] = MultipartFile.fromBytes(imageBytes, filename: imageName);
      }
      await ApiClient.instance.dio.post(
        '/operator/admin/articles/$id/update',
        data: FormData.fromMap(map),
      );
    } catch (_) {}

    final current = await _getLocalArticles();
    final cleanContent = content.trim();
    final updated = current.map((a) {
      if (a.id == id) {
        return a.copyWith(
          title: title.trim(),
          slug: _slugify(title),
          content: cleanContent,
          excerpt: cleanContent.length > 120
              ? '${cleanContent.substring(0, 120)}...'
              : cleanContent,
          isActive: isActive,
          publishedAt: publishedAt,
          clearPublishedAt: publishedAt == null,
        );
      }
      return a;
    }).toList();
    await _saveLocalArticles(updated);
  }

  Future<void> toggleOperatorArticle(int id) async {
    try {
      await ApiClient.instance.dio.patch('/operator/admin/articles/$id/toggle');
    } catch (_) {}

    final current = await _getLocalArticles();
    final updated = current.map((a) {
      if (a.id == id) {
        return a.copyWith(isActive: !a.isActive);
      }
      return a;
    }).toList();
    await _saveLocalArticles(updated);
  }

  Future<void> deleteOperatorArticle(int id) async {
    try {
      await ApiClient.instance.dio.delete('/operator/admin/articles/$id');
    } catch (_) {}

    final current = await _getLocalArticles();
    current.removeWhere((a) => a.id == id);
    await _saveLocalArticles(current);
  }
}

