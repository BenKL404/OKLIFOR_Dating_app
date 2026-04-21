import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/layout_constants.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/widgets/okl_story_gauge_ring.dart';
import '../../../core/flows/okl_flows.dart';
import '../models/user_profile.dart';
import '../models/vip_subscription.dart';
import 'vip_pass_screen.dart';
import 'account_verification_screen.dart';
import 'edit_profile_screen.dart';
import 'invite_friends_screen.dart';
import 'settings_screen.dart';
import 'friend_requests_list_screen.dart';
import 'profile_stat_detail_screen.dart';
import '../../common/views/contact_qr_hub_screen.dart';
import '../../common/views/rich_account_screens.dart';

// ── Données démo ─────────────────────────────────────────────────────────────

const _kFriendRequests = <({
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
    area: 'Kégué',
    avatar:
        'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=200&q=80&auto=format&fit=crop',
    mutualFriends: 5,
  ),
  (
    name: 'Afi',
    area: 'Agoè',
    avatar:
        'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200&q=80&auto=format&fit=crop',
    mutualFriends: 28,
  ),
  (
    name: 'Mawuli',
    area: 'Adidogome',
    avatar:
        'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=200&q=80&auto=format&fit=crop',
    mutualFriends: 3,
  ),
];

const _kRecentActivity = <({IconData icon, String title, String sub, Color color})>[
  (
    icon: LucideIcons.heart,
    title: 'Nouveau match avec Fati',
    sub: 'Il y a 10 min',
    color: Color(0xFFE05B7A),
  ),
  (
    icon: LucideIcons.messageCircle,
    title: "Kossi t'a écrit",
    sub: 'Répondre maintenant',
    color: AppColors.primary,
  ),
  (
    icon: LucideIcons.sparkles,
    title: "Profil boosté aujourd'hui",
    sub: '+12 vues de profil',
    color: AppColors.togoGold,
  ),
];

const _kCommunityEvents = <({IconData icon, String title, String sub})>[
  (
    icon: LucideIcons.partyPopper,
    title: 'Soirée Oklifor',
    sub: '18 utilisateurs confirment',
  ),
  (
    icon: LucideIcons.trophy,
    title: 'Tournoi foot quartier',
    sub: 'Adidogome · samedi',
  ),
  (
    icon: LucideIcons.radio,
    title: 'Live communautaire',
    sub: '7 utilisateurs en direct',
  ),
];

