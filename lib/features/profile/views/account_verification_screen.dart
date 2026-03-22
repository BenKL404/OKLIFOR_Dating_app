import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/widgets/okl_app_bar_icon_button.dart';
import '../../../core/flows/okl_flows.dart';
import '../../../core/utils/okl_feedback.dart';
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

class _StepIdentityCard extends StatefulWidget {
  final UserProfile profile;

  const _StepIdentityCard({required this.profile});

  @override
  State<_StepIdentityCard> createState() => _StepIdentityCardState();
}

class _StepIdentityCardState extends State<_StepIdentityCard> {
  bool _selfieOk = false;
  bool _docOk = false;

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
              'Notre équipe vérifie tes documents sous 24–48 h (simulation).',
              style: TextStyle(
                color: context.oklOnSurfaceMuted(0.62).withValues(alpha: 0.95),
                fontSize: 13,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: () {
                ProfileSession.update(
                  (x) => x.copyWith(idVerified: true, idPendingReview: false),
                );
                OklFlows.pushResult(
                  context,
                  icon: LucideIcons.badgeCheck,
                  title: 'Identité validée',
                  subtitle: 'Ton compte affiche désormais le badge vérifié Oklifor.',
                  primaryLabel: 'Super',
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.togoGreen,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 44),
              ),
              child: const Text('Simuler validation Oklifor'),
            ),
          ],
        ),
      );
    }

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
            '1. Selfie net · 2. Photo lisible de ta CNI ou passeport · 3. Les données sont chiffrées (démo).',
            style: TextStyle(
              color: context.oklOnSurfaceMuted(0.62).withValues(alpha: 0.95),
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() => _selfieOk = true);
                    OklFlows.pushResult(
                      context,
                      icon: LucideIcons.camera,
                      title: 'Selfie enregistré',
                      subtitle: 'Étape 1 sur 2 — ajoute maintenant ta pièce d’identité.',
                      primaryLabel: 'Continuer',
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.oklOnSurface,
                    side: BorderSide(color: context.oklDivider),
                  ),
                  icon: Icon(
                    _selfieOk ? LucideIcons.checkCircle : LucideIcons.camera,
                    size: 18,
                    color: _selfieOk ? AppColors.green : context.oklOnSurfaceMuted(0.62),
                  ),
                  label: const Text('Selfie'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() => _docOk = true);
                    OklFlows.pushResult(
                      context,
                      icon: LucideIcons.fileImage,
                      title: 'Pièce importée',
                      subtitle: 'Vérifie que les informations sont lisibles avant envoi.',
                      primaryLabel: 'OK',
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.oklOnSurface,
                    side: BorderSide(color: context.oklDivider),
                  ),
                  icon: Icon(
                    _docOk ? LucideIcons.checkCircle : LucideIcons.fileImage,
                    size: 18,
                    color: _docOk ? AppColors.green : context.oklOnSurfaceMuted(0.62),
                  ),
                  label: const Text('Pièce'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: (_selfieOk && _docOk)
                ? () {
                    ProfileSession.update(
                      (x) => x.copyWith(idPendingReview: true),
                    );
                    OklFlows.pushResult(
                      context,
                      icon: LucideIcons.send,
                      title: 'Dossier envoyé',
                      subtitle:
                          'Notre équipe examine les documents sous 24 à 48 h. Tu seras notifié·e.',
                      primaryLabel: 'Compris',
                    );
                  }
                : null,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              disabledBackgroundColor: context.oklOnSurface.withValues(alpha: 0.12),
              minimumSize: const Size(double.infinity, 44),
            ),
            child: const Text('Soumettre pour vérification'),
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
