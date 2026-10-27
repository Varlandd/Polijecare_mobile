import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/config/api_config.dart';
import '../../core/network/api_client.dart';
import '../models/app_user.dart';
import '../models/article.dart';
import '../models/user_complaint.dart';
import 'article_service.dart';
import 'auth_service.dart';

/// Service lengkap untuk seluruh menu User / Mahasiswa & Shared Profile
/// (`dashboard.jsx`, `buat-laporan.jsx`, `histori-pengaduan.jsx`,
/// `detail-pengaduan.jsx`, `counseling-request.jsx`, dan `Profile.jsx`).
///
/// Mendukung koneksi langsung ke backend Laravel (`/api/user/*`, `/api/counseling/*`, `/api/profile`)
/// sekaligus penyimpanan fallback di `SharedPreferences` apabila server lokal belum dinyalakan.
class UserPortalService {
  UserPortalService._();
  static final UserPortalService instance = UserPortalService._();

  static const String _localComplaintsKey = 'polijecare_local_user_complaints';
  static const String _localSchedulesKey = 'polijecare_local_user_schedules';

  /// Daftar kategori seeder bawaan (`DatabaseSeeder.php`).
  static final List<ViolenceCategoryItem> _seedCategories = [
    const ViolenceCategoryItem(
      uniqueId: 'CAT-DEMO-001-2026',
      name: 'Kekerasan Fisik',
      description:
          'Tindakan kekerasan yang menyebabkan cedera fisik atau nyeri pada korban',
    ),
    const ViolenceCategoryItem(
      uniqueId: 'CAT-DEMO-002-2026',
      name: 'Kekerasan Psikis',
      description:
          'Tindakan yang menyebabkan tekanan mental, emosional, atau psikologis',
    ),
    const ViolenceCategoryItem(
      uniqueId: 'CAT-DEMO-003-2026',
      name: 'Kekerasan Seksual',
      description: 'Tindakan pelecehan atau kekerasan berbasis seksual',
    ),
    const ViolenceCategoryItem(
      uniqueId: 'CAT-DEMO-004-2026',
      name: 'Kekerasan Verbal',
      description:
          'Tindakan kekerasan melalui kata-kata yang menyakitkan atau mengancam',
    ),
    const ViolenceCategoryItem(
      uniqueId: 'CAT-DEMO-005-2026',
      name: 'Kekerasan Digital',
      description:
          'Tindakan kekerasan melalui media online atau teknologi digital',
    ),
  ];

  /// Daftar Satgas pendamping bawaan (`DatabaseSeeder.php`).
  static const List<CounselorOption> _seedCounselors = [
    CounselorOption(
      id: 2,
      name: 'Siti Konselor',
      email: 'siti@polije.ac.id',
    ),
  ];

