import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/network/api_client.dart';
import '../models/edu_material.dart';
import '../models/user_complaint.dart';
import 'auth_service.dart';
import 'user_portal_service.dart';

/// Model data anggota Satgas (Konselor).
class SatgasCounselor {
  const SatgasCounselor({
    required this.id,
    required this.name,
    required this.email,
    this.phone = '',
    this.unit = 'Satgas PPKPT Polije',
  });

  final int id;
  final String name;
  final String email;
  final String phone;
  final String unit;

  factory SatgasCounselor.fromJson(Map<String, dynamic> json) {
    return SatgasCounselor(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] ?? 'Satgas PPKPT').toString(),
      email: (json['email'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      unit: (json['unit'] ?? 'Satgas PPKPT Polije').toString(),
    );
  }
}

/// Model catatan perkembangan / jadwal sesi konseling pada detail kasus Satgas.
class SatgasSessionRecord {
  const SatgasSessionRecord({
    required this.id,
    this.complaintId,
    this.reportReference = '',
    this.complaintTitle = '',
    required this.counseleeName,
    this.counseleeType = 'pelapor',
    this.guestNim = '',
    this.guestEmail = '',
    this.guestPhone = '',
    this.counselorId = 2,
    this.counselorName = 'Dr. Siti Aminah, M.Psi.',
    this.counselorEmail = 'konselor@polije.ac.id',
    required this.jenisPengaduan,
    required this.tanggal,
    required this.jamMulai,
    required this.jamSelesai,
    this.metode = 'offline',
    this.lokasi = 'Ruang Satgas PPKPT Polije',
    this.meetingLink = '',
    this.status = 'approved',
    this.keteranganPihak = '',
    this.saranKonselor = '',
    this.feedbackAttachmentPath,
    this.isRecordOnly = false,
  });

  final int id;
  final int? complaintId;
  final String reportReference;
  final String complaintTitle;
  final String counseleeName;
  final String counseleeType;
  final String guestNim;
  final String guestEmail;
  final String guestPhone;
  final int counselorId;
  final String counselorName;
  final String counselorEmail;
  final String jenisPengaduan;
  final String tanggal; // YYYY-MM-DD
  final String jamMulai; // HH:mm
  final String jamSelesai; // HH:mm
  final String metode; // offline | online
  final String lokasi;
  final String meetingLink;
  final String status; // pending | approved | completed | rejected | cancelled
  final String keteranganPihak;
  final String saranKonselor;
  final String? feedbackAttachmentPath;
  final bool isRecordOnly;

  SatgasSessionRecord copyWith({
    String? status,
    String? keteranganPihak,
    String? saranKonselor,
    String? feedbackAttachmentPath,
    int? counselorId,
    String? counselorName,
    String? tanggal,
    String? jamMulai,
    String? jamSelesai,
  }) {
    return SatgasSessionRecord(
      id: id,
      complaintId: complaintId,
      reportReference: reportReference,
      complaintTitle: complaintTitle,
      counseleeName: counseleeName,
      counseleeType: counseleeType,
      guestNim: guestNim,
      guestEmail: guestEmail,
      guestPhone: guestPhone,
      counselorId: counselorId ?? this.counselorId,
      counselorName: counselorName ?? this.counselorName,
      counselorEmail: counselorEmail,
      jenisPengaduan: jenisPengaduan,
      tanggal: tanggal ?? this.tanggal,
      jamMulai: jamMulai ?? this.jamMulai,
      jamSelesai: jamSelesai ?? this.jamSelesai,
      metode: metode,
      lokasi: lokasi,
      meetingLink: meetingLink,
      status: status ?? this.status,
      keteranganPihak: keteranganPihak ?? this.keteranganPihak,
      saranKonselor: saranKonselor ?? this.saranKonselor,
      feedbackAttachmentPath:
          feedbackAttachmentPath ?? this.feedbackAttachmentPath,
      isRecordOnly: isRecordOnly,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'complaint_id': complaintId,
        'report_reference': reportReference,
        'complaint_title': complaintTitle,
        'counselee_name': counseleeName,
        'counselee_type': counseleeType,
        'guest_nim': guestNim,
        'guest_email': guestEmail,
        'guest_phone': guestPhone,
        'counselor_id': counselorId,
        'counselor_name': counselorName,
        'counselor_email': counselorEmail,
        'jenis_pengaduan': jenisPengaduan,
        'tanggal': tanggal,
        'jam_mulai': jamMulai,
        'jam_selesai': jamSelesai,
        'metode': metode,
        'lokasi': lokasi,
        'meeting_link': meetingLink,
        'status': status,
        'keterangan_pihak': keteranganPihak,
        'saran_konselor': saranKonselor,
        'feedback_attachment_path': feedbackAttachmentPath,
        'is_record_only': isRecordOnly,
      };

  factory SatgasSessionRecord.fromJson(Map<String, dynamic> json) {
    final comp = json['complaint'] is Map
        ? Map<String, dynamic>.from(json['complaint'] as Map)
        : null;
    final userMap = json['user'] is Map
        ? Map<String, dynamic>.from(json['user'] as Map)
        : null;
    final counsMap = json['counselor'] is Map
        ? Map<String, dynamic>.from(json['counselor'] as Map)
        : null;

    String rawDate = (json['tanggal'] ?? '').toString();
    if (rawDate.contains('T')) {
      rawDate = rawDate.split('T').first;
    } else if (rawDate.contains(' ')) {
      rawDate = rawDate.split(' ').first;
    }

    String normTime(Object? val, String fallback) {
      final s = (val ?? fallback).toString();
      return s.length >= 5 ? s.substring(0, 5) : fallback;
    }

    return SatgasSessionRecord(
      id: (json['id'] as num?)?.toInt() ?? 0,
      complaintId: (json['complaint_id'] as num?)?.toInt() ??
          (comp?['id'] as num?)?.toInt(),
      reportReference: (json['report_reference'] ??
              comp?['report_id'] ??
              comp?['report_reference'] ??
              '')
          .toString(),
      complaintTitle:
          (json['complaint_title'] ?? comp?['title'] ?? '').toString(),
      counseleeName: (json['counselee_name'] ??
              userMap?['name'] ??
              json['user_name'] ??
              comp?['user_name'] ??
              comp?['guest_name'] ??
              'Pelapor')
          .toString(),
      counseleeType: (json['counselee_type'] ?? 'pelapor').toString(),
      guestNim:
          (json['guest_nim'] ?? userMap?['nim'] ?? comp?['nim'] ?? '')
              .toString(),
      guestEmail:
          (json['guest_email'] ?? userMap?['email'] ?? comp?['user_email'] ?? '')
              .toString(),
      guestPhone:
          (json['guest_phone'] ?? userMap?['phone'] ?? comp?['user_phone'] ?? '')
              .toString(),
      counselorId: (json['counselor_id'] as num?)?.toInt() ??
          (counsMap?['id'] as num?)?.toInt() ??
          2,
      counselorName: (json['counselor_name'] ??
              counsMap?['name'] ??
              'Dr. Siti Aminah, M.Psi.')
          .toString(),
      counselorEmail: (json['counselor_email'] ??
              counsMap?['email'] ??
              'konselor@polije.ac.id')
          .toString(),
      jenisPengaduan: (json['jenis_pengaduan'] ??
              comp?['violence_category_name'] ??
              'Penanganan Satgas')
          .toString(),
      tanggal: rawDate,
      jamMulai: normTime(json['jam_mulai'], '09:00'),
      jamSelesai: normTime(json['jam_selesai'], '10:00'),
      metode: (json['metode'] ?? 'offline').toString(),
      lokasi: (json['lokasi'] ?? 'Ruang Satgas PPKPT Polije').toString(),
      meetingLink: (json['meeting_link'] ?? '').toString(),
      status: (json['status'] ?? 'approved').toString().toLowerCase(),
      keteranganPihak: (json['keterangan_pihak'] ?? '').toString(),
      saranKonselor: (json['saran_konselor'] ?? '').toString(),
      feedbackAttachmentPath: json['feedback_attachment_path']?.toString(),
      isRecordOnly: json['is_record_only'] == true ||
          json['is_record_only'] == 1 ||
          json['is_record_only'] == '1',
    );
  }
}

/// Model agenda eksternal kalender penanganan (`counseling_external_agendas`).
class ExternalCalendarAgenda {
  const ExternalCalendarAgenda({
    required this.id,
    required this.title,
    required this.date,
    required this.time,
    this.description = '',
  });

