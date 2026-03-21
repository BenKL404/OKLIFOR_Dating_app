import 'dart:ui' show ImageFilter;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/layout_constants.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/utils/okl_feedback.dart';
import '../../../core/widgets/okl_app_bar_icon_button.dart';
import '../../../core/widgets/okl_pill_search_bar.dart';
import 'nearby_profile_preview_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ZoneDetailsData {
  final String title;
  final String subtitle;
  final String heroUrl;
  final String locality;
  final String narration;
  final List<String> highlights;
  final String bestPeriod;
  final String safetyNote;
  final String languages;
  final List<String> icebreakers;
  final int suggestedMatches;
  final List<String> galleryUrls;

  const _ZoneDetailsData({
    required this.title,
    required this.subtitle,
    required this.heroUrl,
    required this.locality,
    required this.narration,
    required this.highlights,
    required this.bestPeriod,
    required this.safetyNote,
    required this.languages,
    required this.icebreakers,
    required this.suggestedMatches,
    required this.galleryUrls,
  });
}

class _ExploreZoneDetailsScreen extends StatelessWidget {
  final _ZoneDetailsData details;

  const _ExploreZoneDetailsScreen({required this.details});

  @override
  Widget build(BuildContext context) {
    final dark = context.oklMeetIsDark;
    final muted = dark
        ? Colors.white.withValues(alpha: 0.62)
        : context.oklOnSurfaceMuted(0.62);
    final onTitle = dark ? Colors.white : context.oklOnSurface;
    final chipBg = dark
        ? Colors.white.withValues(alpha: 0.08)
        : Color.alphaBlend(
            context.oklOnSurface.withValues(alpha: 0.06),
            context.oklSurface,
          );
    final chipBorder =
        dark ? Colors.white.withValues(alpha: 0.16) : context.oklDivider;
    final chipFg =
        dark ? Colors.white.withValues(alpha: 0.85) : context.oklOnSurface;
    final ph = context.oklSurface;

    return Scaffold(
      backgroundColor: context.oklScaffold,
      appBar: AppBar(
        backgroundColor: dark ? Colors.transparent : context.oklScaffold,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          color: onTitle,
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
        ),
        title: Text(
          details.title,
          style: TextStyle(
            color: onTitle,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: Container(
        decoration: dark ? context.oklMeetCanvasDecoration : null,
        color: dark ? null : context.oklScaffold,
        child: ListView(
          padding: EdgeInsets.fromLTRB(16, 4, 16, MediaQuery.paddingOf(context).bottom + 22),
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: AspectRatio(
                aspectRatio: 16 / 10,
                child: CachedNetworkImage(
                  imageUrl: details.heroUrl,
                  fit: BoxFit.cover,
                  memCacheWidth: 1000,
                  placeholder: (ctx, url) => Container(color: ph),
                  errorWidget: (ctx, url, error) => Container(
                    color: ph,
                    child: Center(
                      child: Icon(
                        LucideIcons.imageOff,
                        color: context.oklOnSurfaceMuted(0.45),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              details.subtitle,
              style: TextStyle(
                color: onTitle,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(LucideIcons.mapPin, size: 16, color: muted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    details.locality,
                    style: TextStyle(color: muted, fontSize: 13),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => OklFeedback.snack(
                    context,
                    'Ouverture carte de ${details.title} (demo)',
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor:
                        dark ? AppColors.togoGold : AppColors.primary,
                  ),
                  icon: Icon(
                    LucideIcons.navigation,
                    size: 16,
                    color: dark ? AppColors.togoGold : AppColors.primary,
                  ),
                  label: const Text('Localiser'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _ZoneInfoCard(
              title: 'Narration de la zone',
              child: Text(
                details.narration,
                style: TextStyle(color: muted, height: 1.45, fontSize: 13.5),
              ),
            ),
            _ZoneInfoCard(
              title: 'Brise-glace',
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final b in details.icebreakers)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: chipBg,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: chipBorder),
                      ),
                      child: Text(
                        b,
                        style: TextStyle(
                          color: chipFg,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            _ZoneInfoCard(
              title: 'Matchs suggérés',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(LucideIcons.users, size: 16, color: muted),
                      const SizedBox(width: 6),
                      Text(
                        '${details.suggestedMatches} personnes intéressées (démo)',
                        style: TextStyle(
                          color: onTitle,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextButton.icon(
                    onPressed: () => OklFeedback.snack(
                      context,
                      'Ouverture des profils pour ${details.title} (démo)',
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor:
                          dark ? AppColors.togoGold : AppColors.primary,
                    ),
                    icon: Icon(
                      LucideIcons.sparkles,
                      size: 16,
                      color: dark ? AppColors.togoGold : AppColors.primary,
                    ),
                    label: const Text(
                      'Voir les profils compatibles',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            _ZoneInfoCard(
              title: 'Points d interet',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final item in details.highlights)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Icon(LucideIcons.dot, size: 16, color: muted),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              item,
                              style: TextStyle(color: muted, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            _ZoneInfoCard(
              title: 'Infos utiles',
              child: Column(
                children: [
                  _MetaLine(label: 'Periode ideale', value: details.bestPeriod),
                  const SizedBox(height: 6),
                  _MetaLine(label: 'Langues', value: details.languages),
                  const SizedBox(height: 6),
                  _MetaLine(label: 'Conseil securite', value: details.safetyNote),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Galerie de la zone',
              style: TextStyle(
                color: onTitle,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 124,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: details.galleryUrls.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final url = details.galleryUrls[index];
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: AspectRatio(
                      aspectRatio: 1.2,
                      child: CachedNetworkImage(
                        imageUrl: url,
                        fit: BoxFit.cover,
                        memCacheWidth: 360,
                        placeholder: (ctx, url) => Container(color: ph),
                        errorWidget: (ctx, url, error) => Container(color: ph),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ZoneInfoCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _ZoneInfoCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final dark = context.oklMeetIsDark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: dark
            ? Colors.white.withValues(alpha: 0.07)
            : context.oklSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: dark
              ? Colors.white.withValues(alpha: 0.12)
              : context.oklDivider,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: dark
                  ? Colors.white.withValues(alpha: 0.92)
                  : context.oklOnSurface,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  final String label;
  final String value;

  const _MetaLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final dark = context.oklMeetIsDark;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: TextStyle(
              color: dark
                  ? Colors.white.withValues(alpha: 0.48)
                  : context.oklOnSurfaceMuted(0.5),
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: dark
                  ? Colors.white.withValues(alpha: 0.78)
                  : context.oklOnSurfaceMuted(0.78),
              fontSize: 12.5,
            ),
          ),
        ),
      ],
    );
  }
}

class _ExploreScreenState extends State<ExploreScreen> {
  static const _groups = <({
    String id,
    String title,
  })>[
    (id: 'all', title: 'Tout'),
    (id: 'ewe', title: 'Ewé'),
    (id: 'mina', title: 'Mina'),
    (id: 'adidogome', title: 'Adidogome'),
    (id: 'zanguera', title: 'Zanguéra'),
    (id: 'agoè', title: 'Agoè'),
    (id: 'kegué', title: 'Kégué'),
    (id: 'kpalimé', title: 'Kpalimé'),
    (id: 'sokodé', title: 'Sokodé'),
  ];

  static const _spots = <({
    String title,
    String subtitle,
    String url,
    List<String> groupIds,
  })>[
    (
      title: 'Lomé',
      subtitle: 'Grande côte & marchés',
      url:
          'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=800&q=85&auto=format&fit=crop',
      groupIds: <String>['all', 'ewe', 'mina', 'adidogome', 'zanguera', 'agoè', 'kegué'],
    ),
    (
      title: 'Kpalimé',
      subtitle: 'Collines & café',
      url:
          'https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=800&q=85&auto=format&fit=crop',
      groupIds: <String>['all', 'kpalimé', 'ewe'],
    ),
    (
      title: 'Cascade',
      subtitle: 'Nature du pays',
      url:
          'https://images.unsplash.com/photo-1432405972618-c60b0225b8f9?w=800&q=85&auto=format&fit=crop',
      groupIds: <String>['all', 'kpalimé', 'sokodé'],
    ),
    (
      title: 'Plage',
      subtitle: 'Fin de journée',
      url:
          'https://images.unsplash.com/photo-1519046904884-53103b34b206?w=800&q=85&auto=format&fit=crop',
      groupIds: <String>['all', 'mina'],
    ),
    (
      title: 'Ville',
      subtitle: 'Ambiance urbaine',
      url:
          'https://images.unsplash.com/photo-1480714378408-67cf0d13bc1b?w=800&q=85&auto=format&fit=crop',
      groupIds: <String>['all', 'ewe', 'adidogome', 'agoè'],
    ),
    (
      title: 'Culture',
      subtitle: 'Rencontres & fêtes',
      url:
          'https://images.unsplash.com/photo-1529156069898-49953e39b3ac?w=800&q=85&auto=format&fit=crop',
      groupIds: <String>['all', 'sokodé', 'ewe'],
    ),
  ];

  static const _nearbyProfiles = <({
    String name,
    String avatarUrl,
    String area,
    String vibe,
    String distance,
  })>[
    (
      name: 'Sena',
      area: 'Agoè',
      vibe: 'Prêt pour un café',
      distance: 'à 1.2 km',
      avatarUrl:
          'https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e?w=200&q=80&auto=format&fit=crop',
    ),
    (
      name: 'Kossi',
      area: 'Kegue',
      vibe: 'Ambiance tranquille',
      distance: 'à 2.4 km',
      avatarUrl:
          'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=200&q=80&auto=format&fit=crop',
    ),
    (
      name: 'Afia',
      area: 'Agoè',
      vibe: 'Sortie ce soir',
      distance: 'à 0.8 km',
      avatarUrl:
          'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200&q=80&auto=format&fit=crop',
    ),
    (
      name: 'Mawuli',
      area: 'Kpalimé',
      vibe: 'Nature & rando',
      distance: 'à 4.1 km',
      avatarUrl:
          'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=200&q=80&auto=format&fit=crop',
    ),
    (
      name: 'Kofi',
      area: 'Lomé',
      vibe: 'Match “culture”',
      distance: 'à 1.6 km',
      avatarUrl:
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200&q=80&auto=format&fit=crop',
    ),
  ];

  String _meetCrowdLabelForSpot(String spotTitle) {
    return switch (spotTitle) {
      'Lomé' => '120 en mode sortie',
      'Kpalimé' => '60 partages cette semaine',
      'Cascade' => '35 visiteurs vibes nature',
      'Plage' => '95 en soirée',
      'Ville' => '80 curieux ce soir',
      'Culture' => '45 rendez-vous culture',
      _ => '30 personnes',
    };
  }

  String _meetMomentLabelForSpot(String spotTitle) {
    return switch (spotTitle) {
      'Lomé' => 'Ce soir',
      'Kpalimé' => 'Week-end',
      'Cascade' => 'Matin / après-midi',
      'Plage' => 'Fin de journée',
      'Ville' => 'Après 19h',
      'Culture' => 'Soirées événements',
      _ => 'Bientôt',
    };
  }

  String _selectedGroupId = 'all';
  bool _searchMode = false;
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _enterSearch() {
    setState(() => _searchMode = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocus.requestFocus();
    });
  }

  void _exitSearch() {
    _searchController.clear();
    _searchFocus.unfocus();
    setState(() => _searchMode = false);
  }

  List<({String title, String subtitle, String url, List<String> groupIds})> get _filteredSpots {
    final Iterable<({String title, String subtitle, String url, List<String> groupIds})> byGroup =
        _selectedGroupId == 'all'
            ? _spots
            : _spots.where((s) => s.groupIds.contains(_selectedGroupId));
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return byGroup.toList(growable: false);
    return byGroup
        .where(
          (s) =>
              s.title.toLowerCase().contains(q) ||
              s.subtitle.toLowerCase().contains(q),
        )
        .toList(growable: false);
  }

  void _openSpotSheet(
    BuildContext context,
    ({String title, String subtitle, String url, List<String> groupIds}) s,
  ) {
    final details = _zoneDetailsFromSpot(s);
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(
        builder: (_) => _ExploreZoneDetailsScreen(details: details),
      ),
    );
  }

  _ZoneDetailsData _zoneDetailsFromSpot(
    ({String title, String subtitle, String url, List<String> groupIds}) s,
  ) {
    if (s.title == 'Lomé') {
      return _ZoneDetailsData(
        title: s.title,
        subtitle: 'Capitale vivante entre mer et marchés',
        heroUrl: s.url,
        locality: 'Golfe 1-6, bord de mer, Agoè',
        narration:
            'Lomé est une zone dynamique avec une ambiance urbaine, des lieux de sortie, '
            'des plages et des quartiers historiques.',
        highlights: ['Grand Marché', 'Plage de Lomé', 'Monument de l Independance'],
        bestPeriod: 'Novembre a mars',
        safetyNote: 'Favoriser les zones animees en soiree.',
        languages: 'Français, Mina, Ewe',
        icebreakers: [
          'On commence par un café avant la plage ?',
          'Quel est ton meilleur spot pour discuter facilement ?',
          'Tu préfères marché animé ou bord de mer ?',
        ],
        suggestedMatches: 24,
        galleryUrls: [s.url, _spots[3].url, _spots[4].url],
      );
    }
    if (s.title == 'Kpalimé') {
      return _ZoneDetailsData(
        title: s.title,
        subtitle: 'Nature, collines et cafe',
        heroUrl: s.url,
        locality: 'Plateaux, region de Kloto',
        narration:
            'Kpalime propose un cadre verdoyant, des circuits nature et une ambiance calme, '
            'ideale pour des sorties et rencontres de qualite.',
        highlights: ['Mont Agou', 'Cascades de Womé', 'Artisanat local'],
        bestPeriod: 'Octobre a fevrier',
        safetyNote: 'Prevoir des chaussures pour sentiers humides.',
        languages: 'Français, Ewe',
        icebreakers: [
          'Tu viens plutôt pour randonner ou juste pour papoter ?',
          'Quel lieu te donne le plus envie d’essayer un rendez-vous ?',
          'On fait une petite promenade + photo ?',
        ],
        suggestedMatches: 18,
        galleryUrls: [s.url, _spots[2].url, _spots[5].url],
      );
    }
    return _ZoneDetailsData(
      title: s.title,
      subtitle: s.subtitle,
      heroUrl: s.url,
      locality: 'Zone ${s.title}, Togo',
      narration:
          '${s.title} offre une ambiance locale ideale pour decouvrir la culture, '
          'rencontrer de nouvelles personnes et profiter des lieux populaires.',
      highlights: ['Points culturels', 'Lieux de rencontre', 'Espaces de sortie'],
      bestPeriod: 'Toute l annee',
      safetyNote: 'Rester dans les zones frequentees en soiree.',
      languages: 'Français, langues locales',
      icebreakers: [
        'Tu veux un plan tranquille ou une sortie plus animée ?',
        'Quel est ton “rendez-vous parfait” dans ce quartier ?',
        'On commence par un message et on se voit sur place ?',
      ],
      suggestedMatches: 12,
      galleryUrls: [s.url, _spots.first.url, _spots.last.url],
    );
  }

  Widget _groupItem(BuildContext context, int index) {
    final g = _groups[index];
    final selected = _selectedGroupId == g.id;

    return Padding(
      padding: EdgeInsets.only(right: index < _groups.length - 1 ? 8 : 0),
      child: _ExploreFilterChip(
        label: g.title,
        selected: selected,
        onTap: () {
          setState(() => _selectedGroupId = g.id);
          OklFeedback.snack(context, 'Filtre : ${g.title} (démo)');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredSpots;
    final bottomPad = oklMainShellListBottomPadding(context);
    final isDark = context.oklMeetIsDark;
    final titleColor = isDark ? Colors.white : context.oklOnSurface;
    final subColor =
        isDark ? Colors.white.withValues(alpha: 0.55) : context.oklOnSurfaceMuted(0.55);

    return Scaffold(
      backgroundColor: context.oklScaffold,
      body: Container(
        decoration: context.oklMeetCanvasDecoration,
        child: SafeArea(
          bottom: false,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: context.oklMeetHeaderScrimGradient,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 12, 10),
                        child: _searchMode
                            ? Row(
                                children: [
                                  OklAppBarIconButton(
                                    icon: LucideIcons.arrowLeft,
                                    onPressed: _exitSearch,
                                    useOverlayStyle: isDark,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: OklPillSearchBar(
                                      controller: _searchController,
                                      focusNode: _searchFocus,
                                      hintText: 'Ville, lieu, ambiance…',
                                      autofocus: true,
                                      onSubmitted: (q) {
                                        if (q.trim().isEmpty) return;
                                        OklFeedback.snack(
                                          context,
                                          'Résultats pour « $q » (démo)',
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              )
                            : Row(
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
                                      'Explorer',
                                      style: TextStyle(
                                        color: titleColor,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.85,
                                        height: 1.05,
                                      ),
                                    ),
                                  ),
                                  OklAppBarIconButton(
                                    icon: LucideIcons.search,
                                    onPressed: _enterSearch,
                                    useOverlayStyle: isDark,
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Filtres',
                        style: TextStyle(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.48)
                              : context.oklOnSurfaceMuted(0.5),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.35,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 44,
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          scrollDirection: Axis.horizontal,
                          itemCount: _groups.length,
                          itemBuilder: _groupItem,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Profils à proximité',
                        style: TextStyle(
                          color: titleColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.25,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 108,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _nearbyProfiles.length,
                          separatorBuilder: (context, _) => const SizedBox(width: 12),
                          itemBuilder: (context, i) {
                            final p = _nearbyProfiles[i];
                            return Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(22),
                                onTap: () => Navigator.of(context, rootNavigator: true).push<void>(
                                  MaterialPageRoute<void>(
                                    builder: (_) => NearbyProfilePreviewScreen(
                                      name: p.name,
                                      area: p.area,
                                      vibe: p.vibe,
                                      distance: p.distance,
                                      avatarUrl: p.avatarUrl,
                                    ),
                                  ),
                                ),
                                child: Container(
                                  width: 212,
                                  height: 108,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.08)
                                        : context.oklSurface,
                                    borderRadius: BorderRadius.circular(22),
                                    border: Border.all(
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.14)
                                          : context.oklDivider,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: isDark ? 0.35 : 0.08,
                                        ),
                                        blurRadius: isDark ? 20 : 14,
                                        offset: Offset(0, isDark ? 10 : 6),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: isDark
                                                ? Colors.white.withValues(alpha: 0.2)
                                                : context.oklDivider,
                                          ),
                                        ),
                                        child: ClipOval(
                                          child: CachedNetworkImage(
                                            imageUrl: p.avatarUrl,
                                            width: 44,
                                            height: 44,
                                            fit: BoxFit.cover,
                                            memCacheWidth: 180,
                                            placeholder: (ctx, url) => Container(
                                              width: 44,
                                              height: 44,
                                              color: isDark
                                                  ? Colors.white.withValues(alpha: 0.06)
                                                  : context.oklScaffold,
                                            ),
                                            errorWidget: (ctx, url, error) => Container(
                                              width: 44,
                                              height: 44,
                                              color: isDark
                                                  ? Colors.white.withValues(alpha: 0.06)
                                                  : context.oklScaffold,
                                              child: Icon(
                                                LucideIcons.imageOff,
                                                size: 16,
                                                color: context.oklOnSurfaceMuted(0.4),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              p.name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: titleColor,
                                                fontWeight: FontWeight.w800,
                                                fontSize: 14,
                                              ),
                                            ),
                                            Text(
                                              p.area,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: isDark
                                                    ? Colors.white.withValues(alpha: 0.62)
                                                    : context.oklOnSurfaceMuted(0.62),
                                                fontSize: 12,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              p.vibe,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: isDark
                                                    ? Colors.white.withValues(alpha: 0.72)
                                                    : context.oklOnSurfaceMuted(0.72),
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            Text(
                                              p.distance,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: isDark
                                                    ? Colors.white.withValues(alpha: 0.45)
                                                    : context.oklOnSurfaceMuted(0.48),
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Lieux',
                        style: TextStyle(
                          color: titleColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.35,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          filtered.isEmpty
                              ? '0 résultat'
                              : '${filtered.length} lieu${filtered.length > 1 ? 'x' : ''}',
                          style: TextStyle(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.45)
                                : context.oklOnSurfaceMuted(0.48),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(14, 0, 14, bottomPad),
                sliver: filtered.isEmpty
                    ? SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 28),
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.07)
                                  : context.oklSurface,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.12)
                                    : context.oklDivider,
                              ),
                            ),
                            child: Column(
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.08)
                                        : context.oklScaffold,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.14)
                                          : context.oklDivider,
                                    ),
                                  ),
                                  child: Icon(
                                    LucideIcons.mapPinOff,
                                    color: context.oklOnSurfaceMuted(0.55),
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Aucun lieu ne correspond',
                                  style: TextStyle(
                                    color: titleColor,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Essaye un autre filtre ou une autre recherche pour « ${_groups.firstWhere((g) => g.id == _selectedGroupId).title} ».',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: subColor,
                                    fontSize: 13,
                                    height: 1.45,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    : SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                          childAspectRatio: 0.72,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, i) {
                            final s = filtered[i];
                            return Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => _openSpotSheet(context, s),
                                borderRadius: BorderRadius.circular(26),
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(26),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: isDark ? 0.55 : 0.12,
                                        ),
                                        blurRadius: isDark ? 24 : 16,
                                        offset: Offset(0, isDark ? 14 : 8),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(26),
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        CachedNetworkImage(
                                          imageUrl: s.url,
                                          fit: BoxFit.cover,
                                          filterQuality: FilterQuality.high,
                                          memCacheWidth: 600,
                                          placeholder: (ctx, url) =>
                                              Container(color: ctx.oklSurface),
                                          errorWidget: (ctx, url, error) => Container(
                                            color: ctx.oklSurface,
                                            alignment: Alignment.center,
                                            child: Icon(
                                              LucideIcons.imageOff,
                                              color: context.oklOnSurfaceMuted(0.4),
                                            ),
                                          ),
                                        ),
                                        const DecoratedBox(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              stops: [0.0, 0.35, 1.0],
                                              colors: [
                                                Color(0x66000000),
                                                Colors.transparent,
                                                Color(0xD8000000),
                                              ],
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          left: 0,
                                          right: 0,
                                          bottom: 0,
                                          child: Container(
                                            padding: const EdgeInsets.fromLTRB(12, 28, 12, 12),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                                colors: [
                                                  Colors.transparent,
                                                  Colors.black.withValues(alpha: 0.82),
                                                ],
                                              ),
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  s.title,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w800,
                                                    letterSpacing: -0.25,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  s.subtitle,
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    color: Colors.white.withValues(alpha: 0.88),
                                                    fontSize: 11.5,
                                                    height: 1.25,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Row(
                                                  children: [
                                                    Icon(
                                                      LucideIcons.users,
                                                      size: 14,
                                                      color: Colors.white.withValues(alpha: 0.92),
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Flexible(
                                                      child: Text(
                                                        _meetCrowdLabelForSpot(s.title),
                                                        maxLines: 1,
                                                        softWrap: false,
                                                        overflow: TextOverflow.ellipsis,
                                                        style: TextStyle(
                                                          color: Colors.white.withValues(alpha: 0.88),
                                                          fontSize: 11,
                                                          fontWeight: FontWeight.w700,
                                                          height: 1.1,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Icon(
                                                      LucideIcons.clock,
                                                      size: 14,
                                                      color: Colors.white.withValues(alpha: 0.92),
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Flexible(
                                                      child: Text(
                                                        _meetMomentLabelForSpot(s.title),
                                                        maxLines: 1,
                                                        softWrap: false,
                                                        overflow: TextOverflow.ellipsis,
                                                        style: TextStyle(
                                                          color: Colors.white.withValues(alpha: 0.88),
                                                          fontSize: 11,
                                                          fontWeight: FontWeight.w700,
                                                          height: 1.1,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          top: 12,
                                          right: 12,
                                          child: ClipOval(
                                            child: BackdropFilter(
                                              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                              child: Container(
                                                padding: const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: Colors.black.withValues(alpha: 0.32),
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: Colors.white.withValues(alpha: 0.18),
                                                  ),
                                                ),
                                                child: Icon(
                                                  LucideIcons.mapPin,
                                                  size: 15,
                                                  color: Colors.white.withValues(alpha: 0.92),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                          childCount: filtered.length,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Puce filtre (verre, cohérente avec Rencontres).
class _ExploreFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ExploreFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dark = context.oklMeetIsDark;
    final unselectedFill = dark
        ? Colors.white.withValues(alpha: 0.1)
        : Color.alphaBlend(
            context.oklOnSurface.withValues(alpha: 0.06),
            context.oklSurface,
          );
    final unselectedBorder = dark
        ? Colors.white.withValues(alpha: 0.2)
        : context.oklDivider;
    final labelColor = selected
        ? Colors.white
        : (dark
            ? Colors.white.withValues(alpha: 0.78)
            : context.oklOnSurfaceMuted(0.78));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: selected ? AppColors.primary : unselectedFill,
            border: Border.all(
              color: selected ? AppColors.primaryDark : unselectedBorder,
              width: selected ? 1.25 : 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: labelColor,
              fontSize: 13,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              letterSpacing: -0.15,
            ),
          ),
        ),
      ),
    );
  }
}
