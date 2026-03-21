import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/layout_constants.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/widgets/okl_app_bar_icon_button.dart';
import '../../../core/utils/okl_feedback.dart';
import '../models/user_profile.dart';
import 'account_verification_screen.dart';
import 'edit_profile_screen.dart';
import 'invite_friends_screen.dart';
import 'settings_screen.dart';
import 'friend_requests_list_screen.dart';
import 'profile_stat_detail_screen.dart';
import '../../common/views/rich_account_screens.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

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
    return ValueListenableBuilder<UserProfile>(
      valueListenable: ProfileSession.profile,
      builder: (context, profile, _) {
        return Scaffold(
      backgroundColor: context.oklScaffold,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: context.oklScaffold,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: profile.coverUrl,
                    fit: BoxFit.cover,
                    memCacheWidth: 900,
                    placeholder: (c, u) => Container(color: c.oklSurface),
                    errorWidget: (c, u, e) => Container(color: c.oklSurface),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.35),
                          Colors.black.withValues(alpha: 0.55),
                          context.oklScaffold,
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
                        backgroundColor: context.oklScaffold,
                        child: CircleAvatar(
                          radius: 41,
                          backgroundColor: context.oklSurface,
                          child: ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: profile.avatarUrl,
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
                padding: const EdgeInsets.only(right: 12),
                child: OklAppBarIconButton(
                  icon: LucideIcons.settings,
                  onPressed: () => Navigator.of(context, rootNavigator: true)
                      .push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) => const SettingsScreen(),
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
                      Expanded(
                        child: Text(
                          profile.displayName,
                          style: TextStyle(
                            color: context.oklOnSurface,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => Navigator.of(context, rootNavigator: true).push<void>(
                          MaterialPageRoute<void>(
                            builder: (_) => const AccountVerificationScreen(),
                          ),
                        ),
                        child: profile.hasOkliforCertificate
                            ? Image.asset(
                                'assets/images/certify_icon.png',
                                width: 22,
                                height: 22,
                                fit: BoxFit.contain,
                              )
                            : Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: context.oklSurface,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: context.oklDivider),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      LucideIcons.shield,
                                      size: 14,
                                      color: context.oklOnSurfaceMuted(0.62),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Vérifier',
                                      style: TextStyle(
                                        color: context.oklOnSurfaceMuted(0.62),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(LucideIcons.mapPin, size: 13, color: context.oklOnSurfaceMuted(0.62)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          profile.city,
                          style: TextStyle(
                            color: context.oklOnSurfaceMuted(0.62),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (!profile.hasOkliforCertificate) ...[
                    const SizedBox(height: 12),
                    Material(
                      color: context.oklSurface,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: () => Navigator.of(context, rootNavigator: true).push<void>(
                          MaterialPageRoute<void>(
                            builder: (_) => const AccountVerificationScreen(),
                          ),
                        ),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: context.oklDivider),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                LucideIcons.shieldCheck,
                                size: 20,
                                color: AppColors.primary.withValues(alpha: 0.9),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Profil à certifier (${profile.completedVerificationSteps}/3)',
                                      style: TextStyle(
                                        color: context.oklOnSurface,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      !profile.emailVerified && !profile.idVerified
                                          ? 'E-mail et identité restants pour le badge Oklifor.'
                                          : !profile.idVerified
                                              ? 'Soumets ta pièce d’identité pour finaliser.'
                                              : 'Termine les étapes depuis l’écran vérification.',
                                      style: TextStyle(
                                        color: context.oklOnSurfaceMuted(0.62).withValues(alpha: 0.95),
                                        fontSize: 12,
                                        height: 1.25,
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
                    ),
                  ],
                  const SizedBox(height: 14),
                  Text(
                    profile.bio,
                    style: TextStyle(
                      color: context.oklOnSurfaceMuted(0.62).withValues(alpha: 0.98),
                      fontSize: 14,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _ProfileChip(icon: LucideIcons.heart, label: profile.relationGoal),
                      _ProfileChip(icon: LucideIcons.languages, label: profile.languages),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatItem(
                        value: '128',
                        label: 'Likes',
                        onTap: () => Navigator.of(context, rootNavigator: true).push<void>(
                          MaterialPageRoute<void>(
                            builder: (_) => const ProfileStatDetailScreen(
                              title: 'Likes reçus',
                              value: '128',
                              hint:
                                  'Personnes qui ont aimé ton profil ou répondu à tes statuts cette semaine (démo).',
                            ),
                          ),
                        ),
                      ),
                      _StatItem(
                        value: '24',
                        label: 'Matchs',
                        onTap: () => Navigator.of(context, rootNavigator: true).push<void>(
                          MaterialPageRoute<void>(
                            builder: (_) => const ProfileStatDetailScreen(
                              title: 'Matchs',
                              value: '24',
                              hint:
                                  'Conversations ouvertes après un double intérêt. Continue à compléter ton profil pour en obtenir plus (démo).',
                            ),
                          ),
                        ),
                      ),
                      _StatItem(
                        value: '17',
                        label: 'Demandes',
                        onTap: () => Navigator.of(context, rootNavigator: true).push<void>(
                          MaterialPageRoute<void>(
                            builder: (_) => const FriendRequestsListScreen(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: Material(
                          color: context.oklSurface,
                          borderRadius: BorderRadius.circular(10),
                          child: InkWell(
                            onTap: () {
                              Navigator.of(context, rootNavigator: true).push<void>(
                                MaterialPageRoute<void>(
                                  builder: (_) => EditProfileScreen(initial: profile),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 11),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: context.oklDivider),
                              ),
                              child: Text(
                                'Modifier le profil',
                                style: TextStyle(
                                  color: context.oklOnSurface,
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
                        color: context.oklSurface,
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          onTap: () => Navigator.of(context, rootNavigator: true)
                              .push<void>(
                            MaterialPageRoute<void>(
                              builder: (_) => const InviteFriendsScreen(),
                            ),
                          ),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: 40,
                            height: 40,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: context.oklDivider),
                            ),
                            child: Icon(
                              LucideIcons.userPlus,
                              color: context.oklOnSurfaceMuted(0.62),
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
                        style: TextStyle(
                          color: context.oklOnSurface,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context, rootNavigator: true).push<void>(
                          MaterialPageRoute<void>(
                            builder: (_) => const FriendRequestsListScreen(),
                          ),
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
                      color: context.oklSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: context.oklDivider),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        for (int i = 0; i < _friendRequests.length; i++) ...[
                          if (i > 0)
                            Divider(height: 1, thickness: 1, color: context.oklDivider),
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
          SliverPadding(
            padding: EdgeInsets.only(
              bottom: oklMainShellListBottomPadding(context),
            ),
            sliver: const SliverToBoxAdapter(child: SizedBox.shrink()),
          ),
        ],
      ),
    );
      },
    );
  }
}

class _ProfileChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ProfileChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: context.oklSurface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: context.oklDivider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: context.oklOnSurfaceMuted(0.62)),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 260),
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: context.oklOnSurface,
                fontSize: 12,
                fontWeight: FontWeight.w600,
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
  final VoidCallback onTap;

  const _StatItem({required this.value, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            children: [
              Text(value,
                  style: TextStyle(
                    color: context.oklOnSurface,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  )),
              const SizedBox(height: 2),
              Text(label,
                  style: TextStyle(
                      color: context.oklOnSurfaceMuted(0.62), fontSize: 12)),
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
              placeholder: (ctx, url) => Container(
                width: 56,
                height: 56,
                color: ctx.oklSurface,
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
                  style: TextStyle(
                    color: context.oklOnSurface,
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
                  style: TextStyle(
                    color: context.oklOnSurfaceMuted(0.62),
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
                          backgroundColor: context.oklScaffold,
                          foregroundColor: context.oklOnSurface,
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
          style: TextStyle(
            color: context.oklOnSurface,
            fontSize: 17,
            fontWeight: FontWeight.w700,
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
              for (int i = 0; i < items.length; i++) ...[
                _CommunityRow(
                  item: items[i],
                  onOpen: () => Navigator.of(context, rootNavigator: true).push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) => OklLegalDocumentScreen(
                        title: items[i].title,
                        paragraphs: [
                          items[i].subtitle,
                          'Fiche d’activité Oklifor (démo) : bientôt actions rapides (message, rappel, partage) depuis cet écran.',
                          'En attendant le backend, utilise Messages et Rencontres pour poursuivre la conversation.',
                        ],
                      ),
                    ),
                  ),
                ),
                if (i != items.length - 1)
                  Divider(height: 1, color: context.oklDivider),
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
  final VoidCallback onOpen;

  const _CommunityRow({required this.item, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Color.alphaBlend(
                    context.oklOnSurface.withValues(alpha: 0.08),
                    context.oklSurface,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(item.icon, size: 17, color: context.oklOnSurfaceMuted(0.62)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        color: context.oklOnSurface,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.subtitle,
                      style: TextStyle(
                        color: context.oklOnSurfaceMuted(0.62),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(LucideIcons.chevronRight, color: context.oklOnSurfaceMuted(0.55), size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
