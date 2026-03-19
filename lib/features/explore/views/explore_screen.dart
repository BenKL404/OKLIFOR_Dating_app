import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/okl_feedback.dart';
import '../../../core/widgets/okl_pill_search_bar.dart';

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
    required this.galleryUrls,
  });
}

class _ExploreZoneDetailsScreen extends StatelessWidget {
  final _ZoneDetailsData details;

  const _ExploreZoneDetailsScreen({required this.details});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dark,
      appBar: AppBar(
        backgroundColor: AppColors.dark,
        title: Text(details.title),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.paddingOf(context).bottom + 18),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 16 / 10,
              child: CachedNetworkImage(
                imageUrl: details.heroUrl,
                fit: BoxFit.cover,
                memCacheWidth: 1000,
                placeholder: (context, url) => Container(color: AppColors.surface),
                errorWidget: (context, url, error) => Container(
                  color: AppColors.surface,
                  child: const Center(
                    child: Icon(LucideIcons.imageOff, color: AppColors.textMuted),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            details.subtitle,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(LucideIcons.mapPin, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  details.locality,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              ),
              TextButton.icon(
                onPressed: () => OklFeedback.snack(
                  context,
                  'Ouverture carte de ${details.title} (demo)',
                ),
                style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
                icon: const Icon(LucideIcons.navigation, size: 16, color: AppColors.textSecondary),
                label: const Text('Localiser'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _ZoneInfoCard(
            title: 'Narration de la zone',
            child: Text(
              details.narration,
              style: const TextStyle(color: AppColors.textSecondary, height: 1.45),
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
                        const Icon(LucideIcons.dot, size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item,
                            style: const TextStyle(color: AppColors.textSecondary),
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
          const Text(
            'Galerie de la zone',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 110,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: details.galleryUrls.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final url = details.galleryUrls[index];
                return ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: 1.2,
                    child: CachedNetworkImage(
                      imageUrl: url,
                      fit: BoxFit.cover,
                      memCacheWidth: 360,
                      placeholder: (context, url) => Container(color: AppColors.surface),
                      errorWidget: (context, url, error) => Container(color: AppColors.surface),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
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
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
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

    return Scaffold(
      backgroundColor: AppColors.dark,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _searchMode
                        ? Row(
                            children: [
                              Material(
                                color: AppColors.surface,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: const BorderSide(color: AppColors.divider),
                                ),
                                child: InkWell(
                                  onTap: _exitSearch,
                                  borderRadius: BorderRadius.circular(12),
                                  child: const SizedBox(
                                    width: 44,
                                    height: 44,
                                    child: Center(
                                      child: Icon(
                                        LucideIcons.arrowLeft,
                                        color: AppColors.textSecondary,
                                        size: 22,
                                      ),
                                    ),
                                  ),
                                ),
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Explorer',
                                      style: TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 30,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -1,
                                        height: 1.05,
                                      ),
                                    ),
            
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Material(
                                color: AppColors.surface,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: const BorderSide(color: AppColors.divider),
                                ),
                                child: InkWell(
                                  onTap: _enterSearch,
                                  borderRadius: BorderRadius.circular(12),
                                  child: const SizedBox(
                                    width: 44,
                                    height: 44,
                                    child: Center(
                                      child: Icon(
                                        LucideIcons.search,
                                        color: AppColors.textSecondary,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Filtres',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
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
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Lieux',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        filtered.isEmpty ? '0 résultat' : '${filtered.length} lieu${filtered.length > 1 ? 'x' : ''}',
                        style: const TextStyle(
                          color: AppColors.textMuted,
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
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              sliver: filtered.isEmpty
                  ? SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppColors.divider),
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: AppColors.dark,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.divider),
                                ),
                                child: const Icon(
                                  LucideIcons.mapPinOff,
                                  color: AppColors.textSecondary,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Aucun lieu ne correspond',
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Essaye un autre filtre ou une autre recherche pour « ${_groups.firstWhere((g) => g.id == _selectedGroupId).title} ».',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColors.textSecondary.withValues(alpha: 0.95),
                                  fontSize: 13,
                                  height: 1.4,
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
                        childAspectRatio: 0.72,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, i) {
                          final s = filtered[i];
                          return Material(
                            color: AppColors.card,
                            elevation: 0,
                            borderRadius: BorderRadius.circular(20),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: () => _openSpotSheet(context, s),
                              borderRadius: BorderRadius.circular(20),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: AppColors.divider, width: 1),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(19),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      CachedNetworkImage(
                                        imageUrl: s.url,
                                        fit: BoxFit.cover,
                                        filterQuality: FilterQuality.high,
                                        memCacheWidth: 600,
                                        placeholder: (context, url) => Container(
                                          color: AppColors.surface,
                                        ),
                                        errorWidget: (context, url, error) => Container(
                                          color: AppColors.surface,
                                          alignment: Alignment.center,
                                          child: const Icon(
                                            LucideIcons.imageOff,
                                            color: AppColors.textMuted,
                                          ),
                                        ),
                                      ),
                                      const DecoratedBox(
                                        decoration: BoxDecoration(
                                          gradient: AppColors.cardOverlay,
                                        ),
                                      ),
                                      Positioned(
                                        left: 0,
                                        right: 0,
                                        bottom: 0,
                                        child: Container(
                                          padding: const EdgeInsets.fromLTRB(12, 24, 12, 12),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [
                                                Colors.transparent,
                                                Colors.black.withValues(alpha: 0.75),
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
                                                  letterSpacing: -0.2,
                                                  shadows: [
                                                    Shadow(
                                                      color: Colors.black54,
                                                      blurRadius: 8,
                                                    ),
                                                  ],
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
                                                  shadows: const [
                                                    Shadow(color: Colors.black45, blurRadius: 6),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top: 10,
                                        right: 10,
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(alpha: 0.45),
                                            shape: BoxShape.circle,
                                            border: Border.all(color: Colors.white24),
                                          ),
                                          child: Icon(
                                            LucideIcons.mapPin,
                                            size: 15,
                                            color: Colors.white.withValues(alpha: 0.92),
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
    );
  }
}

/// Puce horizontale pour les filtres (lisible, style app moderne).
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.card : AppColors.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? AppColors.textSecondary.withValues(alpha: 0.45) : AppColors.divider,
              width: selected ? 1.5 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? AppColors.textPrimary : AppColors.textSecondary,
              fontSize: 13,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              letterSpacing: -0.1,
            ),
          ),
        ),
      ),
    );
  }
}
