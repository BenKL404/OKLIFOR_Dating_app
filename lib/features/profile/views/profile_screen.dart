import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/okl_feedback.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const _coverUrl =
      'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=1200&q=85&auto=format&fit=crop';
  static const _avatarUrl =
      'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400&q=85&auto=format&fit=crop';

  static const _friendRequests = <({
    String name,
    String area,
    String avatar,
    int mutualFriends,
  })>[
    (
      name: 'Sena',
      area: 'Tokoin',
      avatar:
          'https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e?w=200&q=80&auto=format&fit=crop',
      mutualFriends: 12,
    ),
    (
      name: 'Kossi',
      area: 'Kegue',
      avatar:
          'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=200&q=80&auto=format&fit=crop',
      mutualFriends: 5,
    ),
    (
      name: 'Afi',
      area: 'Agoe',
      avatar:
          'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200&q=80&auto=format&fit=crop',
      mutualFriends: 28,
    ),
  ];

  static const _communityEvents = <({String title, String subtitle, IconData icon})>[
    (
      title: 'Soiree Oklifor',
      subtitle: '18 utilisateurs confirment',
      icon: LucideIcons.partyPopper,
    ),
    (
      title: 'Tournoi foot quartier',
      subtitle: 'Adidogome - samedi',
      icon: LucideIcons.trophy,
    ),
    (
      title: 'Live communautaire',
      subtitle: '7 utilisateurs en direct',
      icon: LucideIcons.radio,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dark,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: AppColors.dark,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: _coverUrl,
                    fit: BoxFit.cover,
                    memCacheWidth: 900,
                    placeholder: (c, u) => Container(color: AppColors.surface),
                    errorWidget: (c, u, e) => Container(color: AppColors.surface),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.35),
                          AppColors.dark.withValues(alpha: 0.2),
                          AppColors.dark,
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    bottom: 20,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.igStoryGradient,
                      ),
                      child: CircleAvatar(
                        radius: 44,
                        backgroundColor: AppColors.dark,
                        child: CircleAvatar(
                          radius: 41,
                          backgroundColor: AppColors.surface,
                          child: ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: _avatarUrl,
                              width: 82,
                              height: 82,
                              fit: BoxFit.cover,
                              memCacheWidth: 164,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Material(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    onTap: () => context.push('/settings'),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Icon(
                        LucideIcons.settings,
                        size: 18,
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Amina K.',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Image.asset(
                        'assets/images/certify_icon.png',
                        width: 20,
                        height: 20,
                        fit: BoxFit.contain,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Row(
                    children: [
                      Icon(LucideIcons.mapPin, size: 13, color: AppColors.textSecondary),
                      SizedBox(width: 4),
                      Text('Lome, Agoe',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatItem(value: '128', label: 'Likes'),
                      _StatItem(value: '24', label: 'Matchs'),
                      _StatItem(value: '17', label: 'Demandes'),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: Material(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          child: InkWell(
                            onTap: () {
                              OklFeedback.snack(context, 'Editeur de profil - photos et bio');
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 11),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.divider),
                              ),
                              child: const Text(
                                'Modifier le profil',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Material(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          onTap: () => context.push('/invite-friends'),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: 40,
                            height: 40,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.divider),
                            ),
                            child: const Icon(
                              LucideIcons.userPlus,
                              color: AppColors.textSecondary,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Demandes d'amis (${_friendRequests.length})",
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextButton(
                        onPressed: () => OklFeedback.snack(
                          context,
                          'Toutes les demandes (démo)',
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Voir tout',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.divider),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        for (int i = 0; i < _friendRequests.length; i++) ...[
                          if (i > 0)
                            const Divider(height: 1, thickness: 1, color: AppColors.divider),
                          _FriendRequestFacebookRow(user: _friendRequests[i]),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _CommunitySection(
                    title: 'Mes matchs recents',
                    items: const [
                      (
                        icon: LucideIcons.heart,
                        title: 'Nouveau match avec Fati',
                        subtitle: 'Il y a 10 min',
                      ),
                      (
                        icon: LucideIcons.messageCircle,
                        title: 'Kossi t a ecrit',
                        subtitle: 'Repondre maintenant',
                      ),
                      (
                        icon: LucideIcons.sparkles,
                        title: 'Profil booste aujourd hui',
                        subtitle: '+12 vues de profil',
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _CommunitySection(
                    title: 'Communaute Oklifor',
                    items: _communityEvents
                        .map((e) => (
                              icon: e.icon,
                              title: e.title,
                              subtitle: e.subtitle,
                            ))
                        .toList(growable: false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value, label;
  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          OklFeedback.snack(context, '$label : détail à venir');
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            children: [
              Text(value,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  )),
              const SizedBox(height: 2),
              Text(label,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Ligne de demande d’ami façon fil d’actualité Facebook : avatar large, amis en commun, deux boutons pleine largeur.
class _FriendRequestFacebookRow extends StatelessWidget {
  final ({String name, String area, String avatar, int mutualFriends}) user;

  const _FriendRequestFacebookRow({required this.user});

  @override
  Widget build(BuildContext context) {
    final mutual = user.mutualFriends;
    final mutualLabel = mutual <= 1
        ? '1 ami en commun'
        : '$mutual amis en commun';

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipOval(
            child: CachedNetworkImage(
              imageUrl: user.avatar,
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              memCacheWidth: 120,
              placeholder: (context, url) => Container(
                width: 56,
                height: 56,
                color: AppColors.dark,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  user.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$mutualLabel · ${user.area}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: () => OklFeedback.snack(
                          context,
                          'Demande acceptée : ${user.name}',
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Confirmer',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => OklFeedback.snack(
                          context,
                          'Demande ignorée pour ${user.name}',
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.dark,
                          foregroundColor: AppColors.textPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Ignorer',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CommunitySection extends StatelessWidget {
  final String title;
  final List<({IconData icon, String title, String subtitle})> items;

  const _CommunitySection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
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
              for (int i = 0; i < items.length; i++) ...[
                _CommunityRow(item: items[i]),
                if (i != items.length - 1)
                  const Divider(height: 1, color: AppColors.divider),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _CommunityRow extends StatelessWidget {
  final ({IconData icon, String title, String subtitle}) item;

  const _CommunityRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => OklFeedback.snack(context, item.title),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.dark,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(item.icon, size: 17, color: AppColors.textSecondary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.subtitle,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(LucideIcons.chevronRight, color: AppColors.textMuted, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
