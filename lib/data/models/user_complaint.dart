import 'article.dart';

/// Kategori Kekerasan (`ViolenceCategory` di Laravel & `/user/categories`).
class ViolenceCategoryItem {
  final String uniqueId;
  final String name;
  final String? description;

  const ViolenceCategoryItem({
    required this.uniqueId,
    required this.name,
    this.description,
  });

  factory ViolenceCategoryItem.fromJson(Map<String, dynamic> json) {
    return ViolenceCategoryItem(
      uniqueId:
          json['unique_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ??
          json['kategori']?.toString() ??
          'Kategori Umum',
      description: json['description']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'unique_id': uniqueId,
        'name': name,
        'description': description,
      };
}

/// Lampiran bukti laporan (`ComplaintAttachment`).
class ComplaintAttachmentItem {
  final int id;
  final String fileName;
  final String filePath;
  final String? fileType;
  final int? fileSize;

  const ComplaintAttachmentItem({
    required this.id,
    required this.fileName,
    required this.filePath,
    this.fileType,
    this.fileSize,
  });

  bool get isImage {
    final ext = fileName.split('.').last.toLowerCase();
    final type = (fileType ?? '').toLowerCase();
    return ['png', 'jpg', 'jpeg', 'gif', 'webp', 'svg'].contains(ext) ||
        type.startsWith('image/');
  }

  factory ComplaintAttachmentItem.fromJson(Map<String, dynamic> json) {
    final path =
        json['file_path']?.toString() ?? json['path']?.toString() ?? '';
    final name = json['file_name']?.toString() ??
        (path.isNotEmpty ? path.split('/').last : 'Lampiran');
    return ComplaintAttachmentItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      fileName: name,
      filePath: path,
      fileType: json['file_type']?.toString(),
      fileSize: (json['file_size'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'file_name': fileName,
        'file_path': filePath,
        'file_type': fileType,
        'file_size': fileSize,
      };
}

/// Jadwal konseling / sesi penanganan (`CounselingSchedule`).
class CounselingScheduleItem {
  final int id;
  final String? complaintId;
  final String tanggal;
  final String jamMulai;
  final String jamSelesai;
  final String metode; // 'online' | 'offline'
  final String? lokasi;
  final String? meetingLink;
  final String status; // 'pending' | 'approved' | 'rejected' | 'completed' | 'cancelled'
  final String? counselorName;
  final String? rejectionReason;
  final String? counseleeType;
  final String? counseleeName;
  final String? keteranganPihak;
  final String? feedbackNotes;
  final String? saranKonselor;
  final String? feedbackAttachment;

  const CounselingScheduleItem({
    required this.id,
    this.complaintId,
    required this.tanggal,
    required this.jamMulai,
    required this.jamSelesai,
    this.metode = 'offline',
    this.lokasi,
    this.meetingLink,
    this.status = 'pending',
    this.counselorName,
    this.rejectionReason,
    this.counseleeType,
    this.counseleeName,
    this.keteranganPihak,
    this.feedbackNotes,
    this.saranKonselor,
    this.feedbackAttachment,
  });

  String get jamMulaiShort =>
      jamMulai.length >= 5 ? jamMulai.substring(0, 5) : jamMulai;

  String get jamSelesaiShort =>
      jamSelesai.length >= 5 ? jamSelesai.substring(0, 5) : jamSelesai;

  factory CounselingScheduleItem.fromJson(Map<String, dynamic> json) {
    String? cName = json['counselor_name']?.toString();
    if (cName == null && json['counselor'] is Map) {
      cName = (json['counselor'] as Map)['name']?.toString();
    }
    return CounselingScheduleItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      complaintId: json['complaint_id']?.toString(),
      tanggal: json['tanggal']?.toString() ?? '',
      jamMulai: json['jam_mulai']?.toString() ?? '09:00',
      jamSelesai: json['jam_selesai']?.toString() ?? '10:00',
      metode: json['metode']?.toString() ?? 'offline',
      lokasi: json['lokasi']?.toString(),
      meetingLink: json['meeting_link']?.toString(),
      status: json['status']?.toString() ?? 'pending',
      counselorName: cName,
      rejectionReason: json['rejection_reason']?.toString(),
      counseleeType: json['counselee_type']?.toString(),
      counseleeName: json['counselee_name']?.toString(),
      keteranganPihak: json['keterangan_pihak']?.toString(),
      feedbackNotes: json['feedback_notes']?.toString(),
      saranKonselor: json['saran_konselor']?.toString(),
      feedbackAttachment: json['feedback_attachment']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'complaint_id': complaintId,
        'tanggal': tanggal,
        'jam_mulai': jamMulai,
        'jam_selesai': jamSelesai,
        'metode': metode,
        'lokasi': lokasi,
        'meeting_link': meetingLink,
        'status': status,
        'counselor_name': counselorName,
        'rejection_reason': rejectionReason,
        'counselee_type': counseleeType,
        'counselee_name': counseleeName,
        'keterangan_pihak': keteranganPihak,
        'feedback_notes': feedbackNotes,
        'saran_konselor': saranKonselor,
        'feedback_attachment': feedbackAttachment,
      };
}

/// Laporan Pengaduan Mahasiswa (`Complaint` di Laravel).
class UserComplaint {
  final int id;
  final String reportReference;
  final String title;
  final String status; // 'pending' | 'approved' | 'completed' | 'rejected'
  final String urgencyLevel; // 'low' | 'medium' | 'high' | 'Rendah' | 'Sedang' | 'Tinggi'
  final String categoryId;
  final String categoryName;
  final String? counselorName;
  final String victimType; // 'self' | 'other'
  final String? victimName;
  final String? victimGender;
  final String? victimRelationship;
  final String? suspectName;
  final String? suspectStatus;
  final String? suspectAffiliation;
  final String chronology;
  final String location;
  final String? incidentDate;
  final String? latitude;
  final String? longitude;
  final String? rejectionReason;
  final String? proposedDate;
  final String? proposedTime;
  final DateTime createdAt;
  final List<ComplaintAttachmentItem> attachments;
  final List<CounselingScheduleItem> schedules;

  const UserComplaint({
    required this.id,
    required this.reportReference,
    required this.title,
    required this.status,
    this.urgencyLevel = 'medium',
    this.categoryId = '',
    required this.categoryName,
    this.counselorName,
    this.victimType = 'self',
    this.victimName,
    this.victimGender,
    this.victimRelationship,
    this.suspectName,
    this.suspectStatus,
    this.suspectAffiliation,
    required this.chronology,
    required this.location,
    this.incidentDate,
    this.latitude,
    this.longitude,
    this.rejectionReason,
    this.proposedDate,
    this.proposedTime,
    required this.createdAt,
    this.attachments = const [],
    this.schedules = const [],
  });

  factory UserComplaint.fromJson(Map<String, dynamic> json) {
    String catName = 'Kategori Umum';
    String catId = json['violence_category_id']?.toString() ?? '';
    final vc = json['violenceCategory'] ?? json['violence_category'];
    if (vc is Map) {
      catName = vc['name']?.toString() ??
          vc['kategori']?.toString() ??
          'Kategori Umum';
      if (catId.isEmpty) {
        catId = vc['unique_id']?.toString() ?? '';
      }
    } else if (json['violence_category_name'] != null) {
      catName = json['violence_category_name'].toString();
    }

    String? cName;
    if (json['counselor'] is Map) {
      cName = (json['counselor'] as Map)['name']?.toString();
    } else if (json['counselor_name'] != null) {
      cName = json['counselor_name'].toString();
    }

    final rawAttachments = json['attachments'];
    final attachmentsList = <ComplaintAttachmentItem>[];
    if (rawAttachments is List) {
      for (final a in rawAttachments) {
        if (a is Map) {
          attachmentsList.add(
            ComplaintAttachmentItem.fromJson(Map<String, dynamic>.from(a)),
          );
        }
      }
    }

    final rawSchedules = json['counseling_notes'] ?? json['schedules'];
    final schedulesList = <CounselingScheduleItem>[];
    if (rawSchedules is List) {
      for (final s in rawSchedules) {
        if (s is Map) {
          schedulesList.add(
            CounselingScheduleItem.fromJson(Map<String, dynamic>.from(s)),
          );
        }
      }
    }

    final idVal = (json['id'] as num?)?.toInt() ?? 0;
    return UserComplaint(
      id: idVal,
      reportReference: json['report_reference']?.toString() ??
          json['report_id']?.toString() ??
          '#LP-$idVal',
      title: json['title']?.toString() ?? '-',
      status: json['status']?.toString() ?? 'pending',
      urgencyLevel: json['urgency_level']?.toString() ?? 'medium',
      categoryId: catId,
      categoryName: catName,
      counselorName: cName,
      victimType: json['victim_type']?.toString() ?? 'self',
      victimName: json['victim_name']?.toString(),
      victimGender: json['victim_gender']?.toString(),
      victimRelationship: json['victim_relationship']?.toString(),
      suspectName: json['suspect_name']?.toString(),
      suspectStatus: json['suspect_status']?.toString(),
      suspectAffiliation: json['suspect_affiliation']?.toString(),
      chronology: json['chronology']?.toString() ??
          json['description']?.toString() ??
          '',
      location: json['location']?.toString() ?? '-',
      incidentDate: json['incident_date']?.toString(),
      latitude: json['latitude']?.toString(),
      longitude: json['longitude']?.toString(),
      rejectionReason: json['rejection_reason']?.toString(),
      proposedDate: json['proposed_date']?.toString(),
      proposedTime: json['proposed_time']?.toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      attachments: attachmentsList,
      schedules: schedulesList,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'report_reference': reportReference,
        'title': title,
        'status': status,
        'urgency_level': urgencyLevel,
        'violence_category_id': categoryId,
        'violence_category_name': categoryName,
        'counselor_name': counselorName,
        'victim_type': victimType,
        'victim_name': victimName,
        'victim_gender': victimGender,
        'victim_relationship': victimRelationship,
        'suspect_name': suspectName,
        'suspect_status': suspectStatus,
        'suspect_affiliation': suspectAffiliation,
        'chronology': chronology,
        'location': location,
        'incident_date': incidentDate,
        'latitude': latitude,
        'longitude': longitude,
        'rejection_reason': rejectionReason,
        'proposed_date': proposedDate,
        'proposed_time': proposedTime,
        'created_at': createdAt.toIso8601String(),
        'attachments': attachments.map((e) => e.toJson()).toList(),
        'schedules': schedules.map((e) => e.toJson()).toList(),
      };
}

/// Data Dashboard User (`/user/dashboard`).
class UserDashboardData {
  final int total;
  final int processing;
  final int completed;
  final List<UserComplaint> recentComplaints;
  final CounselingScheduleItem? upcomingSchedule;
  final List<Article> recentArticles;
  final String satgasPhone;
  final String satgasEmail;
  final String satgasLocation;

  const UserDashboardData({
    required this.total,
    required this.processing,
    required this.completed,
    required this.recentComplaints,
    this.upcomingSchedule,
    required this.recentArticles,
    required this.satgasPhone,
    required this.satgasEmail,
    required this.satgasLocation,
  });
}

/// Slot waktu konseling (`/counseling/available-slots`).
class TimeSlotOption {
  final String jamMulai;
  final String jamSelesai;
  final String display;
  final bool available;

  const TimeSlotOption({
    required this.jamMulai,
    required this.jamSelesai,
    required this.display,
    required this.available,
  });

  factory TimeSlotOption.fromJson(Map<String, dynamic> json) {
    final start = json['jam_mulai']?.toString() ?? '09:00';
    final end = json['jam_selesai']?.toString() ?? '10:00';
    return TimeSlotOption(
      jamMulai: start,
      jamSelesai: end,
      display: json['display']?.toString() ?? '$start - $end',
      available: json['available'] == true,
    );
  }
}

/// Data Satgas Pendamping (`/counseling/counselors`).
class CounselorOption {
  final int id;
  final String name;
  final String email;

  const CounselorOption({
    required this.id,
    required this.name,
    required this.email,
  });

  factory CounselorOption.fromJson(Map<String, dynamic> json) {
    return CounselorOption(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? 'Satgas PolijeCare',
      email: json['email']?.toString() ?? '',
    );
  }
}