  /// Contoh laporan awal untuk akun mahasiswa demo agar tampilan dashboard & histori
  /// langsung informatif dan dapat diuji detailnya.
  static List<UserComplaint> _defaultSeedComplaints() {
    final now = DateTime.now();
    return [
      UserComplaint(
        id: 101,
        reportReference: 'LP-2026-0101',
        title: 'Intimidasi dan Perundungan Verbal di Lingkungan Kampus',
        status: 'approved',
        urgencyLevel: 'medium',
        categoryId: 'CAT-DEMO-004-2026',
        categoryName: 'Kekerasan Verbal',
        counselorName: 'Siti Konselor',
        victimType: 'self',
        victimName: 'Ahmad Mahasiswa',
        victimGender: 'Laki-laki',
        suspectName: 'Oknum Senior',
        suspectStatus: 'Mahasiswa',
        suspectAffiliation: 'Jurusan Teknologi Informasi - Teknik Informatika',
        chronology:
            'Pada saat kegiatan diskusi kelompok di area gedung jurusan, terlapor melakukan intimidasi verbal secara berulang di depan rekan-rekan mahasiswa lainnya sehingga menimbulkan tekanan psikologis dan rasa tidak aman untuk mengikuti perkuliahan.',
        location:
            'Jurusan Teknologi Informasi - Lab. Rekayasa Sistem Informasi',
        incidentDate:
            now.subtract(const Duration(days: 4)).toIso8601String().split('T').first,
        proposedDate:
            now.add(const Duration(days: 2)).toIso8601String().split('T').first,
        proposedTime: '09:00',
        createdAt: now.subtract(const Duration(days: 3)),
        schedules: [
          CounselingScheduleItem(
            id: 501,
            complaintId: '101',
            tanggal:
                now.add(const Duration(days: 2)).toIso8601String().split('T').first,
            jamMulai: '09:00:00',
            jamSelesai: '10:00:00',
            metode: 'offline',
            lokasi: 'Ruang Konseling Satgas PPKPT, Gedung Rektorat Lt. 1',
            status: 'approved',
            counselorName: 'Siti Konselor',
            counseleeType: 'pelapor',
            counseleeName: 'Ahmad Mahasiswa',
            keteranganPihak:
                'Laporan telah diverifikasi oleh tim Satgas PPKPT dan sesi pendampingan awal telah dijadwalkan.',
            saranKonselor:
                'Mohon hadir 10 menit sebelum jadwal sesi dimulai dengan membawa bukti pendukung tambahan jika ada.',
          ),
        ],
      ),
      UserComplaint(
        id: 102,
        reportReference: 'LP-2026-0089',
        title: 'Pelecehan Melalui Pesan Singkat Media Sosial',
        status: 'completed',
        urgencyLevel: 'high',
        categoryId: 'CAT-DEMO-005-2026',
        categoryName: 'Kekerasan Digital',
        counselorName: 'Siti Konselor',
        victimType: 'other',
        victimName: 'Rekan Mahasiswa',
        victimGender: 'Perempuan',
        victimRelationship: 'Teman Sekelas',
        suspectName: 'Akun Anonim',
        suspectStatus: 'Mahasiswa',
        suspectAffiliation: 'Jurusan Bisnis',
        chronology:
            'Korban menerima pesan bernada pelecehan dan ancaman penyebaran data pribadi secara berulang melalui aplikasi pesan instan selama dua minggu terakhir sehingga mengganggu konsentrasi akademik korban.',
        location: 'Jurusan Bisnis - Laboratorium Digital Marketing',
        incidentDate:
            now.subtract(const Duration(days: 18)).toIso8601String().split('T').first,
        proposedDate:
            now.subtract(const Duration(days: 14)).toIso8601String().split('T').first,
        proposedTime: '10:00',
        createdAt: now.subtract(const Duration(days: 15)),
        schedules: [
          CounselingScheduleItem(
            id: 502,
            complaintId: '102',
            tanggal: now
                .subtract(const Duration(days: 12))
                .toIso8601String()
                .split('T')
                .first,
            jamMulai: '10:00:00',
            jamSelesai: '11:00:00',
            metode: 'online',
            meetingLink: 'https://meet.polijecare.ac.id/sesi-502',
            status: 'completed',
            counselorName: 'Siti Konselor',
            counseleeType: 'pelapor',
            counseleeName: 'Rekan Mahasiswa',
            keteranganPihak:
                'Sesi konseling dan mediasi perlindungan digital telah dilaksanakan dengan baik.',
            saranKonselor:
                'Kasus telah ditindaklanjuti sesuai prosedur Satgas PPKPT dan korban telah mendapatkan perlindungan penuh.',
          ),
        ],
      ),
    ];
  }

