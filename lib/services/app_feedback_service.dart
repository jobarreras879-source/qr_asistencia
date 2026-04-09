import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum AppFeedbackType { success, info, warning, error }

class AppFeedbackService {
  static void showSnackBar(
    BuildContext context,
    String message, {
    AppFeedbackType type = AppFeedbackType.info,
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: _backgroundColor(type),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
  }

  static Color _backgroundColor(AppFeedbackType type) {
    switch (type) {
      case AppFeedbackType.success:
        return AppTheme.success;
      case AppFeedbackType.info:
        return AppTheme.info;
      case AppFeedbackType.warning:
        return AppTheme.warning;
      case AppFeedbackType.error:
        return AppTheme.error;
    }
  }
}
