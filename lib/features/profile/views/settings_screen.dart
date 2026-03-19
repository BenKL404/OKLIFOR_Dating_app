import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/okl_feedback.dart';

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
      backgroundColor: AppColors.dark,
      appBar: AppBar(
        backgroundColor: AppColors.dark,
        title: const Text(
          'Parametres',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
        children: [
          const Text(
            'Securite',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              children: [
                _SwitchSettingRow(
                  icon: LucideIcons.bookLock,
                  title: 'Protection du repertoire',
                  value: _protectDirectory,
                  onChanged: (v) {
                    setState(() => _protectDirectory = v);
                    OklFeedback.snack(
                      context,
                      v ? 'Repertoire protege' : 'Protection desactivee',
                    );
                  },
                ),
                const Divider(height: 1, color: AppColors.divider),
                _SwitchSettingRow(
                  icon: LucideIcons.mapPinOff,
                  title: 'Mode quartier (distance floue)',
                  value: _neighborhoodMode,
                  onChanged: (v) {
                    setState(() => _neighborhoodMode = v);
                    OklFeedback.snack(
                      context,
                      v ? 'Distance approximative activee' : 'Distance precise',
                    );
                  },
                ),
                const Divider(height: 1, color: AppColors.divider),
                _SwitchSettingRow(
                  icon: LucideIcons.eyeOff,
                  title: 'Mode incognito',
                  value: _incognito,
                  onChanged: (v) {
                    setState(() => _incognito = v);
                    OklFeedback.snack(
                      context,
                      v ? 'Navigation en discret' : 'Mode normal',
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Compte',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              children: [
                _ActionSettingRow(
                  icon: LucideIcons.bell,
                  title: 'Notifications',
                  onTap: () => _openSubPage(const _NotificationsSettingsPage()),
                ),
                const Divider(height: 1, color: AppColors.divider),
                _ActionSettingRow(
                  icon: LucideIcons.shield,
                  title: 'Confidentialite',
                  onTap: () => _openSubPage(const _PrivacySettingsPage()),
                ),
                const Divider(height: 1, color: AppColors.divider),
                _ActionSettingRow(
                  icon: LucideIcons.lock,
                  title: 'Securite du compte',
                  onTap: () => _openSubPage(const _SecuritySettingsPage()),
                ),
                const Divider(height: 1, color: AppColors.divider),
                _ActionSettingRow(
                  icon: LucideIcons.slidersHorizontal,
                  title: 'Preferences de l application',
                  onTap: () => _openSubPage(const _AppPreferencesPage()),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Support',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              children: [
                _ActionSettingRow(
                  icon: LucideIcons.helpCircle,
                  title: 'Aide et support',
                  onTap: () => _openSubPage(const _HelpSupportPage()),
                ),
                const Divider(height: 1, color: AppColors.divider),
                _ActionSettingRow(
                  icon: LucideIcons.messagesSquare,
                  title: 'FAQ',
                  onTap: () => _openSubPage(const _FaqSettingsPage()),
                ),
                const Divider(height: 1, color: AppColors.divider),
                _ActionSettingRow(
                  icon: LucideIcons.fileText,
                  title: 'Conditions et confidentialite',
                  onTap: () => _openSubPage(const _LegalSettingsPage()),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Session',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              children: [
                const Divider(height: 1, color: AppColors.divider),
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
                      onConfirm: () =>
                          OklFeedback.snack(context, 'A bientot sur Oklifor'),
                    );
                  },
                ),
                const Divider(height: 1, color: AppColors.divider),
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
                      onConfirm: () => OklFeedback.snack(
                        context,
                        'Demande de suppression envoyee (demo)',
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: AppColors.textPrimary,
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
  final bool destructive;
  final VoidCallback onTap;

  const _ActionSettingRow({
    required this.icon,
    required this.title,
    required this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = destructive ? AppColors.primary : AppColors.textPrimary;
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
                color: AppColors.textSecondary,
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
              if (!destructive)
                const Icon(
                  LucideIcons.chevronRight,
                  color: AppColors.textMuted,
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
      backgroundColor: AppColors.dark,
      appBar: AppBar(
        backgroundColor: AppColors.dark,
        title: const Text('Notifications'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              children: [
                _SwitchSettingRow(
                  icon: LucideIcons.messageCircle,
                  title: 'Nouveaux messages',
                  value: _messages,
                  onChanged: (v) => setState(() => _messages = v),
                ),
                const Divider(height: 1, color: AppColors.divider),
                _SwitchSettingRow(
                  icon: LucideIcons.heart,
                  title: 'Likes et super likes',
                  value: _likes,
                  onChanged: (v) => setState(() => _likes = v),
                ),
                const Divider(height: 1, color: AppColors.divider),
                _SwitchSettingRow(
                  icon: LucideIcons.sparkles,
                  title: 'Nouveaux matchs',
                  value: _matchs,
                  onChanged: (v) => setState(() => _matchs = v),
                ),
                const Divider(height: 1, color: AppColors.divider),
                _SwitchSettingRow(
                  icon: LucideIcons.radio,
                  title: 'Lives et activites',
                  value: _live,
                  onChanged: (v) => setState(() => _live = v),
                ),
                const Divider(height: 1, color: AppColors.divider),
                _SwitchSettingRow(
                  icon: LucideIcons.mail,
                  title: 'Emails Oklifor',
                  value: _email,
                  onChanged: (v) => setState(() => _email = v),
                ),
                const Divider(height: 1, color: AppColors.divider),
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
      backgroundColor: AppColors.dark,
      appBar: AppBar(
        backgroundColor: AppColors.dark,
        title: const Text('Confidentialite'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              children: [
                _SwitchSettingRow(
                  icon: LucideIcons.wifi,
                  title: 'Afficher mon statut en ligne',
                  value: _showOnline,
                  onChanged: (v) => setState(() => _showOnline = v),
                ),
                const Divider(height: 1, color: AppColors.divider),
                _SwitchSettingRow(
                  icon: LucideIcons.mapPin,
                  title: 'Afficher ma distance',
                  value: _showDistance,
                  onChanged: (v) => setState(() => _showDistance = v),
                ),
                const Divider(height: 1, color: AppColors.divider),
                _SwitchSettingRow(
                  icon: LucideIcons.checkCheck,
                  title: 'Accuses de lecture',
                  value: _readReceipts,
                  onChanged: (v) => setState(() => _readReceipts = v),
                ),
                const Divider(height: 1, color: AppColors.divider),
                _SwitchSettingRow(
                  icon: LucideIcons.userPlus,
                  title: 'Autoriser demandes de tous',
                  value: _allowRequests,
                  onChanged: (v) => setState(() => _allowRequests = v),
                ),
                const Divider(height: 1, color: AppColors.divider),
                _ActionSettingRow(
                  icon: LucideIcons.userX,
                  title: 'Utilisateurs bloques',
                  onTap: () => OklFeedback.snack(context, 'Liste des utilisateurs bloques (demo)'),
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
      backgroundColor: AppColors.dark,
      appBar: AppBar(
        backgroundColor: AppColors.dark,
        title: const Text('Securite du compte'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              children: [
                _SwitchSettingRow(
                  icon: LucideIcons.shieldCheck,
                  title: 'Authentification a 2 facteurs',
                  value: _twoFactor,
                  onChanged: (v) => setState(() => _twoFactor = v),
                ),
                const Divider(height: 1, color: AppColors.divider),
                _SwitchSettingRow(
                  icon: LucideIcons.fingerprint,
                  title: 'Deblocage biometrie',
                  value: _biometric,
                  onChanged: (v) => setState(() => _biometric = v),
                ),
                const Divider(height: 1, color: AppColors.divider),
                _SwitchSettingRow(
                  icon: LucideIcons.lock,
                  title: 'Verrouiller a l ouverture',
                  value: _screenLock,
                  onChanged: (v) => setState(() => _screenLock = v),
                ),
                const Divider(height: 1, color: AppColors.divider),
                _ActionSettingRow(
                  icon: LucideIcons.keyRound,
                  title: 'Changer PIN de securite',
                  onTap: () => OklFeedback.snack(context, 'Changement du PIN (demo)'),
                ),
                const Divider(height: 1, color: AppColors.divider),
                _ActionSettingRow(
                  icon: LucideIcons.smartphone,
                  title: 'Sessions actives',
                  onTap: () => OklFeedback.snack(context, 'Gestion des sessions (demo)'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AppPreferencesPage extends StatefulWidget {
  const _AppPreferencesPage();

  @override
  State<_AppPreferencesPage> createState() => _AppPreferencesPageState();
}

class _AppPreferencesPageState extends State<_AppPreferencesPage> {
  bool _autoPlay = true;
  bool _dataSaver = false;
  bool _vibrate = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dark,
      appBar: AppBar(
        backgroundColor: AppColors.dark,
        title: const Text('Preferences'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              children: [
                _ActionSettingRow(
                  icon: LucideIcons.languages,
                  title: 'Langue de l application',
                  onTap: () => OklFeedback.snack(context, 'Français (par defaut)'),
                ),
                const Divider(height: 1, color: AppColors.divider),
                _ActionSettingRow(
                  icon: LucideIcons.palette,
                  title: 'Theme',
                  onTap: () => OklFeedback.snack(context, 'Theme sombre'),
                ),
                const Divider(height: 1, color: AppColors.divider),
                _SwitchSettingRow(
                  icon: LucideIcons.playCircle,
                  title: 'Lecture auto des medias',
                  value: _autoPlay,
                  onChanged: (v) => setState(() => _autoPlay = v),
                ),
                const Divider(height: 1, color: AppColors.divider),
                _SwitchSettingRow(
                  icon: LucideIcons.signal,
                  title: 'Economiseur de donnees',
                  value: _dataSaver,
                  onChanged: (v) => setState(() => _dataSaver = v),
                ),
                const Divider(height: 1, color: AppColors.divider),
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
      backgroundColor: AppColors.dark,
      appBar: AppBar(
        backgroundColor: AppColors.dark,
        title: const Text('Aide et support'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              children: [
                _ActionSettingRow(
                  icon: LucideIcons.bookOpen,
                  title: 'Centre d aide',
                  onTap: () => OklFeedback.snack(context, 'Articles d aide (demo)'),
                ),
                const Divider(height: 1, color: AppColors.divider),
                _ActionSettingRow(
                  icon: LucideIcons.mail,
                  title: 'Contacter le support',
                  onTap: () => OklFeedback.snack(context, 'support@oklifor.app'),
                ),
                const Divider(height: 1, color: AppColors.divider),
                _ActionSettingRow(
                  icon: LucideIcons.bug,
                  title: 'Signaler un bug',
                  onTap: () => OklFeedback.snack(context, 'Formulaire de bug (demo)'),
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
      backgroundColor: AppColors.dark,
      appBar: AppBar(
        backgroundColor: AppColors.dark,
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
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: ExpansionTile(
        iconColor: AppColors.textSecondary,
        collapsedIconColor: AppColors.textSecondary,
        title: Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Text(
              body,
              style: const TextStyle(color: AppColors.textSecondary, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegalSettingsPage extends StatelessWidget {
  const _LegalSettingsPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dark,
      appBar: AppBar(
        backgroundColor: AppColors.dark,
        title: const Text('Conditions et confidentialite'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              children: [
                _ActionSettingRow(
                  icon: LucideIcons.fileCheck,
                  title: 'Conditions d utilisation',
                  onTap: () => OklFeedback.snack(context, 'Conditions Oklifor (demo)'),
                ),
                const Divider(height: 1, color: AppColors.divider),
                _ActionSettingRow(
                  icon: LucideIcons.shield,
                  title: 'Politique de confidentialite',
                  onTap: () => OklFeedback.snack(context, 'Politique de confidentialite (demo)'),
                ),
                const Divider(height: 1, color: AppColors.divider),
                _ActionSettingRow(
                  icon: LucideIcons.scale,
                  title: 'Regles de la communaute',
                  onTap: () => OklFeedback.snack(context, 'Regles de la communaute (demo)'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
