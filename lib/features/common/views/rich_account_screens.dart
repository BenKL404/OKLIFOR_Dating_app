import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/okl_app_bar_icon_button.dart';
import '../../../core/flows/okl_flows.dart';
import '../../../core/utils/okl_feedback.dart';

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

class ChangePinScreen extends StatefulWidget {
  const ChangePinScreen({super.key});

  @override
  State<ChangePinScreen> createState() => _ChangePinScreenState();
}

class _ChangePinScreenState extends State<ChangePinScreen> {
  final _old = TextEditingController();
  final _n1 = TextEditingController();
  final _n2 = TextEditingController();

  @override
  void dispose() {
    _old.dispose();
    _n1.dispose();
    _n2.dispose();
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
        title: const Text('PIN de sécurité'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          Text(
            'Le PIN protège l’accès à l’app et aux réglages sensibles (démo).',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _old,
            obscureText: true,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'PIN actuel'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _n1,
            obscureText: true,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Nouveau PIN'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _n2,
            obscureText: true,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Confirmer le PIN'),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () {
              if (_n1.text != _n2.text || _n1.text.length < 4) {
                OklFeedback.alert(
                  context,
                  title: 'PIN invalide',
                  message: 'Les deux nouveaux PIN doivent être identiques (4 chiffres minimum).',
                );
                return;
              }
              OklFlows.pushResult(
                context,
                icon: LucideIcons.lock,
                title: 'PIN mis à jour',
                subtitle: 'Utilise-le pour les prochains accès sensibles.',
                primaryLabel: 'OK',
              ).then((_) {
                if (context.mounted) Navigator.of(context).pop();
              });
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }
}

class ActiveSessionsScreen extends StatelessWidget {
  const ActiveSessionsScreen({super.key});

  static const _sessions = <({String device, String where, bool current})>[
    (device: 'Ce téléphone', where: 'Lomé · Android', current: true),
    (device: 'Chrome sur Windows', where: 'Dernière activité : il y a 2 h', current: false),
    (device: 'iPhone 14', where: 'Dernière activité : hier', current: false),
  ];

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
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: _sessions.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final s = _sessions[i];
          return Material(
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
                      onPressed: () => OklFlows.pushResult(
                        context,
                        icon: LucideIcons.logOut,
                        title: 'Session fermée',
                        subtitle: '« ${s.device} » a été déconnecté·e. Reconnexion possible avec ton numéro.',
                        primaryLabel: 'OK',
                      ),
                      child: const Text('Déco.'),
                    ),
            ),
          );
        },
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

class LanguageSettingsScreen extends StatefulWidget {
  const LanguageSettingsScreen({super.key});

  @override
  State<LanguageSettingsScreen> createState() => _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState extends State<LanguageSettingsScreen> {
  String _code = 'fr';

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
              onPressed: () {
                if (_code == 'en') {
                  OklFeedback.alert(
                    context,
                    title: 'English',
                    message: 'L’interface anglaise arrive bientôt. Le français reste actif pour l’instant.',
                  );
                  return;
                }
                OklFlows.pushResult(
                  context,
                  icon: LucideIcons.languages,
                  title: 'Langue',
                  subtitle: 'Français conservé pour toute l’application.',
                  primaryLabel: 'OK',
                ).then((_) {
                  if (context.mounted) Navigator.of(context).pop();
                });
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
