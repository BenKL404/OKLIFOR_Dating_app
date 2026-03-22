import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_settings.dart';
import '../../../core/widgets/okl_app_bar_icon_button.dart';
import '../../../core/flows/okl_flows.dart';
import '../../../core/utils/okl_feedback.dart';
import 'account_verification_screen.dart';
import 'edit_profile_screen.dart';
import '../models/user_profile.dart';
import '../models/vip_subscription.dart';
import 'vip_pass_screen.dart';
import '../../common/views/rich_account_screens.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _protectDirectory = true;
  bool _neighborhoodMode = true;
  bool _incognito = false;

  void _openSubPage(Widget page) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => page),
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
        title: const Text(
          'Parametres',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
        children: [
          Text(
            'Securite',
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
                  title: 'Protection du repertoire',
                  value: _protectDirectory,
                  onChanged: (v) => setState(() => _protectDirectory = v),
                ),
                Divider(height: 1, color: Theme.of(context).dividerColor),
                _SwitchSettingRow(
                  icon: LucideIcons.mapPinOff,
                  title: 'Mode quartier (distance floue)',
                  value: _neighborhoodMode,
                  onChanged: (v) => setState(() => _neighborhoodMode = v),
                ),
                Divider(height: 1, color: Theme.of(context).dividerColor),
                _SwitchSettingRow(
                  icon: LucideIcons.eyeOff,
                  title: 'Mode incognito',
                  value: _incognito,
                  onChanged: (v) => setState(() => _incognito = v),
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
                  title: 'Verification et certificat',
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
                  title: 'Confidentialite',
                  onTap: () => _openSubPage(const _PrivacySettingsPage()),
                ),
                Divider(height: 1, color: Theme.of(context).dividerColor),
                _ActionSettingRow(
                  icon: LucideIcons.lock,
                  title: 'Securite du compte',
                  onTap: () => _openSubPage(const _SecuritySettingsPage()),
                ),
                Divider(height: 1, color: Theme.of(context).dividerColor),
                _ActionSettingRow(
                  icon: LucideIcons.slidersHorizontal,
                  title: 'Preferences de l application',
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
                Divider(height: 1, color: Theme.of(context).dividerColor),
                _ActionSettingRow(
                  icon: LucideIcons.logOut,
                  title: 'Deconnexion',
                  destructive: true,
                  onTap: () {
                    OklFeedback.confirm(
                      context,
                      title: 'Deconnexion',
                      body: 'Tu pourras te reconnecter avec ton numero.',
                      confirmLabel: 'Me deconnecter',
                      onConfirm: () => OklFlows.pushResult(
                        context,
                        icon: LucideIcons.logOut,
                        title: 'À bientôt sur Oklifor',
                        subtitle: 'Tu es déconnecté·e. Reconnecte-toi avec ton numéro quand tu veux.',
                        primaryLabel: 'OK',
                      ),
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
                      body: 'Cette action est irreversible.',
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

class _NotificationsSettingsPage extends StatefulWidget {
  const _NotificationsSettingsPage();

  @override
  State<_NotificationsSettingsPage> createState() => _NotificationsSettingsPageState();
}

class _NotificationsSettingsPageState extends State<_NotificationsSettingsPage> {
  bool _messages = true;
  bool _likes = true;
  bool _matchs = true;
  bool _live = false;
  bool _email = false;
  bool _sound = true;

  @override
  Widget build(BuildContext context) {
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
                  value: _messages,
                  onChanged: (v) => setState(() => _messages = v),
                ),
                Divider(height: 1, color: Theme.of(context).dividerColor),
                _SwitchSettingRow(
                  icon: LucideIcons.heart,
                  title: 'Likes et super likes',
                  value: _likes,
                  onChanged: (v) => setState(() => _likes = v),
                ),
                Divider(height: 1, color: Theme.of(context).dividerColor),
                _SwitchSettingRow(
                  icon: LucideIcons.sparkles,
                  title: 'Nouveaux matchs',
                  value: _matchs,
                  onChanged: (v) => setState(() => _matchs = v),
                ),
                Divider(height: 1, color: Theme.of(context).dividerColor),
                _SwitchSettingRow(
                  icon: LucideIcons.radio,
                  title: 'Lives et activites',
                  value: _live,
                  onChanged: (v) => setState(() => _live = v),
                ),
                Divider(height: 1, color: Theme.of(context).dividerColor),
                _SwitchSettingRow(
                  icon: LucideIcons.mail,
                  title: 'Emails Oklifor',
                  value: _email,
                  onChanged: (v) => setState(() => _email = v),
                ),
                Divider(height: 1, color: Theme.of(context).dividerColor),
                _SwitchSettingRow(
                  icon: LucideIcons.volume2,
                  title: 'Sons de notification',
                  value: _sound,
                  onChanged: (v) => setState(() => _sound = v),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PrivacySettingsPage extends StatefulWidget {
  const _PrivacySettingsPage();

  @override
  State<_PrivacySettingsPage> createState() => _PrivacySettingsPageState();
}

class _PrivacySettingsPageState extends State<_PrivacySettingsPage> {
  bool _showOnline = true;
  bool _showDistance = true;
  bool _readReceipts = true;
  bool _allowRequests = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: const OklAppBarBackButton(),
        automaticallyImplyLeading: false,
        title: const Text('Confidentialite'),
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
                  value: _showOnline,
                  onChanged: (v) => setState(() => _showOnline = v),
                ),
                Divider(height: 1, color: Theme.of(context).dividerColor),
                _SwitchSettingRow(
                  icon: LucideIcons.mapPin,
                  title: 'Afficher ma distance',
                  value: _showDistance,
                  onChanged: (v) => setState(() => _showDistance = v),
                ),
                Divider(height: 1, color: Theme.of(context).dividerColor),
                _SwitchSettingRow(
                  icon: LucideIcons.checkCheck,
                  title: 'Accuses de lecture',
                  value: _readReceipts,
                  onChanged: (v) => setState(() => _readReceipts = v),
                ),
                Divider(height: 1, color: Theme.of(context).dividerColor),
                _SwitchSettingRow(
                  icon: LucideIcons.userPlus,
                  title: 'Autoriser demandes de tous',
                  value: _allowRequests,
                  onChanged: (v) => setState(() => _allowRequests = v),
                ),
                Divider(height: 1, color: Theme.of(context).dividerColor),
                _ActionSettingRow(
                  icon: LucideIcons.userX,
                  title: 'Utilisateurs bloques',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const BlockedUsersScreen()),
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

class _SecuritySettingsPage extends StatefulWidget {
  const _SecuritySettingsPage();

  @override
  State<_SecuritySettingsPage> createState() => _SecuritySettingsPageState();
}

class _SecuritySettingsPageState extends State<_SecuritySettingsPage> {
  bool _twoFactor = false;
  bool _biometric = false;
  bool _screenLock = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: const OklAppBarBackButton(),
        automaticallyImplyLeading: false,
        title: const Text('Securite du compte'),
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
                  title: 'Authentification a 2 facteurs',
                  value: _twoFactor,
                  onChanged: (v) => setState(() => _twoFactor = v),
                ),
                Divider(height: 1, color: Theme.of(context).dividerColor),
                _SwitchSettingRow(
                  icon: LucideIcons.fingerprint,
                  title: 'Deblocage biometrie',
                  value: _biometric,
                  onChanged: (v) => setState(() => _biometric = v),
                ),
                Divider(height: 1, color: Theme.of(context).dividerColor),
                _SwitchSettingRow(
                  icon: LucideIcons.lock,
                  title: 'Verrouiller a l ouverture',
                  value: _screenLock,
                  onChanged: (v) => setState(() => _screenLock = v),
                ),
                Divider(height: 1, color: Theme.of(context).dividerColor),
                _ActionSettingRow(
                  icon: LucideIcons.shieldCheck,
                  title: 'Verification du compte (badge)',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const AccountVerificationScreen(),
                    ),
                  ),
                ),
                Divider(height: 1, color: Theme.of(context).dividerColor),
                _ActionSettingRow(
                  icon: LucideIcons.keyRound,
                  title: 'Changer PIN de securite',
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
  }
}

class _AppPreferencesPage extends ConsumerStatefulWidget {
  const _AppPreferencesPage();

  @override
  ConsumerState<_AppPreferencesPage> createState() =>
      _AppPreferencesPageState();
}

class _AppPreferencesPageState extends ConsumerState<_AppPreferencesPage> {
  bool _autoPlay = true;
  bool _dataSaver = false;
  bool _vibrate = true;

  static String _themeLabel(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.light => 'Clair',
      ThemeMode.system => 'Systeme',
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
                    'Theme',
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
                            'Suit le reglage de l appareil',
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

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: const OklAppBarBackButton(),
        automaticallyImplyLeading: false,
        title: const Text('Preferences'),
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
                  title: 'Langue de l application',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const LanguageSettingsScreen()),
                  ),
                ),
                Divider(height: 1, color: Theme.of(context).dividerColor),
                _ActionSettingRow(
                  icon: LucideIcons.palette,
                  title: 'Theme',
                  valueSubtitle: kOklLightThemeBlocked
                      ? 'Sombre (fixe)'
                      : _themeLabel(themeMode),
                  onTap: _openThemeSheet,
                ),
                Divider(height: 1, color: Theme.of(context).dividerColor),
                _SwitchSettingRow(
                  icon: LucideIcons.playCircle,
                  title: 'Lecture auto des medias',
                  value: _autoPlay,
                  onChanged: (v) => setState(() => _autoPlay = v),
                ),
                Divider(height: 1, color: Theme.of(context).dividerColor),
                _SwitchSettingRow(
                  icon: LucideIcons.signal,
                  title: 'Economiseur de donnees',
                  value: _dataSaver,
                  onChanged: (v) => setState(() => _dataSaver = v),
                ),
                Divider(height: 1, color: Theme.of(context).dividerColor),
                _SwitchSettingRow(
                  icon: LucideIcons.vibrate,
                  title: 'Vibrations',
                  value: _vibrate,
                  onChanged: (v) => setState(() => _vibrate = v),
                ),
              ],
            ),
          ),
        ],
      ),
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
                  title: 'Centre d aide',
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
            title: 'Comment modifier mes preferences de profil ?',
            body: 'Ouvre Profil puis Parametres et utilise les sous-pages dediees.',
          ),
          _FaqItem(
            title: 'Comment masquer ma distance ?',
            body: 'Va dans Confidentialite et desactive l option de distance.',
          ),
          _FaqItem(
            title: 'Comment supprimer mon compte ?',
            body: 'Dans Parametres > Session > Supprimer mon compte.',
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
        title: const Text('Conditions et confidentialite'),
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
                  title: 'Conditions d utilisation',
                  onTap: () => _openLegal(context, 'Conditions d’utilisation', [
                    'En utilisant Oklifor, tu acceptes de respecter les lois en vigueur et de fournir des informations sincères sur ton identité lorsque tu choisis de te vérifier.',
                    'L’application est fournie « en l’état » dans cette version démo ; les fonctionnalités peuvent évoluer.',
                    'Pour toute question juridique : legal@oklifor.app (démo).',
                  ]),
                ),
                Divider(height: 1, color: Theme.of(context).dividerColor),
                _ActionSettingRow(
                  icon: LucideIcons.shield,
                  title: 'Politique de confidentialite',
                  onTap: () => _openLegal(context, 'Politique de confidentialité', [
                    'Nous limitons la collecte aux données nécessaires au fonctionnement de l’app (profil, messages, médias que tu envoies).',
                    'Tu peux ajuster la visibilité (distance, statut en ligne) dans Paramètres > Confidentialité.',
                    'Cette version démo ne constitue pas un document juridique définitif.',
                  ]),
                ),
                Divider(height: 1, color: Theme.of(context).dividerColor),
                _ActionSettingRow(
                  icon: LucideIcons.scale,
                  title: 'Regles de la communaute',
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
