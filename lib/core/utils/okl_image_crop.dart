import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../constants/app_colors.dart';

/// Profils de rognage après [ImagePicker] (Android / iOS natifs ; Web : pas d’uCrop natif).
enum OklImageCropKind {
  /// Cercle 1:1, export carré.
  profileAvatar,
  /// Rectangle 16:9.
  profileCover,
  /// Visage : cadre carré 1:1.
  verificationSelfie,
  /// Pièce : ratio libre (4:3, 3:2, original au choix).
  verificationId,
}

enum _RecadrageOuPasser { recadrer, passerSansRognage }

/// Après sélection d’une image : feuille **Recadrer** / **Passer sans rognage** / **Annuler**.
/// Rognage natif : seul **OK** dans l’écran Recadrer valide ; Annuler là → `null`.
Future<Uint8List?> cropPickedImageIfPossible({
  required BuildContext context,
  required XFile xFile,
  required OklImageCropKind kind,
}) async {
  if (!context.mounted) return null;

  final choice = await _showRecadrerOuPasserSheet(context);
  if (choice == null || !context.mounted) return null;

  if (choice == _RecadrageOuPasser.passerSansRognage) {
    return xFile.readAsBytes();
  }

  // Recadrer
  if (kIsWeb) {
    if (!await _confirmImageForUpload(context, explainNoCropper: true)) {
      return null;
    }
    return xFile.readAsBytes();
  }

  final path = xFile.path;
  if (path.isEmpty) {
    return _recadrageImpossibleUtiliserSansRognage(context, xFile);
  }

  late final CropAspectRatio? aspectRatio;
  late final CropStyle cropStyle;
  late final CropAspectRatioPreset initPreset;
  late final bool lockRatio;
  late final List<CropAspectRatioPreset> androidPresets;
  int? maxWidth;
  int? maxHeight;

  switch (kind) {
    case OklImageCropKind.profileAvatar:
      aspectRatio = const CropAspectRatio(ratioX: 1, ratioY: 1);
      cropStyle = CropStyle.circle;
      initPreset = CropAspectRatioPreset.square;
      lockRatio = true;
      androidPresets = const [CropAspectRatioPreset.square];
      maxWidth = 1200;
      maxHeight = 1200;
      break;
    case OklImageCropKind.profileCover:
      aspectRatio = const CropAspectRatio(ratioX: 16, ratioY: 9);
      cropStyle = CropStyle.rectangle;
      initPreset = CropAspectRatioPreset.ratio16x9;
      lockRatio = true;
      androidPresets = const [CropAspectRatioPreset.ratio16x9];
      maxWidth = 2400;
      maxHeight = 1350;
      break;
    case OklImageCropKind.verificationSelfie:
      aspectRatio = const CropAspectRatio(ratioX: 1, ratioY: 1);
      cropStyle = CropStyle.rectangle;
      initPreset = CropAspectRatioPreset.square;
      lockRatio = true;
      androidPresets = const [CropAspectRatioPreset.square];
      maxWidth = 1600;
      maxHeight = 1600;
      break;
    case OklImageCropKind.verificationId:
      aspectRatio = null;
      cropStyle = CropStyle.rectangle;
      initPreset = CropAspectRatioPreset.original;
      lockRatio = false;
      androidPresets = const [
        CropAspectRatioPreset.original,
        CropAspectRatioPreset.ratio4x3,
        CropAspectRatioPreset.ratio3x2,
        CropAspectRatioPreset.square,
      ];
      maxWidth = 2400;
      maxHeight = 2400;
      break;
  }

  final cropped = await ImageCropper().cropImage(
    sourcePath: path,
    aspectRatio: aspectRatio,
    maxWidth: maxWidth,
    maxHeight: maxHeight,
    compressQuality: 88,
    uiSettings: [
      AndroidUiSettings(
        toolbarTitle: 'Recadrer',
        toolbarColor: AppColors.primary,
        toolbarWidgetColor: Colors.white,
        statusBarLight: false,
        navBarLight: false,
        lockAspectRatio: lockRatio,
        initAspectRatio: initPreset,
        cropStyle: cropStyle,
        aspectRatioPresets: androidPresets,
      ),
      IOSUiSettings(
        title: 'Recadrer',
        doneButtonTitle: 'OK',
        cancelButtonTitle: 'Annuler',
        aspectRatioLockEnabled: aspectRatio != null,
        resetAspectRatioEnabled: aspectRatio == null,
        aspectRatioPickerButtonHidden: aspectRatio != null,
        cropStyle: cropStyle,
      ),
    ],
  );

  if (cropped == null) {
    return null;
  }
  return XFile(cropped.path).readAsBytes();
}

Future<_RecadrageOuPasser?> _showRecadrerOuPasserSheet(BuildContext context) {
  final surface = Theme.of(context).colorScheme.surfaceContainerHighest;
  return showModalBottomSheet<_RecadrageOuPasser>(
    context: context,
    backgroundColor: surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(ctx).dividerColor.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Text(
                'Photo sélectionnée',
                textAlign: TextAlign.center,
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tu peux recadrer l’image ou l’envoyer telle quelle.',
                textAlign: TextAlign.center,
                style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                      color: Theme.of(ctx).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () =>
                    Navigator.pop(ctx, _RecadrageOuPasser.recadrer),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(LucideIcons.crop, size: 20),
                label: const Text('Recadrer'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () =>
                    Navigator.pop(ctx, _RecadrageOuPasser.passerSansRognage),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(LucideIcons.image, size: 20),
                label: const Text('Passer sans rognage'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Annuler'),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Chemin local indisponible pour uCrop : proposer d’utiliser le fichier tel quel ou annuler.
Future<Uint8List?> _recadrageImpossibleUtiliserSansRognage(
  BuildContext context,
  XFile xFile,
) async {
  if (!context.mounted) return null;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Recadrage indisponible'),
      content: const Text(
        'Ce fichier ne peut pas être ouvert dans l’outil de recadrage. '
        'Utiliser la photo sans rognage ?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('OK'),
        ),
      ],
    ),
  );
  if (ok != true || !context.mounted) return null;
  return xFile.readAsBytes();
}

Future<bool> _confirmImageForUpload(
  BuildContext context, {
  required bool explainNoCropper,
}) async {
  if (!context.mounted) return false;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Confirmer la photo'),
      content: Text(
        explainNoCropper
            ? 'Sur le web, le recadrage avancé n’est pas disponible. '
                'Valider cette image pour l’envoi ?'
            : 'Valider cette image pour l’envoi ?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('OK'),
        ),
      ],
    ),
  );
  return ok == true && context.mounted;
}