// ── Écran principal ───────────────────────────────────────────────────────────

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        ProfileSession.profile,
        VipSession.subscription,
      ]),
      builder: (context, _) {
        final profile = ProfileSession.profile.value;
        final vip = VipSession.subscription.value;
        final topPad = MediaQuery.of(context).padding.top;
        return Scaffold(
          backgroundColor: context.oklScaffold,
          body: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    // ── Header : cover + avatar + identité ───────────────
                    _ProfileHeader(
                      profile: profile,
                      topPad: topPad,
                      context: context,
                    ),
                    const SizedBox(height: 16),

                    // ── Sections ─────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _ActionBar(profile: profile, context: context),
                          const SizedBox(height: 16),
                          _StatsCard(context: context),
                          const SizedBox(height: 16),
                          if (profile.bio.isNotEmpty) ...[
                            _BioSection(bio: profile.bio),
                            const SizedBox(height: 16),
                          ],
                          _InterestChips(profile: profile),
                          const SizedBox(height: 16),
                          if (!vip.isActive) ...[
                            _VipBanner(
                              vip: vip,
                              onTap: () =>
                                  Navigator.of(context, rootNavigator: true)
                                      .push<void>(
                                MaterialPageRoute<void>(
                                  builder: (_) => const VipPassScreen(),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          if (!profile.hasOkliforCertificate) ...[
                            _VerifyCard(
                                profile: profile, context: context),
                            const SizedBox(height: 16),
                          ],
                          _SectionHeader(
                            title: "Demandes d'amis",
                            badge: '${_kFriendRequests.length}',
                            onMore: () =>
                                Navigator.of(context, rootNavigator: true)
                                    .push<void>(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    const FriendRequestsListScreen(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          _FriendRequestsCarousel(context: context),
                          const SizedBox(height: 20),
                          const _SectionHeader(
                              title: 'Mes matchs récents'),
                          const SizedBox(height: 10),
                          _ActivityCard(
                              items: _kRecentActivity, context: context),
                          const SizedBox(height: 20),
                          const _SectionHeader(
                              title: 'Communauté Oklifor'),
                          const SizedBox(height: 10),
                          _CommunityCard(
                              items: _kCommunityEvents, context: context),
                          SizedBox(
                            height:
                                oklMainShellListBottomPadding(context) + 8,
                          ),
                        ],
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

// ── Header : cover + avatar + identité ───────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  final UserProfile profile;
  final double topPad;
  final BuildContext context;
  const _ProfileHeader(
      {required this.profile, required this.topPad, required this.context});

  @override
  Widget build(BuildContext ctx) {
    final vip = VipSession.subscription.value;
    const coverHeight = 210.0;
    const avatarRadius = 50.0;
    const avatarBorder = 3.0;
    const avatarTotal = (avatarRadius + avatarBorder) * 2; // 106px

    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            // Cover photo
            SizedBox(
              height: coverHeight,
              width: double.infinity,
              child: CachedNetworkImage(
                imageUrl: profile.coverUrlForDisplay,
                fit: BoxFit.cover,
                memCacheWidth: 900,
                placeholder: (c, _) => Container(color: c.oklSurface),
                errorWidget: (c, e, w) => Container(color: c.oklSurface),
              ),
            ),
            // Gradient top (barre système)
            Positioned(
              top: 0, left: 0, right: 0,
              height: topPad + 56,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xAA000000), Colors.transparent],
                  ),
                ),
              ),
            ),
            // Gradient bas → fondu vers scaffold
            Positioned(
              bottom: 0, left: 0, right: 0,
              height: 80,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [ctx.oklScaffold, Colors.transparent],
                  ),
                ),
              ),
            ),
            // Bouton Settings (top right, safe area)
            Positioned(
              top: topPad + 8,
              right: 12,
              child: _CircleIconBtn(
                icon: LucideIcons.settings,
                onTap: () =>
                    Navigator.of(context, rootNavigator: true).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => const SettingsScreen(),
                  ),
                ),
              ),
            ),
            // Avatar centré, chevauchant le bas du cover
            Positioned(
              bottom: -(avatarTotal / 2),
              left: 0,
              right: 0,
              child: Center(
                child: OklStoryGaugeRing(
                  outerSize: avatarTotal,
                  strokeWidth: 3,
                  child: Container(
                    width: avatarTotal - 2,
                    height: avatarTotal - 2,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: ctx.oklScaffold, width: avatarBorder),
                    ),
                    child: ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: profile.avatarUrlForDisplay,
                        fit: BoxFit.cover,
                        memCacheWidth: 200,
                        placeholder: (c, _) =>
                            Container(color: c.oklSurface),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        // Espace pour la moitié basse de l'avatar
        const SizedBox(height: avatarTotal / 2 + 12),
        // Nom + badges
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  profile.displayName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: ctx.oklOnSurface,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              if (vip.isActive) ...[
                const SizedBox(width: 6),
                Icon(LucideIcons.crown, color: AppColors.togoGold, size: 20),
              ],
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () =>
                    Navigator.of(context, rootNavigator: true).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => const AccountVerificationScreen(),
                  ),
                ),
                child: profile.hasOkliforCertificate
                    ? Icon(LucideIcons.badgeCheck,
                        color: AppColors.togoGold, size: 22)
                    : Icon(LucideIcons.shieldOff,
                        color: ctx.oklOnSurfaceMuted(0.4), size: 18),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        // Ville
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.mapPin,
                size: 13, color: ctx.oklOnSurfaceMuted(0.5)),
            const SizedBox(width: 4),
            Text(
              profile.city,
              style: TextStyle(
                color: ctx.oklOnSurfaceMuted(0.55),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CircleIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleIconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}

// ── Barre d'actions (Modifier, Inviter, QR) ───────────────────────────────────

class _ActionBar extends StatelessWidget {
  final UserProfile profile;
  final BuildContext context;
  const _ActionBar({required this.profile, required this.context});

  @override
  Widget build(BuildContext ctx) {
    return Row(
      children: [
        Expanded(
          child: _OutlinedActionBtn(
            label: 'Modifier le profil',
            onTap: () =>
                Navigator.of(context, rootNavigator: true).push<void>(
              MaterialPageRoute<void>(
                builder: (_) => EditProfileScreen(initial: profile),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        _IconActionBtn(
          icon: LucideIcons.userPlus,
          onTap: () =>
              Navigator.of(context, rootNavigator: true).push<void>(
            MaterialPageRoute<void>(
              builder: (_) => const InviteFriendsScreen(),
            ),
          ),
        ),
        const SizedBox(width: 8),
        _IconActionBtn(
          icon: LucideIcons.qrCode,
          onTap: () =>
              Navigator.of(context, rootNavigator: true).push<void>(
            MaterialPageRoute<void>(
              builder: (_) => const ContactQrHubScreen(),
            ),
          ),
        ),
      ],
    );
  }
}

class _OutlinedActionBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _OutlinedActionBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.oklSurface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.oklDivider),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: context.oklOnSurface,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _IconActionBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconActionBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.oklSurface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.oklDivider),
          ),
          child: Icon(icon, size: 18, color: context.oklOnSurfaceMuted(0.65)),
        ),
      ),
    );
  }
}

