import 'dart:ui' show ImageFilter;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/layout_constants.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/widgets/okl_app_bar_icon_button.dart';
import '../../../core/flows/okl_flows.dart';

class _DemoProfile {
  final String name;
  final int age;
  final String location;
  /// Photo (URL distante, ex. Unsplash).
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

Widget _buildDemoProfileImage(
  BuildContext context,
  _DemoProfile profile, {
  required BoxFit fit,
  int? memCacheWidth,
  FilterQuality filterQuality = FilterQuality.medium,
  Widget? placeholder,
  Widget? errorWidget,
}) {
  return CachedNetworkImage(
    imageUrl: profile.imageUrl,
    fit: fit,
    filterQuality: filterQuality,
    memCacheWidth: memCacheWidth,
    fadeInDuration: const Duration(milliseconds: 200),
    placeholder: placeholder != null
        ? (ctx, url) => placeholder
        : (ctx, url) => Container(color: context.oklSurface),
    errorWidget: errorWidget != null
        ? (ctx, url, err) => errorWidget
        : (ctx, url, err) => Container(color: context.oklSurface),
  );
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
      backgroundColor: context.oklSurface,
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

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top + 80;
    final shellBottom = oklMainShellBottomOverlay(context);
    const dockH = 92.0;

    final isDark = context.oklMeetIsDark;
    return Scaffold(
      backgroundColor: context.oklScaffold,
      extendBody: true,
      body: Container(
        decoration: context.oklMeetCanvasDecoration,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              top: topPad,
              left: 14,
              right: 14,
              bottom: 12,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.55 : 0.14,
                      ),
                      blurRadius: isDark ? 32 : 22,
                      offset: Offset(0, isDark ? 18 : 12),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: PageView.builder(
                    controller: _pageController,
                    scrollDirection: Axis.vertical,
                    allowImplicitScrolling: false,
                    itemCount: _profiles.length,
                    onPageChanged: (i) => setState(() => _currentIndex = i),
                    itemBuilder: (context, index) {
                      final p = _profiles[index];
                      return _ReelPage(
                        profile: p,
                        cacheWidth: _cacheWidth(context),
                        shellBottomInset: shellBottom,
                        dockHeight: dockH,
                        onPass: () {
                          if (index < _profiles.length - 1) {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 320),
                              curve: Curves.easeOutCubic,
                            );
                          }
                        },
                        onLike: () {
                          if (index < _profiles.length - 1) {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 320),
                              curve: Curves.easeOutCubic,
                            );
                          }
                        },
                        onSuper: () {},
                        onOpenDetails: () => _openProfileQuickInfo(context, p),
                        onOpenProfile: () => {},
                      );
                    },
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _MeetHeader(
                currentIndex: _currentIndex,
                totalProfiles: _profiles.length,
                onFilters: () => _openDiscoveryFilters(context),
                onBell: () => Navigator.of(context, rootNavigator: true).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const _NotificationsScreen(),
                  ),
                ),
              ),
            ),
          ],
        ),
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
      backgroundColor: context.oklScaffold,
      appBar: AppBar(
        backgroundColor: context.oklScaffold,
        leading: const OklAppBarBackButton(rootNavigator: true),
        automaticallyImplyLeading: false,
        title: const Text('Profil complet'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.paddingOf(context).bottom + 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 108,
                height: 108,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.togoGold.withValues(alpha: 0.55),
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: _buildDemoProfileImage(
                    context,
                    profile,
                    fit: BoxFit.cover,
                    memCacheWidth: 260,
                    placeholder: Container(color: context.oklSurface),
                    errorWidget: Container(color: context.oklSurface),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                '${profile.name}, ${profile.age}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: context.oklOnSurface,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.mapPin, size: 16, color: context.oklOnSurfaceMuted(0.62)),
                  const SizedBox(width: 6),
                  Text(
                    profile.location,
                    style: TextStyle(color: context.oklOnSurfaceMuted(0.62), fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Center(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: profile.tags
                    .map(
                      (t) => Chip(
                        label: Text(t),
                        backgroundColor: context.oklSurface,
                        side: BorderSide(color: AppColors.togoGold.withValues(alpha: 0.45)),
                        labelStyle: TextStyle(color: context.oklOnSurface, fontSize: 12),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'A propos',
              style: TextStyle(
                color: context.oklOnSurface,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              profile.bio,
              style: TextStyle(
                color: context.oklOnSurfaceMuted(0.62),
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
                    onPressed: () => OklFlows.pushResult(
                      context,
                      icon: LucideIcons.flag,
                      iconColor: AppColors.togoRed,
                      title: 'Signalement enregistré',
                      subtitle:
                          'Notre équipe examinera ce profil sous 24 à 48 h. Merci de garder un ton factuel dans ta description.',
                      bullets: const [
                        'Tu peux bloquer la personne depuis sa fiche.',
                        'Les signalements abusifs peuvent limiter ton compte.',
                      ],
                      primaryLabel: 'Compris',
                    ),
                    icon: const Icon(LucideIcons.flag, size: 18),
                    label: const Text('Signaler'),
                  ),
                ),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => OklFlows.pushResult(
                      context,
                      icon: LucideIcons.send,
                      title: 'Invitation envoyée',
                      subtitle:
                          '${profile.name} recevra une notification. Tu pourras échanger dès qu’elle aura accepté.',
                      primaryLabel: 'OK',
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
        color: context.oklSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.oklDivider),
      ),
      child: Row(
        children: [
          Icon(icon, color: context.oklOnSurfaceMuted(0.62), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: context.oklOnSurfaceMuted(0.62),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: context.oklOnSurface,
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

class _MeetHeader extends StatelessWidget {
  final int currentIndex;
  final int totalProfiles;
  final VoidCallback onFilters;
  final VoidCallback onBell;

  const _MeetHeader({
    required this.currentIndex,
    required this.totalProfiles,
    required this.onFilters,
    required this.onBell,
  });

  @override
  Widget build(BuildContext context) {
    final dark = context.oklMeetIsDark;
    final sub = dark
        ? Colors.white.withValues(alpha: 0.55)
        : context.oklOnSurfaceMuted(0.55);
    final titleColor = dark ? Colors.white : context.oklOnSurface;
    final overlayBtns = dark;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: context.oklMeetHeaderScrimGradient,
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 3,
                        height: 36,
                        margin: const EdgeInsets.only(top: 1),
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
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Rencontres',
                          style: TextStyle(
                            color: titleColor,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.85,
                            height: 1.05,
                          ),
                        ),
                      ),
                      if (totalProfiles > 0)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            '${currentIndex + 1}/$totalProfiles',
                            style: TextStyle(
                              color: sub,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      OklAppBarIconButton(
                        icon: LucideIcons.slidersHorizontal,
                        onPressed: onFilters,
                        useOverlayStyle: overlayBtns,
                      ),
                      const SizedBox(width: 4),
                      OklAppBarIconButton(
                        icon: LucideIcons.bell,
                        onPressed: onBell,
                        useOverlayStyle: overlayBtns,
                      ),
                    ],
                  ),
                ],
              ),
            ),
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
  String _whoLabel = 'Femmes & hommes';
  int _radiusKm = 25;
  int _ageMin = 21;
  int _ageMax = 35;

  /// État par défaut après « Réinitialiser » — toute déviation = filtres « actifs » pour le bouton Appliquer.
  bool get _hasNonDefaultFilters =>
      _verifiedOnly ||
      !_withPhotoOnly ||
      _sameCity ||
      _newProfiles ||
      _whoLabel != 'Femmes & hommes' ||
      _radiusKm != 25 ||
      _ageMin != 21 ||
      _ageMax != 35;

  void _applyAndClose(BuildContext context) {
    Navigator.pop(context);
  }

  Future<void> _pickWho(BuildContext sheetContext) async {
    final options = [
      'Femmes & hommes',
      'Femmes',
      'Hommes',
      'Tous les profils',
    ];
    final picked = await showModalBottomSheet<String>(
      context: sheetContext,
      useRootNavigator: true,
      backgroundColor: sheetContext.oklSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Qui voir',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: ctx.oklOnSurface,
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: 8),
              for (final o in options)
                ListTile(
                  title: Text(o, style: TextStyle(color: ctx.oklOnSurface, fontWeight: FontWeight.w600)),
                  trailing: _whoLabel == o ? Icon(LucideIcons.check, color: AppColors.primary) : null,
                  onTap: () => Navigator.pop(ctx, o),
                ),
            ],
          ),
        ),
      ),
    );
    if (picked != null) setState(() => _whoLabel = picked);
  }

  Future<void> _pickDistance(BuildContext sheetContext) async {
    var km = _radiusKm.toDouble();
    await showModalBottomSheet<void>(
      context: sheetContext,
      useRootNavigator: true,
      backgroundColor: sheetContext.oklSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) {
          return SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.paddingOf(ctx).bottom + 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Distance max',
                    style: TextStyle(
                      color: ctx.oklOnSurface,
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Rayon autour de ta position actuelle.',
                    style: TextStyle(color: ctx.oklOnSurfaceMuted(0.62), fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${km.round()} km',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                    ),
                  ),
                  Slider(
                    value: km,
                    min: 5,
                    max: 100,
                    divisions: 19,
                    label: '${km.round()} km',
                    onChanged: (v) => setModal(() => km = v),
                  ),
                  FilledButton(
                    onPressed: () {
                      setState(() => _radiusKm = km.round());
                      Navigator.pop(ctx);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Enregistrer'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _pickAge(BuildContext sheetContext) async {
    var minA = _ageMin.toDouble();
    var maxA = _ageMax.toDouble();
    await showModalBottomSheet<void>(
      context: sheetContext,
      useRootNavigator: true,
      backgroundColor: sheetContext.oklSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) {
          return SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.paddingOf(ctx).bottom + 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Tranche d’âge',
                    style: TextStyle(
                      color: ctx.oklOnSurface,
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${minA.round()} — ${maxA.round()} ans',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                    ),
                  ),
                  RangeSlider(
                    values: RangeValues(minA, maxA),
                    min: 18,
                    max: 55,
                    divisions: 37,
                    labels: RangeLabels(
                      '${minA.round()}',
                      '${maxA.round()}',
                    ),
                    onChanged: (r) => setModal(() {
                      minA = r.start;
                      maxA = r.end;
                    }),
                  ),
                  FilledButton(
                    onPressed: () {
                      setState(() {
                        _ageMin = minA.round();
                        _ageMax = maxA.round();
                      });
                      Navigator.pop(ctx);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Enregistrer'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
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
          decoration: BoxDecoration(
            color: context.oklSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.oklDivider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Filtres de rencontre',
                      style: TextStyle(
                        color: context.oklOnSurface,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Affine tes rencontres : critères, options rapides et résumé en un coup d’œil.',
                      style: TextStyle(
                        color: context.oklOnSurfaceMuted(0.62).withValues(alpha: 0.95),
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
                        color: Color.alphaBlend(
                          context.oklOnSurface.withValues(alpha: 0.08),
                          context.oklSurface,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: context.oklDivider),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(LucideIcons.layers, size: 16, color: context.oklOnSurfaceMuted(0.62)),
                              const SizedBox(width: 8),
                              Text(
                                'Résumé actif',
                                style: TextStyle(
                                  color: context.oklOnSurface,
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
                            children: [
                              _FilterSummaryChip(label: _whoLabel),
                              _FilterSummaryChip(label: '≤ $_radiusKm km'),
                              _FilterSummaryChip(label: '$_ageMin — $_ageMax ans'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Critères principaux',
                      style: TextStyle(
                        color: context.oklOnSurface,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _FilterRow(
                      icon: LucideIcons.users,
                      title: 'Qui voir',
                      subtitle: _whoLabel,
                      onTap: () => _pickWho(context),
                    ),
                    _FilterRow(
                      icon: LucideIcons.mapPin,
                      title: 'Distance max',
                      subtitle: 'Jusqu’à $_radiusKm km autour de ta position',
                      onTap: () => _pickDistance(context),
                    ),
                    _FilterRow(
                      icon: LucideIcons.cake,
                      title: 'Tranche d’âge',
                      subtitle: '$_ageMin — $_ageMax ans — ajuster la plage',
                      onTap: () => _pickAge(context),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Affiner le fil',
                      style: TextStyle(
                        color: context.oklOnSurface,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Options qui s’appliquent en plus des critères ci-dessus.',
                      style: TextStyle(
                        color: context.oklOnSurfaceMuted(0.55).withValues(alpha: 0.9),
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
                        border: Border.all(color: context.oklDivider),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(LucideIcons.info, size: 18, color: context.oklOnSurfaceMuted(0.62)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Les filtres sont sauvegardés sur cet appareil. Tu peux les réinitialiser à tout moment.',
                              style: TextStyle(
                                color: context.oklOnSurfaceMuted(0.62).withValues(alpha: 0.95),
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
                decoration: BoxDecoration(
                  color: context.oklSurface,
                  border: Border(top: BorderSide(color: context.oklDivider, width: 0.5)),
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
                            _whoLabel = 'Femmes & hommes';
                            _radiusKm = 25;
                            _ageMin = 21;
                            _ageMax = 35;
                          });
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: context.oklOnSurfaceMuted(0.62),
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
                                disabledBackgroundColor: context.oklOnSurface.withValues(alpha: 0.12),
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
                                foregroundColor: context.oklOnSurface,
                                side: BorderSide(color: context.oklDivider, width: 1),
                                backgroundColor: Color.alphaBlend(
                                  context.oklOnSurface.withValues(alpha: 0.06),
                                  context.oklSurface,
                                ),
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
        color: context.oklSurface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: context.oklDivider),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: context.oklOnSurfaceMuted(0.62),
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
        color: Color.alphaBlend(
          context.oklOnSurface.withValues(alpha: 0.06),
          context.oklSurface,
        ),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => onChanged(!value),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(icon, color: context.oklOnSurfaceMuted(0.62), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: context.oklOnSurface,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: context.oklOnSurfaceMuted(0.62),
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
                  inactiveTrackColor: context.oklDivider.withValues(alpha: 0.6),
                  inactiveThumbColor: context.oklOnSurfaceMuted(0.55),
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
        color: context.oklScaffold,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(icon, color: context.oklOnSurfaceMuted(0.62), size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: TextStyle(
                              color: context.oklOnSurface,
                              fontWeight: FontWeight.w700,
                              fontSize: 15)),
                      Text(subtitle,
                          style: TextStyle(color: context.oklOnSurfaceMuted(0.62), fontSize: 12)),
                    ],
                  ),
                ),
                Icon(LucideIcons.chevronRight, color: context.oklOnSurfaceMuted(0.55), size: 18),
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
      backgroundColor: context.oklScaffold,
      appBar: AppBar(
        backgroundColor: context.oklScaffold,
        leading: const OklAppBarBackButton(rootNavigator: true),
        automaticallyImplyLeading: false,
        title: const Text('Notifications'),
      ),
      body: ListView.separated(
        padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.paddingOf(context).bottom + 14),
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final n = items[index];
          return Material(
            color: context.oklSurface,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                final actions = switch (n.title) {
                  'Nouveau like' => [
                    'Voir le profil',
                    'Répondre par un message',
                  ],
                  'Nouveau match' => [
                    'Ouvrir la conversation',
                    'Voir le profil',
                  ],
                  'Ami en live' => [
                    'Regarder le live',
                    'Réagir avec un emoji',
                  ],
                  'Nouvelle demande' => [
                    'Accepter la demande',
                    'Voir le profil',
                    'Refuser',
                  ],
                  _ => <String>['Marquer comme lu'],
                };
                OklFlows.pushNotificationDetail(
                  context,
                  icon: n.icon,
                  title: n.title,
                  subtitle: n.subtitle,
                  time: n.time,
                  actions: actions,
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color.alphaBlend(
                          context.oklOnSurface.withValues(alpha: 0.1),
                          context.oklSurface,
                        ),
                        border: Border.all(color: context.oklDivider),
                      ),
                      child: Icon(n.icon, color: context.oklOnSurfaceMuted(0.62), size: 19),
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
                                  style: TextStyle(
                                    color: context.oklOnSurface,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Text(
                                n.time,
                                style: TextStyle(
                                  color: context.oklOnSurfaceMuted(0.55),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            n.subtitle,
                            style: TextStyle(
                              color: context.oklOnSurfaceMuted(0.62),
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

class _ReelPage extends StatefulWidget {
  final _DemoProfile profile;
  final int cacheWidth;
  final double shellBottomInset;
  final double dockHeight;
  final VoidCallback onPass;
  final VoidCallback onLike;
  final VoidCallback onSuper;
  final VoidCallback onOpenDetails;
  final VoidCallback onOpenProfile;

  const _ReelPage({
    required this.profile,
    required this.cacheWidth,
    required this.shellBottomInset,
    required this.dockHeight,
    required this.onPass,
    required this.onLike,
    required this.onSuper,
    required this.onOpenDetails,
    required this.onOpenProfile,
  });

  @override
  State<_ReelPage> createState() => _ReelPageState();
}

class _ReelPageState extends State<_ReelPage>
    with SingleTickerProviderStateMixin {
  double _dragX = 0;
  late final AnimationController _heartBurst;

  static const _tiktokHeart = Color(0xFFFF3359);

  @override
  void initState() {
    super.initState();
    _heartBurst = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 780),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _heartBurst.reset();
        }
      });
  }

  @override
  void dispose() {
    _heartBurst.dispose();
    super.dispose();
  }

  void _handleLike() {
    HapticFeedback.lightImpact();
    _heartBurst.forward(from: 0);
    widget.onLike();
  }

  Widget _buildTikTokHeartBurst() {
    return AnimatedBuilder(
      animation: _heartBurst,
      builder: (context, child) {
        final t = _heartBurst.value;
        if (t <= 0) return const SizedBox.shrink();

        double opacity;
        if (t < 0.28) {
          opacity = Curves.easeOut.transform(t / 0.28);
        } else if (t < 0.52) {
          opacity = 1;
        } else {
          opacity = 1 - Curves.easeIn.transform((t - 0.52) / 0.48);
        }

        double scale;
        if (t < 0.42) {
          scale = Curves.elasticOut.transform(t / 0.42) * 1.12;
        } else {
          scale = 1.12 - 0.1 * Curves.easeOut.transform((t - 0.42) / 0.58);
        }

        return IgnorePointer(
          child: Center(
            child: Transform.scale(
              scale: scale,
              child: Opacity(
                opacity: opacity.clamp(0.0, 1.0),
                child: Icon(
                  Icons.favorite_rounded,
                  size: 132,
                  color: _tiktokHeart,
                  shadows: const [
                    Shadow(
                      color: Color(0x99000000),
                      blurRadius: 28,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.profile;
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onDoubleTap: _handleLike,
      onHorizontalDragStart: (_) => _dragX = 0,
      onHorizontalDragUpdate: (d) => _dragX += d.delta.dx,
      onHorizontalDragEnd: (_) {
        if (_dragX < -90) widget.onOpenDetails();
        if (_dragX > 90) widget.onOpenProfile();
        _dragX = 0;
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          _buildDemoProfileImage(
            context,
            p,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.high,
            memCacheWidth: widget.cacheWidth,
            placeholder: Container(
              color: Colors.black.withValues(alpha: 0.45),
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
            errorWidget: Container(
              color: Colors.black.withValues(alpha: 0.5),
              alignment: Alignment.center,
              child: Icon(
                LucideIcons.imageOff,
                color: Colors.white.withValues(alpha: 0.55),
                size: 48,
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: Theme.of(context).brightness == Brightness.dark
                  ? const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [0.0, 0.2, 0.52, 1.0],
                      colors: [
                        Color(0x73000000),
                        Colors.transparent,
                        Color(0x28000000),
                        Color(0xE8000000),
                      ],
                    )
                  : LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: const Alignment(0, 0.42),
                      colors: [
                        Colors.black.withValues(alpha: 0.34),
                        Colors.transparent,
                      ],
                    ),
            ),
          ),
          Positioned.fill(child: _buildTikTokHeartBurst()),
          Positioned(
            left: 18,
            right: 18,
            bottom: widget.shellBottomInset + widget.dockHeight + 8,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final t in p.tags.take(3)) ...[
                        _MeetTagChip(label: t),
                        const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: widget.onOpenDetails,
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          '${p.name}, ${p.age}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.85,
                            height: 1.05,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        LucideIcons.badgeCheck,
                        color: AppColors.togoGold,
                        size: 26,
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        LucideIcons.chevronRight,
                        color: Colors.white.withValues(alpha: 0.45),
                        size: 22,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      LucideIcons.mapPin,
                      color: Colors.white.withValues(alpha: 0.82),
                      size: 15,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        p.location,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            left: 10,
            right: 10,
            bottom: widget.shellBottomInset + 6,
            child: _MeetActionDock(
              onPass: widget.onPass,
              onSuper: widget.onSuper,
              onLike: _handleLike,
            ),
          ).animate().fadeIn(duration: 320.ms, delay: 70.ms),
        ],
      ),
    );
  }
}

class _MeetActionDock extends StatelessWidget {
  final VoidCallback onPass;
  final VoidCallback onSuper;
  final VoidCallback onLike;

  const _MeetActionDock({
    required this.onPass,
    required this.onSuper,
    required this.onLike,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.34),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _MeetDockAction(
                icon: LucideIcons.x,
                label: 'Passer',
                accent: AppColors.togoRed,
                onTap: onPass,
                large: true,
              ),
              _MeetDockAction(
                icon: LucideIcons.star,
                label: 'Super',
                accent: AppColors.togoGold,
                onTap: onSuper,
                large: false,
              ),
              _MeetDockAction(
                icon: LucideIcons.heart,
                label: 'Like',
                accent: AppColors.togoGreen,
                onTap: onLike,
                large: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MeetDockAction extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color accent;
  final VoidCallback onTap;
  final bool large;

  const _MeetDockAction({
    required this.icon,
    required this.label,
    required this.accent,
    required this.onTap,
    required this.large,
  });

  @override
  State<_MeetDockAction> createState() => _MeetDockActionState();
}

class _MeetDockActionState extends State<_MeetDockAction> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final dim = widget.large ? 52.0 : 44.0;
    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 110),
            width: dim,
            height: dim,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _down
                  ? widget.accent.withValues(alpha: 0.38)
                  : Colors.white.withValues(alpha: 0.1),
              border: Border.all(
                color: _down ? widget.accent : Colors.white.withValues(alpha: 0.22),
                width: _down ? 2.0 : 1.2,
              ),
            ),
            child: Icon(
              widget.icon,
              color: Colors.white.withValues(alpha: 0.95),
              size: widget.large ? 26 : 21,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            widget.label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.76),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MeetTagChip extends StatelessWidget {
  final String label;

  const _MeetTagChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
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
