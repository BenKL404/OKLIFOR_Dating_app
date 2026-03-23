import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/api/models/settings_patch_body.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/security/okl_security_pin_storage.dart';
import '../../../core/widgets/okl_app_bar_icon_button.dart';
import '../../../core/widgets/okl_pin_code_field.dart';
import '../../../core/flows/okl_flows.dart';
import '../../../core/utils/okl_feedback.dart';
import '../../profile/models/settings_session.dart';
import '../../profile/services/settings_persist.dart';

/// Texte long (conditions, politique, articles).
class OklLegalDocumentScreen extends StatelessWidget {
  final String title;
  final List<String> paragraphs;

  const OklLegalDocumentScreen({
    super.key,
    required this.title,
    required this.paragraphs,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: const OklAppBarBackButton(),
        automaticallyImplyLeading: false,
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          for (final p in paragraphs) ...[
            Text(
              p,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.78),
                height: 1.5,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }
}

class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  final _blocked = <String>[
    'Compte test 12',
    'Spam_ Lomé',
    'Profil signalé',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: const OklAppBarBackButton(),
        automaticallyImplyLeading: false,
        title: const Text('Utilisateurs bloqués'),
      ),
      body: _blocked.isEmpty
          ? Center(
              child: Text(
                'Aucun compte bloqué',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: _blocked.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final name = _blocked[i];
                return Material(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  child: ListTile(
                    title: Text(name),
                    trailing: TextButton(
                      onPressed: () {
                        setState(() => _blocked.remove(name));
                        OklFlows.pushResult(
                          context,
                          icon: LucideIcons.userCheck,
                          title: '$name débloqué·e',
                          subtitle: 'Tu peux à nouveau recevoir des messages de cette personne.',
                          primaryLabel: 'OK',
                        );
                      },
                      child: const Text('Débloquer'),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

enum _PinSetupPhase {
  verifyOld,
  setNew,
  confirmNew,
  removeVerify,
}

class ChangePinScreen extends StatefulWidget {
  const ChangePinScreen({super.key});

  @override
  State<ChangePinScreen> createState() => _ChangePinScreenState();
}

class _ChangePinScreenState extends State<ChangePinScreen> {
  bool _loading = true;
  bool _hasPin = false;
  _PinSetupPhase _phase = _PinSetupPhase.setNew;
  String? _candidateNew;
  int _fieldSalt = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final h = await OklSecurityPinStorage.hasPin();
    if (!mounted) return;
    setState(() {
      _hasPin = h;
      _phase = h ? _PinSetupPhase.verifyOld : _PinSetupPhase.setNew;
      _loading = false;
    });
  }

  void _bumpField() => setState(() => _fieldSalt++);

  Future<void> _onVerifyOrRemoveDigits(String s) async {
    if (s.length < 4) return;
    final ok = await OklSecurityPinStorage.verify(s);
    if (!mounted) return;
    if (ok) {
      if (_phase == _PinSetupPhase.removeVerify) {
        await OklSecurityPinStorage.clearPin();
        if (!mounted) return;
        await OklFlows.pushResult(
          context,
          icon: LucideIcons.unlock,
          title: 'Code supprimé',
          subtitle:
              'Sans code ni biométrie, désactive « Verrouiller à l’ouverture » dans Sécurité si besoin.',
          primaryLabel: 'OK',
        );
        if (mounted) Navigator.of(context).pop();
        return;
      }
      setState(() {
        _phase = _PinSetupPhase.setNew;
        _candidateNew = null;
      });
      return;
    }
    if (s.length == 6) {
      OklFeedback.snack(context, 'Code incorrect');
      _bumpField();
    }
  }

  Future<void> _onSixDigitsEntered(String six) async {
    if (_phase == _PinSetupPhase.setNew) {
      setState(() {
        _candidateNew = six;
        _phase = _PinSetupPhase.confirmNew;
      });
      return;
    }
    if (_phase == _PinSetupPhase.confirmNew) {
      if (six == _candidateNew) {
        try {
          await OklSecurityPinStorage.setPin(six);
        } catch (e) {
          if (mounted) {
            OklFeedback.alert(context, title: 'Erreur', message: '$e');
          }
          return;
        }
        if (!mounted) return;
        await OklFlows.pushResult(
          context,
          icon: LucideIcons.lock,
          title: 'PIN enregistré',
          subtitle: 'Code à 6 chiffres, stocké sur cet appareil.',
          primaryLabel: 'OK',
        );
        if (mounted) Navigator.of(context).pop();
        return;
      }
      OklFeedback.alert(
        context,
        title: 'Les codes diffèrent',
        message: 'Saisis à nouveau un code à 6 chiffres, deux fois de suite.',
      );
      setState(() {
        _phase = _PinSetupPhase.setNew;
        _candidateNew = null;
      });
      _bumpField();
    }
  }

  Future<void> _startRemovePin() async {
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final t = Theme.of(ctx);
        return AlertDialog(
          backgroundColor: t.colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Supprimer le code ?',
            style: TextStyle(color: t.colorScheme.onSurface, fontWeight: FontWeight.w700),
          ),
          content: Text(
            'Tu pourras toujours utiliser la biométrie si elle est activée, sinon pense à désactiver le verrouillage de l’app.',
            style: TextStyle(
              color: t.textTheme.bodyMedium?.color ?? t.colorScheme.onSurface,
              fontSize: 14,
              height: 1.35,
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Continuer'),
            ),
          ],
        );
      },
    );
    if (go != true || !mounted) return;
    setState(() => _phase = _PinSetupPhase.removeVerify);
    _bumpField();
  }

  String get _phaseTitle {
    switch (_phase) {
      case _PinSetupPhase.verifyOld:
        return 'Code actuel';
      case _PinSetupPhase.setNew:
        return 'Nouveau code';
      case _PinSetupPhase.confirmNew:
        return 'Confirmer le code';
      case _PinSetupPhase.removeVerify:
        return 'Supprimer le code';
    }
  }

  String get _phaseHint {
    switch (_phase) {
      case _PinSetupPhase.verifyOld:
        return 'Entre ton code actuel (4 à 6 chiffres).';
      case _PinSetupPhase.setNew:
        return 'Choisis un code à 6 chiffres. La saisie se valide automatiquement.';
      case _PinSetupPhase.confirmNew:
        return 'Entre le même code à 6 chiffres pour confirmer.';
      case _PinSetupPhase.removeVerify:
        return 'Entre ton code actuel pour confirmer la suppression.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: const OklAppBarBackButton(),
        automaticallyImplyLeading: false,
        title: Text(_hasPin ? 'Code PIN' : 'Définir un code'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              children: [
                Text(
                  _phaseHint,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.65),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  _phaseTitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 20),
                OklPinCodeField(
                  key: ValueKey<Object>('$_phase$_fieldSalt'),
                  maxDigits: 6,
                  autofocus: true,
                  onChanged: (_phase == _PinSetupPhase.verifyOld ||
                          _phase == _PinSetupPhase.removeVerify)
                      ? _onVerifyOrRemoveDigits
                      : null,
                  onComplete: (_phase == _PinSetupPhase.setNew ||
                          _phase == _PinSetupPhase.confirmNew)
                      ? _onSixDigitsEntered
                      : null,
                ),
                if (_hasPin && _phase != _PinSetupPhase.removeVerify) ...[
                  const SizedBox(height: 32),
                  Center(
                    child: TextButton(
                      onPressed: _startRemovePin,
                      child: Text(
                        'Supprimer le code PIN',
                        style: TextStyle(
                          color: AppColors.togoRed,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}

class _SessionEntry {
  const _SessionEntry({
    required this.id,
    required this.device,
    required this.where,
    required this.current,
  });

  final String id;
  final String device;
  final String where;
  final bool current;
}

class ActiveSessionsScreen extends StatefulWidget {
  const ActiveSessionsScreen({super.key});

  @override
  State<ActiveSessionsScreen> createState() => _ActiveSessionsScreenState();
}

class _ActiveSessionsScreenState extends State<ActiveSessionsScreen> {
  static const _others = <_SessionEntry>[
    _SessionEntry(
      id: 'web_chrome',
      device: 'Chrome sur Windows',
      where: 'Dernière activité : il y a 2 h',
      current: false,
    ),
    _SessionEntry(
      id: 'iphone14',
      device: 'iPhone 14',
      where: 'Dernière activité : hier',
      current: false,
    ),
  ];

  final Set<String> _revoked = {};
  bool _loading = true;
  String _thisDeviceLabel = 'Cet appareil';
  String _thisDeviceWhere = '';

  @override
  void initState() {
    super.initState();
    _loadDevice();
  }

  Future<void> _loadDevice() async {
    if (kIsWeb) {
      if (mounted) {
        setState(() {
          _thisDeviceLabel = 'Navigateur web';
          _thisDeviceWhere = 'Session actuelle';
          _loading = false;
        });
      }
      return;
    }
    try {
      final di = DeviceInfoPlugin();
      if (defaultTargetPlatform == TargetPlatform.android) {
        final a = await di.androidInfo;
        _thisDeviceLabel = '${a.manufacturer} ${a.model}'.trim();
        _thisDeviceWhere = 'Android ${a.version.release} · Lomé';
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final i = await di.iosInfo;
        _thisDeviceLabel = i.name;
        _thisDeviceWhere = '${i.systemName} ${i.systemVersion}';
      }
    } catch (_) {
      _thisDeviceWhere = 'Session actuelle';
    }
    if (mounted) setState(() => _loading = false);
  }

  List<_SessionEntry> get _visible {
    final current = _SessionEntry(
      id: 'local',
      device: _thisDeviceLabel,
      where: _thisDeviceWhere.isEmpty ? 'Session actuelle' : _thisDeviceWhere,
      current: true,
    );
    final rest = _others.where((e) => !_revoked.contains(e.id));
    return [current, ...rest];
  }

  Future<void> _disconnect(_SessionEntry s) async {
    if (s.current) return;
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final t = Theme.of(ctx);
        return AlertDialog(
          backgroundColor: t.colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Déconnecter cette session ?',
            style: TextStyle(color: t.colorScheme.onSurface, fontWeight: FontWeight.w700),
          ),
          content: Text(
            '${s.device} ne pourra plus utiliser ton compte sans se reconnecter.',
            style: TextStyle(
              color: t.textTheme.bodyMedium?.color ?? t.colorScheme.onSurface,
              fontSize: 14,
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
              child: const Text('Déconnecter'),
            ),
          ],
        );
      },
    );
    if (go != true || !mounted) return;
    setState(() => _revoked.add(s.id));
    await OklFlows.pushResult(
      context,
      icon: LucideIcons.logOut,
      title: 'Session fermée',
      subtitle: '« ${s.device} » a été déconnecté. Reconnexion possible avec ton numéro.',
      primaryLabel: 'OK',
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
        title: const Text('Sessions actives'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                Text(
                  'Les sessions listées ici reflètent les appareils où tu t’es connecté·e. '
                  'La déconnexion distante sera reliée au serveur lorsque l’API sessions sera disponible.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.62),
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 14),
                ..._visible.map(
                  (s) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Material(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      child: ListTile(
                        title: Row(
                          children: [
                            Expanded(child: Text(s.device)),
                            if (s.current)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  'Ici',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        subtitle: Text(s.where),
                        trailing: s.current
                            ? null
                            : TextButton(
                                onPressed: () => _disconnect(s),
                                child: const Text('Déconnecter'),
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  void _openDoc(BuildContext context, String title, List<String> paras) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => OklLegalDocumentScreen(title: title, paragraphs: paras),
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
        title: const Text('Centre d’aide'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _HelpTile(
            icon: LucideIcons.rocket,
            title: 'Premiers pas',
            onTap: () => _openDoc(context, 'Premiers pas', [
              'Complète ton profil avec des photos nettes et une bio sincère.',
              'Utilise Rencontres pour swiper, et Messages pour échanger en toute sécurité.',
              'L’onglet Sorties te propose des idées de lieux et des ambiances pour planifier un rendez-vous.',
            ]),
          ),
          _HelpTile(
            icon: LucideIcons.shield,
            title: 'Sécurité et signalement',
            onTap: () => _openDoc(context, 'Sécurité', [
              'Tu peux bloquer un compte depuis son profil ou la conversation.',
              'Signale tout comportement inapproprié : l’équipe modère sous 24–48 h (démo).',
              'Ne partage jamais tes codes PIN ou mots de passe par message.',
            ]),
          ),
          _HelpTile(
            icon: LucideIcons.heart,
            title: 'Matchs et conversations',
            onTap: () => _openDoc(context, 'Conversations', [
              'Les accusés de lecture peuvent être désactivés dans Confidentialité.',
              'Archive tes discussions comme sur WhatsApp depuis la liste Messages.',
              'Les statuts disparaissent après visionnage (démo).',
            ]),
          ),
        ],
      ),
    );
  }
}

class _HelpTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _HelpTile({required this.icon, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        child: ListTile(
          leading: Icon(icon, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55)),
          title: Text(title),
          trailing: Icon(LucideIcons.chevronRight, size: 18, color: Theme.of(context).dividerColor),
          onTap: onTap,
        ),
      ),
    );
  }
}

class ContactSupportScreen extends StatefulWidget {
  const ContactSupportScreen({super.key});

  @override
  State<ContactSupportScreen> createState() => _ContactSupportScreenState();
}

class _ContactSupportScreenState extends State<ContactSupportScreen> {
  final _subject = TextEditingController();
  final _body = TextEditingController();

  @override
  void dispose() {
    _subject.dispose();
    _body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: const OklAppBarBackButton(),
        automaticallyImplyLeading: false,
        title: const Text('Contacter le support'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          Text(
            'Nous répondons à support@oklifor.app — ce formulaire simule l’envoi (démo).',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _subject,
            decoration: const InputDecoration(labelText: 'Sujet'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _body,
            maxLines: 6,
            decoration: const InputDecoration(
              labelText: 'Message',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () {
              if (_subject.text.trim().isEmpty || _body.text.trim().isEmpty) {
                OklFeedback.alert(
                  context,
                  title: 'Formulaire incomplet',
                  message: 'Remplis le sujet et le message pour contacter le support.',
                );
                return;
              }
              OklFlows.pushResult(
                context,
                icon: LucideIcons.send,
                title: 'Message envoyé',
                subtitle: 'Nous répondons sous 24 à 48 h sur support@oklifor.app.',
                primaryLabel: 'OK',
              ).then((_) {
                if (context.mounted) Navigator.of(context).pop();
              });
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
  }
}

class BugReportScreen extends StatefulWidget {
  const BugReportScreen({super.key});

  @override
  State<BugReportScreen> createState() => _BugReportScreenState();
}

class _BugReportScreenState extends State<BugReportScreen> {
  final _steps = TextEditingController();

  @override
  void dispose() {
    _steps.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: const OklAppBarBackButton(),
        automaticallyImplyLeading: false,
        title: const Text('Signaler un bug'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          Text(
            'Décris ce que tu faisais quand le problème est apparu. Version démo : le rapport est simulé.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _steps,
            maxLines: 8,
            decoration: const InputDecoration(
              labelText: 'Étapes pour reproduire',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () {
              if (_steps.text.trim().length < 8) {
                OklFeedback.alert(
                  context,
                  title: 'Plus de détails',
                  message: 'Décris au moins quelques lignes pour qu’on puisse reproduire le bug.',
                );
                return;
              }
              OklFlows.pushResult(
                context,
                icon: LucideIcons.bug,
                title: 'Rapport reçu',
                subtitle: 'Merci — notre équipe technique analysera ta description.',
                primaryLabel: 'OK',
              ).then((_) {
                if (context.mounted) Navigator.of(context).pop();
              });
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Envoyer le rapport'),
          ),
        ],
      ),
    );
  }
}

class LanguageSettingsScreen extends ConsumerStatefulWidget {
  const LanguageSettingsScreen({super.key});

  @override
  ConsumerState<LanguageSettingsScreen> createState() =>
      _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState extends ConsumerState<LanguageSettingsScreen> {
  late String _code;

  @override
  void initState() {
    super.initState();
    _code = SettingsSession.settings.value.appLanguage;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: const OklAppBarBackButton(),
        automaticallyImplyLeading: false,
        title: const Text('Langue'),
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Français'),
            trailing: _code == 'fr'
                ? Icon(LucideIcons.check, color: AppColors.primary, size: 20)
                : null,
            onTap: () => setState(() => _code = 'fr'),
          ),
          ListTile(
            title: const Text('English (bientôt)'),
            trailing: _code == 'en'
                ? Icon(LucideIcons.check, color: AppColors.primary, size: 20)
                : null,
            onTap: () => setState(() => _code = 'en'),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: FilledButton(
              onPressed: () async {
                if (_code == 'en') {
                  OklFeedback.alert(
                    context,
                    title: 'English',
                    message:
                        'L’interface anglaise arrive bientôt. Le français reste actif pour l’instant.',
                  );
                  return;
                }
                await persistAppSettings(
                  ref,
                  context,
                  applyOptimistic: (p) => p.copyWith(appLanguage: 'fr'),
                  patch: const SettingsPatchBody(appLanguage: 'fr'),
                );
                if (!context.mounted) return;
                await OklFlows.pushResult(
                  context,
                  icon: LucideIcons.languages,
                  title: 'Langue',
                  subtitle: 'Préférence enregistrée sur ton compte (français).',
                  primaryLabel: 'OK',
                );
                if (context.mounted) Navigator.of(context).pop();
              },
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Appliquer'),
            ),
          ),
        ],
      ),
    );
  }
}
