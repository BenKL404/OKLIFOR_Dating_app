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
import 'explore_see_all_screens.dart';
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
              title: 'Pourquoi y aller à deux',
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
              title: 'Membres avec la même envie',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(LucideIcons.users, size: 16, color: muted),
                      const SizedBox(width: 6),
                      Text(
                        '${details.suggestedMatches} profils ouverts à ce type de sortie (démo)',
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
                      'Voir des profils avec la même envie',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            _ZoneInfoCard(
              title: 'Repères sur place',
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
  /// Ambiances de rendez-vous (plus pertinent que quartier / ethnie pour une app de rencontres).
  static const _groups = <({
    String id,
    String title,
  })>[
    (id: 'all', title: 'Tout'),
    (id: 'calme', title: 'Café & discussion'),
    (id: 'nature', title: 'Dehors & nature'),
    (id: 'soir', title: 'Soirée & plage'),
    (id: 'culture', title: 'Ville & culture'),
    (id: 'weekend', title: 'Week-end'),
  ];

  /// Restos, bars, boîtes, lounges…
  static const _venues = <({
    String title,
    String subtitle,
    String url,
    String kind,
    List<String> groupIds,
  })>[
    (
      title: 'Le Marché Gourmet',
      subtitle: 'Resto · fusion & partage · Tokoin',
      url:
          'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=800&q=85&auto=format&fit=crop',
      kind: 'restaurant',
      groupIds: <String>['all', 'calme', 'culture', 'soir'],
    ),
    (
      title: 'Terrazzo 228',
      subtitle: 'Bar rooftop · cocktails · centre-ville',
      url:
          'https://images.unsplash.com/photo-1470337458703-46ad1756a187?w=800&q=85&auto=format&fit=crop',
      kind: 'bar',
      groupIds: <String>['all', 'soir', 'culture', 'calme'],
    ),
    (
      title: 'Pulse Club',
      subtitle: 'Boîte · DJ & dancefloor',
      url:
          'https://images.unsplash.com/photo-1571266025683-ea67b9ea6ec8?w=800&q=85&auto=format&fit=crop',
      kind: 'club',
      groupIds: <String>['all', 'soir', 'weekend'],
    ),
    (
      title: 'Café des Arts',
      subtitle: 'Café-concert · brunch le dimanche',
      url:
          'https://images.unsplash.com/photo-1554118811-1e0d79424c94?w=800&q=85&auto=format&fit=crop',
      kind: 'cafe',
      groupIds: <String>['all', 'calme', 'culture', 'weekend'],
    ),
    (
      title: 'La Plage House',
      subtitle: 'Resto-plage · fin de journée',
      url:
          'https://images.unsplash.com/photo-1519046904884-53103b34b206?w=800&q=85&auto=format&fit=crop',
      kind: 'plage',
      groupIds: <String>['all', 'soir', 'nature', 'calme'],
    ),
    (
      title: 'Underground',
      subtitle: 'Club · électro & live',
      url:
          'https://images.unsplash.com/photo-1574391884720-bdbc281977aa?w=800&q=85&auto=format&fit=crop',
      kind: 'club',
      groupIds: <String>['all', 'soir', 'culture', 'weekend'],
    ),
    (
      title: 'Skyline Lounge',
      subtitle: 'Lounge · vue & afterwork',
      url:
          'https://images.unsplash.com/photo-1566417713940-fe7c737a9ef2?w=800&q=85&auto=format&fit=crop',
      kind: 'lounge',
      groupIds: <String>['all', 'soir', 'calme', 'culture'],
    ),
    (
      title: 'Braise du Golfe',
      subtitle: 'Grill · terrasse · groupes bienvenus',
      url:
          'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=800&q=85&auto=format&fit=crop',
      kind: 'restaurant',
      groupIds: <String>['all', 'calme', 'soir', 'culture'],
    ),
  ];

  static const _nearbyEvents = <({
    String title,
    String venue,
    String dayLabel,
    String time,
    String distance,
    String url,
    bool certified,
    List<String> groupIds,
  })>[
    (
      title: 'Afterwork Oklifor',
      venue: 'Skyline Lounge',
      dayLabel: 'Ce ven.',
      time: '19 h',
      distance: '2,1 km',
      url:
          'https://images.unsplash.com/photo-1540575467063-27aef4de018b?w=800&q=85&auto=format&fit=crop',
      certified: true,
      groupIds: <String>['all', 'soir', 'culture', 'calme'],
    ),
    (
      title: 'Soirée live jazz',
      venue: 'Café des Arts',
      dayLabel: 'Demain',
      time: '21 h',
      distance: '1,4 km',
      url:
          'https://images.unsplash.com/photo-1415201364774-f6f0bb35f28f?w=800&q=85&auto=format&fit=crop',
      certified: true,
      groupIds: <String>['all', 'culture', 'calme', 'soir'],
    ),
    (
      title: 'Marché nocturne & street food',
      venue: 'Grand Marché zone',
      dayLabel: 'Sam.',
      time: '18 h – 23 h',
      distance: '3 km',
      url:
          'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=800&q=85&auto=format&fit=crop',
      certified: false,
      groupIds: <String>['all', 'culture', 'soir', 'calme'],
    ),
    (
      title: 'Beach games & sunset',
      venue: 'Plage publique',
      dayLabel: 'Dim.',
      time: '17 h',
      distance: '4,2 km',
      url:
          'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=800&q=85&auto=format&fit=crop',
      certified: false,
      groupIds: <String>['all', 'nature', 'soir', 'weekend'],
    ),
    (
      title: 'Open mic & rencontres',
      venue: 'Terraço 228',
      dayLabel: 'Jeu.',
      time: '20 h 30',
      distance: '1,9 km',
      url:
          'https://images.unsplash.com/photo-1529156069898-49953e39b3ac?w=800&q=85&auto=format&fit=crop',
      certified: true,
      groupIds: <String>['all', 'culture', 'calme', 'soir'],
    ),
  ];

  static const _ambiancesNearby = <({
    String label,
    String hint,
    String url,
    List<String> groupIds,
  })>[
    (
      label: 'Terrasses animées',
      hint: 'Beaucoup de monde en ce moment',
      url:
          'https://images.unsplash.com/photo-1514933651103-005eec06c04b?w=600&q=80&auto=format&fit=crop',
      groupIds: <String>['all', 'soir', 'calme'],
    ),
    (
      label: 'Soirée club',
      hint: 'Files en hausse près de toi',
      url:
          'https://images.unsplash.com/photo-1571266025683-ea67b9ea6ec8?w=600&q=80&auto=format&fit=crop',
      groupIds: <String>['all', 'soir', 'weekend'],
    ),
    (
      label: 'Jazz & chill',
      hint: 'Ambiance posée ce soir',
      url:
          'https://images.unsplash.com/photo-1415201364774-f6f0bb35f28f?w=600&q=80&auto=format&fit=crop',
      groupIds: <String>['all', 'culture', 'calme'],
    ),
    (
      label: 'Coucher de soleil',
      hint: 'Plage & apéro',
      url:
          'https://images.unsplash.com/photo-1519046904884-53103b34b206?w=600&q=80&auto=format&fit=crop',
      groupIds: <String>['all', 'nature', 'soir', 'calme'],
    ),
    (
      label: 'Resto romantique',
      hint: 'Tables demandées',
      url:
          'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=600&q=80&auto=format&fit=crop',
      groupIds: <String>['all', 'calme', 'culture', 'soir'],
    ),
    (
      label: 'Afterwork',
      hint: 'Créneau 18 h – 21 h',
      url:
          'https://images.unsplash.com/photo-1540575467063-27aef4de018b?w=600&q=80&auto=format&fit=crop',
      groupIds: <String>['all', 'soir', 'culture', 'calme'],
    ),
  ];

  static const _gatherings = <({
    String title,
    String subtitle,
    int going,
    String when,
    String distance,
    String url,
    List<String> groupIds,
  })>[
    (
      title: 'Sorties Lomé ensemble',
      subtitle: 'On coordonne bars & restos le week-end',
      going: 24,
      when: 'Actif ce soir',
      distance: 'Autour de toi',
      url:
          'https://images.unsplash.com/photo-1528605248644-14dd04022da1?w=600&q=80&auto=format&fit=crop',
      groupIds: <String>['all', 'soir', 'culture', 'weekend'],
    ),
    (
      title: 'Rando & photo Kpalimé',
      subtitle: 'Covoit depuis Lomé',
      going: 8,
      when: 'Dim. matin',
      distance: 'Groupe · 45 km',
      url:
          'https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=600&q=80&auto=format&fit=crop',
      groupIds: <String>['all', 'nature', 'weekend', 'calme'],
    ),
    (
      title: 'Soirée filles · safe night',
      subtitle: 'Taxi partagé & lieu validé',
      going: 12,
      when: 'Ven. 22 h',
      distance: 'à 2 km',
      url:
          'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?w=600&q=80&auto=format&fit=crop',
      groupIds: <String>['all', 'soir', 'culture'],
    ),
    (
      title: 'Apéro langues FR / Ewe',
      subtitle: '6 places · débutants OK',
      going: 6,
      when: 'Mer. 19 h',
      distance: 'Tokoin',
      url:
          'https://images.unsplash.com/photo-1556761175-5973dc0f32e7?w=600&q=80&auto=format&fit=crop',
      groupIds: <String>['all', 'calme', 'culture'],
    ),
  ];

  /// Personnes qui cherchent des participant·e·s pour un plan concret.
  static const _participationAsks = <({
    String name,
    String avatarUrl,
    String area,
    String ask,
    String slot,
    String distance,
    List<String> groupIds,
  })>[
    (
      name: 'Sena',
      area: 'Agoè',
      ask: '2 personnes pour une expo samedi — entrée déjà payée',
      slot: 'Sam. 15 h',
      distance: 'à 1,2 km',
      avatarUrl:
          'https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e?w=200&q=80&auto=format&fit=crop',
      groupIds: <String>['all', 'culture', 'weekend', 'calme'],
    ),
    (
      name: 'Kossi',
      area: 'Kégué',
      ask: 'Table pour 4 au Braise dimanche — il manque du monde',
      slot: 'Dim. 13 h',
      distance: 'à 2,4 km',
      avatarUrl:
          'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=200&q=80&auto=format&fit=crop',
      groupIds: <String>['all', 'calme', 'culture', 'soir'],
    ),
    (
      name: 'Afia',
      area: 'Agoè',
      ask: 'Qui veut tester le nouveau club Pulse ce vendredi ?',
      slot: 'Ven. 23 h',
      distance: 'à 0,8 km',
      avatarUrl:
          'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200&q=80&auto=format&fit=crop',
      groupIds: <String>['all', 'soir', 'weekend'],
    ),
    (
      name: 'Mawuli',
      area: 'Kpalimé',
      ask: 'Covoiturage + rando — 3 sièges libres',
      slot: 'Sam. 7 h',
      distance: 'Départ Lomé',
      avatarUrl:
          'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=200&q=80&auto=format&fit=crop',
      groupIds: <String>['all', 'nature', 'weekend', 'calme'],
    ),
    (
      name: 'Kofi',
      area: 'Lomé',
      ask: 'Afterwork Skyline — on partage une bouteille ?',
      slot: 'Ven. 19 h',
      distance: 'à 1,6 km',
      avatarUrl:
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200&q=80&auto=format&fit=crop',
      groupIds: <String>['all', 'soir', 'culture', 'calme'],
    ),
  ];

  IconData _venueKindIcon(String kind) {
    return switch (kind) {
      'restaurant' => LucideIcons.utensilsCrossed,
      'bar' => LucideIcons.wine,
      'club' => LucideIcons.music,
      'lounge' => LucideIcons.sofa,
      'cafe' => LucideIcons.coffee,
      'plage' => LucideIcons.sun,
      _ => LucideIcons.mapPin,
    };
  }

  /// Libellé court pour puce sur la carte lieu (évite le bloc bas surchargé).
  String _venueKindShortLabel(String kind) {
    return switch (kind) {
      'restaurant' => 'Resto',
      'bar' => 'Bar',
      'club' => 'Club',
      'lounge' => 'Lounge',
      'cafe' => 'Café',
      'plage' => 'Plage',
      _ => 'Lieu',
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

  bool _matchesGroup(List<String> groupIds) =>
      _selectedGroupId == 'all' || groupIds.contains(_selectedGroupId);

  /// Ligne contextuelle sur les écrans « Voir » (filtre ambiance / recherche).
  String? _seeAllContextHint() {
    final parts = <String>[];
    if (_selectedGroupId != 'all') {
      parts.add(
        'Ambiance : ${_groups.firstWhere((g) => g.id == _selectedGroupId).title}',
      );
    }
    final q = _searchController.text.trim();
    if (q.isNotEmpty) {
      parts.add('Recherche : « $q »');
    }
    if (parts.isEmpty) return null;
    return parts.join(' · ');
  }

  List<
      ({
        String title,
        String subtitle,
        String url,
        String kind,
        List<String> groupIds,
      })> get _filteredVenues {
    final byGroup = _venues.where((v) => _matchesGroup(v.groupIds));
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return byGroup.toList(growable: false);
    return byGroup
        .where(
          (v) =>
              v.title.toLowerCase().contains(q) ||
              v.subtitle.toLowerCase().contains(q),
        )
        .toList(growable: false);
  }

  List<
      ({
        String title,
        String venue,
        String dayLabel,
        String time,
        String distance,
        String url,
        bool certified,
        List<String> groupIds,
      })> get _filteredEvents {
    final byGroup = _nearbyEvents.where((e) => _matchesGroup(e.groupIds));
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return byGroup.toList(growable: false);
    return byGroup
        .where(
          (e) =>
              e.title.toLowerCase().contains(q) ||
              e.venue.toLowerCase().contains(q) ||
              e.dayLabel.toLowerCase().contains(q),
        )
        .toList(growable: false);
  }

  List<
      ({
        String title,
        String venue,
        String dayLabel,
        String time,
        String distance,
        String url,
        bool certified,
        List<String> groupIds,
      })> get _filteredCertifiedEvents =>
      _filteredEvents.where((e) => e.certified).toList(growable: false);

  List<
      ({
        String label,
        String hint,
        String url,
        List<String> groupIds,
      })> get _filteredAmbiances {
    final byGroup = _ambiancesNearby.where((a) => _matchesGroup(a.groupIds));
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return byGroup.toList(growable: false);
    return byGroup
        .where(
          (a) =>
              a.label.toLowerCase().contains(q) ||
              a.hint.toLowerCase().contains(q),
        )
        .toList(growable: false);
  }

  List<
      ({
        String title,
        String subtitle,
        int going,
        String when,
        String distance,
        String url,
        List<String> groupIds,
      })> get _filteredGatherings {
    final byGroup = _gatherings.where((g) => _matchesGroup(g.groupIds));
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return byGroup.toList(growable: false);
    return byGroup
        .where(
          (g) =>
              g.title.toLowerCase().contains(q) ||
              g.subtitle.toLowerCase().contains(q) ||
              g.when.toLowerCase().contains(q),
        )
        .toList(growable: false);
  }

  List<
      ({
        String name,
        String avatarUrl,
        String area,
        String ask,
        String slot,
        String distance,
        List<String> groupIds,
      })> get _filteredParticipationAsks {
    final byGroup = _participationAsks.where((p) => _matchesGroup(p.groupIds));
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return byGroup.toList(growable: false);
    return byGroup
        .where(
          (p) =>
              p.name.toLowerCase().contains(q) ||
              p.area.toLowerCase().contains(q) ||
              p.ask.toLowerCase().contains(q),
        )
        .toList(growable: false);
  }

  void _openVenueSheet(
    BuildContext context,
    ({
      String title,
      String subtitle,
      String url,
      String kind,
      List<String> groupIds,
    }) v,
  ) {
    final details = _zoneDetailsFromVenue(v);
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(
        builder: (_) => _ExploreZoneDetailsScreen(details: details),
      ),
    );
  }

  void _openEventSheet(
    BuildContext context,
    ({
      String title,
      String venue,
      String dayLabel,
      String time,
      String distance,
      String url,
      bool certified,
      List<String> groupIds,
    }) e,
  ) {
    final dark = context.oklMeetIsDark;
    final onSurface = dark ? Colors.white : context.oklOnSurface;
    final muted = dark
        ? Colors.white.withValues(alpha: 0.65)
        : context.oklOnSurfaceMuted(0.62);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.oklScaffold,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            MediaQuery.paddingOf(ctx).bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: CachedNetworkImage(
                    imageUrl: e.url,
                    fit: BoxFit.cover,
                    memCacheWidth: 800,
                    placeholder: (c, u) => Container(color: ctx.oklSurface),
                    errorWidget: (c, u, err) => Container(color: ctx.oklSurface),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              if (e.certified)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.badgeCheck, size: 16, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        'Événement certifié Oklifor',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              if (e.certified) const SizedBox(height: 10),
              Text(
                e.title,
                style: TextStyle(
                  color: onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${e.venue} · ${e.dayLabel} · ${e.time} · ${e.distance}',
                style: TextStyle(color: muted, fontSize: 13, height: 1.35),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    OklFeedback.snack(context, 'Participation enregistrée (démo)');
                  },
                  icon: const Icon(LucideIcons.userPlus, size: 20),
                  label: const Text('Je participe / intéressé·e'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  _ZoneDetailsData _zoneDetailsFromVenue(
    ({
      String title,
      String subtitle,
      String url,
      String kind,
      List<String> groupIds,
    }) v,
  ) {
    final kindFr = switch (v.kind) {
      'restaurant' => 'restaurant',
      'bar' => 'bar',
      'club' => 'boîte de nuit',
      'lounge' => 'lounge',
      'cafe' => 'café',
      'plage' => 'spot plage',
      _ => 'lieu de sortie',
    };
    return _ZoneDetailsData(
      title: v.title,
      subtitle: v.subtitle,
      heroUrl: v.url,
      locality: 'Autour de toi · démo',
      narration:
          '${v.title} est un $kindFr à ajouter à ta liste : sortie en groupe, afterwork ou rendez-vous, '
          'avec une adresse concrète plutôt qu’un vague « on verra ».',
      highlights: const [
        'Horaires variables le week-end',
        'Pense à réserver aux heures de pointe',
        'Idéal pour briser la glace sur place',
      ],
      bestPeriod: 'Selon le type de soirée (démo)',
      safetyNote: 'Privilégie les trajets connus le soir ; sort de groupe possible.',
      languages: 'Français, langues locales',
      icebreakers: [
        'Tu viens pour manger, danser ou juste discuter ?',
        'On s’y retrouve directement ou on fait un point avant ?',
        'Tu connais déjà la carte / la musique ici ?',
      ],
      suggestedMatches: 12,
      galleryUrls: [v.url, _venues[1].url, _venues[4].url],
    );
  }

  Widget _sectionVoirButton(BuildContext context, {required VoidCallback onPressed}) {
    return TextButton(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.fromLTRB(8, 0, 0, 0),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        foregroundColor: AppColors.primary,
      ),
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Voir',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: AppColors.primary,
            ),
          ),
          Icon(LucideIcons.chevronRight, size: 16, color: AppColors.primary),
        ],
      ),
    );
  }

  void _pushSeeAllCertifiedEvents(BuildContext context) {
    final certifiedEvents = _filteredCertifiedEvents;
    Navigator.of(context, rootNavigator: true).push<void>(
      MaterialPageRoute<void>(
        builder: (ctx) => ExploreSeeAllEventsScreen(
          title: 'Événements certifiés Oklifor',
          events: certifiedEvents,
          contextHint: _seeAllContextHint(),
          onEventTap: _openEventSheet,
        ),
      ),
    );
  }

  void _pushSeeAllOtherEvents(BuildContext context) {
    final certifiedEvents = _filteredCertifiedEvents;
    final eventsMainList = certifiedEvents.isEmpty
        ? _filteredEvents
        : _filteredEvents.where((e) => !e.certified).toList(growable: false);
    Navigator.of(context, rootNavigator: true).push<void>(
      MaterialPageRoute<void>(
        builder: (ctx) => ExploreSeeAllEventsScreen(
          title: certifiedEvents.isEmpty
              ? 'Événements à proximité'
              : 'Autres événements près de toi',
          events: eventsMainList,
          contextHint: _seeAllContextHint(),
          onEventTap: _openEventSheet,
        ),
      ),
    );
  }

  void _pushSeeAllAmbiances(BuildContext context) {
    Navigator.of(context, rootNavigator: true).push<void>(
      MaterialPageRoute<void>(
        builder: (ctx) => ExploreSeeAllAmbiancesScreen(
          ambiances: _filteredAmbiances,
          contextHint: _seeAllContextHint(),
        ),
      ),
    );
  }

  void _pushSeeAllParticipation(BuildContext context) {
    Navigator.of(context, rootNavigator: true).push<void>(
      MaterialPageRoute<void>(
        builder: (ctx) => ExploreSeeAllParticipationScreen(
          asks: _filteredParticipationAsks,
          contextHint: _seeAllContextHint(),
        ),
      ),
    );
  }

  void _pushSeeAllGatherings(BuildContext context) {
    Navigator.of(context, rootNavigator: true).push<void>(
      MaterialPageRoute<void>(
        builder: (ctx) => ExploreSeeAllGatheringsScreen(
          gatherings: _filteredGatherings,
          contextHint: _seeAllContextHint(),
        ),
      ),
    );
  }

  void _pushSeeAllVenues(BuildContext context) {
    Navigator.of(context, rootNavigator: true).push<void>(
      MaterialPageRoute<void>(
        builder: (ctx) => ExploreSeeAllVenuesScreen(
          title: 'Restos, bars & boîtes',
          venues: _filteredVenues,
          contextHint: _seeAllContextHint(),
          onVenueTap: _openVenueSheet,
        ),
      ),
    );
  }

  Widget _buildEventCarouselCard(
    BuildContext context, {
    required String title,
    required String venue,
    required String dayLabel,
    required String time,
    required String distance,
    required String imageUrl,
    required bool certified,
    required VoidCallback onTap,
  }) {
    final isDark = context.oklMeetIsDark;
    const w = 220.0;
    const h = 158.0;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: w,
          height: h,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
                  blurRadius: isDark ? 16 : 12,
                  offset: Offset(0, isDark ? 8 : 5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    memCacheWidth: 440,
                    placeholder: (c, u) => Container(color: context.oklSurface),
                    errorWidget: (c, u, e) => Container(color: context.oklSurface),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.3),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.78),
                        ],
                        stops: const [0.0, 0.45, 1.0],
                      ),
                    ),
                  ),
                  if (certified)
                    Positioned(
                      left: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.badgeCheck, size: 10, color: Colors.white),
                            SizedBox(width: 3),
                            Text(
                              'Certifié',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  Positioned(
                    left: 10,
                    right: 10,
                    bottom: 10,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            height: 1.12,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          venue,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.88),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '$dayLabel · $time · $distance',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.78),
                            fontSize: 9.5,
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
        ),
      ),
    );
  }

  Widget _buildAmbianceCard(
    BuildContext context, {
    required String label,
    required String hint,
    required String imageUrl,
    required VoidCallback onTap,
  }) {
    final isDark = context.oklMeetIsDark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 128,
          height: 92,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  memCacheWidth: 320,
                  placeholder: (c, u) => Container(color: context.oklSurface),
                  errorWidget: (c, u, e) => Container(color: context.oklSurface),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.2),
                        Colors.black.withValues(alpha: 0.75),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 8,
                  right: 8,
                  bottom: 8,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          height: 1.08,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        hint,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 9.5,
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
      ),
    );
  }

  Widget _buildGatheringCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required int going,
    required String when,
    required String distance,
    required String imageUrl,
    required VoidCallback onTap,
  }) {
    final isDark = context.oklMeetIsDark;
    final titleColor = isDark ? Colors.white : context.oklOnSurface;
    final subColor =
        isDark ? Colors.white.withValues(alpha: 0.55) : context.oklOnSurfaceMuted(0.55);
    const thumb = 86.0;
    const h = 90.0;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 252,
          height: h,
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.08) : context.oklSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.14) : context.oklDivider,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.05),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: thumb,
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  memCacheWidth: 360,
                  placeholder: (c, u) => Container(color: context.oklScaffold),
                  errorWidget: (c, u, e) => Container(color: context.oklScaffold),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 7, 10, 7),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: titleColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: subColor, fontSize: 10, height: 1.15),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(LucideIcons.users, size: 11, color: AppColors.primary),
                          const SizedBox(width: 3),
                          Text(
                            '$going',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w800,
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(LucideIcons.clock, size: 11, color: subColor),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              when,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: subColor,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(LucideIcons.mapPin, size: 10, color: subColor),
                          const SizedBox(width: 2),
                          Flexible(
                            child: Text(
                              distance,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.end,
                              style: TextStyle(
                                color: subColor,
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
        onTap: () => setState(() => _selectedGroupId = g.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final venues = _filteredVenues;
    final certifiedEvents = _filteredCertifiedEvents;
    final eventsMainList = certifiedEvents.isEmpty
        ? _filteredEvents
        : _filteredEvents.where((e) => !e.certified).toList(growable: false);
    final ambiances = _filteredAmbiances;
    final gatherings = _filteredGatherings;
    final asks = _filteredParticipationAsks;
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
                                      hintText: 'Événement, bar, ambiance, groupe…',
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
                                      'Sorties',
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
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Événements, ambiances & lieux près de toi',
                        style: TextStyle(
                          color: titleColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.35,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Certifiés Oklifor, soirées, restos, bars, clubs, rassemblements — et des personnes qui cherchent des participant·e·s pour un plan concret.',
                        style: TextStyle(
                          color: subColor,
                          fontSize: 13,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Ton envie du moment',
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
              if (certifiedEvents.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Événements certifiés Oklifor',
                                    style: TextStyle(
                                      color: titleColor,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.25,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Sélection équipe — partenaires & plans vérifiés (démo).',
                                    style: TextStyle(
                                      color: subColor,
                                      fontSize: 11.5,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _sectionVoirButton(
                              context,
                              onPressed: () => _pushSeeAllCertifiedEvents(context),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 158,
                          child: ListView.separated(
                            padding: const EdgeInsets.only(right: 4),
                            scrollDirection: Axis.horizontal,
                            itemCount: certifiedEvents.length,
                            separatorBuilder: (context, _) => const SizedBox(width: 12),
                            itemBuilder: (context, i) {
                              final e = certifiedEvents[i];
                              return _buildEventCarouselCard(
                                context,
                                title: e.title,
                                venue: e.venue,
                                dayLabel: e.dayLabel,
                                time: e.time,
                                distance: e.distance,
                                imageUrl: e.url,
                                certified: e.certified,
                                onTap: () => _openEventSheet(context, e),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (eventsMainList.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, certifiedEvents.isNotEmpty ? 16 : 12, 12, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    certifiedEvents.isEmpty
                                        ? 'Événements à proximité'
                                        : 'Autres événements près de toi',
                                    style: TextStyle(
                                      color: titleColor,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.25,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Ouvre la fiche pour dire que tu viens (démo).',
                                    style: TextStyle(
                                      color: subColor,
                                      fontSize: 11.5,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _sectionVoirButton(
                              context,
                              onPressed: () => _pushSeeAllOtherEvents(context),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 158,
                          child: ListView.separated(
                            padding: const EdgeInsets.only(right: 4),
                            scrollDirection: Axis.horizontal,
                            itemCount: eventsMainList.length,
                            separatorBuilder: (context, _) => const SizedBox(width: 12),
                            itemBuilder: (context, i) {
                              final e = eventsMainList[i];
                              return _buildEventCarouselCard(
                                context,
                                title: e.title,
                                venue: e.venue,
                                dayLabel: e.dayLabel,
                                time: e.time,
                                distance: e.distance,
                                imageUrl: e.url,
                                certified: e.certified,
                                onTap: () => _openEventSheet(context, e),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (ambiances.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Ambiances à proximité',
                                    style: TextStyle(
                                      color: titleColor,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.25,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Tendance du soir autour de toi (démo).',
                                    style: TextStyle(
                                      color: subColor,
                                      fontSize: 11.5,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _sectionVoirButton(
                              context,
                              onPressed: () => _pushSeeAllAmbiances(context),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 92,
                          child: ListView.separated(
                            padding: const EdgeInsets.only(right: 4),
                            scrollDirection: Axis.horizontal,
                            itemCount: ambiances.length,
                            separatorBuilder: (context, _) => const SizedBox(width: 10),
                            itemBuilder: (context, i) {
                              final a = ambiances[i];
                              return _buildAmbianceCard(
                                context,
                                label: a.label,
                                hint: a.hint,
                                imageUrl: a.url,
                                onTap: () => OklFeedback.snack(
                                  context,
                                  'Ambiance « ${a.label} » (démo)',
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
                  padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Demandes de participation',
                                  style: TextStyle(
                                    color: titleColor,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.25,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Complète un groupe ou réponds à un plan concret (démo).',
                                  style: TextStyle(
                                    color: subColor,
                                    fontSize: 11.5,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _sectionVoirButton(
                            context,
                            onPressed: () => _pushSeeAllParticipation(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (asks.isEmpty)
                        Text(
                          'Aucune demande pour ce filtre — élargis ton ambiance ou ta recherche.',
                          style: TextStyle(color: subColor, fontSize: 13, height: 1.4),
                        )
                      else
                        SizedBox(
                          height: 114,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: asks.length,
                            separatorBuilder: (context, _) => const SizedBox(width: 12),
                            itemBuilder: (context, i) {
                              final p = asks[i];
                              return Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(18),
                                  onTap: () => Navigator.of(context, rootNavigator: true).push<void>(
                                    MaterialPageRoute<void>(
                                      builder: (_) => NearbyProfilePreviewScreen(
                                        name: p.name,
                                        area: p.area,
                                        vibe: p.ask,
                                        distance: p.distance,
                                        avatarUrl: p.avatarUrl,
                                        slot: p.slot,
                                        participationAsk: true,
                                      ),
                                    ),
                                  ),
                                  child: Container(
                                    width: 236,
                                    padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.08)
                                          : context.oklSurface,
                                      borderRadius: BorderRadius.circular(18),
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
                                      crossAxisAlignment: CrossAxisAlignment.start,
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
                                              width: 40,
                                              height: 40,
                                              fit: BoxFit.cover,
                                              memCacheWidth: 160,
                                              placeholder: (ctx, url) => Container(
                                                width: 40,
                                                height: 40,
                                                color: isDark
                                                    ? Colors.white.withValues(alpha: 0.06)
                                                    : context.oklScaffold,
                                              ),
                                              errorWidget: (ctx, url, error) => Container(
                                                width: 40,
                                                height: 40,
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
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      p.name,
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        color: titleColor,
                                                        fontWeight: FontWeight.w800,
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                  ),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.primary.withValues(alpha: 0.12),
                                                      borderRadius: BorderRadius.circular(999),
                                                    ),
                                                    child: Text(
                                                      p.slot,
                                                      style: TextStyle(
                                                        color: AppColors.primary,
                                                        fontSize: 9,
                                                        fontWeight: FontWeight.w800,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 1),
                                              Text(
                                                p.area,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: isDark
                                                      ? Colors.white.withValues(alpha: 0.55)
                                                      : context.oklOnSurfaceMuted(0.58),
                                                  fontSize: 10,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                p.ask,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: isDark
                                                      ? Colors.white.withValues(alpha: 0.78)
                                                      : context.oklOnSurfaceMuted(0.78),
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  height: 1.2,
                                                ),
                                              ),
                                              const SizedBox(height: 3),
                                              Row(
                                                children: [
                                                  Icon(
                                                    LucideIcons.mapPin,
                                                    size: 11,
                                                    color: isDark
                                                        ? Colors.white.withValues(alpha: 0.42)
                                                        : context.oklOnSurfaceMuted(0.45),
                                                  ),
                                                  const SizedBox(width: 3),
                                                  Text(
                                                    p.distance,
                                                    style: TextStyle(
                                                      color: isDark
                                                          ? Colors.white.withValues(alpha: 0.42)
                                                          : context.oklOnSurfaceMuted(0.48),
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                  const Spacer(),
                                                  Icon(
                                                    LucideIcons.userPlus,
                                                    size: 13,
                                                    color: AppColors.primary,
                                                  ),
                                                ],
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
              if (gatherings.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Rassemblements & groupes',
                                    style: TextStyle(
                                      color: titleColor,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.25,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Rejoins un créneau ou un covoit (démo).',
                                    style: TextStyle(
                                      color: subColor,
                                      fontSize: 11.5,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _sectionVoirButton(
                              context,
                              onPressed: () => _pushSeeAllGatherings(context),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 90,
                          child: ListView.separated(
                            padding: const EdgeInsets.only(right: 4),
                            scrollDirection: Axis.horizontal,
                            itemCount: gatherings.length,
                            separatorBuilder: (context, _) => const SizedBox(width: 12),
                            itemBuilder: (context, i) {
                              final g = gatherings[i];
                              return _buildGatheringCard(
                                context,
                                title: g.title,
                                subtitle: g.subtitle,
                                going: g.going,
                                when: g.when,
                                distance: g.distance,
                                imageUrl: g.url,
                                onTap: () => OklFeedback.snack(
                                  context,
                                  'Groupe « ${g.title} » (démo)',
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
                  padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Restos, bars & boîtes',
                              style: TextStyle(
                                color: titleColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.35,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              venues.isEmpty
                                  ? '0 lieu'
                                  : '${venues.length} lieu${venues.length > 1 ? 'x' : ''}',
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.45)
                                    : context.oklOnSurfaceMuted(0.48),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _sectionVoirButton(
                        context,
                        onPressed: () => _pushSeeAllVenues(context),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(14, 0, 14, bottomPad),
                sliver: venues.isEmpty
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
                                  'Aucun lieu pour cette ambiance',
                                  style: TextStyle(
                                    color: titleColor,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Essaie un autre filtre « ${_groups.firstWhere((g) => g.id == _selectedGroupId).title} » ou élargis ta recherche.',
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
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1.02,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, i) {
                            final s = venues[i];
                            return Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => _openVenueSheet(context, s),
                                borderRadius: BorderRadius.circular(18),
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(18),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: isDark ? 0.45 : 0.1,
                                        ),
                                        blurRadius: isDark ? 18 : 12,
                                        offset: Offset(0, isDark ? 10 : 6),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(18),
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
                                        DecoratedBox(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              stops: const [0.0, 0.55, 1.0],
                                              colors: [
                                                Colors.black.withValues(alpha: 0.08),
                                                Colors.transparent,
                                                Colors.black.withValues(alpha: 0.35),
                                              ],
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          top: 8,
                                          left: 8,
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(999),
                                            child: BackdropFilter(
                                              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 7,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.black.withValues(alpha: 0.35),
                                                  borderRadius: BorderRadius.circular(999),
                                                  border: Border.all(
                                                    color: Colors.white.withValues(alpha: 0.2),
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      _venueKindIcon(s.kind),
                                                      size: 11,
                                                      color: Colors.white.withValues(alpha: 0.95),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      _venueKindShortLabel(s.kind),
                                                      style: TextStyle(
                                                        color: Colors.white.withValues(alpha: 0.95),
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.w800,
                                                        letterSpacing: 0.15,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          left: 0,
                                          right: 0,
                                          bottom: 0,
                                          child: Container(
                                            padding: const EdgeInsets.fromLTRB(9, 20, 9, 8),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                                stops: const [0.0, 0.45, 1.0],
                                                colors: [
                                                  Colors.transparent,
                                                  Colors.black.withValues(alpha: 0.25),
                                                  Colors.black.withValues(alpha: 0.75),
                                                ],
                                              ),
                                            ),
                                            child: Text(
                                              s.title,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: -0.25,
                                                height: 1.12,
                                                shadows: [
                                                  Shadow(
                                                    offset: Offset(0, 1),
                                                    blurRadius: 4,
                                                    color: Color(0x66000000),
                                                  ),
                                                ],
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
                          childCount: venues.length,
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