  final String id;
  final String title;
  final String date; // YYYY-MM-DD
  final String time; // HH:mm
  final String description;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'date': date,
        'time': time,
        'description': description,
      };

  factory ExternalCalendarAgenda.fromJson(Map<String, dynamic> json) {
    return ExternalCalendarAgenda(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      date: (json['date'] ?? '').toString(),
      time: (json['time'] ?? '09:00').toString(),
      description: (json['description'] ?? '').toString(),
    );
  }
}

/// Model data lengkap kasus untuk Konselor & Operator (`ComplaintDetail`).
class SatgasComplaintItem {
  const SatgasComplaintItem({
    required this.id,
    required this.reportId,
    required this.title,
    required this.description,
    required this.chronology,
    required this.status,
    required this.urgencyLevel,
    required this.categoryId,
    required this.categoryName,
    required this.victimType,
    required this.userName,
    required this.userEmail,
    required this.userPhone,
    required this.nimNip,
    required this.reporterPobDob,
    required this.reporterAddress,
    required this.reporterGender,
    required this.reporterStatus,
    required this.victimName,
    required this.victimGender,
    required this.victimStatus,
    required this.victimAffiliation,
    required this.suspectName,
    required this.suspectGender,
    required this.suspectStatus,
    required this.suspectNimNip,
    required this.suspectPhone,
    required this.suspectAffiliation,
    required this.location,
    required this.incidentDate,
    required this.createdAt,
    this.latitude,
    this.longitude,
    this.rejectionReason,
    this.alasanPengaduan = const [],
    this.counselorId,
    this.counselorName = 'Belum diplot',
    this.counselingSchedule,
    this.coCounselors = const [],
    this.coCounselorsList = const [],
    this.attachments = const [],
    this.counselingNotes = const [],
    this.victimIdentityProof,
  });

  final int id;
  final String reportId;
  final String title;
  final String description;
  final String chronology;
  final String status; // pending | approved | completed | rejected
  final String urgencyLevel; // low | medium | high | critical
  final String categoryId;
  final String categoryName;
  final String victimType; // self | other
  final String userName;
  final String userEmail;
  final String userPhone;
  final String nimNip;
  final String reporterPobDob;
  final String reporterAddress;
  final String reporterGender;
  final String reporterStatus;
  final String victimName;
  final String victimGender;
  final String victimStatus;
  final String victimAffiliation;
  final String suspectName;
  final String suspectGender;
  final String suspectStatus;
  final String suspectNimNip;
  final String suspectPhone;
  final String suspectAffiliation;
  final String location;
  final DateTime incidentDate;
  final DateTime createdAt;
  final double? latitude;
  final double? longitude;
  final String? rejectionReason;
  final List<String> alasanPengaduan;
  final int? counselorId;
  final String counselorName;
  final String? counselingSchedule;
  final List<int> coCounselors;
  final List<SatgasCounselor> coCounselorsList;
  final List<ComplaintAttachmentItem> attachments;
  final List<SatgasSessionRecord> counselingNotes;
  final String? victimIdentityProof;