  Future<List<UserComplaint>> _getLocalComplaints() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_localComplaintsKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          return decoded
              .whereType<Map>()
              .map((e) => UserComplaint.fromJson(Map<String, dynamic>.from(e)))
              .toList();
        }
      }
      final defaults = _defaultSeedComplaints();
      await _saveLocalComplaints(defaults);
      return defaults;
    } catch (_) {
      return _defaultSeedComplaints();
    }
  }

  Future<void> _saveLocalComplaints(List<UserComplaint> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _localComplaintsKey,
        jsonEncode(items.map((e) => e.toJson()).toList()),
      );
    } catch (_) {}
  }

  /// Mengambil data `/user/dashboard`.
  Future<UserDashboardData> getDashboardData() async {
    try {
      final res = await ApiClient.instance.dio.get('/user/dashboard');
      final body = res.data;
      if (body is Map && body['success'] == true && body['data'] is Map) {
        final d = Map<String, dynamic>.from(body['data'] as Map);
        final stats = d['stats'] is Map
            ? Map<String, dynamic>.from(d['stats'] as Map)
            : <String, dynamic>{};

        final recentList = <UserComplaint>[];
        if (d['recent_complaints'] is List) {
          for (final item in d['recent_complaints'] as List) {
            if (item is Map) {
              recentList.add(
                UserComplaint.fromJson(Map<String, dynamic>.from(item)),
              );
            }
          }
        }

        CounselingScheduleItem? upcoming;
        if (d['upcoming_schedule'] is Map) {
          upcoming = CounselingScheduleItem.fromJson(
            Map<String, dynamic>.from(d['upcoming_schedule'] as Map),
          );
        }

        final articlesList = <Article>[];
        if (d['recent_articles'] is List) {
          for (final a in d['recent_articles'] as List) {
            if (a is Map) {
              articlesList.add(
                Article.fromJson(Map<String, dynamic>.from(a)),
              );
            }
          }
        }

        final contact = d['satgas_contact'] is Map
            ? Map<String, dynamic>.from(d['satgas_contact'] as Map)
            : <String, dynamic>{};

        return UserDashboardData(
          total: (stats['total'] as num?)?.toInt() ?? recentList.length,
          processing: (stats['processing'] as num?)?.toInt() ?? 0,
          completed: (stats['completed'] as num?)?.toInt() ?? 0,
          recentComplaints: recentList,
          upcomingSchedule: upcoming,
          recentArticles: articlesList.isNotEmpty
              ? articlesList
              : await ArticleService.instance.getPublicArticles(limit: 4),
          satgasPhone: contact['phone']?.toString().isNotEmpty == true
              ? contact['phone'].toString()
              : '+62 812-3456-7890',
          satgasEmail: contact['email']?.toString().isNotEmpty == true
              ? contact['email'].toString()
              : 'satgas.ppkpt@polije.ac.id',
          satgasLocation: contact['location']?.toString().isNotEmpty == true
              ? contact['location'].toString()
              : 'Gedung Rektorat Lt. 1, Politeknik Negeri Jember',
        );
      }
    } catch (_) {}

    // Fallback ke penyimpanan lokal + seeder
    final complaints = await _getLocalComplaints();
    final articles = await ArticleService.instance.getPublicArticles(limit: 4);
    final processingCount = complaints
        .where((c) => c.status == 'pending' || c.status == 'approved')
        .length;
    final completedCount =
        complaints.where((c) => c.status == 'completed').length;

    CounselingScheduleItem? upcoming;
    for (final c in complaints) {
      for (final s in c.schedules) {
        if (s.status == 'approved' || s.status == 'pending') {
          upcoming = s;
          break;
        }
      }
      if (upcoming != null) break;
    }

    return UserDashboardData(
      total: complaints.length,
      processing: processingCount,
      completed: completedCount,
      recentComplaints: complaints.take(5).toList(),
      upcomingSchedule: upcoming,
      recentArticles: articles,
      satgasPhone: '+62 812-3456-7890',
      satgasEmail: 'satgas.ppkpt@polije.ac.id',
      satgasLocation: 'Gedung Rektorat Lt. 1, Politeknik Negeri Jember',
    );
  }

  /// Mengambil daftar kategori kekerasan (`/user/categories`).
  Future<List<ViolenceCategoryItem>> getCategories() async {
    try {
      final res = await ApiClient.instance.dio.get('/user/categories');
      final Object? body = res.data;
      final rawList = (body is Map && body['data'] is List)
          ? body['data'] as List
          : (body is List ? body : null);
      if (rawList != null && rawList.isNotEmpty) {
        return rawList
            .whereType<Map>()
            .map((e) =>
                ViolenceCategoryItem.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    } catch (_) {}
    return _seedCategories;
  }

  /// Mengambil slot jam yang sudah dipesan pada tanggal tertentu (`/public/booked-slots`).
  Future<List<String>> getBookedSlots(String date) async {
    try {
      final res = await ApiClient.instance.dio.get(
        '/public/booked-slots',
        queryParameters: {'date': date},
      );
      final Object? body = res.data;
      if (body is Map && body['data'] is List) {
        return (body['data'] as List).map((e) => e.toString()).toList();
      }
    } catch (_) {}
    return const [];
  }

  /// Mengambil histori pengaduan mahasiswa (`/user/complaints`).
  Future<List<UserComplaint>> getHistoriPengaduan({
    String search = '',
    String status = '',
  }) async {
    try {
      final res = await ApiClient.instance.dio.get(
        '/user/complaints',
        queryParameters: {
          'per_page': 50,
          'page': 1,
          if (search.trim().isNotEmpty) 'search': search.trim(),
          if (status.trim().isNotEmpty) 'status': status.trim(),
        },
      );
      final Object? body = res.data;
      final rawList = (body is Map && body['data'] is List)
          ? body['data'] as List
          : (body is List ? body : null);
      if (rawList != null) {
        return rawList
            .whereType<Map>()
            .map((e) => UserComplaint.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    } catch (_) {}

    final all = await _getLocalComplaints();
    return all.where((item) {
      final matchStatus = status.isEmpty || item.status == status;
      final q = search.trim().toLowerCase();
      final matchSearch = q.isEmpty ||
          item.title.toLowerCase().contains(q) ||
          item.reportReference.toLowerCase().contains(q) ||
          item.categoryName.toLowerCase().contains(q);
      return matchStatus && matchSearch;
    }).toList();
  }

  /// Mengambil detail pengaduan berdasarkan ID (`/user/complaints/{id}`).
  Future<UserComplaint?> getDetailPengaduan(int id) async {
    try {
      final res = await ApiClient.instance.dio.get('/user/complaints/$id');
      final Object? body = res.data;
      final dataMap = (body is Map && body['data'] is Map)
          ? Map<String, dynamic>.from(body['data'] as Map)
          : (body is Map ? Map<String, dynamic>.from(body) : null);

      if (dataMap != null && dataMap['id'] != null) {
        var complaint = UserComplaint.fromJson(dataMap);
        try {
          final schedRes = await ApiClient.instance.dio.get(
            '/user/counseling-schedule',
            queryParameters: {'complaint_id': id},
          );
          final Object? sBody = schedRes.data;
          final rawSched = (sBody is Map && sBody['data'] is List)
              ? sBody['data'] as List
              : (sBody is Map &&
                      sBody['data'] is Map &&
                      (sBody['data'] as Map)['data'] is List)
                  ? (sBody['data'] as Map)['data'] as List
                  : null;
          if (rawSched != null && rawSched.isNotEmpty) {
            final parsedSchedules = rawSched
                .whereType<Map>()
                .map((e) => CounselingScheduleItem.fromJson(
                    Map<String, dynamic>.from(e)))
                .toList();
            complaint = UserComplaint(
              id: complaint.id,
              reportReference: complaint.reportReference,
              title: complaint.title,
              status: complaint.status,
              urgencyLevel: complaint.urgencyLevel,
              categoryId: complaint.categoryId,
              categoryName: complaint.categoryName,
              counselorName: complaint.counselorName,
              victimType: complaint.victimType,
              victimName: complaint.victimName,
              victimGender: complaint.victimGender,
              victimRelationship: complaint.victimRelationship,
              suspectName: complaint.suspectName,
              suspectStatus: complaint.suspectStatus,
              suspectAffiliation: complaint.suspectAffiliation,
              chronology: complaint.chronology,
              location: complaint.location,
              incidentDate: complaint.incidentDate,
              latitude: complaint.latitude,
              longitude: complaint.longitude,
              rejectionReason: complaint.rejectionReason,
              proposedDate: complaint.proposedDate,
              proposedTime: complaint.proposedTime,
              createdAt: complaint.createdAt,
              attachments: complaint.attachments,
              schedules: parsedSchedules,
            );
          }
        } catch (_) {}
        return complaint;
      }
    } catch (_) {}

    final list = await _getLocalComplaints();
    for (final item in list) {
      if (item.id == id) return item;
    }
    return list.isNotEmpty ? list.first : null;
  }

  /// Mengirim laporan baru (`/user/reports` di `buat-laporan.jsx`).
  /// Mengembalikan nomor registrasi laporan (`report_id`).
  Future<String> submitReport({
    required String title,
    required String categoryId,
    required String categoryName,
    required String victimType,
    required String victimGender,
    String? victimName,
    String? victimRelationship,
    String? victimStatus,
    required String suspectName,
    required String suspectGender,
    required String suspectStatus,
    required String suspectAffiliation,
    String? suspectPhone,
    String? suspectNimNip,
    required String chronology,
    required String location,
    required String incidentDate,
    required String guestPhone,
    required String guestEmail,
    String? guestNim,
    String? guestProdi,
    String? guestUnit,
    required String reporterGender,
    required String reporterStatus,
    required String reporterPobDob,
    required String reporterAddress,
    required List<String> alasanPengaduan,
    required String proposedDate,
    required String proposedTime,
    List<String> attachmentNames = const [],
  }) async {
    try {
      final formMap = <String, dynamic>{
        'title': title,
        'violence_category_id': categoryId,
        'victim_type': victimType,
        'victim_gender': victimGender,
        if (victimType == 'other') ...{
          'victim_name': victimName ?? '',
          'victim_relationship': victimRelationship ?? '',
          'is_external_victim': '0',
        },
        'suspect_name': suspectName,
        'suspect_gender': suspectGender,
        'suspect_status': suspectStatus,
        'suspect_affiliation': suspectAffiliation,
        'suspect_phone': suspectPhone ?? '',
        'description': chronology,
        'chronology': chronology,
        'location': location,
        'incident_date': incidentDate,
        'guest_phone': guestPhone,
        'guest_email': guestEmail,
        'guest_nim': ?guestNim,
        'guest_prodi': ?guestProdi,
        'guest_unit': ?guestUnit,
        'reporter_pob_dob': reporterPobDob,
        'reporter_address': reporterAddress,
        if (suspectNimNip != null && suspectNimNip.isNotEmpty)
          'suspect_nim_nip': suspectNimNip,
        'alasan_pengaduan[]': alasanPengaduan,
        'reporter_gender': reporterGender,
        'reporter_status': reporterStatus,
        'victim_status':
            victimType == 'self' ? reporterStatus : (victimStatus ?? ''),
        'proposed_date': proposedDate,
        'proposed_time': proposedTime,
      };

      final res = await ApiClient.instance.dio.post(
        '/user/reports',
        data: FormData.fromMap(formMap),
      );
      final body = res.data;
      if (body is Map) {
        final data = body['data'];
        if (data is Map && data['report_id'] != null) {
          return data['report_id'].toString();
        }
      }
    } catch (_) {}

    // Simpan ke penyimpanan lokal agar langsung tampil di Dashboard & Histori
    final current = await _getLocalComplaints();
    final newId = 100 + current.length + 1;
    final refCode =
        'LP-${DateTime.now().year}-${newId.toString().padLeft(4, '0')}';
    final endHour =
        (int.tryParse(proposedTime.split(':').first) ?? 9) + 1;
    final endStr = '${endHour.toString().padLeft(2, '0')}:00:00';

    final newComplaint = UserComplaint(
      id: newId,
      reportReference: refCode,
      title: title,
      status: 'pending',
      urgencyLevel: 'medium',
      categoryId: categoryId,
      categoryName: categoryName,
      counselorName: 'Siti Konselor',
      victimType: victimType,
      victimName: victimType == 'self'
          ? (AuthService.instance.user?.name ?? 'Pelapor')
          : victimName,
      victimGender: victimGender,
      victimRelationship: victimRelationship,
      suspectName: suspectName,
      suspectStatus: suspectStatus,
      suspectAffiliation: suspectAffiliation,
      chronology: chronology,
      location: location,
      incidentDate: incidentDate,
      proposedDate: proposedDate,
      proposedTime: proposedTime,
      createdAt: DateTime.now(),
      attachments: [
        for (int i = 0; i < attachmentNames.length; i++)
          ComplaintAttachmentItem(
            id: i + 1,
            fileName: attachmentNames[i],
            filePath: attachmentNames[i],
          ),
      ],
      schedules: [
        CounselingScheduleItem(
          id: 500 + newId,
          complaintId: newId.toString(),
          tanggal: proposedDate,
          jamMulai: '$proposedTime:00',
          jamSelesai: endStr,
          metode: 'offline',
          lokasi: 'Gedung Rektorat Lt. 1, Politeknik Negeri Jember',
          status: 'pending',
          counselorName: 'Siti Konselor',
          counseleeType: 'pelapor',
          counseleeName: AuthService.instance.user?.name ?? 'Pelapor',
        ),
      ],
    );

    await _saveLocalComplaints([newComplaint, ...current]);
    return refCode;
  }

  /// Mengambil daftar Satgas Pendamping (`/counseling/counselors`).
  Future<List<CounselorOption>> getCounselors() async {
    try {
      final res = await ApiClient.instance.dio.get('/counseling/counselors');
      final body = res.data;
      if (body is Map && body['success'] == true && body['data'] is List) {
        final list = (body['data'] as List)
            .whereType<Map>()
            .map((e) => CounselorOption.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        if (list.isNotEmpty) return list;
      }
    } catch (_) {}
    return _seedCounselors;
  }

  /// Mengambil slot waktu tersedia untuk Satgas & tanggal (`/counseling/available-slots`).
  Future<List<TimeSlotOption>> getAvailableSlots(
    int counselorId,
    String tanggal,
  ) async {
    try {
      final res = await ApiClient.instance.dio.get(
        '/counseling/available-slots',
        queryParameters: {
          'counselor_id': counselorId,
          'tanggal': tanggal,
        },
      );
      final body = res.data;
      if (body is Map &&
          body['success'] == true &&
          body['data'] is Map &&
          (body['data'] as Map)['slots'] is List) {
        return ((body['data'] as Map)['slots'] as List)
            .whereType<Map>()
            .map((e) => TimeSlotOption.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    } catch (_) {}

    // Fallback slot jam kerja 08:00 - 16:00
    const hours = [
      ['08:00', '09:00'],
      ['09:00', '10:00'],
      ['10:00', '11:00'],
      ['11:00', '12:00'],
      ['13:00', '14:00'],
      ['14:00', '15:00'],
      ['15:00', '16:00'],
    ];
    return [
      for (final pair in hours)
        TimeSlotOption(
          jamMulai: pair[0],
          jamSelesai: pair[1],
          display: '${pair[0]} - ${pair[1]} WIB',
          available: true,
        ),
    ];
  }

  /// Mengajukan jadwal penanganan baru (`/counseling/request`).
  Future<bool> requestCounselingSchedule({
    required int counselorId,
    required String counselorName,
    String? complaintId,
    String? jenisPengaduan,
    required String tanggal,
    required String jamMulai,
    required String jamSelesai,
    required String metode,
    String? lokasi,
    String? meetingLink,
  }) async {
    try {
      final res = await ApiClient.instance.dio.post(
        '/counseling/request',
        data: {
          'counselor_id': counselorId,
          'complaint_id':
              (complaintId != null && complaintId.isNotEmpty) ? complaintId : null,
          'jenis_pengaduan': jenisPengaduan ?? '',
          'tanggal': tanggal,
          'jam_mulai': jamMulai,
          'jam_selesai': jamSelesai,
          'metode': metode,
          'lokasi': metode == 'offline' ? lokasi : null,
          'meeting_link': metode == 'online' ? meetingLink : null,
        },
      );
      if (res.data is Map && (res.data as Map)['success'] == true) {
        return true;
      }
    } catch (_) {}

    // Simpan jadwal ke complaint lokal terbaru agar muncul di Dashboard
    final complaints = await _getLocalComplaints();
    final newSchedule = CounselingScheduleItem(
      id: Random().nextInt(900) + 600,
      complaintId: complaintId,
      tanggal: tanggal,
      jamMulai: jamMulai,
      jamSelesai: jamSelesai,
      metode: metode,
      lokasi: lokasi ?? 'Ruang Satgas PPKPT Gedung Rektorat Lt. 1',
      meetingLink: meetingLink,
      status: 'approved',
      counselorName: counselorName,
      counseleeType: 'pelapor',
      counseleeName: AuthService.instance.user?.name ?? 'Mahasiswa',
    );

    if (complaints.isNotEmpty) {
      final first = complaints.first;
      final updatedFirst = UserComplaint(
        id: first.id,
        reportReference: first.reportReference,
        title: first.title,
        status: first.status,
        urgencyLevel: first.urgencyLevel,
        categoryId: first.categoryId,
        categoryName: first.categoryName,
        counselorName: counselorName,
        victimType: first.victimType,
        victimName: first.victimName,
        victimGender: first.victimGender,
        victimRelationship: first.victimRelationship,
        suspectName: first.suspectName,
        suspectStatus: first.suspectStatus,
        suspectAffiliation: first.suspectAffiliation,
        chronology: first.chronology,
        location: first.location,
        incidentDate: first.incidentDate,
        latitude: first.latitude,
        longitude: first.longitude,
        rejectionReason: first.rejectionReason,
        proposedDate: first.proposedDate,
        proposedTime: first.proposedTime,
        createdAt: first.createdAt,
        attachments: first.attachments,
        schedules: [newSchedule, ...first.schedules],
      );
      complaints[0] = updatedFirst;
      await _saveLocalComplaints(complaints);
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localSchedulesKey, jsonEncode(newSchedule.toJson()));
    }
    return true;
  }

  /// Generate link meeting online sesuai `counselingService.generateMeetingLink()`.
  String generateMeetingLink() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final rnd = Random();
    final id =
        List.generate(10, (_) => chars[rnd.nextInt(chars.length)]).join();
    return 'https://meet.polijecare.ac.id/$id';
  }

  /// Mengambil statistik kontribusi profil (`/profile/stats`).
  Future<Map<String, dynamic>> getProfileStats() async {
    try {
      final res = await ApiClient.instance.dio.get('/profile/stats');
      final body = res.data;
      if (body is Map && body['success'] == true && body['data'] is Map) {
        return Map<String, dynamic>.from(body['data'] as Map);
      }
    } catch (_) {}

    final role = AuthService.instance.user?.normalizedRole ?? 'user';
    if (role == 'user') {
      final list = await _getLocalComplaints();
      return {
        'total_contribution': list.length,
        'label': 'Total Laporan',
      };
    } else if (role == 'konselor') {
      return {
        'total_contribution': 12,
        'label': 'Kasus Ditangani',
      };
    }
    return {
      'total_contribution': 24,
      'label': 'Kontribusi Sistem',
    };
  }

  /// Memperbarui data profil (`PUT /profile` di `Profile.jsx`).
  Future<AppUser> updateProfile({
    required String name,
    required String phone,
    required String gender,
    required String unit,
    required String prodi,
    required String nim,
    required String semester,
    required String bio,
  }) async {
    final current = AuthService.instance.user;
    try {
      final res = await ApiClient.instance.dio.put(
        '/profile',
        data: {
          'name': name,
          'phone': phone,
          'gender': gender,
          'unit': unit,
          'prodi': prodi,
          'nim': nim,
          'semester': semester,
          'bio': bio,
        },
      );
      final body = res.data;
      if (body is Map && body['success'] == true && body['user'] is Map) {
        final updated = AppUser.fromJson(
          Map<String, dynamic>.from(body['user'] as Map),
        );
        await AuthService.instance.setUser(updated);
        return updated;
      }
    } catch (_) {}

    final updatedLocal = AppUser(
      id: current?.id ?? 4,
      name: name,
      email: current?.email ?? '2021001@student.polije.ac.id',
      role: current?.role ?? 'user',
      nim: nim,
      semester: semester,
      phone: phone,
      gender: gender,
      unit: unit,
      prodi: prodi,
      bio: bio,
      profilePhoto: current?.profilePhoto,
      avatar: current?.avatar,
    );
    await AuthService.instance.setUser(updatedLocal);
    return updatedLocal;
  }

  String getWhatsappConfirmUrl({
    required String reportId,
    required String reporterName,
    required String categoryName,
    required String title,
    required String proposedDate,
    required String proposedTime,
  }) {
    final message = '*KONFIRMASI LAPORAN POLIJECARE*\n\n'
        'Halo Satgas PPKPT Polije, saya telah mengirimkan laporan pengaduan melalui aplikasi PolijeCare.\n\n'
        '*Detail Laporan:*\n'
        '- *ID Laporan:* $reportId\n'
        '- *Nama Pelapor:* $reporterName\n'
        '- *Kategori:* $categoryName\n'
        '- *Judul:* $title\n\n'
        '*Usulan Jadwal Penanganan:*\n'
        '- *Tanggal:* $proposedDate\n'
        '- *Jam:* $proposedTime WIB\n\n'
        'Mohon bantuan untuk proses selanjutnya. Terima kasih.';
    return 'https://wa.me/${ApiConfig.confirmReportWhatsapp}?text=${Uri.encodeComponent(message)}';
  }
}

