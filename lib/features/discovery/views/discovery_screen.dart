import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/okl_feedback.dart';

class _DemoProfile {
  final String name;
  final int age;
  final String location;
  final String imageUrl;
  final List<String> tags;
  final String relationGoal;
  final String ethnicity;
  final String motherTongue;
  final String languages;
  final String lifestyle;
  final String bio;

  const _DemoProfile({
    required this.name,
    required this.age,
    required this.location,
    required this.imageUrl,
    required this.tags,
    required this.relationGoal,
    required this.ethnicity,
    required this.motherTongue,
    required this.languages,
    required this.lifestyle,
    required this.bio,
  });
}

/// Images Unsplash haute définition (portraits & ambiance claire).
const _profiles = <_DemoProfile>[
  _DemoProfile(
    name: 'Afi',
    age: 24,
    location: 'Agoè, Lomé',
    imageUrl:
        'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=1080&q=88&auto=format&fit=crop',
    tags: ['Amour', 'Danse'],
    relationGoal: 'Relation sérieuse',
    ethnicity: 'Ewe',
    motherTongue: 'Ewe',
    languages: 'Français, Mina',
    lifestyle: 'Calme, sorties weekend',
    bio: 'Je cherche une relation stable avec quelqu’un de vrai.',
  ),
  _DemoProfile(
    name: 'Kofi',
    age: 27,
    location: 'Kégué, Lomé',
    imageUrl:
        'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=1080&q=88&auto=format&fit=crop',
    tags: ['Musique', 'Plage'],
    relationGoal: 'Rencontre sérieuse',
    ethnicity: 'Kotocoli',
    motherTongue: 'Tem',
    languages: 'Français, Tem',
    lifestyle: 'Sport, musique live',
    bio: 'Passionné de musique et de voyages, prêt pour une vraie histoire.',
  ),
  _DemoProfile(
    name: 'Mawuli',
    age: 25,
    location: 'Bè, Lomé',
    imageUrl:
        'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=1080&q=88&auto=format&fit=crop',
    tags: ['Photo', 'Voyage'],
    relationGoal: 'Relation engagée',
    ethnicity: 'Ewe',
    motherTongue: 'Ewe',
    languages: 'Français, Ewe, Anglais',
    lifestyle: 'Créatif, spontané',
    bio: 'Photographe amateur, je veux construire quelque chose de sincère.',
  ),
  _DemoProfile(
    name: 'Sena',
    age: 23,
    location: 'Tokoin, Lomé',
    imageUrl:
        'https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e?w=1080&q=88&auto=format&fit=crop',
    tags: ['Art', 'Café'],
    relationGoal: 'Relation sérieuse',
    ethnicity: 'Ouatchi',
    motherTongue: 'Mina',
    languages: 'Français, Mina',
    lifestyle: 'Art, café, balades',
    bio: 'J’aime les conversations profondes et les rencontres authentiques.',
  ),
  _DemoProfile(
    name: 'Edem',
    age: 26,
    location: 'Kpalimé',
    imageUrl:
        'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=1080&q=88&auto=format&fit=crop',
    tags: ['Nature', 'Sport'],
    relationGoal: 'Mariage à long terme',
    ethnicity: 'Akposso',
    motherTongue: 'Akposso',
    languages: 'Français, Akposso',
    lifestyle: 'Nature, sport, famille',
    bio: 'Simple et loyal, je veux bâtir une relation durable.',
  ),
  _DemoProfile(
    name: 'Kossi',
    age: 28,
    location: 'Lomé — Centre',
    imageUrl:
        'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=1080&q=88&auto=format&fit=crop',
    tags: ['Tech', 'Food'],
    relationGoal: 'Relation stable',
    ethnicity: 'Moba',
    motherTongue: 'Moba',
    languages: 'Français, Moba',
    lifestyle: 'Tech, cuisine, fitness',
    bio: 'Entrepreneur à Lomé, je cherche une partenaire ambitieuse et simple.',
  ),
];

