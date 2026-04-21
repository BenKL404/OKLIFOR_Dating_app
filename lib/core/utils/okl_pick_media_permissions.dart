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

  static Future<void> _alertDenied(
    BuildContext context,
    PermissionStatus status, {
    required bool forCamera,
    required bool forMicrophone,
  }) async {
    final needSettings =
        status.isPermanentlyDenied || status.isRestricted;
    final String message;
    if (forMicrophone) {
      message = needSettings
          ? "L'accès micro est bloqué. Active le micro dans les réglages du téléphone."
          : "Sans accès micro, impossible d'enregistrer un vocal.";
    } else if (forCamera) {
      message = needSettings
          ? "L'accès caméra est bloqué. Active la caméra dans les réglages du téléphone."
          : "Sans accès caméra, impossible de prendre une photo/vidéo.";
    } else {
      message = needSettings
          ? "L'accès à la galerie est bloqué. Active Photos/Vidéos dans les réglages."
          : "Sans accès à la galerie, impossible de choisir un média.";
    }

    if (!needSettings) {
      OklFeedback.alert(
        context,
        title: 'Permission refusée',
        message: message,
      );
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Permission requise'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await openAppSettings();
            },
            child: const Text('Ouvrir réglages'),
          ),
        ],
      ),
    );
  }

  /// Caméra : [Permission.camera]. Galerie : **aucune** sur iOS (PHPicker). Sur Android, selon la version d’OS.
  static Future<bool> ensureImageSource(BuildContext context, ImageSource source) async {
    if (kIsWeb) return true;

    if (source == ImageSource.camera) {
      final s = await Permission.camera.request();
      if (s.isGranted) return true;
      if (!context.mounted) return false;
      await _alertDenied(
        context,
        s,
        forCamera: true,
        forMicrophone: false,
      );
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
        await _alertDenied(
          context,
          s,
          forCamera: false,
          forMicrophone: false,
        );
        return false;
      }
      final s = await Permission.storage.request();
      if (s.isGranted) return true;
      if (!context.mounted) return false;
      await _alertDenied(
        context,
        s,
        forCamera: false,
        forMicrophone: false,
      );
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
        await _alertDenied(
          context,
          s,
          forCamera: false,
          forMicrophone: false,
        );
        return false;
      }
      final s = await Permission.storage.request();
      if (s.isGranted) return true;
      if (!context.mounted) return false;
      await _alertDenied(
        context,
        s,
        forCamera: false,
        forMicrophone: false,
      );
      return false;
    }

    return true;
  }

  static Future<bool> ensureMicrophone(BuildContext context) async {
    if (kIsWeb) return true;
    final s = await Permission.microphone.request();
    if (s.isGranted) return true;
    if (!context.mounted) return false;
    await _alertDenied(
      context,
      s,
      forCamera: false,
      forMicrophone: true,
    );
    return false;
  }
}
