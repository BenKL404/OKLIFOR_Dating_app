import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import 'okl_feedback.dart';

/// Permissions pour [ImagePicker] : évite le combo Android « photos + storage » qui casse la galerie
/// à partir d’Android 13 (API 33).
class OklPickMediaPermissions {
  OklPickMediaPermissions._();

  static bool _mediaGranted(PermissionStatus s) {
    if (s.isGranted) return true;
    // Accès limité (iOS bibliothèque / Android 14+ sélection partielle)
    return s == PermissionStatus.limited;
  }

  static void _alertDenied(BuildContext context, PermissionStatus status, {required bool forCamera}) {
    if (status.isPermanentlyDenied) {
      OklFeedback.alert(
        context,
        title: 'Permission requise',
        message: forCamera
            ? 'L’accès caméra a été refusé. Active la permission dans les réglages du téléphone.'
            : 'L’accès à la galerie a été refusé. Active « Photos et vidéos » ou « Stockage » dans les réglages.',
      );
    } else {
      OklFeedback.alert(
        context,
        title: 'Permission refusée',
        message: forCamera
            ? 'Sans accès caméra, impossible de prendre une photo.'
            : 'Sans accès à la galerie, impossible de choisir une image.',
      );
    }
  }

  /// Caméra : [Permission.camera]. Galerie : **aucune** sur iOS (PHPicker). Sur Android, selon la version d’OS.
  static Future<bool> ensureImageSource(BuildContext context, ImageSource source) async {
    if (kIsWeb) return true;

    if (source == ImageSource.camera) {
      final s = await Permission.camera.request();
      if (s.isGranted) return true;
      if (!context.mounted) return false;
      _alertDenied(context, s, forCamera: true);
      return false;
    }

    // Galerie — iOS 14+ : PHPicker, pas de demande lecture bibliothèque
    if (Platform.isIOS) return true;

    if (Platform.isAndroid) {
      final sdk = (await DeviceInfoPlugin().androidInfo).version.sdkInt;
      if (sdk >= 33) {
        final s = await Permission.photos.request();
        if (_mediaGranted(s)) return true;
        if (!context.mounted) return false;
        _alertDenied(context, s, forCamera: false);
        return false;
      }
      final s = await Permission.storage.request();
      if (s.isGranted) return true;
      if (!context.mounted) return false;
      _alertDenied(context, s, forCamera: false);
      return false;
    }

    return true;
  }

  /// Stories / statut : galerie photo ou vidéo (Android 13+ sépare images et vidéos).
  static Future<bool> ensureGalleryForPick(
    BuildContext context, {
    required bool isVideo,
  }) async {
    if (kIsWeb) return true;
    if (Platform.isIOS) return true;

    if (Platform.isAndroid) {
      final sdk = (await DeviceInfoPlugin().androidInfo).version.sdkInt;
      if (sdk >= 33) {
        final perm = isVideo ? Permission.videos : Permission.photos;
        final s = await perm.request();
        if (_mediaGranted(s)) return true;
        if (!context.mounted) return false;
        _alertDenied(context, s, forCamera: false);
        return false;
      }
      final s = await Permission.storage.request();
      if (s.isGranted) return true;
      if (!context.mounted) return false;
      _alertDenied(context, s, forCamera: false);
      return false;
    }

    return true;
  }
}