  SatgasComplaintItem copyWith({
    String? status,
    String? urgencyLevel,
    String? rejectionReason,
    int? counselorId,
    String? counselorName,
    String? counselingSchedule,
    List<int>? coCounselors,
    List<SatgasCounselor>? coCounselorsList,
    List<SatgasSessionRecord>? counselingNotes,
  }) {
    return SatgasComplaintItem(
      id: id,
      reportId: reportId,
      title: title,
      description: description,
      chronology: chronology,
      status: status ?? this.status,
      urgencyLevel: urgencyLevel ?? this.urgencyLevel,
      categoryId: categoryId,
      categoryName: categoryName,
      victimType: victimType,
      userName: userName,
      userEmail: userEmail,
      userPhone: userPhone,
      nimNip: nimNip,
      reporterPobDob: reporterPobDob,
      reporterAddress: reporterAddress,
      reporterGender: reporterGender,
      reporterStatus: reporterStatus,
      victimName: victimName,
      victimGender: victimGender,
      victimStatus: victimStatus,
      victimAffiliation: victimAffiliation,
      suspectName: suspectName,
      suspectGender: suspectGender,
      suspectStatus: suspectStatus,
      suspectNimNip: suspectNimNip,
      suspectPhone: suspectPhone,
      suspectAffiliation: suspectAffiliation,
      location: location,
      incidentDate: incidentDate,
      createdAt: createdAt,
      latitude: latitude,
      longitude: longitude,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      alasanPengaduan: alasanPengaduan,
      counselorId: counselorId ?? this.counselorId,
      counselorName: counselorName ?? this.counselorName,
      counselingSchedule: counselingSchedule ?? this.counselingSchedule,
      coCounselors: coCounselors ?? this.coCounselors,
      coCounselorsList: coCounselorsList ?? this.coCounselorsList,
      attachments: attachments,
      counselingNotes: counselingNotes ?? this.counselingNotes,
      victimIdentityProof: victimIdentityProof,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'report_id': reportId,
        'title': title,
        'description': description,
        'chronology': chronology,
        'status': status,
        'urgency_level': urgencyLevel,
        'violence_category_id': categoryId,
        'violence_category_name': categoryName,
        'victim_type': victimType,
        'user_name': userName,
        'user_email': userEmail,
        'user_phone': userPhone,
        'nim': nimNip,
        'reporter_pob_dob': reporterPobDob,
        'reporter_address': reporterAddress,
        'reporter_gender': reporterGender,
        'reporter_status': reporterStatus,
        'victim_name': victimName,
        'victim_gender': victimGender,
        'victim_status': victimStatus,
        'user_affiliation': victimAffiliation,
        'suspect_name': suspectName,
        'suspect_gender': suspectGender,
        'suspect_status': suspectStatus,
        'suspect_nim_nip': suspectNimNip,
        'suspect_phone': suspectPhone,
        'suspect_affiliation': suspectAffiliation,
        'location': location,
        'incident_date': incidentDate.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
        'latitude': latitude,
        'longitude': longitude,
        'rejection_reason': rejectionReason,
        'alasan_pengaduan': alasanPengaduan,
        'counselor_id': counselorId,
        'counselor_name': counselorName,
        'counseling_schedule': counselingSchedule,
        'co_counselors': coCounselors,
        'co_counselors_list': coCounselorsList
            .map((e) => {'id': e.id, 'name': e.name, 'email': e.email})
            .toList(),
        'attachments': attachments
            .map((a) => {
                  'id': a.id,
                  'file_name': a.fileName,
                  'file_path': a.filePath,
                  'file_size': a.fileSize,
                })
            .toList(),
        'counseling_notes': counselingNotes.map((n) => n.toJson()).toList(),
        'victim_identity_proof': victimIdentityProof,
      };

  factory SatgasComplaintItem.fromJson(Map<String, dynamic> json) {
    final userMap = json['user'] is Map
        ? Map<String, dynamic>.from(json['user'] as Map)
        : null;
    final counsMap = json['counselor'] is Map
        ? Map<String, dynamic>.from(json['counselor'] as Map)
        : null;
    final catMap = json['category'] is Map
        ? Map<String, dynamic>.from(json['category'] as Map)
        : (json['violence_category'] is Map
            ? Map<String, dynamic>.from(json['violence_category'] as Map)
            : null);

    // Parse alasan_pengaduan
    List<String> parseAlasan(Object? raw) {
      if (raw == null) return const [];
      if (raw is List) {
        return raw.map((e) => e.toString().trim()).where((s) => s.isNotEmpty).toList();
      }
      final str = raw.toString().trim();
      if (str.isEmpty) return const [];
      if (str.startsWith('[')) {
        try {
          final decoded = jsonDecode(str);
          if (decoded is List) {
            return decoded
                .map((e) => e.toString().trim())
                .where((s) => s.isNotEmpty)
                .toList();
          }
        } catch (_) {}
      }
      return [str];
    }

    final rawCo = json['co_counselors'];
    final coIds = <int>[];
    if (rawCo is List) {
      for (final item in rawCo) {
        final parsed = int.tryParse(item.toString());
        if (parsed != null) coIds.add(parsed);
      }
    }

    final rawCoList = json['co_counselors_list'];
    final coList = <SatgasCounselor>[];
    if (rawCoList is List) {
      for (final item in rawCoList) {
        if (item is Map) {
          coList.add(
            SatgasCounselor.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }

    final rawAtt = json['attachments'];
    final attList = <ComplaintAttachmentItem>[];
    if (rawAtt is List) {
      for (final item in rawAtt) {
        if (item is Map) {
          attList.add(
            ComplaintAttachmentItem.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }

    final rawNotes = json['counseling_notes'] ?? json['schedules'];
    final notesList = <SatgasSessionRecord>[];
    if (rawNotes is List) {
      for (final item in rawNotes) {
        if (item is Map) {
          notesList.add(
            SatgasSessionRecord.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }

    return SatgasComplaintItem(
      id: (json['id'] as num?)?.toInt() ?? 101,
      reportId: (json['report_id'] ??
              json['report_reference'] ??
              'LAP-2026-${json['id'] ?? 101}')
          .toString(),
      title: (json['title'] ?? 'Laporan Pengaduan Satgas').toString(),
      description:
          (json['description'] ?? json['chronology'] ?? '').toString(),
      chronology:
          (json['chronology'] ?? json['description'] ?? '').toString(),
      status: (json['status'] ?? 'pending').toString().toLowerCase(),
      urgencyLevel:
          (json['urgency_level'] ?? 'medium').toString().toLowerCase(),
      categoryId: (json['violence_category_id'] ??
              catMap?['unique_id'] ??
              'CAT-01')
          .toString(),
      categoryName: (json['violence_category_name'] ??
              catMap?['name'] ??
              catMap?['kategori'] ??
              'Kekerasan Seksual')
          .toString(),
      victimType: (json['victim_type'] ?? 'self').toString(),
      userName: (json['user_name'] ??
              json['guest_name'] ??
              userMap?['name'] ??
              'Budi Santoso')
          .toString(),
      userEmail: (json['user_email'] ??
              json['guest_email'] ??
              userMap?['email'] ??
              'budi.santoso@student.polije.ac.id')
          .toString(),
      userPhone: (json['user_phone'] ??
              json['guest_phone'] ??
              userMap?['phone'] ??
              '081234567890')
          .toString(),
      nimNip: (json['guest_nim'] ??
              json['nim'] ??
              userMap?['nim'] ??
              userMap?['nip'] ??
              'E41221001')
          .toString(),
      reporterPobDob:
          (json['reporter_pob_dob'] ?? 'Jember, 14 Mei 2004').toString(),
      reporterAddress: (json['reporter_address'] ??
              'Jl. Mastrip Timur No. 42, Sumbersari, Jember')
          .toString(),
      reporterGender:
          (json['reporter_gender'] ?? json['victim_gender'] ?? 'Laki-laki')
              .toString(),
      reporterStatus:
          (json['reporter_status'] ?? json['victim_status'] ?? 'Mahasiswa')
              .toString(),
      victimName: (json['victim_name'] ??
              json['user_name'] ??
              userMap?['name'] ??
              'Budi Santoso')
          .toString(),
      victimGender: (json['victim_gender'] ?? 'Laki-laki').toString(),
      victimStatus: (json['victim_status'] ?? 'Mahasiswa').toString(),
      victimAffiliation: (json['user_affiliation'] ??
              userMap?['unit'] ??
              'Teknologi Informasi - Teknik Informatika')
          .toString(),
      suspectName: (json['suspect_name'] ?? 'Oknum Terlapor').toString(),
      suspectGender: (json['suspect_gender'] ?? 'Laki-laki').toString(),
      suspectStatus: (json['suspect_status'] ?? 'Mahasiswa').toString(),
      suspectNimNip: (json['suspect_nim_nip'] ?? '-').toString(),
      suspectPhone: (json['suspect_phone'] ?? '085711223344').toString(),
      suspectAffiliation:
          (json['suspect_affiliation'] ?? 'Teknologi Informasi').toString(),
      location:
          (json['location'] ?? 'Gedung Jurusan Teknologi Informasi Lt. 2')
              .toString(),
      incidentDate: DateTime.tryParse(
              (json['incident_date'] ?? '').toString()) ??
          DateTime.now().subtract(const Duration(days: 3)),
      createdAt:
          DateTime.tryParse((json['created_at'] ?? '').toString()) ??
              DateTime.now().subtract(const Duration(days: 2)),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      rejectionReason: json['rejection_reason']?.toString(),
      alasanPengaduan: parseAlasan(json['alasan_pengaduan']),
      counselorId: (json['counselor_id'] as num?)?.toInt() ??
          (counsMap?['id'] as num?)?.toInt(),
      counselorName: (json['counselor_name'] ??
              counsMap?['name'] ??
              'Dr. Siti Aminah, M.Psi.')
          .toString(),
      counselingSchedule: json['counseling_schedule']?.toString(),
      coCounselors: coIds,
      coCounselorsList: coList,
      attachments: attList,
      counselingNotes: notesList,
      victimIdentityProof: json['victim_identity_proof']?.toString(),
    );
  }
}

/// Service terpusat untuk seluruh menu Satgas / Konselor (`/konselor/*` & `/counseling/*`).
class KonselorPortalService {
  KonselorPortalService._();
  static final KonselorPortalService instance = KonselorPortalService._();

  static const String _kCasesStorageKey = 'polijecare_konselor_cases_v1';
  static const String _kSessionsStorageKey = 'polijecare_konselor_sessions_v1';
  static const String _kMaterialsStorageKey =
      'polijecare_konselor_materials_v1';
  static const String _kExternalAgendasKey = 'counseling_external_agendas';

  static const List<SatgasCounselor> _seedCounselors = [
    SatgasCounselor(
      id: 2,
      name: 'Dr. Siti Aminah, M.Psi.',
      email: 'konselor@polije.ac.id',
      phone: '081234560001',
    ),
    SatgasCounselor(
      id: 21,
      name: 'Dr. Hendra Wijaya, M.Psi., Psikolog',
      email: 'hendra.satgas@polije.ac.id',
      phone: '081234560002',
    ),
    SatgasCounselor(
      id: 22,
      name: 'Ns. Ratna Kusuma, S.Kep., M.Kes.',
      email: 'ratna.satgas@polije.ac.id',
      phone: '081234560003',
    ),
    SatgasCounselor(
      id: 23,
      name: 'Ahmad Fauzi, S.H., M.H.',
      email: 'fauzi.satgas@polije.ac.id',
      phone: '081234560004',
    ),
  ];

  List<SatgasSessionRecord> _buildDefaultSessions() {
    final now = DateTime.now();
    final todayStr = _fmtDate(now);
    final tomorrowStr = _fmtDate(now.add(const Duration(days: 1)));
    final next3DaysStr = _fmtDate(now.add(const Duration(days: 3)));
    final prev2DaysStr = _fmtDate(now.subtract(const Duration(days: 2)));

    return [
      SatgasSessionRecord(
        id: 501,
        complaintId: 101,
        reportReference: 'LAP-2026-0101',
        complaintTitle:
            'Laporan Intimidasi dan Pelecehan Verbal di Area Laboratorium',
        counseleeName: 'Budi Santoso',
        counseleeType: 'pelapor',
        guestNim: 'E41221001',
        guestEmail: 'budi.santoso@student.polije.ac.id',
        guestPhone: '081234567890',
        counselorId: 2,
        counselorName: 'Dr. Siti Aminah, M.Psi.',
        jenisPengaduan: 'Pelecehan Verbal & Psikis',
        tanggal: todayStr,
        jamMulai: '09:00',
        jamSelesai: '10:00',
        metode: 'offline',
        lokasi: 'Ruang Konseling Satgas PPKPT Gd. Rektorat Lt. 1',
        status: 'approved',
        keteranganPihak:
            'Pelapor menyampaikan kronologi awal intimidasi verbal saat kegiatan praktikum di laboratorium.',
        saranKonselor:
            'Pendampingan psikologis tahap awal dan pemanggilan saksi mata laboratorium.',
      ),
      SatgasSessionRecord(
        id: 502,
        complaintId: 103,
        reportReference: 'LAP-2026-0103',
        complaintTitle: 'Pengaduan Kekerasan Seksual Berbasis Elektronik (KSBE)',
        counseleeName: 'Nadia Putri Rahmawati',
        counseleeType: 'pelapor',
        guestNim: 'G41230812',
        guestEmail: 'nadia.putri@student.polije.ac.id',
        guestPhone: '085233445566',
        counselorId: 2,
        counselorName: 'Dr. Siti Aminah, M.Psi.',
        jenisPengaduan: 'Kekerasan Seksual',
        tanggal: tomorrowStr,
        jamMulai: '10:00',
        jamSelesai: '11:00',
        metode: 'online',
        lokasi: 'Google Meet Satgas PPKPT',
        meetingLink: 'https://meet.google.com/ppk-polije-care',
        status: 'approved',
        keteranganPihak:
            'Korban mengalami ancaman penyebaran tangkapan layar pribadi melalui media sosial.',
        saranKonselor:
            'Amankan seluruh bukti digital dan koordinasi dengan tim hukum Satgas PPKPT.',
      ),
      SatgasSessionRecord(
        id: 503,
        complaintId: 104,
        reportReference: 'LAP-2026-0104',
        complaintTitle: 'Laporan Perundungan (Bullying) Kegiatan Organisasi',
        counseleeName: 'Rizky Pratama',
        counseleeType: 'pelapor',
        guestNim: 'B32220419',
        guestEmail: 'rizky.pratama@student.polije.ac.id',
        guestPhone: '081355667788',
        counselorId: 2,
        counselorName: 'Dr. Siti Aminah, M.Psi.',
        jenisPengaduan: 'Perundungan (Bullying)',
        tanggal: next3DaysStr,
        jamMulai: '13:00',
        jamSelesai: '14:00',
        metode: 'offline',
        lokasi: 'Ruang Satgas PPKPT Polije',
        status: 'pending',
        keteranganPihak:
            'Permohonan jadwal konsultasi awal terkait tekanan psikis di lingkungan kepanitiaan.',
      ),
      SatgasSessionRecord(
        id: 504,
        complaintId: 102,
        reportReference: 'LAP-2026-0102',
        complaintTitle: 'Laporan Perundungan Siber di Grup Angkatan',
        counseleeName: 'Budi Santoso',
        counseleeType: 'pelapor',
        guestNim: 'E41221001',
        guestEmail: 'budi.santoso@student.polije.ac.id',
        guestPhone: '081234567890',
        counselorId: 2,
        counselorName: 'Dr. Siti Aminah, M.Psi.',
        jenisPengaduan: 'Perundungan (Bullying)',
        tanggal: prev2DaysStr,
        jamMulai: '10:00',
        jamSelesai: '11:00',
        metode: 'offline',
        lokasi: 'Ruang Konseling Satgas PPKPT Polije',
        status: 'completed',
        keteranganPihak:
            'Mediasi dan klarifikasi telah dilaksanakan bersama pihak terkait serta pembina kemahasiswaan.',
        saranKonselor:
            'Kasus dinyatakan selesai dengan penandatanganan Berita Acara Penyelesaian Kasus.',
        isRecordOnly: true,
      ),
    ];
  }

  List<SatgasComplaintItem> _buildDefaultCases() {
    final now = DateTime.now();
    final sessions = _buildDefaultSessions();
    return [
      SatgasComplaintItem(
        id: 101,
        reportId: 'LAP-2026-0101',
        title:
            'Laporan Intimidasi dan Pelecehan Verbal di Area Laboratorium',
        description:
            'Terjadi tindakan intimidasi dan ucapan bernada pelecehan verbal secara berulang saat jam praktikum berlangsung.',
        chronology:
            'Pada saat sesi praktikum sore pukul 15.30 WIB, terlapor melontarkan komentar tidak pantas di hadapan beberapa mahasiswa dan mengintimidasi pelapor agar tidak melaporkan kejadian tersebut.',
        status: 'approved',
        urgencyLevel: 'high',
        categoryId: 'CAT-02',
        categoryName: 'Pelecehan Verbal & Psikis',
        victimType: 'self',
        userName: 'Budi Santoso',
        userEmail: 'budi.santoso@student.polije.ac.id',
        userPhone: '081234567890',
        nimNip: 'E41221001',
        reporterPobDob: 'Jember, 14 Mei 2004',
        reporterAddress: 'Jl. Mastrip Timur No. 42, Sumbersari, Jember',
        reporterGender: 'Laki-laki',
        reporterStatus: 'Mahasiswa',
        victimName: 'Budi Santoso',
        victimGender: 'Laki-laki',
        victimStatus: 'Mahasiswa',
        victimAffiliation: 'Teknologi Informasi - Teknik Informatika',
        suspectName: 'Oknum Kakak Tingkat (Inisial R)',
        suspectGender: 'Laki-laki',
        suspectStatus: 'Mahasiswa',
        suspectNimNip: 'E41210992',
        suspectPhone: '085711223344',
        suspectAffiliation: 'Teknologi Informasi - Teknik Informatika',
        location: 'Gedung Jurusan Teknologi Informasi Lt. 2',
        incidentDate: now.subtract(const Duration(days: 4)),
        createdAt: now.subtract(const Duration(days: 3)),
        latitude: -8.15994,
        longitude: 113.72312,
        alasanPengaduan: const [
          'Saya seorang korban yang memerlukan bantuan pemulihan',
          'Saya ingin perguruan tinggi menindak tegas terlapor',
        ],
        counselorId: 2,
        counselorName: 'Dr. Siti Aminah, M.Psi.',
        counselingSchedule:
            '${_fmtDate(now)}T09:00',
        coCounselors: const [21],
        coCounselorsList: const [
          SatgasCounselor(
            id: 21,
            name: 'Dr. Hendra Wijaya, M.Psi., Psikolog',
            email: 'hendra.satgas@polije.ac.id',
            phone: '081234560002',
          ),
        ],
        attachments: const [
          ComplaintAttachmentItem(
            id: 1,
            fileName: 'tangkapan_layar_bukti_chat.png',
            filePath: 'complaints/bukti_chat.png',
            fileSize: 245760,
          ),
        ],
        counselingNotes: [sessions[0]],
      ),
      SatgasComplaintItem(
        id: 103,
        reportId: 'LAP-2026-0103',
        title: 'Pengaduan Kekerasan Seksual Berbasis Elektronik (KSBE)',
        description:
            'Pelapor menerima ancaman penyebaran foto pribadi dan pesan bernada seksual melalui aplikasi pesan instan.',
        chronology:
            'Sejak pekan lalu terlapor mengirimkan pesan beruntun di malam hari dan mengancam akan menyebarkan foto hasil rekayasa jika korban menolak bertemu.',
        status: 'pending',
        urgencyLevel: 'critical',
        categoryId: 'CAT-01',
        categoryName: 'Kekerasan Seksual',
        victimType: 'self',
        userName: 'Nadia Putri Rahmawati',
        userEmail: 'nadia.putri@student.polije.ac.id',
        userPhone: '085233445566',
        nimNip: 'G41230812',
        reporterPobDob: 'Banyuwangi, 22 Agustus 2005',
        reporterAddress: 'Jl. Kalimantan X No. 18, Sumbersari, Jember',
        reporterGender: 'Perempuan',
        reporterStatus: 'Mahasiswa',
        victimName: 'Nadia Putri Rahmawati',
        victimGender: 'Perempuan',
        victimStatus: 'Mahasiswa',
        victimAffiliation: 'Kesehatan - Rekam Medik',
        suspectName: 'Inisial D (Mahasiswa)',
        suspectGender: 'Laki-laki',
        suspectStatus: 'Mahasiswa',
        suspectNimNip: 'E41220311',
        suspectPhone: '089612345678',
        suspectAffiliation: 'Teknologi Informasi',
        location: 'Area Kampus Politeknik Negeri Jember / Media Sosial',
        incidentDate: now.subtract(const Duration(days: 2)),
        createdAt: now.subtract(const Duration(days: 1)),
        latitude: -8.15880,
        longitude: 113.72245,
        alasanPengaduan: const [
          'Saya seorang korban yang memerlukan bantuan pemulihan',
          'Saya ingin perguruan tinggi menindak tegas terlapor',
          'Saya ingin Satgas mendokumentasikan kejadian ini',
        ],
        counselorId: 2,
        counselorName: 'Dr. Siti Aminah, M.Psi.',
        counselingSchedule:
            '${_fmtDate(now.add(const Duration(days: 1)))}T10:00',
        coCounselors: const [22],
        coCounselorsList: const [
          SatgasCounselor(
            id: 22,
            name: 'Ns. Ratna Kusuma, S.Kep., M.Kes.',
            email: 'ratna.satgas@polije.ac.id',
            phone: '081234560003',
          ),
        ],
        attachments: const [
          ComplaintAttachmentItem(
            id: 2,
            fileName: 'bukti_ancaman_ksbe.pdf',
            filePath: 'complaints/bukti_ancaman_ksbe.pdf',
            fileSize: 512000,
          ),
        ],
        counselingNotes: [sessions[1]],
      ),
      SatgasComplaintItem(
        id: 104,
        reportId: 'LAP-2026-0104',
        title: 'Laporan Perundungan (Bullying) Kegiatan Organisasi',
        description:
            'Saksi melaporkan adanya tindakan perundungan verbal dan pengucilan terhadap anggota kepanitiaan baru.',
        chronology:
            'Saat rapat evaluasi pukul 19.00 WIB, beberapa pengurus senior melakukan bentakan dan penghinaan fisik di depan umum terhadap mahasiswa baru.',
        status: 'pending',
        urgencyLevel: 'medium',
        categoryId: 'CAT-04',
        categoryName: 'Perundungan (Bullying)',
        victimType: 'other',
        userName: 'Rizky Pratama',
        userEmail: 'rizky.pratama@student.polije.ac.id',
        userPhone: '081355667788',
        nimNip: 'B32220419',
        reporterPobDob: 'Bondowoso, 09 Januari 2004',
        reporterAddress: 'Jl. Jawa VII No. 11, Sumbersari, Jember',
        reporterGender: 'Laki-laki',
        reporterStatus: 'Mahasiswa',
        victimName: 'Dimas Aditya',
        victimGender: 'Laki-laki',
        victimStatus: 'Mahasiswa',
        victimAffiliation: 'Teknologi Pertanian',
        suspectName: 'Oknum Panitia Senior (Inisial K)',
        suspectGender: 'Laki-laki',
        suspectStatus: 'Mahasiswa',
        suspectNimNip: 'B32210114',
        suspectPhone: '082199887766',
        suspectAffiliation: 'Teknologi Pertanian',
        location: 'Sekretariat UKM / Gedung Kemahasiswaan',
        incidentDate: now.subtract(const Duration(days: 5)),
        createdAt: now.subtract(const Duration(days: 2)),
        alasanPengaduan: const [
          'Saya seorang saksi yang khawatir dengan keadaan korban',
        ],
        counselorId: 2,
        counselorName: 'Dr. Siti Aminah, M.Psi.',
        counselingSchedule:
            '${_fmtDate(now.add(const Duration(days: 3)))}T13:00',
        counselingNotes: [sessions[2]],
      ),
      SatgasComplaintItem(
        id: 102,
        reportId: 'LAP-2026-0102',
        title: 'Laporan Perundungan Siber di Grup Angkatan',
        description:
            'Penyebaran komentar merendahkan di grup pesan singkat angkatan yang berdampak pada kondisi psikologis pelapor.',
        chronology:
            'Pelapor mendapati adanya pesan berantai yang menyudutkan dirinya di grup diskusi kelas selama 3 hari berturut-turut.',
        status: 'completed',
        urgencyLevel: 'low',
        categoryId: 'CAT-04',
        categoryName: 'Perundungan (Bullying)',
        victimType: 'self',
        userName: 'Budi Santoso',
        userEmail: 'budi.santoso@student.polije.ac.id',
        userPhone: '081234567890',
        nimNip: 'E41221001',
        reporterPobDob: 'Jember, 14 Mei 2004',
        reporterAddress: 'Jl. Mastrip Timur No. 42, Sumbersari, Jember',
        reporterGender: 'Laki-laki',
        reporterStatus: 'Mahasiswa',
        victimName: 'Budi Santoso',
        victimGender: 'Laki-laki',
        victimStatus: 'Mahasiswa',
        victimAffiliation: 'Teknologi Informasi - Teknik Informatika',
        suspectName: 'Inisial A',
        suspectGender: 'Perempuan',
        suspectStatus: 'Mahasiswa',
        suspectNimNip: 'E41221088',
        suspectPhone: '081900112233',
        suspectAffiliation: 'Teknologi Informasi',
        location: 'Grup WhatsApp Kelas / Kampus Polije',
        incidentDate: now.subtract(const Duration(days: 20)),
        createdAt: now.subtract(const Duration(days: 18)),
        alasanPengaduan: const [
          'Saya ingin Satgas mendokumentasikan kejadian ini',
        ],
        counselorId: 2,
        counselorName: 'Dr. Siti Aminah, M.Psi.',
        counselingSchedule:
            '${_fmtDate(now.subtract(const Duration(days: 2)))}T10:00',
        counselingNotes: [sessions[3]],
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

  String _fmtDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<List<SatgasComplaintItem>> _getLocalCases() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kCasesStorageKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List && decoded.isNotEmpty) {
          return decoded
              .whereType<Map>()
              .map((e) =>
                  SatgasComplaintItem.fromJson(Map<String, dynamic>.from(e)))
              .toList();
        }
      }
      final defaults = _buildDefaultCases();
      await _saveLocalCases(defaults);
      return defaults;
    } catch (_) {
      return _buildDefaultCases();
    }
  }

  Future<void> _saveLocalCases(List<SatgasComplaintItem> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _kCasesStorageKey,
        jsonEncode(items.map((e) => e.toJson()).toList()),
      );
    } catch (_) {}
  }

  Future<List<SatgasSessionRecord>> _getLocalSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kSessionsStorageKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List && decoded.isNotEmpty) {
          return decoded
              .whereType<Map>()
              .map((e) =>
                  SatgasSessionRecord.fromJson(Map<String, dynamic>.from(e)))
              .toList();
        }
      }
      final defaults = _buildDefaultSessions();
      await _saveLocalSessions(defaults);
      return defaults;
    } catch (_) {
      return _buildDefaultSessions();
    }
  }

  Future<void> _saveLocalSessions(List<SatgasSessionRecord> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _kSessionsStorageKey,
        jsonEncode(items.map((e) => e.toJson()).toList()),
      );
    } catch (_) {}
  }

  Future<List<EduMaterial>> _getLocalMaterials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kMaterialsStorageKey);
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
        _kMaterialsStorageKey,
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

