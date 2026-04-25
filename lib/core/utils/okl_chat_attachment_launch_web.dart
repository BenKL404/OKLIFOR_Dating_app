import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/oklifor_media_url.dart';
import 'okl_feedback.dart';

bool _isValidHttpUrl(String resolved, Uri? uri) {
  return uri != null &&
      (uri.isScheme('http') || uri.isScheme('https')) &&
      resolved.isNotEmpty;
}

Future<bool> saveChatFileToDownloads(
  BuildContext context,
  String raw, {
  String? displayName,
}) async {
  // Web: leave the browser to handle downloads.
  final resolved = OkliforMediaUrl.resolve(raw.trim());
  final uri = Uri.tryParse(resolved);
  if (!_isValidHttpUrl(resolved, uri)) {
    if (context.mounted) {
      OklFeedback.snack(context, 'Lien du fichier invalide');
    }
    return false;
  }
  try {
    final ok = await launchUrl(
      uri!,
      mode: LaunchMode.externalApplication,
    );
    if (!ok && context.mounted) {
      OklFeedback.snack(context, 'Téléchargement impossible');
    }
    return ok;
  } catch (_) {
    if (context.mounted) {
      OklFeedback.snack(context, 'Téléchargement impossible');
    }
    return false;
  }
}

/// Navigateur ou app par défaut.
Future<void> launchChatAttachmentUrl(
  BuildContext context,
  String raw, {
  String? displayName,
}) async {
  final resolved = OkliforMediaUrl.resolve(raw.trim());
  final uri = Uri.tryParse(resolved);
  if (!_isValidHttpUrl(resolved, uri)) {
    if (context.mounted) {
      OklFeedback.snack(context, 'Lien du fichier invalide');
    }
    return;
  }
  try {
    final ok = await launchUrl(
      uri!,
      mode: LaunchMode.externalApplication,
    );
    if (!ok && context.mounted) {
      OklFeedback.snack(context, 'Ouverture impossible');
    }
  } catch (_) {
    if (context.mounted) {
      OklFeedback.snack(context, 'Ouverture du fichier impossible');
    }
  }
}

Future<void> shareChatAttachmentUrl(
  BuildContext context,
  String raw, {
  String? displayName,
}) async {
  final resolved = OkliforMediaUrl.resolve(raw.trim());
  final uri = Uri.tryParse(resolved);
  if (!_isValidHttpUrl(resolved, uri)) {
    if (context.mounted) {
      OklFeedback.snack(context, 'Lien du fichier invalide');
    }
    return;
  }
  try {
    await SharePlus.instance.share(ShareParams(uri: uri!));
  } catch (_) {
    if (context.mounted) {
      OklFeedback.snack(context, 'Partage impossible');
    }
  }
}

Future<void> saveChatMediaToGallery(
  BuildContext context,
  String raw, {
  String? displayName,
  required bool isVideo,
}) async {
  // Web: we use the same download logic as for files.
  await saveChatFileToDownloads(context, raw, displayName: displayName);
}
