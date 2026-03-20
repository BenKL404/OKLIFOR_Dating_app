import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/widgets/okl_app_bar_icon_button.dart';
import '../../../core/utils/okl_feedback.dart';
import '../models/chat_models.dart';

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
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: thread.hasStory ? AppColors.igStoryGradient : null,
                      color: thread.hasStory ? null : context.oklDivider,
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
                    color: (Theme.of(context).textTheme.bodyMedium?.color ??
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
                  onTap: () => OklFeedback.snack(context, 'Profil de ${thread.name} (démo)'),
                ),
                const SizedBox(height: 10),
                _ActionCard(
                  icon: LucideIcons.image,
                  title: 'Médias, fichiers et liens',
                  subtitle: 'Tout ce qui a été partagé ici',
                  onTap: () => OklFeedback.snack(context, 'Galerie de la conversation (démo)'),
                ),
                const SizedBox(height: 10),
                _ActionCard(
                  icon: LucideIcons.bellOff,
                  title: 'Notifications',
                  subtitle: 'Silencieux, mentions…',
                  onTap: () => OklFeedback.snack(context, 'Réglages notifications (démo)'),
                ),
                const SizedBox(height: 10),
                _ActionCard(
                  icon: LucideIcons.shield,
                  title: 'Confidentialité',
                  subtitle: 'Signaler ou bloquer',
                  onTap: () => OklFeedback.snack(context, 'Options sécurité (démo)'),
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
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                shadows: [Shadow(color: Colors.black54, blurRadius: 8)],
              ),
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
                    color: (Theme.of(context).textTheme.bodyMedium?.color ??
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
                    color: (Theme.of(context).textTheme.bodyMedium?.color ??
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
                            OklFeedback.snack(context, 'Ajouter un membre (démo)'),
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
                          OklFeedback.snack(context, 'Paramètres du groupe (démo)'),
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
                        _MemberTile(
                          contact: members[i],
                          isAdmin: i == 0,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _ActionCard(
                  icon: LucideIcons.image,
                  title: 'Médias du groupe',
                  subtitle: 'Photos et fichiers partagés',
                  onTap: () => OklFeedback.snack(context, 'Médias du groupe (démo)'),
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
                    onConfirm: () =>
                        OklFeedback.snack(context, 'Groupe quitté (démo)'),
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
      onTap: () => OklFeedback.snack(context, 'Profil de ${contact.name} (démo)'),
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
                        color: destructive ? AppColors.primary : context.oklOnSurface,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: (Theme.of(context).textTheme.bodyMedium?.color ??
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
