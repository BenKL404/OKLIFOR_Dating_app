import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/flows/okl_flows.dart';
import '../../../core/widgets/okl_story_gauge_ring.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/widgets/okl_app_bar_icon_button.dart';
import '../../../core/utils/okl_feedback.dart';
import '../models/chat_models.dart'
    show ChatContact, ChatThread, demoMembersForGroup, demoPeerBioForThread;
import '../providers/chat_contacts_provider.dart';

/// Détails du contact ou du groupe depuis l’en-tête de conversation.
class ChatThreadDetailScreen extends StatelessWidget {
  final ChatThread thread;

  const ChatThreadDetailScreen({super.key, required this.thread});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.oklScaffold,
      body: thread.isGroup
          ? _GroupDetailBody(thread: thread)
          : _DirectDetailBody(thread: thread),
    );
  }
}

class _DirectDetailBody extends StatelessWidget {
  final ChatThread thread;

  const _DirectDetailBody({required this.thread});

  @override
  Widget build(BuildContext context) {
    final bio = demoPeerBioForThread(thread);
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          backgroundColor: context.oklScaffold,
          leading: const OklAppBarBackButton(rootNavigator: true),
          automaticallyImplyLeading: false,
          title: const Text('Contact'),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            child: Column(
              children: [
                const SizedBox(height: 8),
                Hero(
                  tag: 'thread_avatar_${thread.id}',
                  child: thread.hasStory
                      ? OklStoryGaugeRing(
                          outerSize: 120,
                          strokeWidth: 3,
                          child: SizedBox(
                            width: 112,
                            height: 112,
                            child: CircleAvatar(
                              radius: 56,
                              backgroundColor: context.oklSurface,
                              child: CircleAvatar(
                                radius: 52,
                                backgroundColor: context.oklScaffold,
                                child: ClipOval(
                                  child: CachedNetworkImage(
                                    imageUrl: thread.avatarUrl,
                                    width: 104,
                                    height: 104,
                                    fit: BoxFit.cover,
                                    memCacheWidth: 208,
                                    placeholder: (c, u) => Container(
                                      width: 104,
                                      height: 104,
                                      color: context.oklSurface,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        )
                      : Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: context.oklDivider,
                          ),
                          child: CircleAvatar(
                            radius: 56,
                            backgroundColor: context.oklSurface,
                            child: CircleAvatar(
                              radius: 52,
                              backgroundColor: context.oklScaffold,
                              child: ClipOval(
                                child: CachedNetworkImage(
                                  imageUrl: thread.avatarUrl,
                                  width: 104,
                                  height: 104,
                                  fit: BoxFit.cover,
                                  memCacheWidth: 208,
                                  placeholder: (c, u) => Container(
                                    width: 104,
                                    height: 104,
                                    color: context.oklSurface,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                ),
                const SizedBox(height: 18),
                Text(
                  thread.name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: context.oklOnSurface,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: thread.online
                            ? AppColors.green
                            : context.oklOnSurfaceMuted(0.55),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      thread.online ? 'En ligne' : 'Hors ligne',
                      style: TextStyle(
                        color: thread.online
                            ? AppColors.green
                            : (Theme.of(context).textTheme.bodyMedium?.color ??
                                  context.oklOnSurfaceMuted(0.62)),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Text(
                  bio,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color:
                        (Theme.of(context).textTheme.bodyMedium?.color ??
                                context.oklOnSurfaceMuted(0.62))
                            .withValues(alpha: 0.98),
                    fontSize: 15,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 28),
                _ActionCard(
                  icon: LucideIcons.user,
                  title: 'Voir le profil complet',
                  subtitle: 'Photos, intérêts, vérifications',
                  onTap: () => Navigator.of(context, rootNavigator: true).push(
                    MaterialPageRoute<void>(
                      builder: (_) => _ContactProfileSubPage(thread: thread),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _ActionCard(
                  icon: LucideIcons.image,
                  title: 'Médias, fichiers et liens',
                  subtitle: 'Tout ce qui a été partagé ici',
                  onTap: () => Navigator.of(context, rootNavigator: true).push(
                    MaterialPageRoute<void>(
                      builder: (_) => _SharedMediaSubPage(thread: thread),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _ActionCard(
                  icon: LucideIcons.phoneCall,
                  title: 'Appels',
                  subtitle: 'Historique et actions rapides',
                  onTap: () => Navigator.of(context, rootNavigator: true).push(
                    MaterialPageRoute<void>(
                      builder: (_) => _ContactCallsSubPage(thread: thread),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _ActionCard(
                  icon: LucideIcons.bellOff,
                  title: 'Notifications',
                  subtitle: 'Silencieux, mentions…',
                  onTap: () => Navigator.of(context, rootNavigator: true).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          _ContactNotificationsSubPage(thread: thread),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _ActionCard(
                  icon: LucideIcons.shield,
                  title: 'Confidentialité',
                  subtitle: 'Signaler ou bloquer',
                  onTap: () => Navigator.of(context, rootNavigator: true).push(
                    MaterialPageRoute<void>(
                      builder: (_) => _ContactPrivacySubPage(thread: thread),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _GroupDetailBody extends StatelessWidget {
  final ChatThread thread;

  const _GroupDetailBody({required this.thread});

  @override
  Widget build(BuildContext context) {
    final members = demoMembersForGroup(thread);
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          expandedHeight: 200,
          backgroundColor: context.oklScaffold,
          leading: const OklAppBarBackButton(rootNavigator: true),
          automaticallyImplyLeading: false,
          flexibleSpace: FlexibleSpaceBar(
            title: Text(
              thread.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            background: Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl: thread.avatarUrl,
                  fit: BoxFit.cover,
                  memCacheWidth: 800,
                  placeholder: (c, u) => Container(color: context.oklSurface),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.2),
                        context.oklScaffold,
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${thread.groupMemberCount} membres · groupe',
                  style: TextStyle(
                    color:
                        (Theme.of(context).textTheme.bodyMedium?.color ??
                                context.oklOnSurfaceMuted(0.62))
                            .withValues(alpha: 0.95),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Organisez vos sorties, partagez des photos et gardez tout le monde au courant. '
                  '(Description démo — sera liée au vrai groupe plus tard.)',
                  style: TextStyle(
                    color:
                        (Theme.of(context).textTheme.bodyMedium?.color ??
                                context.oklOnSurfaceMuted(0.62))
                            .withValues(alpha: 0.95),
                    fontSize: 14,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () =>
                            Navigator.of(context, rootNavigator: true).push(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    _GroupInviteScreen(thread: thread),
                              ),
                            ),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(LucideIcons.userPlus, size: 18),
                        label: const Text('Inviter'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton(
                      onPressed: () =>
                          Navigator.of(context, rootNavigator: true).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  _GroupSettingsScreen(thread: thread),
                            ),
                          ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: context.oklOnSurface,
                        side: BorderSide(color: context.oklDivider),
                        padding: const EdgeInsets.all(12),
                      ),
                      child: const Icon(LucideIcons.settings, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Text(
                  'Membres',
                  style: TextStyle(
                    color: context.oklOnSurface,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: context.oklSurface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: context.oklDivider),
                  ),
                  child: Column(
                    children: [
                      for (var i = 0; i < members.length; i++) ...[
                        if (i > 0)
                          Divider(height: 1, color: context.oklDivider),
                        _MemberTile(contact: members[i], isAdmin: i == 0),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _ActionCard(
                  icon: LucideIcons.image,
                  title: 'Médias du groupe',
                  subtitle: 'Photos et fichiers partagés',
                  onTap: () => Navigator.of(context, rootNavigator: true).push(
                    MaterialPageRoute<void>(
                      builder: (_) => _GroupMediaSubPage(thread: thread),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _ActionCard(
                  icon: LucideIcons.logOut,
                  title: 'Quitter le groupe',
                  subtitle: 'Tu ne recevras plus les messages',
                  destructive: true,
                  onTap: () => OklFeedback.confirm(
                    context,
                    title: 'Quitter le groupe ?',
                    body: 'Tu pourras être réinvité plus tard.',
                    confirmLabel: 'Quitter',
                    onConfirm: () => OklFlows.pushResult(
                      context,
                      icon: LucideIcons.logOut,
                      title: 'Tu as quitté le groupe',
                      subtitle:
                          'Tu ne recevras plus les messages de « ${thread.name} ».',
                      primaryLabel: 'OK',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MemberTile extends StatelessWidget {
  final ChatContact contact;
  final bool isAdmin;

  const _MemberTile({required this.contact, this.isAdmin = false});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      leading: CircleAvatar(
        radius: 22,
        backgroundColor: context.oklScaffold,
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: contact.avatarUrl,
            width: 44,
            height: 44,
            fit: BoxFit.cover,
            memCacheWidth: 88,
            placeholder: (c, u) => Container(color: context.oklSurface),
          ),
        ),
      ),
      title: Text(
        contact.name,
        style: TextStyle(
          color: context.oklOnSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: isAdmin
          ? Text(
              'Admin du groupe',
              style: TextStyle(
                color: AppColors.primary.withValues(alpha: 0.95),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            )
          : Text(
              'Membre',
              style: TextStyle(
                color: context.oklOnSurfaceMuted(0.55),
                fontSize: 12,
              ),
            ),
      trailing: Icon(
        LucideIcons.chevronRight,
        color: context.oklOnSurfaceMuted(0.55),
        size: 18,
      ),
      onTap: () => Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              _GroupMemberProfileSubPage(contact: contact, isAdmin: isAdmin),
        ),
      ),
    );
  }
}

class _ContactProfileSubPage extends StatelessWidget {
  final ChatThread thread;
  const _ContactProfileSubPage({required this.thread});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.oklScaffold,
      appBar: AppBar(
        backgroundColor: context.oklScaffold,
        leading: const OklAppBarBackButton(rootNavigator: true),
        automaticallyImplyLeading: false,
        title: const Text('Profil complet'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _SimpleInfoCard(
            title: thread.name,
            subtitle: demoPeerBioForThread(thread),
            icon: LucideIcons.user,
          ),
          const SizedBox(height: 10),
          _SimpleInfoCard(
            title: 'Centres d’intérêt',
            subtitle:
                'Sorties, découvertes locales, discussions et rencontres.',
            icon: LucideIcons.sparkles,
          ),
          const SizedBox(height: 10),
          _SimpleInfoCard(
            title: 'Vérification',
            subtitle: 'Compte actif et visible dans les recommandations.',
            icon: LucideIcons.shieldCheck,
          ),
        ],
      ),
    );
  }
}

class _SharedMediaSubPage extends StatelessWidget {
  final ChatThread thread;
  const _SharedMediaSubPage({required this.thread});

  @override
  Widget build(BuildContext context) {
    final media = [
      thread.statusImageUrl,
      'https://images.unsplash.com/photo-1519046904884-53103b34b206?w=600&q=80&auto=format&fit=crop',
      'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=600&q=80&auto=format&fit=crop',
    ];
    return Scaffold(
      backgroundColor: context.oklScaffold,
      appBar: AppBar(
        backgroundColor: context.oklScaffold,
        leading: const OklAppBarBackButton(rootNavigator: true),
        automaticallyImplyLeading: false,
        title: const Text('Médias, fichiers et liens'),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: media.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemBuilder: (context, i) => ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: CachedNetworkImage(
            imageUrl: media[i],
            fit: BoxFit.cover,
            memCacheWidth: 320,
            placeholder: (c, u) => Container(color: context.oklSurface),
            errorWidget: (c, u, e) => Container(color: context.oklSurface),
          ),
        ),
      ),
    );
  }
}

class _ContactCallsSubPage extends StatelessWidget {
  final ChatThread thread;
  const _ContactCallsSubPage({required this.thread});

  @override
  Widget build(BuildContext context) {
    final rows = <({String when, bool incoming, bool missed})>[
      (when: 'Aujourd’hui · 18:42', incoming: true, missed: false),
      (when: 'Hier · 21:10', incoming: false, missed: false),
      (when: 'Lun. · 07:34', incoming: true, missed: true),
    ];
    return Scaffold(
      backgroundColor: context.oklScaffold,
      appBar: AppBar(
        backgroundColor: context.oklScaffold,
        leading: const OklAppBarBackButton(rootNavigator: true),
        automaticallyImplyLeading: false,
        title: const Text('Appels'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: rows.length,
        separatorBuilder: (context, index) =>
            Divider(height: 1, color: context.oklDivider),
        itemBuilder: (context, i) {
          final r = rows[i];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 4,
              vertical: 4,
            ),
            leading: CircleAvatar(
              backgroundColor: context.oklSurface,
              child: Icon(
                r.incoming
                    ? LucideIcons.phoneIncoming
                    : LucideIcons.phoneOutgoing,
                color: r.missed
                    ? AppColors.primary
                    : context.oklOnSurfaceMuted(0.62),
                size: 18,
              ),
            ),
            title: Text(
              thread.name,
              style: TextStyle(color: context.oklOnSurface),
            ),
            subtitle: Text(
              r.when,
              style: TextStyle(color: context.oklOnSurfaceMuted(0.55)),
            ),
            trailing: IconButton(
              icon: const Icon(LucideIcons.phone),
              onPressed: () => OklFlows.pushOutgoingCall(
                context,
                contactName: thread.name,
                avatarUrl: thread.isGroup ? null : thread.avatarUrl,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ContactNotificationsSubPage extends StatefulWidget {
  final ChatThread thread;
  const _ContactNotificationsSubPage({required this.thread});

  @override
  State<_ContactNotificationsSubPage> createState() =>
      _ContactNotificationsSubPageState();
}

class _ContactNotificationsSubPageState
    extends State<_ContactNotificationsSubPage> {
  bool muted = false;
  bool popup = true;
  bool vibration = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.oklScaffold,
      appBar: AppBar(
        backgroundColor: context.oklScaffold,
        leading: const OklAppBarBackButton(rootNavigator: true),
        automaticallyImplyLeading: false,
        title: const Text('Notifications'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          SwitchListTile.adaptive(
            value: muted,
            onChanged: (v) => setState(() => muted = v),
            title: Text(
              'Silencieux',
              style: TextStyle(color: context.oklOnSurface),
            ),
          ),
          SwitchListTile.adaptive(
            value: popup,
            onChanged: (v) => setState(() => popup = v),
            title: Text(
              'Aperçu popup',
              style: TextStyle(color: context.oklOnSurface),
            ),
          ),
          SwitchListTile.adaptive(
            value: vibration,
            onChanged: (v) => setState(() => vibration = v),
            title: Text(
              'Vibrations',
              style: TextStyle(color: context.oklOnSurface),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactPrivacySubPage extends StatelessWidget {
  final ChatThread thread;
  const _ContactPrivacySubPage({required this.thread});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.oklScaffold,
      appBar: AppBar(
        backgroundColor: context.oklScaffold,
        leading: const OklAppBarBackButton(rootNavigator: true),
        automaticallyImplyLeading: false,
        title: const Text('Confidentialité'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _SimpleActionRow(
            icon: LucideIcons.flag,
            title: 'Signaler ${thread.name}',
            onTap: () => OklFlows.pushResult(
              context,
              icon: LucideIcons.flag,
              iconColor: AppColors.togoRed,
              title: 'Signalement envoyé',
              subtitle:
                  'Merci pour ton retour. Notre équipe traitera la demande sous 24 à 48 h.',
              primaryLabel: 'Compris',
            ),
          ),
          _SimpleActionRow(
            icon: LucideIcons.userX,
            title: 'Bloquer ${thread.name}',
            onTap: () => OklFeedback.confirm(
              context,
              title: 'Bloquer ce contact ?',
              body: 'Tu ne recevras plus ses messages.',
              confirmLabel: 'Bloquer',
              onConfirm: () => OklFlows.pushResult(
                context,
                icon: LucideIcons.userX,
                title: 'Contact bloqué',
                subtitle:
                    'Tu ne recevras plus de messages de ${thread.name}. Tu peux débloquer depuis Réglages.',
                primaryLabel: 'OK',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupMediaSubPage extends StatelessWidget {
  final ChatThread thread;
  const _GroupMediaSubPage({required this.thread});

  static const _urls = <String>[
    'https://images.unsplash.com/photo-1529156069898-49953e39b3ac?w=600&q=80&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1519046904884-53103b34b206?w=600&q=80&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=600&q=80&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1432405972618-c60b0225b8f9?w=600&q=80&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1480714378408-67cf0d13bc1b?w=600&q=80&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=600&q=80&auto=format&fit=crop',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.oklScaffold,
      appBar: AppBar(
        backgroundColor: context.oklScaffold,
        leading: const OklAppBarBackButton(rootNavigator: true),
        automaticallyImplyLeading: false,
        title: Text('Médias · ${thread.name}'),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _urls.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemBuilder: (context, i) => ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: CachedNetworkImage(
            imageUrl: _urls[i],
            fit: BoxFit.cover,
            memCacheWidth: 400,
            placeholder: (c, u) => Container(color: context.oklSurface),
          ),
        ),
      ),
    );
  }
}

class _GroupInviteScreen extends ConsumerStatefulWidget {
  final ChatThread thread;
  const _GroupInviteScreen({required this.thread});

  @override
  ConsumerState<_GroupInviteScreen> createState() => _GroupInviteScreenState();
}

class _GroupInviteScreenState extends ConsumerState<_GroupInviteScreen> {
  final Set<String> _selected = {};

  @override
  Widget build(BuildContext context) {
    final contactsAsync = ref.watch(chatContactsProvider);
    return Scaffold(
      backgroundColor: context.oklScaffold,
      appBar: AppBar(
        backgroundColor: context.oklScaffold,
        leading: const OklAppBarBackButton(rootNavigator: true),
        automaticallyImplyLeading: false,
        title: const Text('Inviter des membres'),
      ),
      body: Column(
        children: [
          Expanded(
            child: contactsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) =>
                  const Center(child: Text('Chargement impossible')),
              data: (contacts) => ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                    child: Text(
                      'Sélectionne des contacts à ajouter à « ${widget.thread.name} ».',
                      style: TextStyle(
                        color: context.oklOnSurfaceMuted(0.62),
                        height: 1.35,
                      ),
                    ),
                  ),
                  for (final c in contacts)
                    CheckboxListTile(
                      value: _selected.contains(c.id),
                      onChanged: (v) {
                        setState(() {
                          if (v == true) {
                            _selected.add(c.id);
                          } else {
                            _selected.remove(c.id);
                          }
                        });
                      },
                      title: Text(
                        c.name,
                        style: TextStyle(color: context.oklOnSurface),
                      ),
                      secondary: CircleAvatar(
                        backgroundImage: CachedNetworkImageProvider(
                          c.avatarUrl,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: FilledButton(
                onPressed: () {
                  if (_selected.isEmpty) {
                    OklFeedback.alert(
                      context,
                      title: 'Sélection requise',
                      message: 'Choisis au moins un contact à inviter.',
                    );
                    return;
                  }
                  final n = _selected.length;
                  OklFlows.pushResult(
                    context,
                    icon: LucideIcons.userPlus,
                    title:
                        'Invitation${n > 1 ? 's' : ''} envoyée${n > 1 ? 's' : ''}',
                    subtitle:
                        '$n contact${n > 1 ? 's' : ''} recevront une invitation pour « ${widget.thread.name} ».',
                    primaryLabel: 'Parfait',
                  ).then((_) {
                    if (context.mounted) Navigator.of(context).pop();
                  });
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size.fromHeight(48),
                ),
                child: Text('Inviter (${_selected.length})'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupSettingsScreen extends StatefulWidget {
  final ChatThread thread;
  const _GroupSettingsScreen({required this.thread});

  @override
  State<_GroupSettingsScreen> createState() => _GroupSettingsScreenState();
}

class _GroupSettingsScreenState extends State<_GroupSettingsScreen> {
  late final TextEditingController _name;
  bool _onlyAdmins = false;
  bool _muteAll = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.thread.name);
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.oklScaffold,
      appBar: AppBar(
        backgroundColor: context.oklScaffold,
        leading: const OklAppBarBackButton(rootNavigator: true),
        automaticallyImplyLeading: false,
        title: const Text('Paramètres du groupe'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Nom du groupe'),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: Text(
              'Seuls les admins peuvent modifier le nom',
              style: TextStyle(color: context.oklOnSurface),
            ),
            value: _onlyAdmins,
            onChanged: (v) => setState(() => _onlyAdmins = v),
          ),
          SwitchListTile(
            title: Text(
              'Couper les notifs du groupe',
              style: TextStyle(color: context.oklOnSurface),
            ),
            value: _muteAll,
            onChanged: (v) => setState(() => _muteAll = v),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () {
              OklFlows.pushResult(
                context,
                icon: LucideIcons.check,
                title: 'Paramètres enregistrés',
                subtitle: 'Les changements sont appliqués pour ce groupe.',
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

class _GroupMemberProfileSubPage extends StatelessWidget {
  final ChatContact contact;
  final bool isAdmin;
  const _GroupMemberProfileSubPage({
    required this.contact,
    required this.isAdmin,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.oklScaffold,
      appBar: AppBar(
        backgroundColor: context.oklScaffold,
        leading: const OklAppBarBackButton(rootNavigator: true),
        automaticallyImplyLeading: false,
        title: const Text('Profil membre'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 44,
              backgroundColor: context.oklSurface,
              child: ClipOval(
                child: CachedNetworkImage(
                  imageUrl: contact.avatarUrl,
                  width: 88,
                  height: 88,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              contact.name,
              style: TextStyle(
                color: context.oklOnSurface,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isAdmin ? 'Admin du groupe' : 'Membre',
              style: TextStyle(color: context.oklOnSurfaceMuted(0.55)),
            ),
          ],
        ),
      ),
    );
  }
}

class _SimpleInfoCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  const _SimpleInfoCard({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.oklSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.oklDivider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: context.oklOnSurfaceMuted(0.62), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: context.oklOnSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: context.oklOnSurfaceMuted(0.62),
                    fontSize: 13,
                    height: 1.35,
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

class _SimpleActionRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  const _SimpleActionRow({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.oklSurface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: context.oklOnSurfaceMuted(0.62), size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: context.oklOnSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                LucideIcons.chevronRight,
                color: context.oklOnSurfaceMuted(0.55),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool destructive;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.oklSurface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: context.oklDivider),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: destructive
                    ? AppColors.primary
                    : (Theme.of(context).textTheme.bodyMedium?.color ??
                          context.oklOnSurfaceMuted(0.62)),
                size: 20,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: destructive
                            ? AppColors.primary
                            : context.oklOnSurface,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color:
                            (Theme.of(context).textTheme.bodyMedium?.color ??
                                    context.oklOnSurfaceMuted(0.62))
                                .withValues(alpha: 0.95),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                LucideIcons.chevronRight,
                color: context.oklOnSurfaceMuted(0.55),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
