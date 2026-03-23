import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/api/oklifor_api_exception.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/widgets/okl_app_bar_icon_button.dart';
import '../../../core/flows/okl_flows.dart';
import '../../../core/utils/okl_feedback.dart';
import '../../../core/utils/okl_image_crop.dart';
import '../../../core/utils/okl_pick_media_permissions.dart';
import '../../auth/providers/auth_api_provider.dart';
import '../models/user_profile.dart';

/// Parcours de vérification (téléphone, email, identité) + certificat Oklifor (démo).
class AccountVerificationScreen extends StatelessWidget {
  const AccountVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<UserProfile>(
      valueListenable: ProfileSession.profile,
      builder: (context, profile, _) {
        return Scaffold(
          backgroundColor: context.oklScaffold,
          appBar: AppBar(
            backgroundColor: context.oklScaffold,
            leading: const OklAppBarBackButton(rootNavigator: true),
            automaticallyImplyLeading: false,
            title: const Text('Vérification et certificat'),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              _TrustHeaderCard(profile: profile),
              const SizedBox(height: 20),
              Text(
                'Étapes',
                style: TextStyle(
                  color: context.oklOnSurfaceMuted(0.55),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.35,
                ),
              ),
              const SizedBox(height: 10),
              _StepPhoneCard(done: profile.phoneVerified),
              const SizedBox(height: 10),
              _StepEmailCard(
                done: profile.emailVerified,
                onVerify: () => _showEmailCodeDialog(context),
              ),
              const SizedBox(height: 10),
              _StepIdentityCard(profile: profile),
              if (profile.hasOkliforCertificate) ...[
                const SizedBox(height: 22),
                FilledButton.icon(
                  onPressed: () => _showCertificateSheet(context, profile),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(LucideIcons.award, size: 20),
                  label: const Text(
                    'Voir mon certificat Oklifor',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              _LegalNotice(),
            ],
          ),
        );
      },
    );
  }

  static void _showEmailCodeDialog(BuildContext context) {
    final codeCtrl = TextEditingController(text: '123456');
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.oklSurface,
        title: Text(
          'Confirmer l’e-mail',
          style: TextStyle(color: ctx.oklOnSurface),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Saisis le code reçu sur amina.demo@oklifor.tg (simulation).',
              style: TextStyle(
                color: ctx.oklOnSurfaceMuted(0.62).withValues(alpha: 0.95),
                fontSize: 13,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: codeCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              maxLength: 6,
              style: TextStyle(
                color: ctx.oklOnSurface,
                fontSize: 20,
                letterSpacing: 4,
                fontWeight: FontWeight.w700,
              ),
              decoration: InputDecoration(
                counterText: '',
                hintText: '000000',
                hintStyle: TextStyle(color: ctx.oklOnSurfaceMuted(0.55).withValues(alpha: 0.6)),
                filled: true,
                fillColor: ctx.oklScaffold,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              if (codeCtrl.text.trim() == '123456') {
                ProfileSession.update((p) => p.copyWith(emailVerified: true));
                Navigator.pop(ctx);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  OklFlows.pushResult(
                    context,
                    icon: LucideIcons.mail,
                    title: 'E-mail confirmé',
                    subtitle: 'Ton adresse est vérifiée. Tu recevras les alertes importantes.',
                    primaryLabel: 'Parfait',
                  );
                });
              } else {
                OklFeedback.alert(
                  context,
                  title: 'Code incorrect',
                  message: 'Essaie le code démo 123456 pour valider l’étape.',
                );
              }
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Valider'),
          ),
        ],
      ),
    );
  }

  static void _showCertificateSheet(BuildContext context, UserProfile profile) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.72,
        minChildSize: 0.45,
        maxChildSize: 0.92,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: context.oklSurface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: context.oklDivider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Certificat de compte',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: context.oklOnSurface,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Ce document atteste que le compte a passé les vérifications Oklifor (démo).',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: context.oklOnSurfaceMuted(0.62).withValues(alpha: 0.95),
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 22),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: AppColors.primaryGradient,
                  ),
                  child: Column(
                    children: [
                      const Icon(LucideIcons.shieldCheck, color: Colors.white, size: 42),
                      const SizedBox(height: 12),
                      Text(
                        profile.displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Compte certifié · Niveau maximum',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.92),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _CertRow(k: 'ID certificat', v: 'OKL-TG-${profile.displayName.hashCode.abs()}'),
                            const SizedBox(height: 8),
                            _CertRow(k: 'Téléphone', v: 'Vérifié (SMS)'),
                            const SizedBox(height: 8),
                            _CertRow(k: 'E-mail', v: 'Vérifié'),
                            const SizedBox(height: 8),
                            _CertRow(k: 'Identité', v: 'Document validé'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  height: 120,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: context.oklScaffold,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.oklDivider),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.qrCode, size: 56, color: context.oklOnSurfaceMuted(0.55).withValues(alpha: 0.5)),
                      const SizedBox(height: 8),
                      Text(
                        'QR de vérification (fictif)',
                        style: TextStyle(color: context.oklOnSurfaceMuted(0.55), fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.oklOnSurface,
                    side: BorderSide(color: context.oklDivider),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Fermer'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CertRow extends StatelessWidget {
  final String k;
  final String v;

  const _CertRow({required this.k, required this.v});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            k,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            v,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _TrustHeaderCard extends StatelessWidget {
  final UserProfile profile;

  const _TrustHeaderCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final score = profile.trustScore;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.oklSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.oklDivider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  LucideIcons.shield,
                  color: profile.hasOkliforCertificate
                      ? AppColors.primary
                      : context.oklOnSurfaceMuted(0.62),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.hasOkliforCertificate
                          ? 'Profil certifié Oklifor'
                          : 'Renforce la confiance',
                      style: TextStyle(
                        color: context.oklOnSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      profile.hasOkliforCertificate
                          ? 'Toutes les vérifications sont validées.'
                          : 'Complète les étapes pour obtenir le badge et le certificat.',
                      style: TextStyle(
                        color: context.oklOnSurfaceMuted(0.62).withValues(alpha: 0.95),
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: score / 100,
              minHeight: 8,
              backgroundColor: context.oklScaffold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Indice de confiance : $score % · ${profile.completedVerificationSteps}/3 étapes',
            style: TextStyle(
              color: context.oklOnSurfaceMuted(0.55),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _StepPhoneCard extends StatelessWidget {
  final bool done;

  const _StepPhoneCard({required this.done});

  @override
  Widget build(BuildContext context) {
    return _StepShell(
      icon: LucideIcons.smartphone,
      title: 'Numéro de téléphone',
      subtitle: done
          ? 'Vérifié à l’inscription (SMS).'
          : 'Envoie un SMS pour valider ton numéro.',
      done: done,
      trailing: done
          ? const Icon(LucideIcons.checkCircle, color: AppColors.green, size: 22)
          : TextButton(
              onPressed: () => OklFlows.pushResult(
                context,
                icon: LucideIcons.smartphone,
                title: 'SMS renvoyé',
                subtitle: 'Un nouveau code arrive sous quelques secondes (simulation).',
                primaryLabel: 'OK',
              ),
              child: const Text('Renvoyer'),
            ),
    );
  }
}

class _StepEmailCard extends StatelessWidget {
  final bool done;
  final VoidCallback onVerify;

  const _StepEmailCard({required this.done, required this.onVerify});

  @override
  Widget build(BuildContext context) {
    return _StepShell(
      icon: LucideIcons.mail,
      title: 'Adresse e-mail',
      subtitle: done
          ? 'amina.demo@oklifor.tg confirmée.'
          : 'Ajoute et confirme ton e-mail pour sécuriser le compte.',
      done: done,
      trailing: done
          ? const Icon(LucideIcons.checkCircle, color: AppColors.green, size: 22)
          : FilledButton(
              onPressed: onVerify,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
              child: const Text('Confirmer'),
            ),
    );
  }
}

enum _PieceMode { twoSides, pdf }

enum _CardFace { recto, verso }

class _StepIdentityCard extends ConsumerStatefulWidget {
  final UserProfile profile;

  const _StepIdentityCard({required this.profile});

  @override
  ConsumerState<_StepIdentityCard> createState() => _StepIdentityCardState();
}

class _StepIdentityCardState extends ConsumerState<_StepIdentityCard> {
  Uint8List? _selfieBytes;
  String _selfieFilename = 'selfie.jpg';
  _PieceMode _pieceMode = _PieceMode.twoSides;
  Uint8List? _pdfBytes;
  String _pdfFilename = 'piece.pdf';
  Uint8List? _rectoBytes;
  String _rectoFilename = 'recto.jpg';
  Uint8List? _versoBytes;
  String _versoFilename = 'verso.jpg';
  bool _submitting = false;
  bool _approving = false;

  bool get _pieceReady =>
      _pieceMode == _PieceMode.pdf
          ? (_pdfBytes != null && _pdfBytes!.isNotEmpty)
          : (_rectoBytes != null && _versoBytes != null);

  void _setPieceMode(_PieceMode m) {
    setState(() {
      _pieceMode = m;
      if (m == _PieceMode.pdf) {
        _rectoBytes = null;
        _versoBytes = null;
      } else {
        _pdfBytes = null;
      }
    });
  }

  Future<ImageSource?> _pickImageSource() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: context.oklSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(LucideIcons.camera, color: ctx.oklOnSurface),
              title: Text('Prendre une photo', style: TextStyle(color: ctx.oklOnSurface)),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: Icon(LucideIcons.image, color: ctx.oklOnSurface),
              title: Text('Galerie', style: TextStyle(color: ctx.oklOnSurface)),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickSelfie() async {
    final source = await _pickImageSource();
    if (source == null || !mounted) return;
    if (!await OklPickMediaPermissions.ensureImageSource(context, source)) return;

    final x = await ImagePicker().pickImage(
      source: source,
      maxWidth: 2048,
      imageQuality: 88,
    );
    if (x == null || !mounted) return;
    final bytes = await cropPickedImageIfPossible(
      context: context,
      xFile: x,
      kind: OklImageCropKind.verificationSelfie,
    );
    if (bytes == null || !mounted) return;
    setState(() {
      _selfieBytes = bytes;
      _selfieFilename = 'selfie.jpg';
    });
  }

  Future<void> _pickCardFace(_CardFace face) async {
    final source = await _pickImageSource();
    if (source == null || !mounted) return;
    if (!await OklPickMediaPermissions.ensureImageSource(context, source)) return;

    final x = await ImagePicker().pickImage(
      source: source,
      maxWidth: 2048,
      imageQuality: 88,
    );
    if (x == null || !mounted) return;
    final bytes = await cropPickedImageIfPossible(
      context: context,
      xFile: x,
      kind: OklImageCropKind.verificationId,
    );
    if (bytes == null || !mounted) return;
    final baseName = face == _CardFace.recto ? 'recto.jpg' : 'verso.jpg';
    setState(() {
      _pieceMode = _PieceMode.twoSides;
      _pdfBytes = null;
      if (face == _CardFace.recto) {
        _rectoBytes = bytes;
        _rectoFilename = baseName;
      } else {
        _versoBytes = bytes;
        _versoFilename = baseName;
      }
    });
  }

  Future<void> _pickPdf() async {
    final r = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );
    if (r == null || r.files.isEmpty || !mounted) return;
    final f = r.files.single;
    final bytes = f.bytes;
    if (bytes == null || bytes.isEmpty) return;
    setState(() {
      _pieceMode = _PieceMode.pdf;
      _pdfBytes = bytes;
      _pdfFilename = f.name.isNotEmpty ? f.name : 'piece.pdf';
      _rectoBytes = null;
      _versoBytes = null;
    });
  }

  Future<void> _refreshProfileFromServer() async {
    final me = await ref.read(okliforApiClientProvider).fetchMe();
    if (!mounted) return;
    me.applyToLocalSessions();
  }

  Future<void> _submit() async {
    final selfie = _selfieBytes;
    if (selfie == null || !_pieceReady) return;
    setState(() => _submitting = true);
    try {
      if (_pieceMode == _PieceMode.pdf) {
        await ref.read(okliforApiClientProvider).submitVerificationUpload(
              selfieBytes: selfie,
              selfieFilename: _selfieFilename,
              idPdfBytes: _pdfBytes,
              idPdfFilename: _pdfFilename,
            );
      } else {
        await ref.read(okliforApiClientProvider).submitVerificationUpload(
              selfieBytes: selfie,
              selfieFilename: _selfieFilename,
              idRectoBytes: _rectoBytes,
              idRectoFilename: _rectoFilename,
              idVersoBytes: _versoBytes,
              idVersoFilename: _versoFilename,
            );
      }
      await _refreshProfileFromServer();
      if (!mounted) return;
      await OklFlows.pushResult(
        context,
        icon: LucideIcons.send,
        title: 'Dossier envoyé',
        subtitle:
            'Tes fichiers sont enregistrés sur le serveur. Examen sous 24–48 h ou validation démo.',
        primaryLabel: 'Compris',
      );
    } on OkliforApiException catch (e) {
      if (mounted) {
        OklFeedback.alert(context, title: 'Envoi impossible', message: e.message);
      }
    } catch (e) {
      if (mounted) {
        OklFeedback.alert(context, title: 'Envoi impossible', message: '$e');
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _simulateApprove() async {
    setState(() => _approving = true);
    try {
      await ref.read(okliforApiClientProvider).simulateVerificationApprove();
      await _refreshProfileFromServer();
      if (!mounted) return;
      await OklFlows.pushResult(
        context,
        icon: LucideIcons.badgeCheck,
        title: 'Identité validée',
        subtitle: 'Ton compte affiche le badge vérifié Oklifor (réponse serveur).',
        primaryLabel: 'Super',
      );
    } on OkliforApiException catch (e) {
      if (mounted) {
        OklFeedback.alert(
          context,
          title: 'Action impossible',
          message: e.statusCode == 403
              ? 'La validation démo est désactivée sur ce serveur (OKLIFOR_VERIFICATION_DEMO_APPROVE).'
              : e.message,
        );
      }
    } catch (e) {
      if (mounted) {
        OklFeedback.alert(context, title: 'Erreur', message: '$e');
      }
    } finally {
      if (mounted) setState(() => _approving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.profile;
    if (p.idVerified) {
      return _StepShell(
        icon: LucideIcons.creditCard,
        title: 'Pièce d’identité',
        subtitle: 'Identité validée par Oklifor.',
        done: true,
        trailing: const Icon(LucideIcons.checkCircle, color: AppColors.green, size: 22),
      );
    }

    if (p.idPendingReview) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.oklSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.oklDivider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(LucideIcons.clock, color: AppColors.togoGold, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Dossier en examen',
                    style: TextStyle(
                      color: context.oklOnSurface,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Les fichiers ont été transmis au serveur. En production, une équipe vérifie sous 24–48 h.',
              style: TextStyle(
                color: context.oklOnSurfaceMuted(0.62).withValues(alpha: 0.95),
                fontSize: 13,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: _approving ? null : _simulateApprove,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.togoGreen,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 44),
              ),
              child: _approving
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Simuler validation Oklifor (démo)'),
            ),
          ],
        ),
      );
    }

    final selfieOk = _selfieBytes != null;
    final rectoOk = _rectoBytes != null;
    final versoOk = _versoBytes != null;
    final pdfOk = _pdfBytes != null;
    final hasPiecePreview = selfieOk || (_pieceMode == _PieceMode.pdf ? pdfOk : (rectoOk || versoOk));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.oklSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.oklDivider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.creditCard, color: context.oklOnSurfaceMuted(0.62), size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Pièce d’identité',
                  style: TextStyle(
                    color: context.oklOnSurface,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Étape 1 — Selfie net (visage visible).\n'
            'Étape 2 — Soit un fichier PDF de la pièce, soit une photo recto puis verso (lisibles).\n'
            'Étape 3 — Envoi sécurisé (multipart).',
            style: TextStyle(
              color: context.oklOnSurfaceMuted(0.62).withValues(alpha: 0.95),
              fontSize: 12,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: _submitting ? null : _pickSelfie,
            style: OutlinedButton.styleFrom(
              foregroundColor: context.oklOnSurface,
              side: BorderSide(color: context.oklDivider),
              minimumSize: const Size(double.infinity, 44),
            ),
            icon: Icon(
              selfieOk ? LucideIcons.checkCircle : LucideIcons.camera,
              size: 18,
              color: selfieOk ? AppColors.green : context.oklOnSurfaceMuted(0.62),
            ),
            label: const Text('1. Selfie'),
          ),
          const SizedBox(height: 12),
          Text(
            'Format de la pièce',
            style: TextStyle(
              color: context.oklOnSurfaceMuted(0.55),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          SegmentedButton<_PieceMode>(
            segments: [
              ButtonSegment<_PieceMode>(
                value: _PieceMode.twoSides,
                label: const Text('Recto / verso'),
                icon: const Icon(LucideIcons.image, size: 16),
              ),
              ButtonSegment<_PieceMode>(
                value: _PieceMode.pdf,
                label: const Text('PDF'),
                icon: const Icon(LucideIcons.fileText, size: 16),
              ),
            ],
            selected: {_pieceMode},
            onSelectionChanged: _submitting
                ? null
                : (s) {
                    if (s.isEmpty) return;
                    _setPieceMode(s.first);
                  },
            style: ButtonStyle(
              foregroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.white;
                }
                return context.oklOnSurface;
              }),
            ),
          ),
          const SizedBox(height: 12),
          if (_pieceMode == _PieceMode.pdf)
            OutlinedButton.icon(
              onPressed: _submitting ? null : _pickPdf,
              style: OutlinedButton.styleFrom(
                foregroundColor: context.oklOnSurface,
                side: BorderSide(color: context.oklDivider),
                minimumSize: const Size(double.infinity, 44),
              ),
              icon: Icon(
                pdfOk ? LucideIcons.checkCircle : LucideIcons.fileText,
                size: 18,
                color: pdfOk ? AppColors.green : context.oklOnSurfaceMuted(0.62),
              ),
              label: const Text('2. Choisir un PDF'),
            )
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _submitting ? null : () => _pickCardFace(_CardFace.recto),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.oklOnSurface,
                      side: BorderSide(color: context.oklDivider),
                    ),
                    icon: Icon(
                      rectoOk ? LucideIcons.checkCircle : LucideIcons.fileImage,
                      size: 18,
                      color: rectoOk ? AppColors.green : context.oklOnSurfaceMuted(0.62),
                    ),
                    label: const Text('2a. Recto'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _submitting ? null : () => _pickCardFace(_CardFace.verso),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.oklOnSurface,
                      side: BorderSide(color: context.oklDivider),
                    ),
                    icon: Icon(
                      versoOk ? LucideIcons.checkCircle : LucideIcons.fileImage,
                      size: 18,
                      color: versoOk ? AppColors.green : context.oklOnSurfaceMuted(0.62),
                    ),
                    label: const Text('2b. Verso'),
                  ),
                ),
              ],
            ),
          if (hasPiecePreview) ...[
            const SizedBox(height: 12),
            Text(
              'Aperçu (local)',
              style: TextStyle(
                color: context.oklOnSurfaceMuted(0.5),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            if (selfieOk)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.memory(
                  _selfieBytes!,
                  height: 96,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            if (selfieOk && (_pieceMode == _PieceMode.pdf ? pdfOk : (rectoOk || versoOk)))
              const SizedBox(height: 8),
            if (_pieceMode == _PieceMode.pdf && pdfOk)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                decoration: BoxDecoration(
                  color: context.oklOnSurface.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: context.oklDivider),
                ),
                child: Row(
                  children: [
                    Icon(LucideIcons.fileText, color: context.oklOnSurfaceMuted(0.62)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _pdfFilename,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: context.oklOnSurface, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              )
            else if (_pieceMode == _PieceMode.twoSides && (rectoOk || versoOk))
              Row(
                children: [
                  if (rectoOk)
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.memory(
                          _rectoBytes!,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  if (rectoOk && versoOk) const SizedBox(width: 8),
                  if (versoOk)
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.memory(
                          _versoBytes!,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                ],
              ),
          ],
          const SizedBox(height: 12),
          FilledButton(
            onPressed: (selfieOk && _pieceReady && !_submitting) ? _submit : null,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              disabledBackgroundColor: context.oklOnSurface.withValues(alpha: 0.12),
              minimumSize: const Size(double.infinity, 44),
            ),
            child: _submitting
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                : const Text('3. Soumettre pour vérification'),
          ),
        ],
      ),
    );
  }
}

class _StepShell extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool done;
  final Widget trailing;

  const _StepShell({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.done,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.oklSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: done ? AppColors.green.withValues(alpha: 0.35) : context.oklDivider,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: context.oklOnSurfaceMuted(0.62), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: context.oklOnSurface,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: context.oklOnSurfaceMuted(0.62).withValues(alpha: 0.95),
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          trailing,
        ],
      ),
    );
  }
}

class _LegalNotice extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text(
      'Les vérifications réelles seront traitées conformément à notre politique de confidentialité. '
      'Cet écran est une simulation pour la maquette Oklifor.',
      style: TextStyle(
        color: context.oklOnSurfaceMuted(0.55),
        fontSize: 11,
        height: 1.45,
      ),
    );
  }
}
