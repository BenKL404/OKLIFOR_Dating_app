import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_settings.dart';
import '../../../core/widgets/okl_app_bar_icon_button.dart';
import '../../../core/flows/okl_flows.dart';
import '../../../core/utils/okl_feedback.dart';
import '../../auth/providers/auth_api_provider.dart';
import '../models/settings_session.dart';
import '../services/settings_persist.dart';
import '../../../core/api/models/settings_patch_body.dart';
import '../../../core/security/okl_local_auth_service.dart';
import '../../../core/security/okl_security_pin_storage.dart';
import 'account_verification_screen.dart';
import 'edit_profile_screen.dart';
import '../models/user_profile.dart';
import '../models/vip_subscription.dart';
import 'vip_pass_screen.dart';
import '../../common/views/rich_account_screens.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  void _openSubPage(Widget page) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: SettingsSession.settings,
      builder: (context, _) {
        final s = SettingsSession.settings.value;
        return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: const OklAppBarBackButton(),
        automaticallyImplyLeading: false,
        title: const Text(
          'Paramètres',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
        children: [
          Text(
            'Sécurité',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Column(
              children: [
                _SwitchSettingRow(
                  icon: LucideIcons.bookLock,
                  title: 'Protection du répertoire',
                  value: s.protectDirectory,
                  onChanged: (v) => persistAppSettings(
                    ref,
                    context,
                    applyOptimistic: (p) => p.copyWith(protectDirectory: v),
                    patch: SettingsPatchBody(protectDirectory: v),
                  ),
                ),
                Divider(height: 1, color: Theme.of(context).dividerColor),
                _SwitchSettingRow(
                  icon: LucideIcons.mapPinOff,
                  title: 'Mode quartier (distance floue)',
                  value: s.neighborhoodMode,
                  onChanged: (v) => persistAppSettings(
                    ref,
                    context,
                    applyOptimistic: (p) => p.copyWith(neighborhoodMode: v),
                    patch: SettingsPatchBody(neighborhoodMode: v),
                  ),
                ),
                Divider(height: 1, color: Theme.of(context).dividerColor),
                _SwitchSettingRow(
                  icon: LucideIcons.eyeOff,
                  title: 'Mode incognito',
                  value: s.incognito,
                  onChanged: (v) => persistAppSettings(
                    ref,
                    context,
                    applyOptimistic: (p) => p.copyWith(incognito: v),
                    patch: SettingsPatchBody(incognito: v),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Abonnement',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          ValueListenableBuilder<VipSubscriptionState>(
            valueListenable: VipSession.subscription,
            builder: (context, vip, _) {
              return Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Column(
                  children: [
                    _ActionSettingRow(
                      icon: LucideIcons.crown,
                      title: vip.isActive ? 'Pass VIP actif' : 'Obtenir mon Pass VIP',
                      valueSubtitle: vip.isActive ? 'Jusqu’au ${vip.expiresLabelFr}' : 'Mobile Money (démo)',
                      onTap: () => _openSubPage(const VipPassScreen()),
                    ),
                    if (vip.isActive) ...[
                      Divider(height: 1, color: Theme.of(context).dividerColor),
                      _ActionSettingRow(
                        icon: LucideIcons.rotateCcw,
                        title: 'Réinitialiser le VIP (démo)',
                        valueSubtitle: 'Pour retester le parcours',
                        onTap: () => VipSession.deactivateDemo(),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            'Compte',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Column(
              children: [
                _ActionSettingRow(
                  icon: LucideIcons.pencil,
                  title: 'Modifier mon profil',
                  onTap: () => _openSubPage(
                    EditProfileScreen(initial: ProfileSession.profile.value),
                  ),
                ),
                Divider(height: 1, color: Theme.of(context).dividerColor),
                _ActionSettingRow(
                  icon: LucideIcons.badgeCheck,
                  title: 'Vérification et certificat',
                  onTap: () => _openSubPage(const AccountVerificationScreen()),
                ),
                Divider(height: 1, color: Theme.of(context).dividerColor),
                _ActionSettingRow(
                  icon: LucideIcons.bell,
                  title: 'Notifications',
                  onTap: () => _openSubPage(const _NotificationsSettingsPage()),
                ),
                Divider(height: 1, color: Theme.of(context).dividerColor),
                _ActionSettingRow(
                  icon: LucideIcons.shield,
                  title: 'Confidentialité',
                  onTap: () => _openSubPage(const _PrivacySettingsPage()),
                ),
                Divider(height: 1, color: Theme.of(context).dividerColor),
                _ActionSettingRow(
                  icon: LucideIcons.lock,
                  title: 'Sécurité du compte',
                  onTap: () => _openSubPage(const _SecuritySettingsPage()),
                ),
                Divider(height: 1, color: Theme.of(context).dividerColor),
                _ActionSettingRow(
                  icon: LucideIcons.slidersHorizontal,
                  title: 'Préférences de l’application',
                  onTap: () => _openSubPage(const _AppPreferencesPage()),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Support',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Column(
              children: [
                _ActionSettingRow(
                  icon: LucideIcons.helpCircle,
                  title: 'Aide et support',
                  onTap: () => _openSubPage(const _HelpSupportPage()),
                ),
                Divider(height: 1, color: Theme.of(context).dividerColor),
                _ActionSettingRow(
                  icon: LucideIcons.messagesSquare,
                  title: 'FAQ',
                  onTap: () => _openSubPage(const _FaqSettingsPage()),
                ),
                Divider(height: 1, color: Theme.of(context).dividerColor),
                _ActionSettingRow(
                  icon: LucideIcons.fileText,
                  title: 'Conditions et confidentialite',
                  onTap: () => _openSubPage(const _LegalSettingsPage()),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Session',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Column(
              children: [
                _ActionSettingRow(
                  icon: LucideIcons.logOut,
                  title: 'Déconnexion',
                  destructive: true,
                  onTap: () {
                    OklFeedback.confirm(
                      context,
                      title: 'Déconnexion',
                      body: 'Tu pourras te reconnecter avec ton numéro.',
                      confirmLabel: 'Me déconnecter',
                      onConfirm: () async {
                        await ref.read(okliforApiClientProvider).logout();
                        SettingsSession.reset();
                        ProfileSession.set(UserProfile.initialDemo());
                        VipSession.deactivateDemo();
                        if (!context.mounted) return;
                        await OklFlows.pushResult(
                          context,
                          icon: LucideIcons.logOut,
                          title: 'À bientôt sur Oklifor',
                          subtitle:
                              'Tu es déconnecté·e. Reconnecte-toi avec ton numéro quand tu veux.',
                          primaryLabel: 'OK',
                        );
                        if (context.mounted) context.go('/login');
                      },
                    );
                  },
                ),
                Divider(height: 1, color: Theme.of(context).dividerColor),
                _ActionSettingRow(
                  icon: LucideIcons.trash2,
                  title: 'Supprimer mon compte',
                  destructive: true,
                  onTap: () {
                    OklFeedback.confirm(
                      context,
                      title: 'Supprimer le compte',
                      body: 'Cette action est irréversible.',
                      confirmLabel: 'Supprimer',
                      onConfirm: () => OklFlows.pushResult(
                        context,
                        icon: LucideIcons.trash2,
                        iconColor: AppColors.togoRed,
                          title: 'Demande enregistrée',
                        subtitle:
                            'Notre équipe traitera la suppression sous quelques jours. Tu recevras un e-mail de confirmation.',
                        primaryLabel: 'Compris',
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
      },
    );
  }
}

class _SwitchSettingRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchSettingRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: cs.onSurface.withValues(alpha: 0.55), size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: cs.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Switch.adaptive(
            value: value,
            activeTrackColor: AppColors.primary,
            activeThumbColor: Colors.white,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _ActionSettingRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? valueSubtitle;
  final bool destructive;
  final VoidCallback onTap;

  const _ActionSettingRow({
    required this.icon,
    required this.title,
    required this.onTap,
    this.valueSubtitle,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = destructive ? AppColors.primary : cs.onSurface;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(
                icon,
                color: cs.onSurface.withValues(alpha: 0.55),
                size: 18,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (valueSubtitle != null) ...[
                Text(
                  valueSubtitle!,
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.5),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              if (!destructive)
                Icon(
                  LucideIcons.chevronRight,
                  color: cs.onSurface.withValues(alpha: 0.35),
                  size: 16,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationsSettingsPage extends ConsumerStatefulWidget {
  const _NotificationsSettingsPage();

  @override
  ConsumerState<_NotificationsSettingsPage> createState() =>
      _NotificationsSettingsPageState();
}

class _NotificationsSettingsPageState
    extends ConsumerState<_NotificationsSettingsPage> {
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: SettingsSession.settings,
      builder: (context, _) {
        final s = SettingsSession.settings.value;
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            leading: const OklAppBarBackButton(),
            automaticallyImplyLeading: false,
            title: const Text('Notifications'),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Column(
                  children: [
                    _SwitchSettingRow(
                      icon: LucideIcons.messageCircle,
                      title: 'Nouveaux messages',
                      value: s.notifyMessages,
                      onChanged: (v) => persistAppSettings(
                        ref,
                        context,
                        applyOptimistic: (p) => p.copyWith(notifyMessages: v),
                        patch: SettingsPatchBody(notifyMessages: v),
                      ),
                    ),
                    Divider(height: 1, color: Theme.of(context).dividerColor),
                    _SwitchSettingRow(
                      icon: LucideIcons.heart,
                      title: 'Likes et super likes',
                      value: s.notifyLikes,
                      onChanged: (v) => persistAppSettings(
                        ref,
                        context,
                        applyOptimistic: (p) => p.copyWith(notifyLikes: v),
                        patch: SettingsPatchBody(notifyLikes: v),
                      ),
                    ),
                    Divider(height: 1, color: Theme.of(context).dividerColor),
                    _SwitchSettingRow(
                      icon: LucideIcons.sparkles,
                      title: 'Nouveaux matchs',
                      value: s.notifyMatches,
                      onChanged: (v) => persistAppSettings(
                        ref,
                        context,
                        applyOptimistic: (p) => p.copyWith(notifyMatches: v),
                        patch: SettingsPatchBody(notifyMatches: v),
                      ),
                    ),
                    Divider(height: 1, color: Theme.of(context).dividerColor),
                    _SwitchSettingRow(
                      icon: LucideIcons.radio,
                      title: 'Lives et activités',
                      value: s.notifyLive,
                      onChanged: (v) => persistAppSettings(
                        ref,
                        context,
                        applyOptimistic: (p) => p.copyWith(notifyLive: v),
                        patch: SettingsPatchBody(notifyLive: v),
                      ),
                    ),
                    Divider(height: 1, color: Theme.of(context).dividerColor),
                    _SwitchSettingRow(
                      icon: LucideIcons.mail,
                      title: 'Emails Oklifor',
                      value: s.notifyEmail,
                      onChanged: (v) => persistAppSettings(
                        ref,
                        context,
                        applyOptimistic: (p) => p.copyWith(notifyEmail: v),
                        patch: SettingsPatchBody(notifyEmail: v),
                      ),
                    ),
                    Divider(height: 1, color: Theme.of(context).dividerColor),
                    _SwitchSettingRow(
                      icon: LucideIcons.volume2,
                      title: 'Sons de notification',
                      value: s.notifySound,
                      onChanged: (v) => persistAppSettings(
                        ref,
                        context,
                        applyOptimistic: (p) => p.copyWith(notifySound: v),
                        patch: SettingsPatchBody(notifySound: v),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PrivacySettingsPage extends ConsumerStatefulWidget {
  const _PrivacySettingsPage();

  @override
  ConsumerState<_PrivacySettingsPage> createState() => _PrivacySettingsPageState();
}

class _PrivacySettingsPageState extends ConsumerState<_PrivacySettingsPage> {
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: SettingsSession.settings,
      builder: (context, _) {
        final s = SettingsSession.settings.value;
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            leading: const OklAppBarBackButton(),
            automaticallyImplyLeading: false,
            title: const Text('Confidentialité'),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Column(
                  children: [
                    _SwitchSettingRow(
                      icon: LucideIcons.wifi,
                      title: 'Afficher mon statut en ligne',
                      value: s.privacyShowOnline,
                      onChanged: (v) => persistAppSettings(
                        ref,
                        context,
                        applyOptimistic: (p) =>
                            p.copyWith(privacyShowOnline: v),
                        patch: SettingsPatchBody(privacyShowOnline: v),
                      ),
                    ),
                    Divider(height: 1, color: Theme.of(context).dividerColor),
                    _SwitchSettingRow(
                      icon: LucideIcons.mapPin,
                      title: 'Afficher ma distance',
                      value: s.privacyShowDistance,
                      onChanged: (v) => persistAppSettings(
                        ref,
                        context,
                        applyOptimistic: (p) =>
                            p.copyWith(privacyShowDistance: v),
                        patch: SettingsPatchBody(privacyShowDistance: v),
                      ),
                    ),
                    Divider(height: 1, color: Theme.of(context).dividerColor),
                    _SwitchSettingRow(
                      icon: LucideIcons.checkCheck,
                      title: 'Accusés de lecture',
                      value: s.privacyReadReceipts,
                      onChanged: (v) => persistAppSettings(
                        ref,
                        context,
                        applyOptimistic: (p) =>
                            p.copyWith(privacyReadReceipts: v),
                        patch: SettingsPatchBody(privacyReadReceipts: v),
                      ),
                    ),
                    Divider(height: 1, color: Theme.of(context).dividerColor),
                    _SwitchSettingRow(
                      icon: LucideIcons.userPlus,
                      title: 'Autoriser demandes de tous',
                      value: s.privacyAllowRequests,
                      onChanged: (v) => persistAppSettings(
                        ref,
                        context,
                        applyOptimistic: (p) =>
                            p.copyWith(privacyAllowRequests: v),
                        patch: SettingsPatchBody(privacyAllowRequests: v),
                      ),
                    ),
                    Divider(height: 1, color: Theme.of(context).dividerColor),
                    _ActionSettingRow(
                      icon: LucideIcons.userX,
                      title: 'Utilisateurs bloqués',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                            builder: (_) => const BlockedUsersScreen()),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SecuritySettingsPage extends ConsumerStatefulWidget {
  const _SecuritySettingsPage();

  @override
  ConsumerState<_SecuritySettingsPage> createState() =>
      _SecuritySettingsPageState();
}

class _SecuritySettingsPageState extends ConsumerState<_SecuritySettingsPage> {
  Future<void> _onTwoFactorChanged(bool v) async {
    if (!mounted) return;
    if (v) {
      final go = await showDialog<bool>(
        context: context,
        builder: (ctx) {
          final t = Theme.of(ctx);
          return AlertDialog(
            backgroundColor: t.colorScheme.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              'Double authentification',
              style: TextStyle(color: t.colorScheme.onSurface, fontWeight: FontWeight.w700),
            ),
            content: Text(
              'Tu pourras recevoir un code par SMS lors des connexions depuis un nouvel appareil ou pour des actions sensibles.',
              style: TextStyle(
                color: t.textTheme.bodyMedium?.color ?? t.colorScheme.onSurface,
                fontSize: 14,
                height: 1.35,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Annuler'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                child: const Text('Activer'),
              ),
            ],
          );
        },
      );
      if (go != true) return;
    } else {
      final go = await showDialog<bool>(
        context: context,
        builder: (ctx) {
          final t = Theme.of(ctx);
          return AlertDialog(
            backgroundColor: t.colorScheme.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              'Désactiver la 2FA ?',
              style: TextStyle(color: t.colorScheme.onSurface, fontWeight: FontWeight.w700),
            ),
            content: Text(
              'Sans la double authentification, ton compte est plus vulnérable si quelqu’un accède à ton téléphone.',
              style: TextStyle(
                color: t.textTheme.bodyMedium?.color ?? t.colorScheme.onSurface,
                fontSize: 14,
                height: 1.35,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Annuler'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                child: const Text('Désactiver'),
              ),
            ],
          );
        },
      );
      if (go != true) return;
    }
    if (!mounted) return;
    await persistAppSettings(
      ref,
      context,
      applyOptimistic: (p) => p.copyWith(securityTwoFactor: v),
      patch: SettingsPatchBody(securityTwoFactor: v),
    );
  }

  Future<void> _onBiometricChanged(bool v) async {
    if (!mounted) return;
    if (kIsWeb) {
      OklFeedback.alert(
        context,
        title: 'Indisponible',
        message: 'La biométrie n’est pas disponible sur le web.',
      );
      return;
    }
    if (!v) {
      await persistAppSettings(
        ref,
        context,
        applyOptimistic: (p) => p.copyWith(securityBiometric: false),
        patch: SettingsPatchBody(securityBiometric: false),
      );
      return;
    }
    final svc = OklLocalAuthService();
    if (!await svc.deviceSupportsBiometrics()) {
      if (!mounted) return;
      OklFeedback.alert(
        context,
        title: 'Biométrie indisponible',
        message:
            'Aucune empreinte ou reconnaissance faciale n’est configurée sur cet appareil.',
      );
      return;
    }
    final ok = await svc.authenticateEnrollment(
      localizedReason: 'Confirme ton identité pour activer le déverrouillage biométrique.',
    );
    if (!ok || !mounted) return;
    await persistAppSettings(
      ref,
      context,
      applyOptimistic: (p) => p.copyWith(securityBiometric: true),
      patch: SettingsPatchBody(securityBiometric: true),
    );
  }

  Future<void> _onScreenLockChanged(bool v) async {
    if (!mounted) return;
    if (!v) {
      await persistAppSettings(
        ref,
        context,
        applyOptimistic: (p) => p.copyWith(securityScreenLock: false),
        patch: SettingsPatchBody(securityScreenLock: false),
      );
      return;
    }
    final hasPin = await OklSecurityPinStorage.hasPin();
    final bio = SettingsSession.settings.value.securityBiometric;
    if (!hasPin && !bio) {
      if (!mounted) return;
      OklFeedback.alert(
        context,
        title: 'Code ou biométrie requis',
        message:
            'Définis un code PIN ci-dessous (« Changer PIN ») ou active la biométrie avant de verrouiller l’app.',
      );
      return;
    }
    if (!mounted) return;
    await persistAppSettings(
      ref,
      context,
      applyOptimistic: (p) => p.copyWith(securityScreenLock: true),
      patch: SettingsPatchBody(securityScreenLock: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: SettingsSession.settings,
      builder: (context, _) {
        final s = SettingsSession.settings.value;
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            leading: const OklAppBarBackButton(),
            automaticallyImplyLeading: false,
            title: const Text('Sécurité du compte'),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Column(
                  children: [
                    _SwitchSettingRow(
                      icon: LucideIcons.shieldCheck,
                      title: 'Authentification à 2 facteurs',
                      value: s.securityTwoFactor,
                      onChanged: (v) => _onTwoFactorChanged(v),
                    ),
                    Divider(height: 1, color: Theme.of(context).dividerColor),
                    _SwitchSettingRow(
                      icon: LucideIcons.fingerprint,
                      title: 'Déblocage biométrique',
                      value: s.securityBiometric,
                      onChanged: (v) => _onBiometricChanged(v),
                    ),
                    Divider(height: 1, color: Theme.of(context).dividerColor),
                    _SwitchSettingRow(
                      icon: LucideIcons.lock,
                      title: 'Verrouiller à l’ouverture',
                      value: s.securityScreenLock,
                      onChanged: (v) => _onScreenLockChanged(v),
                    ),
                Divider(height: 1, color: Theme.of(context).dividerColor),
                _ActionSettingRow(
                  icon: LucideIcons.shieldCheck,
                  title: 'Vérification du compte (badge)',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const AccountVerificationScreen(),
                    ),
                  ),
                ),
                Divider(height: 1, color: Theme.of(context).dividerColor),
                _ActionSettingRow(
                  icon: LucideIcons.keyRound,
                  title: 'Changer le PIN de sécurité',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const ChangePinScreen()),
                  ),
                ),
                Divider(height: 1, color: Theme.of(context).dividerColor),
                _ActionSettingRow(
                  icon: LucideIcons.smartphone,
                  title: 'Sessions actives',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const ActiveSessionsScreen()),
                  ),
                ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AppPreferencesPage extends ConsumerStatefulWidget {
  const _AppPreferencesPage();

  @override
  ConsumerState<_AppPreferencesPage> createState() =>
      _AppPreferencesPageState();
}

class _AppPreferencesPageState extends ConsumerState<_AppPreferencesPage> {
  static String _themeLabel(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.light => 'Clair',
      ThemeMode.system => 'Système',
      ThemeMode.dark => 'Sombre',
    };
  }

  Future<void> _openThemeSheet() async {
    if (kOklLightThemeBlocked) {
      OklFeedback.alert(
        context,
        title: 'Thème clair',
        message: 'Le thème clair est désactivé pour l’instant dans cette build.',
      );
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: Theme.of(ctx).dividerColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 12, bottom: 4),
                  child: Text(
                    'Thème',
                    style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                ...[
                  ThemeMode.dark,
                  if (!kOklLightThemeBlocked) ...[
                    ThemeMode.light,
                    ThemeMode.system,
                  ],
                ].map((mode) {
                  final current = ref.watch(themeModeProvider);
                  return ListTile(
                    title: Text(_themeLabel(mode)),
                    subtitle: mode == ThemeMode.system
                        ? Text(
                            'Suit le réglage de l’appareil',
                            style: Theme.of(ctx).textTheme.bodySmall,
                          )
                        : null,
                    trailing: current == mode
                        ? Icon(LucideIcons.check, color: AppColors.primary, size: 20)
                        : null,
                    onTap: () async {
                      await ref.read(themeModeProvider.notifier).setThemeMode(mode);
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  static String _languageLabel(String code) {
    return switch (code) {
      'en' => 'English',
      _ => 'Français',
    };
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    return AnimatedBuilder(
      animation: SettingsSession.settings,
      builder: (context, _) {
        final s = SettingsSession.settings.value;
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            leading: const OklAppBarBackButton(),
            automaticallyImplyLeading: false,
            title: const Text('Préférences'),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Column(
                  children: [
                    _ActionSettingRow(
                      icon: LucideIcons.languages,
                      title: 'Langue de l’application',
                      valueSubtitle: _languageLabel(s.appLanguage),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                            builder: (_) => const LanguageSettingsScreen()),
                      ),
                    ),
                    Divider(height: 1, color: Theme.of(context).dividerColor),
                    _ActionSettingRow(
                      icon: LucideIcons.palette,
                      title: 'Thème',
                      valueSubtitle: kOklLightThemeBlocked
                          ? 'Sombre (fixe)'
                          : _themeLabel(themeMode),
                      onTap: _openThemeSheet,
                    ),
                    Divider(height: 1, color: Theme.of(context).dividerColor),
                    _SwitchSettingRow(
                      icon: LucideIcons.playCircle,
                      title: 'Lecture auto des médias',
                      value: s.appAutoPlayMedia,
                      onChanged: (v) => persistAppSettings(
                        ref,
                        context,
                        applyOptimistic: (p) =>
                            p.copyWith(appAutoPlayMedia: v),
                        patch: SettingsPatchBody(appAutoPlayMedia: v),
                      ),
                    ),
                    Divider(height: 1, color: Theme.of(context).dividerColor),
                    _SwitchSettingRow(
                      icon: LucideIcons.signal,
                      title: 'Économiseur de données',
                      value: s.appDataSaver,
                      onChanged: (v) => persistAppSettings(
                        ref,
                        context,
                        applyOptimistic: (p) => p.copyWith(appDataSaver: v),
                        patch: SettingsPatchBody(appDataSaver: v),
                      ),
                    ),
                    Divider(height: 1, color: Theme.of(context).dividerColor),
                    _SwitchSettingRow(
                      icon: LucideIcons.vibrate,
                      title: 'Vibrations',
                      value: s.appVibrate,
                      onChanged: (v) => persistAppSettings(
                        ref,
                        context,
                        applyOptimistic: (p) => p.copyWith(appVibrate: v),
                        patch: SettingsPatchBody(appVibrate: v),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HelpSupportPage extends StatelessWidget {
  const _HelpSupportPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: const OklAppBarBackButton(),
        automaticallyImplyLeading: false,
        title: const Text('Aide et support'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Column(
              children: [
                _ActionSettingRow(
                  icon: LucideIcons.bookOpen,
                  title: 'Centre d’aide',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const HelpCenterScreen()),
                  ),
                ),
                Divider(height: 1, color: Theme.of(context).dividerColor),
                _ActionSettingRow(
                  icon: LucideIcons.mail,
                  title: 'Contacter le support',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const ContactSupportScreen()),
                  ),
                ),
                Divider(height: 1, color: Theme.of(context).dividerColor),
                _ActionSettingRow(
                  icon: LucideIcons.bug,
                  title: 'Signaler un bug',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const BugReportScreen()),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FaqSettingsPage extends StatelessWidget {
  const _FaqSettingsPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: const OklAppBarBackButton(),
        automaticallyImplyLeading: false,
        title: const Text('FAQ'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _FaqItem(
            title: 'Comment modifier mes préférences de profil ?',
            body: 'Ouvre Profil puis Paramètres et utilise les sous-pages dédiées.',
          ),
          _FaqItem(
            title: 'Comment masquer ma distance ?',
            body: 'Va dans Confidentialité et désactive l’option de distance.',
          ),
          _FaqItem(
            title: 'Comment supprimer mon compte ?',
            body: 'Dans Paramètres > Session > Supprimer mon compte.',
          ),
        ],
      ),
    );
  }
}

class _FaqItem extends StatelessWidget {
  final String title;
  final String body;

  const _FaqItem({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: ExpansionTile(
        iconColor: cs.onSurface.withValues(alpha: 0.55),
        collapsedIconColor: cs.onSurface.withValues(alpha: 0.55),
        title: Text(
          title,
          style: TextStyle(
            color: cs.onSurface,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Text(
              body,
              style: TextStyle(
                color: cs.onSurface.withValues(alpha: 0.65),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegalSettingsPage extends StatelessWidget {
  const _LegalSettingsPage();

  void _openLegal(BuildContext context, String title, List<String> paragraphs) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => OklLegalDocumentScreen(title: title, paragraphs: paragraphs),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: const OklAppBarBackButton(),
        automaticallyImplyLeading: false,
        title: const Text('Conditions et confidentialité'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Column(
              children: [
                _ActionSettingRow(
                  icon: LucideIcons.fileCheck,
                  title: 'Conditions d’utilisation',
                  onTap: () => _openLegal(context, 'Conditions d’utilisation', [
                    'En utilisant Oklifor, tu acceptes de respecter les lois en vigueur et de fournir des informations sincères sur ton identité lorsque tu choisis de te vérifier.',
                    'L’application est fournie « en l’état » dans cette version démo ; les fonctionnalités peuvent évoluer.',
                    'Pour toute question juridique : legal@oklifor.app (démo).',
                  ]),
                ),
                Divider(height: 1, color: Theme.of(context).dividerColor),
                _ActionSettingRow(
                  icon: LucideIcons.shield,
                  title: 'Politique de confidentialité',
                  onTap: () => _openLegal(context, 'Politique de confidentialité', [
                    'Nous limitons la collecte aux données nécessaires au fonctionnement de l’app (profil, messages, médias que tu envoies).',
                    'Tu peux ajuster la visibilité (distance, statut en ligne) dans Paramètres > Confidentialité.',
                    'Cette version démo ne constitue pas un document juridique définitif.',
                  ]),
                ),
                Divider(height: 1, color: Theme.of(context).dividerColor),
                _ActionSettingRow(
                  icon: LucideIcons.scale,
                  title: 'Règles de la communauté',
                  onTap: () => _openLegal(context, 'Règles de la communauté', [
                    'Respect et consentement : pas de harcèlement, pas de contenu illégal.',
                    'Signale les profils ou messages problématiques depuis le menu conversation ou le profil.',
                    'Les organisateurs d’événements communautaires doivent veiller à la sécurité des participants.',
                  ]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