  /// GET `/konselor/dashboard` — Statistik ringkasan Dashboard Satgas.
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final res = await ApiClient.instance.dio.get('/konselor/dashboard');
      final Object? body = res.data;
      if (body is Map && body['success'] == true && body['data'] is Map) {
        return Map<String, dynamic>.from(body['data'] as Map);
      }
    } catch (_) {}

    final sessions = await _getLocalSessions();
    final materials = await _getLocalMaterials();
    final todayStr = _fmtDate(DateTime.now());

    final pending = sessions.where((s) => s.status == 'pending').length;
    final approved = sessions.where((s) => s.status == 'approved').length;
    final completed = sessions.where((s) => s.status == 'completed').length;
    final today = sessions
        .where((s) => s.tanggal == todayStr && s.status != 'cancelled')
        .length;
    final upcoming = sessions
        .where(
            (s) => s.tanggal.compareTo(todayStr) > 0 && s.status == 'approved')
        .length;

    return {
      'jadwal': {
        'pending': pending,
        'approved': approved,
        'completed': completed,
        'total': sessions.length,
        'today': today,
        'upcoming': upcoming,
      },
      'materi': materials.length,
    };
  }

  /// GET `/konselor/dashboard/report-category-distribution`
  Future<List<Map<String, dynamic>>> getCategoryDistribution({
    String year = '2026',
    String month = 'Semua',
  }) async {
    try {
      final res = await ApiClient.instance.dio.get(
        '/konselor/dashboard/report-category-distribution',
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

    final cases = await _getLocalCases();
    final counts = <String, int>{};
    for (final c in cases) {
      if (year != 'Semua' && c.createdAt.year.toString() != year) continue;
      if (month != 'Semua' && c.createdAt.month.toString() != month) continue;
      counts[c.categoryName] = (counts[c.categoryName] ?? 0) + 1;
    }
    if (counts.isEmpty) {
      return [
        {'kategori': 'Kekerasan Seksual', 'jumlah': 4},
        {'kategori': 'Pelecehan Verbal & Psikis', 'jumlah': 3},
        {'kategori': 'Perundungan (Bullying)', 'jumlah': 2},
        {'kategori': 'Kekerasan Fisik', 'jumlah': 1},
      ];
    }
    final list = counts.entries
        .map((e) => {'kategori': e.key, 'jumlah': e.value})
        .toList();
    list.sort((a, b) => (b['jumlah'] as int).compareTo(a['jumlah'] as int));
    return list;
  }

  /// GET `/konselor/dashboard/gender-distribution`
  Future<Map<String, dynamic>> getGenderDistribution({
    String year = '2026',
    String month = 'Semua',
  }) async {
    try {
      final res = await ApiClient.instance.dio.get(
        '/konselor/dashboard/gender-distribution',
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

    return {
      'terlapor': {
        'gender': [
          {'name': 'Laki-laki', 'value': 7},
          {'name': 'Perempuan', 'value': 1},
        ],
        'status': [
          {'name': 'Mahasiswa', 'value': 6},
          {'name': 'Dosen', 'value': 1},
          {'name': 'Pihak Luar', 'value': 1},
        ],
      },
      'pelapor': {
        'gender': [
          {'name': 'Perempuan', 'value': 5},
          {'name': 'Laki-laki', 'value': 3},
        ],
        'status': [
          {'name': 'Mahasiswa', 'value': 7},
          {'name': 'Tenaga Pendidik', 'value': 1},
        ],
      },
      'korban': {
        'gender': [
          {'name': 'Perempuan', 'value': 6},
          {'name': 'Laki-laki', 'value': 2},
        ],
        'status': [
          {'name': 'Mahasiswa', 'value': 8},
        ],
      },
    };
  }

  /// GET `/konselor/dashboard/department-distribution`
  Future<List<Map<String, dynamic>>> getDepartmentDistribution({
    String year = '2026',
    String month = 'Semua',
  }) async {
    try {
      final res = await ApiClient.instance.dio.get(
        '/konselor/dashboard/department-distribution',
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

    return [
      {'name': 'Teknologi Informasi', 'value': 4},
      {'name': 'Kesehatan', 'value': 3},
      {'name': 'Teknologi Pertanian', 'value': 2},
      {'name': 'Manajemen Agribisnis', 'value': 1},
    ];
  }

  /// GET `/counseling/counselors` — Daftar anggota Satgas (Konselor).
  Future<List<SatgasCounselor>> getCounselors() async {
    try {
      final res = await ApiClient.instance.dio.get('/counseling/counselors');
      final Object? body = res.data;
      final rawList = (body is Map && body['data'] is List)
          ? body['data'] as List
          : (body is List ? body : null);
      if (rawList != null && rawList.isNotEmpty) {
        return rawList
            .whereType<Map>()
            .map((e) =>
                SatgasCounselor.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    } catch (_) {}
    return _seedCounselors;
  }

  /// Mengambil statistik gabungan untuk halaman Manajemen Kasus (`/counseling/statistics` + `/konselor/complaints-stats`).
  Future<Map<String, int>> getCaseManagementStats() async {
    try {
      final results = await Future.wait([
        ApiClient.instance.dio.get('/counseling/statistics'),
        ApiClient.instance.dio.get('/konselor/complaints-stats'),
      ]);
      final Object? sBody = results[0].data;
      final Object? cBody = results[1].data;
      if (sBody is Map &&
          sBody['data'] is Map &&
          cBody is Map &&
          cBody['data'] is Map) {
        final sMap = Map<String, dynamic>.from(sBody['data'] as Map);
        final cMap = Map<String, dynamic>.from(cBody['data'] as Map);
        return {
          'total': (cMap['total'] as num?)?.toInt() ?? 0,
          'pending': (cMap['pending'] as num?)?.toInt() ?? 0,
          'approved': (cMap['approved'] as num?)?.toInt() ?? 0,
          'archived': (cMap['archived'] as num?)?.toInt() ?? 0,
          'today': (sMap['today'] as num?)?.toInt() ?? 0,
          'upcoming': (sMap['upcoming'] as num?)?.toInt() ?? 0,
          'completed': (sMap['completed'] as num?)?.toInt() ?? 0,
        };
      }
    } catch (_) {}

    final cases = await _getLocalCases();
    final sessions = await _getLocalSessions();
    final todayStr = _fmtDate(DateTime.now());

    return {
      'total': cases.length,
      'pending': cases.where((c) => c.status == 'pending').length,
      'approved': cases.where((c) => c.status == 'approved').length,
      'archived': cases
          .where((c) =>
              c.status == 'completed' ||
              c.status == 'rejected' ||
              c.status == 'cancelled')
          .length,
      'today': sessions
          .where((s) => s.tanggal == todayStr && s.status == 'approved')
          .length,
      'upcoming': sessions
          .where(
              (s) => s.tanggal.compareTo(todayStr) > 0 && s.status == 'approved')
          .length,
      'completed': cases.where((c) => c.status == 'completed').length,
    };
  }

  /// Mengambil daftar kasus Satgas berdasarkan filter & tab (`/konselor/complaints`).
  Future<List<SatgasComplaintItem>> getComplaints({
    String tab = 'all', // all | new | active | archive
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
        '/konselor/complaints',
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

    final all = await _getLocalCases();
    final q = search.trim().toLowerCase();
    return all.where((item) {
      if (tab == 'new' && item.status != 'pending') return false;
      if (tab == 'active' && item.status != 'approved') return false;
      if (tab == 'archive') {
        if (status != 'all') {
          if (item.status != status) return false;
        } else if (item.status != 'completed' &&
            item.status != 'rejected' &&
            item.status != 'cancelled') {
          return false;
        }
      } else if (status != 'all' && item.status != status) {
        return false;
      }

      if (urgency != 'all' && item.urgencyLevel != urgency) return false;

      if (q.isNotEmpty) {
        final match = item.reportId.toLowerCase().contains(q) ||
            item.title.toLowerCase().contains(q) ||
            item.userName.toLowerCase().contains(q) ||
            item.location.toLowerCase().contains(q) ||
            item.categoryName.toLowerCase().contains(q);
        if (!match) return false;
      }
      return true;
    }).toList();
  }

  /// Mengambil daftar jadwal penanganan Satgas (`/konselor/jadwal`).
  Future<List<SatgasSessionRecord>> getSchedules({
    String tab = 'all', // all | today | upcoming
    String search = '',
    String status = 'all',
    String metode = 'all',
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
        if (metode != 'all') 'metode': metode,
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
        '/konselor/jadwal',
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

    final all = await _getLocalSessions();
    final q = search.trim().toLowerCase();
    return all.where((s) {
      if (tab == 'today') {
        if (s.tanggal != todayStr || s.status != 'approved') return false;
      } else if (tab == 'upcoming') {
        if (s.tanggal.compareTo(tomorrowStr) < 0 || s.status != 'approved') {
          return false;
        }
      } else {
        if (status != 'all' && s.status != status) return false;
        if (dateFrom.isNotEmpty && s.tanggal.compareTo(dateFrom) < 0) {
          return false;
        }
        if (dateTo.isNotEmpty && s.tanggal.compareTo(dateTo) > 0) {
          return false;
        }
      }
      if (metode != 'all' && s.metode != metode) return false;
      if (q.isNotEmpty) {
        final match = s.counseleeName.toLowerCase().contains(q) ||
            s.jenisPengaduan.toLowerCase().contains(q) ||
            s.reportReference.toLowerCase().contains(q) ||
            s.lokasi.toLowerCase().contains(q);
        if (!match) return false;
      }
      return true;
    }).toList();
  }

  /// Detail 1 kasus lengkap (`/konselor/complaints/{id}`).
  Future<SatgasComplaintItem?> getComplaintDetail(
    int id, {
    bool isCounselor = true,
  }) async {
    try {
      final endpoint =
          isCounselor ? '/konselor/complaints/$id' : '/operator/complaints/$id';
      final res = await ApiClient.instance.dio.get(endpoint);
      final Object? body = res.data;
      if (body is Map && body['success'] == true && body['data'] is Map) {
        return SatgasComplaintItem.fromJson(
          Map<String, dynamic>.from(body['data'] as Map),
        );
      }
    } catch (_) {}

    final cases = await _getLocalCases();
    for (final c in cases) {
      if (c.id == id) return c;
    }
    return cases.isNotEmpty ? cases.first : null;
  }

  /// Update status atau tingkat urgensi laporan (`PATCH /konselor/complaints/{id}/status`).
  Future<bool> updateComplaintStatus(
    int id, {
    String? status,
    String? rejectionReason,
    String? urgencyLevel,
  }) async {
    final payload = <String, dynamic>{
      'status': ?status,
      'rejection_reason': ?rejectionReason,
      'urgency_level': ?urgencyLevel,
    };

    try {
      await ApiClient.instance.dio.patch(
        '/konselor/complaints/$id/status',
        data: payload,
      );
    } catch (_) {
      try {
        await ApiClient.instance.dio.patch(
          '/operator/complaints/$id/status',
          data: payload,
        );
      } catch (_) {}
    }

    final cases = await _getLocalCases();
    final updated = cases.map((c) {
      if (c.id == id) {
        return c.copyWith(
          status: status ?? c.status,
          rejectionReason: rejectionReason ?? c.rejectionReason,
          urgencyLevel: urgencyLevel ?? c.urgencyLevel,
        );
      }
      return c;
    }).toList();
    await _saveLocalCases(updated);
    return true;
  }

  /// Delegasi kasus & penjadwalan sesi pertama (`PATCH /konselor/complaints/{id}/schedule`).
  Future<bool> delegateOrScheduleComplaint(
    int id, {
    required int counselorId,
    required String counselingSchedule,
    List<int> coCounselors = const [],
  }) async {
    try {
      await ApiClient.instance.dio.patch(
        '/konselor/complaints/$id/schedule',
        data: {
          'counselor_id': counselorId,
          'counseling_schedule': counselingSchedule,
          'co_counselors': coCounselors,
        },
      );
    } catch (_) {}

    final counselors = await getCounselors();
    final mainCouns = counselors.firstWhere(
      (c) => c.id == counselorId,
      orElse: () => _seedCounselors.first,
    );
    final coList =
        counselors.where((c) => coCounselors.contains(c.id)).toList();

    final cases = await _getLocalCases();
    final updated = cases.map((c) {
      if (c.id == id) {
        return c.copyWith(
          status: c.status == 'pending' ? 'approved' : c.status,
          counselorId: counselorId,
          counselorName: mainCouns.name,
          counselingSchedule: counselingSchedule,
          coCounselors: coCounselors,
          coCounselorsList: coList,
        );
      }
      return c;
    }).toList();
    await _saveLocalCases(updated);
    return true;
  }

  /// Atur Tim Satgas: Klaim PJ Utama / Gabung / Keluar Tim (`PATCH /konselor/complaints/{id}/assign`).
  Future<bool> assignTeam(
    int id, {
    required int? counselorId,
    required List<int> coCounselors,
    bool isCounselor = true,
  }) async {
    try {
      final endpoint = isCounselor
          ? '/konselor/complaints/$id/assign'
          : '/operator/complaints/$id/assign';
      await ApiClient.instance.dio.patch(
        endpoint,
        data: {
          'counselor_id': counselorId,
          'co_counselors': coCounselors,
        },
      );
    } catch (_) {}

    final counselors = await getCounselors();
    final currentUser = AuthService.instance.user;
    String mainName = 'Belum diplot';
    if (counselorId != null) {
      final found = counselors.where((c) => c.id == counselorId);
      if (found.isNotEmpty) {
        mainName = found.first.name;
      } else if (currentUser != null && currentUser.id == counselorId) {
        mainName = currentUser.name;
      } else {
        mainName = 'Dr. Siti Aminah, M.Psi.';
      }
    }
    final coList = <SatgasCounselor>[];
    for (final cid in coCounselors) {
      final match = counselors.where((c) => c.id == cid);
      if (match.isNotEmpty) {
        coList.add(match.first);
      } else if (currentUser != null && currentUser.id == cid) {
        coList.add(
          SatgasCounselor(
            id: currentUser.id,
            name: currentUser.name,
            email: currentUser.email,
            phone: currentUser.phone ?? '',
          ),
        );
      }
    }

    final cases = await _getLocalCases();
    final updated = cases.map((c) {
      if (c.id == id) {
        return c.copyWith(
          counselorId: counselorId,
          counselorName: mainName,
          coCounselors: coCounselors,
          coCounselorsList: coList,
        );
      }
      return c;
    }).toList();
    await _saveLocalCases(updated);
    return true;
  }

  /// Tambah Catatan Perkembangan Baru atau Selesaikan Sesi Terjadwal.
  Future<bool> submitProgressNote({
    required int complaintId,
    int? activeSessionId,
    required String counseleeType,
    required String counseleeName,
    required String keteranganPihak,
    required String saranKonselor,
    String? attachmentName,
    List<int>? attachmentBytes,
  }) async {
    final now = DateTime.now();
    final todayStr = _fmtDate(now);
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    try {
      final map = <String, dynamic>{
        'keterangan_pihak': keteranganPihak,
        'saran_konselor': saranKonselor,
      };
      if (attachmentBytes != null &&
          attachmentName != null &&
          attachmentName.isNotEmpty) {
        map['feedback_attachment'] = MultipartFile.fromBytes(
          attachmentBytes,
          filename: attachmentName,
        );
      }
      String endpoint = '/konselor/jadwal';
      if (activeSessionId != null) {
        endpoint = '/konselor/jadwal/$activeSessionId/feedback';
      } else {
        map.addAll({
          'complaint_id': complaintId,
          'counselee_type': counseleeType,
          'counselee_name': counseleeName,
          'is_record_only': '1',
          'status': 'completed',
          'tanggal': todayStr,
          'jam_mulai': timeStr,
          'jam_selesai': timeStr,
        });
      }
      await ApiClient.instance.dio.post(
        endpoint,
        data: FormData.fromMap(map),
      );
    } catch (_) {}

    final user = AuthService.instance.user;
    final cases = await _getLocalCases();
    final sessions = await _getLocalSessions();

    if (activeSessionId != null) {
      final updatedSessions = sessions.map((s) {
        if (s.id == activeSessionId) {
          return s.copyWith(
            status: 'completed',
            keteranganPihak: keteranganPihak,
            saranKonselor: saranKonselor,
            feedbackAttachmentPath: attachmentName,
          );
        }
        return s;
      }).toList();
      await _saveLocalSessions(updatedSessions);

      final updatedCases = cases.map((c) {
        if (c.id == complaintId) {
          final updatedNotes = c.counselingNotes.map((n) {
            if (n.id == activeSessionId) {
              return n.copyWith(
                status: 'completed',
                keteranganPihak: keteranganPihak,
                saranKonselor: saranKonselor,
                feedbackAttachmentPath: attachmentName,
              );
            }
            return n;
          }).toList();
          return c.copyWith(counselingNotes: updatedNotes);
        }
        return c;
      }).toList();
      await _saveLocalCases(updatedCases);
    } else {
      final newId = DateTime.now().millisecondsSinceEpoch % 100000;
      final newNote = SatgasSessionRecord(
        id: newId,
        complaintId: complaintId,
        counseleeName: counseleeName.isNotEmpty ? counseleeName : 'Pelapor',
        counseleeType: counseleeType,
        counselorId: user?.id ?? 2,
        counselorName: user?.name ?? 'Dr. Siti Aminah, M.Psi.',
        jenisPengaduan: 'Catatan Perkembangan Kasus',
        tanggal: todayStr,
        jamMulai: timeStr,
        jamSelesai: timeStr,
        status: 'completed',
        keteranganPihak: keteranganPihak,
        saranKonselor: saranKonselor,
        feedbackAttachmentPath: attachmentName,
        isRecordOnly: true,
      );
      await _saveLocalSessions([newNote, ...sessions]);

      final updatedCases = cases.map((c) {
        if (c.id == complaintId) {
          return c.copyWith(
            counselingNotes: [newNote, ...c.counselingNotes],
          );
        }
        return c;
      }).toList();
      await _saveLocalCases(updatedCases);
    }
    return true;
  }

  /// Hapus laporan pengaduan.
  Future<bool> deleteComplaint(int id) async {
    try {
      await ApiClient.instance.dio.delete('/konselor/complaints/$id');
    } catch (_) {
      try {
        await ApiClient.instance.dio.delete('/operator/complaints/$id');
      } catch (_) {}
    }

    final cases = await _getLocalCases();
    cases.removeWhere((c) => c.id == id);
    await _saveLocalCases(cases);
    return true;
  }

  /// Update status jadwal sesi konseling (`completed` / `cancelled`).
  Future<bool> updateScheduleStatus(int scheduleId, String status) async {
    try {
      await ApiClient.instance.dio.patch(
        '/konselor/jadwal/$scheduleId/status',
        data: {'status': status},
      );
    } catch (_) {}

    final sessions = await _getLocalSessions();
    final updated = sessions.map((s) {
      if (s.id == scheduleId) {
        return s.copyWith(status: status);
      }
      return s;
    }).toList();
    await _saveLocalSessions(updated);
    return true;
  }

  /// Simpan sesi Penanganan Manual (`POST /konselor/jadwal`).
  Future<bool> createManualCounseling(Map<String, dynamic> form) async {
    try {
      await ApiClient.instance.dio.post('/konselor/jadwal', data: form);
    } catch (_) {}

    final user = AuthService.instance.user;
    final isRecordOnly = form['is_record_only'] == true;
    final newSessionId = DateTime.now().millisecondsSinceEpoch % 100000;
    final newComplaintId = 200 + (newSessionId % 700);
    final reportRef = 'LAP-2026-M${newComplaintId.toString().padLeft(3, '0')}';

    final newSession = SatgasSessionRecord(
      id: newSessionId,
      complaintId: newComplaintId,
      reportReference: reportRef,
      complaintTitle:
          'Sesi Penanganan Langsung: ${form['jenis_pengaduan'] ?? 'Umum'}',
      counseleeName: (form['counselee_name'] ?? 'Pelapor Walk-in').toString(),
      counseleeType: (form['counselee_type'] ?? 'pelapor').toString(),
      guestNim: (form['guest_nim'] ?? '').toString(),
      guestEmail: (form['guest_email'] ?? '').toString(),
      guestPhone: (form['guest_wa'] ?? form['guest_phone'] ?? '').toString(),
      counselorId: user?.id ?? 2,
      counselorName: user?.name ?? 'Dr. Siti Aminah, M.Psi.',
      jenisPengaduan:
          (form['jenis_pengaduan'] ?? 'Penanganan Langsung').toString(),
      tanggal: (form['tanggal'] ?? _fmtDate(DateTime.now())).toString(),
      jamMulai: (form['jam_mulai'] ?? '09:00').toString(),
      jamSelesai: (form['jam_selesai'] ?? '10:00').toString(),
      metode: (form['metode'] ?? 'offline').toString(),
      lokasi: (form['lokasi'] ?? 'Kantor Satgas').toString(),
      meetingLink: (form['meeting_link'] ?? '').toString(),
      status: isRecordOnly ? 'completed' : 'approved',
      keteranganPihak: (form['keterangan_pihak'] ?? '').toString(),
      saranKonselor: (form['saran_konselor'] ?? '').toString(),
      isRecordOnly: isRecordOnly,
    );

    final sessions = await _getLocalSessions();
    await _saveLocalSessions([newSession, ...sessions]);

    final newCase = SatgasComplaintItem(
      id: newComplaintId,
      reportId: reportRef,
      title: 'Penanganan Manual: ${form['jenis_pengaduan'] ?? 'Umum'}',
      description: (form['keterangan_pihak'] ?? '').toString(),
      chronology: (form['keterangan_pihak'] ?? '').toString(),
      status: isRecordOnly ? 'completed' : 'approved',
      urgencyLevel: 'medium',
      categoryId: 'CAT-MANUAL',
      categoryName: (form['jenis_pengaduan'] ?? 'Umum').toString(),
      victimType: 'self',
      userName: (form['counselee_name'] ?? 'Pelapor').toString(),
      userEmail: (form['guest_email'] ?? '-').toString(),
      userPhone: (form['guest_wa'] ?? '-').toString(),
      nimNip: (form['guest_nim'] ?? '-').toString(),
      reporterPobDob: '-',
      reporterAddress: (form['lokasi'] ?? 'Kampus Polije').toString(),
      reporterGender: (form['reporter_gender'] ?? '-').toString(),
      reporterStatus: (form['reporter_status'] ?? 'Mahasiswa').toString(),
      victimName: (form['counselee_name'] ?? 'Pelapor').toString(),
      victimGender:
          (form['victim_gender'] ?? form['reporter_gender'] ?? '-').toString(),
      victimStatus: (form['victim_status'] ??
              form['reporter_status'] ??
              'Mahasiswa')
          .toString(),
      victimAffiliation: 'Politeknik Negeri Jember',
      suspectName: (form['suspect_name'] ?? '-').toString(),
      suspectGender: (form['suspect_gender'] ?? '-').toString(),
      suspectStatus: (form['suspect_status'] ?? 'Mahasiswa').toString(),
      suspectNimNip: '-',
      suspectPhone: (form['suspect_phone'] ?? '-').toString(),
      suspectAffiliation: (form['suspect_affiliation'] ?? '-').toString(),
      location: (form['lokasi'] ?? 'Kantor Satgas PPKPT').toString(),
      incidentDate:
          DateTime.tryParse((form['tanggal'] ?? '').toString()) ??
              DateTime.now(),
      createdAt: DateTime.now(),
      counselorId: user?.id ?? 2,
      counselorName: user?.name ?? 'Dr. Siti Aminah, M.Psi.',
      counselingSchedule: '${newSession.tanggal}T${newSession.jamMulai}',
      counselingNotes: [newSession],
    );

    final cases = await _getLocalCases();
    await _saveLocalCases([newCase, ...cases]);
    return true;
  }

  /// Agenda Eksternal Kalender (`counseling_external_agendas`).
  Future<List<ExternalCalendarAgenda>> getExternalAgendas() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kExternalAgendasKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          return decoded
              .whereType<Map>()
              .map((e) =>
                  ExternalCalendarAgenda.fromJson(Map<String, dynamic>.from(e)))
              .toList();
        }
      }
    } catch (_) {}
    return const [];
  }

  Future<List<ExternalCalendarAgenda>> addExternalAgenda({
    required String title,
    required String date,
    required String time,
    String description = '',
  }) async {
    final current = await getExternalAgendas();
    final item = ExternalCalendarAgenda(
      id: 'ext-${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      date: date,
      time: time,
      description: description,
    );
    final next = [...current, item];
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _kExternalAgendasKey,
        jsonEncode(next.map((e) => e.toJson()).toList()),
      );
    } catch (_) {}
    return next;
  }

  Future<List<ExternalCalendarAgenda>> deleteExternalAgenda(String id) async {
    final current = await getExternalAgendas();
    final next = current.where((a) => a.id != id).toList();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _kExternalAgendasKey,
        jsonEncode(next.map((e) => e.toJson()).toList()),
      );
    } catch (_) {}
    return next;
  }

  /// CRUD Materi Pusat Edukasi Satgas (`/konselor/materials`).
  Future<List<EduMaterial>> getKonselorMaterials({
    String search = '',
    String kategori = 'all',
    String tipe = 'all',
  }) async {
    try {
      final res = await ApiClient.instance.dio.get(
        '/konselor/materials',
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

  Future<bool> createKonselorMaterial({
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
        '/konselor/materials',
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
          ? 'materials/${fileName ?? 'dokumen-satgas.pdf'}'
          : null,
      link: tipe == 'link' ? link : null,
    );
    await _saveLocalMaterials([newItem, ...current]);
    return true;
  }

  Future<bool> updateKonselorMaterial({
    required String uniqueId,
    required String judul,
    required String deskripsi,
    required String kategori,
  }) async {
    try {
      await ApiClient.instance.dio.put(
        '/konselor/materials/$uniqueId',
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
    return true;
  }

  Future<bool> deleteKonselorMaterial(String uniqueId) async {
    try {
      await ApiClient.instance.dio.delete('/konselor/materials/$uniqueId');
    } catch (_) {}

    final current = await _getLocalMaterials();
    current.removeWhere((m) => m.uniqueId == uniqueId);
    await _saveLocalMaterials(current);
    return true;
  }

  /// Menghasilkan isi CSV laporan pengaduan Satgas (untuk fitur Ekspor).
  Future<String> generateExportCsv({
    String dateFrom = '',
    String dateTo = '',
    String status = 'all',
  }) async {
    final items = await getComplaints(
      status: status,
      dateFrom: dateFrom,
      dateTo: dateTo,
    );
    final buffer = StringBuffer();
    buffer.writeln(
      'ID Laporan,Judul Kasus,Kategori,Tingkat Urgensi,Status,Nama Pelapor,NIM/NIP,Lokasi,Tanggal Lapor,Satgas PJ',
    );
    for (final c in items) {
      String esc(String v) => '"${v.replaceAll('"', '""')}"';
      buffer.writeln([
        esc(c.reportId),
        esc(c.title),
        esc(c.categoryName),
        esc(c.urgencyLevel.toUpperCase()),
        esc(c.status.toUpperCase()),
        esc(c.userName),
        esc(c.nimNip),
        esc(c.location),
        esc(_fmtDate(c.createdAt)),
        esc(c.counselorName),
      ].join(','));
    }
    return buffer.toString();
  }

  /// Daftar kategori kekerasan (membaca dari `UserPortalService`).
  Future<List<ViolenceCategoryItem>> getCategories() {
    return UserPortalService.instance.getCategories();
  }
}
