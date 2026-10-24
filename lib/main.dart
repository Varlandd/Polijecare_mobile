import 'package:flutter/material.dart';

import 'app/routes.dart';
import 'core/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
