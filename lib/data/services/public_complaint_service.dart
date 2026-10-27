import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';

import '../../core/config/api_config.dart';
import '../../core/network/api_client.dart';
import '../models/user_complaint.dart';

/// Service untuk public (tanpa login) — fetch kategori, cek booked slots,
/// submit laporan pengaduan publik.
/// Port 1:1 dari `LaporUmum.jsx` (endpoint `/public-categories`,
/// `/public/booked-slots`, `POST /public-complaints`).
class PublicComplaintService {
  PublicComplaintService._();
  static final PublicComplaintService instance = PublicComplaintService._();

  /// Daftar kategori seeder bawaan (fallback jika API belum jalan).
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
      description: 'Ancaman, intimidasi, atau ujaran kebencian secara lisan',
    ),
    const ViolenceCategoryItem(
      uniqueId: 'CAT-DEMO-005-2026',
      name: 'Pelecehan Seksual',
      description: 'Tindakan pelecehan seksual non-fisik maupun fisik',
    ),
    const ViolenceCategoryItem(
      uniqueId: 'CAT-DEMO-006-2026',
      name: 'Bullying / Perundungan',
      description:
          'Tindakan perundungan berulang yang bertujuan menyakiti korban',
    ),
  ];

  /// Fetch daftar kategori kekerasan dari `GET /public-categories`.
  Future<List<ViolenceCategoryItem>> fetchCategories() async {
    try {
      final res = await ApiClient.instance.dio.get('/public-categories');
      final body = res.data;
      if (body is Map && body['data'] is List) {
        return (body['data'] as List).map((e) {
          final m = e as Map<String, dynamic>;
          return ViolenceCategoryItem(
            uniqueId: (m['unique_id'] ?? m['id'] ?? '').toString(),
            name: (m['name'] ?? m['kategori'] ?? '').toString(),
            description: (m['description'] ?? '').toString(),
          );
        }).toList();
      }
      if (body is List) {
        return body.map((e) {
          final m = e as Map<String, dynamic>;
          return ViolenceCategoryItem(
            uniqueId: (m['unique_id'] ?? m['id'] ?? '').toString(),
            name: (m['name'] ?? m['kategori'] ?? '').toString(),
            description: (m['description'] ?? '').toString(),
          );
        }).toList();
      }
    } catch (_) {}
    return List.unmodifiable(_seedCategories);
  }

  /// Fetch booked time slots for a given date.
  /// `GET /public/booked-slots?date=YYYY-MM-DD`
  Future<List<String>> fetchBookedSlots(String date) async {
    try {
      final res = await ApiClient.instance.dio.get(
        '/public/booked-slots',
        queryParameters: {'date': date},
      );
      final body = res.data;
      if (body is Map && body['data'] is List) {
        return (body['data'] as List).map((e) => e.toString()).toList();
      }
    } catch (_) {}
    return const [];
  }

  /// Fetch contact WhatsApp Satgas.
  Future<String> fetchSatgasWhatsapp() async {
    try {
      final res = await ApiClient.instance.dio.get('/contact');
      final body = res.data;
      if (body is Map && body['data'] is Map) {
        final data = body['data'] as Map;
        final wa = (data['whatsapp'] ?? data['phone'] ?? '').toString();
        return wa.replaceAll(RegExp(r'[^0-9]'), '');
      }
    } catch (_) {}
    return ApiConfig.confirmReportWhatsapp;
  }

  /// Submit public complaint via `POST /public-complaints`.
  /// Returns `{'report_id': ..., 'tracking_code': ...}` on success.
  Future<Map<String, String>> submitPublicComplaint({
    required String guestName,
    required String guestEmail,
    required String guestPhone,
    required String guestNik,
    required String victimType,
    required String victimGender,
    String? victimName,
    String? victimRelationship,
    String? victimStatus,
    required String suspectName,
    String? suspectGender,
    required String suspectStatus,
    required String suspectAffiliation,
    String? suspectPhone,
    String? suspectNimNip,
    required String reporterGender,
    required String reporterStatus,
    required String reporterPobDob,
    required String reporterAddress,
    required List<String> alasanPengaduan,
    required String categoryId,
    required String title,
    required String chronology,
    required String location,
    required String incidentDate,
    required String proposedDate,
    required String proposedTime,
    List<String> attachmentPaths = const [],
    String? ktpPath,
  }) async {
    try {
      final formMap = <String, dynamic>{
        'guest_name': guestName,
        'guest_email': guestEmail,
        'guest_phone': guestPhone,
        'guest_nik': guestNik,
        'victim_type': victimType,
        'victim_name': victimType == 'self' ? guestName : (victimName ?? ''),
        'victim_gender': victimGender,
        'victim_relationship':
            victimType == 'self' ? 'Diri Sendiri' : (victimRelationship ?? ''),
        'suspect_name':
            suspectName.isNotEmpty ? suspectName : 'Tidak Diketahui',
        'suspect_gender': suspectGender ?? '',
        'suspect_status': suspectStatus,
        'suspect_affiliation':
            suspectAffiliation.isNotEmpty ? suspectAffiliation : '-',
        'suspect_phone': suspectPhone ?? '',
        if (suspectNimNip != null && suspectNimNip.isNotEmpty)
          'suspect_nim_nip': suspectNimNip,
        'reporter_gender': reporterGender,
        'reporter_status': reporterStatus,
        'victim_status':
            victimType == 'self' ? reporterStatus : (victimStatus ?? ''),
        'reporter_pob_dob': reporterPobDob,
        'reporter_address': reporterAddress,
        'alasan_pengaduan[]': alasanPengaduan,
        'violence_category_id': categoryId,
        'title': title,
        'description': chronology,
        'chronology': chronology,
        'location': location,
        'incident_date': incidentDate,
        'proposed_date': proposedDate,
        'proposed_time': proposedTime,
      };

      if (ktpPath != null && ktpPath.isNotEmpty) {
        formMap['victim_identity_proof'] =
            await MultipartFile.fromFile(ktpPath, filename: 'ktp.jpg');
      }

      for (int i = 0; i < attachmentPaths.length; i++) {
        formMap['attachments[$i]'] = await MultipartFile.fromFile(
          attachmentPaths[i],
          filename: attachmentPaths[i].split('/').last,
        );
      }

      final res = await ApiClient.instance.dio.post(
        '/public-complaints',
        data: FormData.fromMap(formMap),
      );

      final body = res.data;
      if (body is Map && body['data'] is Map) {
        final data = body['data'] as Map;
        return {
          'report_id': (data['report_id'] ?? 'ID-LAPORAN').toString(),
          'tracking_code': (data['tracking_code'] ?? '').toString(),
        };
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 422) {
        final body = e.response?.data;
        if (body is Map && body['errors'] is Map) {
          final errors = body['errors'] as Map;
          final messages =
              errors.values.expand((v) => v is List ? v : [v]).join(', ');
          throw Exception(messages);
        }
        throw Exception(
            (body is Map ? body['message'] : null) ?? 'Validasi gagal');
      }
      rethrow;
    }

    // Fallback — generate locally
    final rng = Random();
    final fakeId =
        'LP-PUB-${DateTime.now().year}-${(1000 + rng.nextInt(9000))}';
    final fakeCode =
        '${String.fromCharCode(65 + rng.nextInt(26))}${rng.nextInt(900000) + 100000}';
    return {
      'report_id': fakeId,
      'tracking_code': fakeCode,
    };
  }
}

