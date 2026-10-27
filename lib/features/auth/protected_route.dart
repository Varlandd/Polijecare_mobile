import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../data/services/auth_service.dart';

/// Port dari `components/NewProtectedRoute.jsx` di web.
/// Memastikan pengguna sudah login dan memiliki role yang sesuai.
class ProtectedRoute extends StatelessWidget {
  const ProtectedRoute({
    super.key,
    required this.child,
    this.requiredRoles,
  });

  final Widget child;
  final List<String>? requiredRoles;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AuthService.instance,
      builder: (context, _) {
        final auth = AuthService.instance;

        if (!auth.initialized) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Memeriksa autentikasi...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (!auth.isAuthenticated) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              Navigator.of(context).pushNamedAndRemoveUntil(
                AppRoutes.login,
                (route) => false,
              );
            }
          });
          return const SizedBox.shrink();
        }

        if (requiredRoles != null && requiredRoles!.isNotEmpty) {
          final currentRole = auth.userRole ?? '';
          final allowed = requiredRoles!
              .map((r) => r.toLowerCase())
              .contains(currentRole);
          if (!allowed) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  auth.redirectPath,
                  (route) => false,
                );
              }
            });
            return const SizedBox.shrink();
          }
        }

        return child;
      },
    );
  }
}

