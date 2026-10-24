import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Halaman sementara untuk fitur yang belum dikerjakan.
class ComingSoonPage extends StatelessWidget {
  const ComingSoonPage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.navy.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.construction_rounded,
                    size: 40, color: AppColors.navy),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Halaman ini sedang dalam pengembangan.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.gray500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

