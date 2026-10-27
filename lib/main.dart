import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/routes.dart';
import 'core/theme/app_theme.dart';
import 'data/services/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  await AuthService.instance.init();
  runApp(const PolijeCareApp());
}

class PolijeCareApp extends StatelessWidget {
  const PolijeCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PolijeCare',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: AppRoutes.landing,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}
