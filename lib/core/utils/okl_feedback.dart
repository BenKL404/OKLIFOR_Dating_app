import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Snackbars et helpers pour actions démo (richesse UX sans backend).
class OklFeedback {
  OklFeedback._();

  static void snack(BuildContext context, String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    final t = Theme.of(context);
    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: TextStyle(
              color: t.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 88),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: t.colorScheme.surface,
        ),
      );
  }

  static Future<void> confirm(
    BuildContext context, {
    required String title,
    required String body,
    required String confirmLabel,
    VoidCallback? onConfirm,
  }) {
    return showDialog<void>(
      context: context,
      builder: (ctx) {
        final t = Theme.of(ctx);
        return AlertDialog(
        backgroundColor: t.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          title,
          style: TextStyle(
            color: t.colorScheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          body,
          style: TextStyle(
            color: t.textTheme.bodyMedium?.color ?? t.colorScheme.onSurface,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm?.call();
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            child: Text(confirmLabel),
          ),
        ],
        );
      },
    );
  }
}
