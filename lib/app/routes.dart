import 'package:flutter/material.dart';

import '../features/auth/login_page.dart';
import '../features/common/coming_soon_page.dart';
import '../features/konselor/konselor_case_management_page.dart';
import '../features/konselor/konselor_complaint_detail_page.dart';
import '../features/konselor/konselor_counseling_dashboard_page.dart';
import '../features/konselor/konselor_dashboard_page.dart';
import '../features/konselor/konselor_manual_counseling_page.dart';
import '../features/konselor/konselor_materi_page.dart';
import '../features/landing/landing_page.dart';
import '../features/public/lapor_umum_page.dart';
import '../features/operator/operator_article_management_page.dart';
import '../features/operator/operator_case_management_page.dart';
import '../features/operator/operator_categories_management_page.dart';
import '../features/operator/operator_dashboard_page.dart';
import '../features/operator/operator_manual_counseling_page.dart';
import '../features/operator/operator_materials_management_page.dart';
import '../features/operator/operator_user_management_page.dart';
import '../features/shared/profile_page.dart';
import '../features/user/buat_laporan_page.dart';
import '../features/user/counseling_request_page.dart';
import '../features/user/detail_pengaduan_page.dart';
import '../features/user/histori_pengaduan_page.dart';
import '../features/user/user_dashboard_page.dart';

/// Daftar route aplikasi (disamakan dengan path di web `App.jsx`).
class AppRoutes {
  AppRoutes._();

  // Public
  static const String landing = '/';
  static const String login = '/login-new';
  static const String loginLegacy = '/login';
  static const String laporUmum = '/lapor-umum';
  static const String lacakLaporan = '/lacak-laporan';
  static const String edukasi = '/edukasi';
  static const String artikelDetail = '/artikel'; // argumen: slug (String)

  // Super Admin / Operator
  static const String operatorDashboard = '/operator/dashboard';
  static const String operatorCaseManagement = '/operator/case-management';
  static const String operatorComplaintsManagement =
      '/operator/complaints-management';
  static const String operatorCounselingManagement =
      '/operator/counseling-management';
  static const String operatorManualCounseling = '/operator/manual-counseling';
  static const String operatorUserManagement = '/operator/user-management';
  static const String operatorMaterialsManagement =
      '/operator/materials-management';
  static const String operatorCategoriesManagement =
      '/operator/violence-categories-management';
  static const String operatorArticleManagement =
      '/operator/article-management';
  static const String operatorComplaintDetail = '/operator/complaint-detail';

  // Konselor (Satgas)
  static const String konselorDashboard = '/konselor/dashboard';
  static const String konselorCaseManagement = '/konselor/case-management';
  static const String konselorMateri = '/konselor/materi';
  static const String konselorPengaduan = '/konselor/pengaduan';
  static const String konselorCounselingDashboard =
      '/konselor/counseling-dashboard';
  static const String konselorJadwal = '/konselor/jadwal';
  static const String konselorComplaintDetail = '/konselor/complaint-detail';
  static const String konselorManualCounseling = '/konselor/manual-counseling';

  // User (Mahasiswa/Pelapor)
  static const String userDashboard = '/user/dashboard';
  static const String dashboardLegacy = '/dashboard';
  static const String userBuatLaporan = '/user/buat-laporan';
  static const String userReportCreate = '/user/report/create';
  static const String userHistoriPengaduan = '/user/histori-pengaduan';
  static const String userDetailPengaduan = '/user/histori-pengaduan/detail';
  static const String userCounselingRequest = '/user/counseling-request';

  // Shared
  static const String profile = '/profile';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    Widget page;
    final args = settings.arguments;
    final routeName = settings.name ?? landing;

    // Support dynamic path `/user/histori-pengaduan/:id`
    if (routeName.startsWith('/user/histori-pengaduan/') &&
        routeName != userDetailPengaduan) {
      final idStr = routeName.split('/').last;
      final parsedId = int.tryParse(idStr) ?? 101;
      return MaterialPageRoute(
        builder: (_) => DetailPengaduanPage(complaintId: parsedId),
        settings: settings,
      );
    }

    // Support dynamic path `/konselor/complaint-detail/:id`
    if (routeName.startsWith('/konselor/complaint-detail/') &&
        routeName != konselorComplaintDetail) {
      final idStr = routeName.split('/').last;
      final parsedId = int.tryParse(idStr) ?? 101;
      return MaterialPageRoute(
        builder: (_) => KonselorComplaintDetailPage(
          complaintId: parsedId,
          isCounselor: true,
        ),
        settings: settings,
      );
    }

    // Support dynamic path `/operator/complaint-detail/:id`
    if (routeName.startsWith('/operator/complaint-detail/') &&
        routeName != operatorComplaintDetail) {
      final idStr = routeName.split('/').last;
      final parsedId = int.tryParse(idStr) ?? 101;
      return MaterialPageRoute(
        builder: (_) => KonselorComplaintDetailPage(
          complaintId: parsedId,
          isCounselor: false,
        ),
        settings: settings,
      );
    }