class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  int _cacheWidth(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final w = MediaQuery.sizeOf(context).width;
    return (w * dpr).round().clamp(360, 1440);
  }

  void _openDiscoveryFilters(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => const _DiscoveryFiltersSheet(),
    );
  }

  void _openProfileQuickInfo(BuildContext context, _DemoProfile p) {
    Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 280),
        reverseTransitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (context, animation, secondaryAnimation) =>
            _ProfileDetailsScreen(profile: p),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curve = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(curve),
            child: child,
          );
        },
      ),
    );
  }

  void _openProfileLive(BuildContext context, _DemoProfile p) {
    final liveFriends = _profiles
        .where((item) => item.name != p.name)
        .take(4)
        .toList(growable: false);
    Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 280),
        reverseTransitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (context, animation, secondaryAnimation) => _LiveFriendsScreen(
          host: p,
          liveFriends: liveFriends,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curve = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(-1, 0),
              end: Offset.zero,
            ).animate(curve),
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomBarSpace = MediaQuery.paddingOf(context).bottom + 68;

    return Scaffold(
      backgroundColor: Colors.black,
      extendBody: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            allowImplicitScrolling: false,
            itemCount: _profiles.length,
            onPageChanged: (i) {
              setState(() => _currentIndex = i);
            },
            itemBuilder: (context, index) {
              final p = _profiles[index];
              return _ReelPage(
                profile: p,
                cacheWidth: _cacheWidth(context),
                bottomInset: bottomBarSpace,
                onPass: () {
                  OklFeedback.snack(context, 'Profil passé');
                  if (index < _profiles.length - 1) {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 320),
                      curve: Curves.easeOutCubic,
                    );
                  }
                },
                onLike: () {
                  OklFeedback.snack(context, 'Like envoyé à ${p.name}');
                  if (index < _profiles.length - 1) {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 320),
                      curve: Curves.easeOutCubic,
                    );
                  }
                },
                onSuper: () {
                  OklFeedback.snack(context, 'Super Like pour ${p.name}');
                },
                onOpenDetails: () => _openProfileQuickInfo(context, p),
                onOpenLives: () => _openProfileLive(context, p),
              );
            },
          ),
          _DiscoveryTopBar(
            onFilters: () => _openDiscoveryFilters(context),
            onBell: () => Navigator.of(context, rootNavigator: true).push(
              MaterialPageRoute<void>(
                builder: (_) => const _NotificationsScreen(),
              ),
            ),
            onInfo: () => _openProfileLive(context, _profiles[_currentIndex]),
          ),
        ],
      ),
    );
  }
}

class _ProfileDetailsScreen extends StatelessWidget {
  final _DemoProfile profile;