// ── Stats ─────────────────────────────────────────────────────────────────────

class _StatsCard extends StatelessWidget {
  final BuildContext context;
  const _StatsCard({required this.context});

  @override
  Widget build(BuildContext ctx) {
    return Container(
      decoration: BoxDecoration(
        color: ctx.oklSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ctx.oklDivider),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            _StatCell(
              value: '128',
              label: 'Likes',
              onTap: () =>
                  Navigator.of(context, rootNavigator: true).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => const ProfileStatDetailScreen(
                    title: 'Likes reçus',
                    value: '128',
                    hint: 'Personnes qui ont aimé ton profil ou répondu à tes statuts cette semaine (démo).',
                  ),
                ),
              ),
            ),
            VerticalDivider(
                width: 1, thickness: 1, color: ctx.oklDivider),
            _StatCell(
              value: '24',
              label: 'Matchs',
              onTap: () =>
                  Navigator.of(context, rootNavigator: true).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => const ProfileStatDetailScreen(
                    title: 'Matchs',
                    value: '24',
                    hint: 'Conversations ouvertes après un double intérêt (démo).',
                  ),
                ),
              ),
            ),
            VerticalDivider(
                width: 1, thickness: 1, color: ctx.oklDivider),
            _StatCell(
              value: '17',
              label: 'Demandes',
              onTap: () =>
                  Navigator.of(context, rootNavigator: true).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => const FriendRequestsListScreen(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String value;
  final String label;
  final VoidCallback onTap;
  const _StatCell(
      {required this.value, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 14),
            child: Column(
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: context.oklOnSurface,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: context.oklOnSurfaceMuted(0.55),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Bio ───────────────────────────────────────────────────────────────────────

class _BioSection extends StatefulWidget {
  final String bio;
  const _BioSection({required this.bio});

  @override
  State<_BioSection> createState() => _BioSectionState();
}

class _BioSectionState extends State<_BioSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    const maxLines = 3;
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Text(
        widget.bio,
        maxLines: _expanded ? null : maxLines,
        overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
        style: TextStyle(
          color: context.oklOnSurface.withValues(alpha: 0.82),
          fontSize: 14,
          height: 1.55,
        ),
      ),
    );
  }
}

// ── Chips d'intérêts ──────────────────────────────────────────────────────────

class _InterestChips extends StatelessWidget {
  final UserProfile profile;
  const _InterestChips({required this.profile});

  @override
  Widget build(BuildContext context) {
    final chips = <({IconData icon, String label, Color color})>[
      if (profile.relationGoal.isNotEmpty)
        (
          icon: LucideIcons.heart,
          label: profile.relationGoal,
          color: const Color(0xFFE05B7A),
        ),
      if (profile.languages.isNotEmpty)
        (
          icon: LucideIcons.languages,
          label: profile.languages,
          color: AppColors.primary,
        ),
      if (profile.lifestyle.isNotEmpty)
        (
          icon: LucideIcons.sun,
          label: profile.lifestyle,
          color: AppColors.togoGold,
        ),
      if (profile.profession.isNotEmpty)
        (
          icon: LucideIcons.briefcase,
          label: profile.profession,
          color: const Color(0xFF7B68EE),
        ),
      if (profile.education.isNotEmpty)
        (
          icon: LucideIcons.graduationCap,
          label: profile.education,
          color: const Color(0xFF20B2AA),
        ),
    ];

    if (chips.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          for (int i = 0; i < chips.length; i++) ...[
            _Chip(
              icon: chips[i].icon,
              label: chips[i].label,
              color: chips[i].color,
            ),
            if (i < chips.length - 1) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _Chip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 180),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: context.oklOnSurface.withValues(alpha: 0.9),
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

// ── Bannière VIP ──────────────────────────────────────────────────────────────

class _VipBanner extends StatelessWidget {
  final VipSubscriptionState vip;
  final VoidCallback onTap;
  const _VipBanner({required this.vip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (vip.isActive) {
      return _VipTile(
        leading: Icon(LucideIcons.crown, color: AppColors.togoGold, size: 22),
        title: 'Pass VIP actif',
        sub: "Valable jusqu'au ${vip.expiresLabelFr} · ${vip.planLabelFr}",
        borderColor: AppColors.togoGold.withValues(alpha: 0.4),
        bgColor: AppColors.togoGold.withValues(alpha: 0.1),
        onTap: onTap,
      );
    }
    return _VipTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.togoGold, Color(0xFFFFAA00)],
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(LucideIcons.crown, color: Colors.white, size: 18),
      ),
      title: 'Obtenir mon Pass VIP',
      sub: "Mobile Money · voir qui t'a liké, badge, boost visibilité",
      borderColor: AppColors.togoGold.withValues(alpha: 0.35),
      bgColor: AppColors.togoGold.withValues(alpha: 0.08),
      onTap: onTap,
    );
  }
}

class _VipTile extends StatelessWidget {
  final Widget leading;
  final String title, sub;
  final Color borderColor, bgColor;
  final VoidCallback onTap;

  const _VipTile({
    required this.leading,
    required this.title,
    required this.sub,
    required this.borderColor,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              leading,
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
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sub,
                      style: TextStyle(
                        color: context.oklOnSurfaceMuted(0.62),
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(LucideIcons.chevronRight,
                  size: 16, color: context.oklOnSurfaceMuted(0.4)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Carte de vérification ─────────────────────────────────────────────────────

class _VerifyCard extends StatelessWidget {
  final UserProfile profile;
  final BuildContext context;
  const _VerifyCard({required this.profile, required this.context});

  @override
  Widget build(BuildContext ctx) {
    final steps = profile.completedVerificationSteps;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () =>
            Navigator.of(context, rootNavigator: true).push<void>(
          MaterialPageRoute<void>(
            builder: (_) => const AccountVerificationScreen(),
          ),
        ),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: ctx.oklSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: ctx.oklDivider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(LucideIcons.shieldCheck,
                      size: 18,
                      color: AppColors.primary.withValues(alpha: 0.9)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Certifie ton compte ($steps/3)',
                      style: TextStyle(
                        color: ctx.oklOnSurface,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Icon(LucideIcons.chevronRight,
                      size: 16, color: ctx.oklOnSurfaceMuted(0.4)),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: steps / 3,
                  minHeight: 5,
                  backgroundColor: ctx.oklDivider,
                  valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                !profile.emailVerified && !profile.idVerified
                    ? 'E-mail et identité restants pour le badge Oklifor.'
                    : !profile.idVerified
                        ? "Soumets ta pièce d'identité pour finaliser."
                        : 'Dernière étape — presque là !',
                style: TextStyle(
                  color: ctx.oklOnSurfaceMuted(0.6),
                  fontSize: 12,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── En-tête de section ────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? badge;
  final VoidCallback? onMore;

  const _SectionHeader({required this.title, this.badge, this.onMore});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Text(
                title,
                style: TextStyle(
                  color: context.oklOnSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    badge!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (onMore != null)
          GestureDetector(
            onTap: onMore,
            child: Text(
              'Voir tout',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

// ── Carrousel demandes d'amis ─────────────────────────────────────────────────

class _FriendRequestsCarousel extends StatelessWidget {
  final BuildContext context;
  const _FriendRequestsCarousel({required this.context});

  @override
  Widget build(BuildContext ctx) {
    return SizedBox(
      height: 156,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _kFriendRequests.length,
        separatorBuilder: (_, i) => const SizedBox(width: 10),
        itemBuilder: (ctx, i) {
          final u = _kFriendRequests[i];
          return _FriendRequestCard(user: u, context: context);
        },
      ),
    );
  }
}

class _FriendRequestCard extends StatelessWidget {
  final ({String name, String area, String avatar, int mutualFriends}) user;
  final BuildContext context;
  const _FriendRequestCard({required this.user, required this.context});

  @override
  Widget build(BuildContext ctx) {
    return Container(
      width: 130,
      decoration: BoxDecoration(
        color: ctx.oklSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ctx.oklDivider),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Avatar
          SizedBox(
            height: 72,
            child: CachedNetworkImage(
              imageUrl: user.avatar,
              fit: BoxFit.cover,
              width: double.infinity,
              memCacheWidth: 260,
              placeholder: (c, _) => Container(color: c.oklScaffold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: ctx.oklOnSurface,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                Text(
                  '${user.mutualFriends} amis communs',
                  maxLines: 1,
                  style: TextStyle(
                    color: ctx.oklOnSurfaceMuted(0.55),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: _MiniBtn(
                    label: 'Confirmer',
                    primary: true,
                    onTap: () => OklFlows.pushResult(
                      context,
                      icon: LucideIcons.userCheck,
                      title: 'Demande acceptée',
                      subtitle:
                          '${user.name} fait partie de tes contacts Oklifor.',
                      primaryLabel: 'Super',
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                _DismissBtn(
                  onTap: () => OklFlows.pushResult(
                    context,
                    icon: LucideIcons.userX,
                    title: 'Demande ignorée',
                    subtitle:
                        'Tu peux toujours retrouver ${user.name} dans les suggestions.',
                    primaryLabel: 'OK',
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

class _DismissBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _DismissBtn({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.oklScaffold,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: context.oklDivider),
          ),
          child: Icon(
            LucideIcons.x,
            size: 15,
            color: context.oklOnSurfaceMuted(0.55),
          ),
        ),
      ),
    );
  }
}

class _MiniBtn extends StatelessWidget {
  final String label;
  final bool primary;
  final VoidCallback onTap;
  const _MiniBtn(
      {required this.label, required this.primary, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: primary
          ? AppColors.primary
          : context.oklScaffold,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: primary
                ? null
                : Border.all(color: context.oklDivider),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: primary ? Colors.white : context.oklOnSurfaceMuted(0.7),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Carte activité ────────────────────────────────────────────────────────────

class _ActivityCard extends StatelessWidget {
  final List<({IconData icon, String title, String sub, Color color})> items;
  final BuildContext context;
  const _ActivityCard({required this.items, required this.context});

  @override
  Widget build(BuildContext ctx) {
    return Container(
      decoration: BoxDecoration(
        color: ctx.oklSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ctx.oklDivider),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            if (i > 0) Divider(height: 1, color: ctx.oklDivider),
            _ActivityRow(
              item: items[i],
              onTap: () => Navigator.of(context, rootNavigator: true).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => OklLegalDocumentScreen(
                    title: items[i].title,
                    paragraphs: [
                      items[i].sub,
                      'Bientôt : actions rapides (message, rappel) depuis cet écran.',
                    ],
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

class _ActivityRow extends StatelessWidget {
  final ({IconData icon, String title, String sub, Color color}) item;
  final VoidCallback onTap;
  const _ActivityRow({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(item.icon, size: 16, color: item.color),
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
                    Text(
                      item.sub,
                      style: TextStyle(
                        color: context.oklOnSurfaceMuted(0.55),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(LucideIcons.chevronRight,
                  size: 15, color: context.oklOnSurfaceMuted(0.4)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Carte communauté ──────────────────────────────────────────────────────────

class _CommunityCard extends StatelessWidget {
  final List<({IconData icon, String title, String sub})> items;
  final BuildContext context;
  const _CommunityCard({required this.items, required this.context});

  @override
  Widget build(BuildContext ctx) {
    return Container(
      decoration: BoxDecoration(
        color: ctx.oklSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ctx.oklDivider),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            if (i > 0) Divider(height: 1, color: ctx.oklDivider),
            _CommunityRow(
              item: items[i],
              onTap: () => Navigator.of(context, rootNavigator: true).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => OklLegalDocumentScreen(
                    title: items[i].title,
                    paragraphs: [items[i].sub],
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

class _CommunityRow extends StatelessWidget {
  final ({IconData icon, String title, String sub}) item;
  final VoidCallback onTap;
  const _CommunityRow({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: context.oklOnSurface.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(item.icon,
                    size: 16, color: context.oklOnSurfaceMuted(0.65)),
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
                    Text(
                      item.sub,
                      style: TextStyle(
                        color: context.oklOnSurfaceMuted(0.55),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(LucideIcons.chevronRight,
                  size: 15, color: context.oklOnSurfaceMuted(0.4)),
            ],
          ),
        ),
      ),
    );
  }
}