    switch (routeName) {
      case landing:
        page = const LandingPage();
        break;
      case login:
      case loginLegacy:
        bool fromForm = false;
        String? errorParam;
        if (args is Map) {
          fromForm = args['from'] == 'form-laporan';
          errorParam = args['error']?.toString();
        }
        page = LoginPage(
          fromFormLaporan: fromForm,
          initialError: errorParam,
        );
        break;

      // Super Admin / Operator routes (LENGKAP)
      case operatorDashboard:
        page = const OperatorDashboardPage();
        break;
      case operatorCaseManagement:
        String opTab = 'new';
        if (args is Map && args['tab'] != null) {
          opTab = args['tab'].toString();
        } else if (args is String && args.isNotEmpty) {
          opTab = args;
        }
        page = OperatorCaseManagementPage(initialTab: opTab);
        break;
      case operatorComplaintsManagement:
        page = const OperatorCaseManagementPage(initialTab: 'new');
        break;
      case operatorCounselingManagement:
        page = const OperatorCaseManagementPage(initialTab: 'today');
        break;
      case operatorManualCounseling:
        page = const OperatorManualCounselingPage();
        break;
      case operatorUserManagement:
        page = const OperatorUserManagementPage();
        break;
      case operatorMaterialsManagement:
        page = const OperatorMaterialsManagementPage();
        break;
      case operatorCategoriesManagement:
        page = const OperatorCategoriesManagementPage();
        break;
      case operatorArticleManagement:
        page = const OperatorArticleManagementPage();
        break;
      case operatorComplaintDetail:
        int id = 101;
        if (args is int) {
          id = args;
        } else if (args is Map && args['id'] != null) {
          id = int.tryParse(args['id'].toString()) ?? 101;
        } else if (args != null) {
          id = int.tryParse(args.toString()) ?? 101;
        }
        page = KonselorComplaintDetailPage(
          complaintId: id,
          isCounselor: false,
        );
        break;

      // Konselor / Satgas routes (LENGKAP)
      case konselorDashboard:
        page = const KonselorDashboardPage();
        break;
      case konselorCaseManagement:
        String initialTab = 'today';
        if (args is Map && args['tab'] != null) {
          initialTab = args['tab'].toString();
        } else if (args is String && args.isNotEmpty) {
          initialTab = args;
        }
        page = KonselorCaseManagementPage(initialTab: initialTab);
        break;
      case konselorPengaduan:
        page = const KonselorCaseManagementPage(initialTab: 'new');
        break;
      case konselorMateri:
        page = const KonselorMateriPage();
        break;
      case konselorCounselingDashboard:
      case konselorJadwal:
        page = const KonselorCounselingDashboardPage();
        break;
      case konselorComplaintDetail:
        int id = 101;
        if (args is int) {
          id = args;
        } else if (args is Map && args['id'] != null) {
          id = int.tryParse(args['id'].toString()) ?? 101;
        } else if (args != null) {
          id = int.tryParse(args.toString()) ?? 101;
        }
        page = KonselorComplaintDetailPage(
          complaintId: id,
          isCounselor: true,
        );
        break;
      case konselorManualCounseling:
        page = const KonselorManualCounselingPage();
        break;

      // User / Mahasiswa routes (LENGKAP)
      case userDashboard:
      case dashboardLegacy:
        page = const UserDashboardPage();
        break;
      case userBuatLaporan:
      case userReportCreate:
        page = const BuatLaporanPage();
        break;
      case userHistoriPengaduan:
        String statusParam = '';
        if (args is Map && args['status'] != null) {
          statusParam = args['status'].toString();
        }
        page = HistoriPengaduanPage(initialStatus: statusParam);
        break;
      case userDetailPengaduan:
        final id = (args is int)
            ? args
            : int.tryParse(args?.toString() ?? '') ?? 101;
        page = DetailPengaduanPage(complaintId: id);
        break;
      case userCounselingRequest:
        page = const CounselingRequestPage();
        break;

      // Shared Profile route (LENGKAP)
      case profile:
        page = const ProfilePage();
        break;

      // Placeholder untuk halaman publik tahap berikutnya
      case laporUmum:
        page = const LaporUmumPage();
        break;
      case lacakLaporan:
        page = const ComingSoonPage(title: 'Lacak Laporan');
        break;
      case edukasi:
        page = const ComingSoonPage(title: 'Pusat Edukasi');
        break;
      case artikelDetail:
        page = const ComingSoonPage(title: 'Detail Artikel');
        break;
      default:
        page = const LandingPage();
    }
    return MaterialPageRoute(builder: (_) => page, settings: settings);
  }
}