  const _ProfileDetailsScreen({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dark,
      appBar: AppBar(
        backgroundColor: AppColors.dark,
        title: const Text('Profil complet'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.paddingOf(context).bottom + 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 4 / 5,
                child: CachedNetworkImage(
                  imageUrl: profile.imageUrl,
                  fit: BoxFit.cover,
                  memCacheWidth: 900,
                  placeholder: (context, url) => Container(color: AppColors.surface),
                  errorWidget: (context, url, error) => Container(color: AppColors.surface),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '${profile.name}, ${profile.age}',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(LucideIcons.mapPin, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(
                  profile.location,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: profile.tags
                  .map(
                    (t) => Chip(
                      label: Text(t),
                      backgroundColor: AppColors.surface,
                      side: BorderSide(color: AppColors.togoGold.withValues(alpha: 0.45)),
                      labelStyle: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 18),
            const Text(
              'A propos',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              profile.bio,
              style: const TextStyle(
                color: AppColors.textSecondary,
                height: 1.4,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 18),
            _ProfileFieldTile(
              icon: LucideIcons.heartHandshake,
              label: 'Type de relation attendue',
              value: profile.relationGoal,
            ),
            _ProfileFieldTile(
              icon: LucideIcons.mapPin,
              label: 'Localite',
              value: profile.location,
            ),
            _ProfileFieldTile(
              icon: LucideIcons.users,
              label: 'Ethnie',
              value: profile.ethnicity,
            ),
            _ProfileFieldTile(
              icon: LucideIcons.messageSquare,
              label: 'Langue maternelle',
              value: profile.motherTongue,
            ),
            _ProfileFieldTile(
              icon: LucideIcons.languages,
              label: 'Langues parlees',
              value: profile.languages,
            ),
            _ProfileFieldTile(
              icon: LucideIcons.leaf,
              label: 'Mode de vie',
              value: profile.lifestyle,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => OklFeedback.snack(
                      context,
                      'Profil signale (demo)',
                    ),
                    icon: const Icon(LucideIcons.flag, size: 18),
                    label: const Text('Signaler'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => OklFeedback.snack(
                      context,
                      'Invitation envoyee a ${profile.name}',
                    ),
                    icon: const Icon(LucideIcons.messageCircle, size: 18),
                    label: const Text('Inviter'),
                    style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileFieldTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileFieldTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
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

class _LiveFriendsScreen extends StatelessWidget {
  final _DemoProfile host;
  final List<_DemoProfile> liveFriends;

  const _LiveFriendsScreen({
    required this.host,
    required this.liveFriends,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dark,
      appBar: AppBar(
        backgroundColor: AppColors.dark,
        title: const Text('Amis en live'),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.paddingOf(context).bottom + 18),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 16 / 10,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: host.imageUrl,
                    fit: BoxFit.cover,
                    memCacheWidth: 1000,
                    placeholder: (context, url) => Container(color: AppColors.surface),
                    errorWidget: (context, url, error) => Container(color: AppColors.surface),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Color(0xC9000000)],
                        stops: [0.45, 1.0],
                      ),
                    ),
                  ),
                  const Positioned(
                    top: 12,
                    left: 12,
                    child: _LivePill(),
                  ),
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 12,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${host.name} est en live maintenant',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        FilledButton.icon(
                          onPressed: () => OklFeedback.snack(
                            context,
                            'Tu rejoins la live de ${host.name} (demo)',
                          ),
                          icon: const Icon(LucideIcons.play, size: 16),
                          label: const Text('Regarder'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.togoRed,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Amis connectes en live',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          for (final friend in liveFriends)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                children: [
                  ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: friend.imageUrl,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      memCacheWidth: 120,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                '${friend.name}, ${friend.age}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            const _LivePill(),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${friend.location} • ${friend.relationGoal}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Ethnie: ${friend.ethnicity} • Langues: ${friend.languages}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () => OklFeedback.snack(
                      context,
                      'Invitation envoyee a ${friend.name}',
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    child: const Text('Inviter'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _DiscoveryTopBar extends StatelessWidget {
  final VoidCallback onFilters;
  final VoidCallback onBell;
  final VoidCallback onInfo;

  const _DiscoveryTopBar({
    required this.onFilters,
    required this.onBell,
    required this.onInfo,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 22,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.togoGreen,
                          AppColors.togoGold,
                          AppColors.togoRed,
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Oklifor',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                      shadows: [
                        Shadow(
                          color: Colors.black54,
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  _GlassIconBtn(icon: LucideIcons.slidersHorizontal, onTap: onFilters),
                  const SizedBox(width: 8),
                  _GlassIconBtn(icon: LucideIcons.bell, onTap: onBell),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onInfo,
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white24),
                      ),
                      child: const Center(
                        child: Icon(LucideIcons.radio, color: Colors.white70, size: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DiscoveryFiltersSheet extends StatefulWidget {
  const _DiscoveryFiltersSheet();

  @override
  State<_DiscoveryFiltersSheet> createState() => _DiscoveryFiltersSheetState();
}

class _DiscoveryFiltersSheetState extends State<_DiscoveryFiltersSheet> {
  bool _verifiedOnly = false;
  bool _withPhotoOnly = true;
  bool _sameCity = false;
  bool _newProfiles = false;

  /// État par défaut après « Réinitialiser » — toute déviation = filtres « actifs » pour le bouton Appliquer.
  bool get _hasNonDefaultFilters =>
      _verifiedOnly ||
      !_withPhotoOnly ||
      _sameCity ||
      _newProfiles;

  void _applyAndClose(BuildContext context) {
    Navigator.pop(context);
    OklFeedback.snack(context, 'Filtres appliqués');
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.78,
      minChildSize: 0.42,
      maxChildSize: 0.94,
      expand: false,
      builder: (context, scrollController) {
        return DecoratedBox(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Filtres de découverte',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Affine ton fil : critères principaux, options rapides et résumé en un coup d’œil.',
                      style: TextStyle(
                        color: AppColors.textSecondary.withValues(alpha: 0.95),
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.dark.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(LucideIcons.layers, size: 16, color: AppColors.textSecondary),
                              const SizedBox(width: 8),
                              const Text(
                                'Résumé actif',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: const [
                              _FilterSummaryChip(label: 'Femmes & hommes'),
                              _FilterSummaryChip(label: '≤ 25 km'),
                              _FilterSummaryChip(label: '21 — 35 ans'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Critères principaux',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _FilterRow(
                      icon: LucideIcons.users,
                      title: 'Qui voir',
                      subtitle: 'Femmes, hommes, tous — personnaliser',
                      onTap: () {
                        Navigator.pop(context);
                        OklFeedback.snack(context, 'Préférences enregistrées (démo)');
                      },
                    ),
                    _FilterRow(
                      icon: LucideIcons.mapPin,
                      title: 'Distance max',
                      subtitle: 'Jusqu’à 25 km autour de ta position',
                      onTap: () {
                        Navigator.pop(context);
                        OklFeedback.snack(context, 'Rayon : 25 km');
                      },
                    ),
                    _FilterRow(
                      icon: LucideIcons.cake,
                      title: 'Tranche d’âge',
                      subtitle: '21 — 35 ans — ajuster la plage',
                      onTap: () {
                        Navigator.pop(context);
                        OklFeedback.snack(context, 'Âge : 21 à 35 ans');
                      },
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Affiner le fil',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Options qui s’appliquent en plus des critères ci-dessus.',
                      style: TextStyle(
                        color: AppColors.textMuted.withValues(alpha: 0.9),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _FilterToggleTile(
                      icon: LucideIcons.badgeCheck,
                      title: 'Profils vérifiés uniquement',
                      subtitle: 'Réduit le fil aux comptes certifiés',
                      value: _verifiedOnly,
                      onChanged: (v) => setState(() => _verifiedOnly = v),
                    ),
                    _FilterToggleTile(
                      icon: LucideIcons.image,
                      title: 'Avec photo obligatoire',
                      subtitle: 'Masque les profils sans photo principale',
                      value: _withPhotoOnly,
                      onChanged: (v) => setState(() => _withPhotoOnly = v),
                    ),
                    _FilterToggleTile(
                      icon: LucideIcons.building2,
                      title: 'Même ville / agglomération',
                      subtitle: 'Priorise les profils proches de ton quartier',
                      value: _sameCity,
                      onChanged: (v) => setState(() => _sameCity = v),
                    ),
                    _FilterToggleTile(
                      icon: LucideIcons.sparkles,
                      title: 'Nouveaux profils en priorité',
                      subtitle: 'Met en avant les arrivées récentes',
                      value: _newProfiles,
                      onChanged: (v) => setState(() => _newProfiles = v),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(LucideIcons.info, size: 18, color: AppColors.textSecondary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Les filtres sont sauvegardés sur cet appareil. Tu peux les réinitialiser à tout moment.',
                              style: TextStyle(
                                color: AppColors.textSecondary.withValues(alpha: 0.95),
                                fontSize: 12,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: MediaQuery.paddingOf(context).bottom + 100),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.fromLTRB(
                  20,
                  12,
                  20,
                  MediaQuery.paddingOf(context).bottom + 14,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(top: BorderSide(color: AppColors.divider, width: 0.5)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          setState(() {
                            _verifiedOnly = false;
                            _withPhotoOnly = true;
                            _sameCity = false;
                            _newProfiles = false;
                          });
                          OklFeedback.snack(context, 'Filtres réinitialisés');
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Réinitialiser'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: _hasNonDefaultFilters
                          ? FilledButton(
                              onPressed: () => _applyAndClose(context),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: AppColors.textMuted,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Appliquer',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            )
                          : OutlinedButton(
                              onPressed: () => _applyAndClose(context),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.textPrimary,
                                side: const BorderSide(color: AppColors.divider, width: 1),
                                backgroundColor: AppColors.dark.withValues(alpha: 0.35),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Appliquer',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
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

class _FilterSummaryChip extends StatelessWidget {
  final String label;

  const _FilterSummaryChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.divider),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _FilterToggleTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _FilterToggleTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.dark.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => onChanged(!value),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(icon, color: AppColors.textSecondary, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11.5,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: value,
                  onChanged: onChanged,
                  activeTrackColor: AppColors.primary.withValues(alpha: 0.45),
                  activeThumbColor: Colors.white,
                  inactiveTrackColor: AppColors.divider.withValues(alpha: 0.6),
                  inactiveThumbColor: AppColors.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _FilterRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.dark,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(icon, color: AppColors.textSecondary, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 15)),
                      Text(subtitle,
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
                const Icon(LucideIcons.chevronRight, color: AppColors.textMuted, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationsScreen extends StatelessWidget {
  const _NotificationsScreen();

  @override
  Widget build(BuildContext context) {
    final items = <({
      IconData icon,
      String title,
      String subtitle,
      String time,
      bool unread,
    })>[
      (
        icon: LucideIcons.heart,
        title: 'Nouveau like',
        subtitle: 'Afi a like ton profil.',
        time: 'il y a 2 min',
        unread: true,
      ),
      (
        icon: LucideIcons.sparkles,
        title: 'Nouveau match',
        subtitle: 'Tu as matché avec Kossi.',
        time: 'il y a 8 min',
        unread: true,
      ),
      (
        icon: LucideIcons.radio,
        title: 'Ami en live',
        subtitle: 'Sena est en direct maintenant.',
        time: 'il y a 16 min',
        unread: false,
      ),
      (
        icon: LucideIcons.userPlus,
        title: 'Nouvelle demande',
        subtitle: 'Mawuli veut rejoindre tes amis.',
        time: 'il y a 1 h',
        unread: false,
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.dark,
      appBar: AppBar(
        backgroundColor: AppColors.dark,
        title: const Text('Notifications'),
      ),
      body: ListView.separated(
        padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.paddingOf(context).bottom + 14),
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final n = items[index];
          return Material(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => OklFeedback.snack(context, n.title),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.dark.withValues(alpha: 0.55),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Icon(n.icon, color: AppColors.textSecondary, size: 19),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  n.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Text(
                                n.time,
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            n.subtitle,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (n.unread) ...[
                      const SizedBox(width: 8),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ReelPage extends StatelessWidget {
  final _DemoProfile profile;
  final int cacheWidth;
  final double bottomInset;
  final VoidCallback onPass;
  final VoidCallback onLike;
  final VoidCallback onSuper;
  final VoidCallback onOpenDetails;
  final VoidCallback onOpenLives;

  const _ReelPage({
    required this.profile,
    required this.cacheWidth,
    required this.bottomInset,
    required this.onPass,
    required this.onLike,
    required this.onSuper,
    required this.onOpenDetails,
    required this.onOpenLives,
  });

  @override
  Widget build(BuildContext context) {
    double dragX = 0;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onDoubleTap: onLike,
      onHorizontalDragUpdate: (d) => dragX += d.delta.dx,
      onHorizontalDragEnd: (_) {
        // Swipe vers la gauche pour ouvrir le profil complet.
        if (dragX < -90) onOpenDetails();
        // Swipe vers la droite pour ouvrir la page des lives.
        if (dragX > 90) onOpenLives();
        dragX = 0;
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: profile.imageUrl,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.high,
            memCacheWidth: cacheWidth,
            fadeInDuration: const Duration(milliseconds: 180),
            placeholder: (context, url) => Container(
              color: AppColors.surface,
              alignment: Alignment.center,
              child: const SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.togoGold,
                ),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              color: AppColors.surface,
              alignment: Alignment.center,
              child: const Icon(
                LucideIcons.imageOff,
                color: AppColors.textMuted,
                size: 48,
              ),
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(gradient: AppColors.togoHeroOverlay),
          ),
          // Colonne d’actions (style IG)
          Positioned(
            right: 10,
            bottom: bottomInset + 8,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _SideAction(
                  icon: LucideIcons.x,
                  color: AppColors.togoRed,
                  label: 'Passer',
                  onTap: onPass,
                ),
                const SizedBox(height: 18),
                _SideAction(
                  icon: LucideIcons.star,
                  color: AppColors.togoGold,
                  label: 'Super',
                  onTap: onSuper,
                ),
                const SizedBox(height: 18),
                _SideAction(
                  icon: LucideIcons.heart,
                  color: AppColors.togoGreen,
                  label: 'Like',
                  onTap: onLike,
                ),
              ],
            ).animate().fadeIn(duration: 350.ms, delay: 80.ms),
          ),
          // Infos bas
          Positioned(
            left: 16,
            right: 72,
            bottom: bottomInset,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final t in profile.tags) ...[
                        _TogoChip(label: t),
                        const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        '${profile.name}, ${profile.age}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                          shadows: [Shadow(color: Colors.black54, blurRadius: 10)],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Image.asset(
                      'assets/images/certify_icon.png',
                      width: 26,
                      height: 26,
                      fit: BoxFit.contain,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      LucideIcons.mapPin,
                      color: Colors.white.withValues(alpha: 0.85),
                      size: 15,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        profile.location,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.88),
                          fontSize: 14,
                          shadows: const [
                            Shadow(color: Colors.black45, blurRadius: 8)
                          ],
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

class _GlassIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _GlassIconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

class _SideAction extends StatefulWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _SideAction({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  @override
  State<_SideAction> createState() => _SideActionState();
}

class _SideActionState extends State<_SideAction> {
  bool _pressed = false;

  void _setPressed(bool v) {
    if (_pressed == v) return;
    setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = _pressed
        ? widget.color
        : AppColors.textSecondary.withValues(alpha: 0.9);
    final labelColor = _pressed
        ? Colors.white.withValues(alpha: 0.92)
        : AppColors.textSecondary.withValues(alpha: 0.9);

    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withValues(alpha: 0.4),
              border: Border.all(color: Colors.white24),
              boxShadow: _pressed
                  ? [
                      BoxShadow(
                        color: widget.color.withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : const [],
            ),
            child: Icon(widget.icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 5),
          Text(
            widget.label,
            style: TextStyle(
              color: labelColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              shadows: _pressed
                  ? const [Shadow(color: Colors.black87, blurRadius: 6)]
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _TogoChip extends StatelessWidget {
  final String label;

  const _TogoChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.togoGreen.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.togoGold.withValues(alpha: 0.65),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _LivePill extends StatelessWidget {
  const _LivePill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(LucideIcons.radio, color: Colors.white, size: 13),
          const SizedBox(width: 6),
          Text(
            'En direct',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
