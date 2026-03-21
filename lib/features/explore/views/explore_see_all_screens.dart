import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/utils/okl_feedback.dart';
import '../../../core/widgets/okl_app_bar_icon_button.dart';
import 'nearby_profile_preview_screen.dart';

typedef OklExploreVenue = ({
  String title,
  String subtitle,
  String url,
  String kind,
  List<String> groupIds,
});

typedef OklExploreEvent = ({
  String title,
  String venue,
  String dayLabel,
  String time,
  String distance,
  String url,
  bool certified,
  List<String> groupIds,
});

typedef OklExploreAmbiance = ({
  String label,
  String hint,
  String url,
  List<String> groupIds,
});

typedef OklExploreGathering = ({
  String title,
  String subtitle,
  int going,
  String when,
  String distance,
  String url,
  List<String> groupIds,
});

typedef OklExploreParticipationAsk = ({
  String name,
  String avatarUrl,
  String area,
  String ask,
  String slot,
  String distance,
  List<String> groupIds,
});

typedef OklExploreVenueTap = void Function(BuildContext context, OklExploreVenue v);
typedef OklExploreEventTap = void Function(BuildContext context, OklExploreEvent e);

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

class ExploreSeeAllVenuesScreen extends StatelessWidget {
  final String title;
  final List<OklExploreVenue> venues;
  final String? contextHint;
  final OklExploreVenueTap onVenueTap;

  const ExploreSeeAllVenuesScreen({
    super.key,
    required this.title,
    required this.venues,
    required this.onVenueTap,
    this.contextHint,
  });

  @override
  Widget build(BuildContext context) {
    final dark = context.oklMeetIsDark;
    final onTitle = dark ? Colors.white : context.oklOnSurface;
    final muted = dark
        ? Colors.white.withValues(alpha: 0.55)
        : context.oklOnSurfaceMuted(0.55);

    return Scaffold(
      backgroundColor: context.oklScaffold,
      appBar: AppBar(
        backgroundColor: context.oklScaffold,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: const OklAppBarBackButton(rootNavigator: true),
        title: Text(
          title,
          style: TextStyle(
            color: onTitle,
            fontWeight: FontWeight.w800,
            fontSize: 17,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (contextHint != null && contextHint!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                contextHint!,
                style: TextStyle(color: muted, fontSize: 12.5, height: 1.35),
              ),
            ),
          Expanded(
            child: venues.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Aucun lieu pour ce filtre.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: muted, fontSize: 15),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: EdgeInsets.fromLTRB(16, 4, 16, MediaQuery.paddingOf(context).bottom + 24),
                    itemCount: venues.length,
                    separatorBuilder: (context, _) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final v = venues[i];
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => onVenueTap(context, v),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: dark
                                  ? Colors.white.withValues(alpha: 0.07)
                                  : context.oklSurface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: dark
                                    ? Colors.white.withValues(alpha: 0.12)
                                    : context.oklDivider,
                              ),
                            ),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: CachedNetworkImage(
                                    imageUrl: v.url,
                                    width: 64,
                                    height: 64,
                                    fit: BoxFit.cover,
                                    memCacheWidth: 200,
                                    placeholder: (c, u) => Container(
                                      width: 64,
                                      height: 64,
                                      color: context.oklScaffold,
                                    ),
                                    errorWidget: (c, u, e) => Container(
                                      width: 64,
                                      height: 64,
                                      color: context.oklScaffold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            _venueKindIcon(v.kind),
                                            size: 14,
                                            color: AppColors.primary,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            _venueKindShortLabel(v.kind),
                                            style: TextStyle(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        v.title,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: onTitle,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 15,
                                          height: 1.15,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        v.subtitle,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: muted,
                                          fontSize: 12,
                                          height: 1.25,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  LucideIcons.chevronRight,
                                  color: muted,
                                  size: 20,
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
    );
  }
}

class ExploreSeeAllEventsScreen extends StatelessWidget {
  final String title;
  final List<OklExploreEvent> events;
  final String? contextHint;
  final OklExploreEventTap onEventTap;

  const ExploreSeeAllEventsScreen({
    super.key,
    required this.title,
    required this.events,
    required this.onEventTap,
    this.contextHint,
  });

  @override
  Widget build(BuildContext context) {
    final dark = context.oklMeetIsDark;
    final onTitle = dark ? Colors.white : context.oklOnSurface;
    final muted = dark
        ? Colors.white.withValues(alpha: 0.55)
        : context.oklOnSurfaceMuted(0.55);

    return Scaffold(
      backgroundColor: context.oklScaffold,
      appBar: AppBar(
        backgroundColor: context.oklScaffold,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: const OklAppBarBackButton(rootNavigator: true),
        title: Text(
          title,
          style: TextStyle(
            color: onTitle,
            fontWeight: FontWeight.w800,
            fontSize: 17,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (contextHint != null && contextHint!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                contextHint!,
                style: TextStyle(color: muted, fontSize: 12.5, height: 1.35),
              ),
            ),
          Expanded(
            child: events.isEmpty
                ? Center(
                    child: Text(
                      'Aucun événement pour ce filtre.',
                      style: TextStyle(color: muted, fontSize: 15),
                    ),
                  )
                : ListView.separated(
                    padding: EdgeInsets.fromLTRB(16, 4, 16, MediaQuery.paddingOf(context).bottom + 24),
                    itemCount: events.length,
                    separatorBuilder: (context, _) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final e = events[i];
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => onEventTap(context, e),
                          borderRadius: BorderRadius.circular(16),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: SizedBox(
                              height: 112,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  CachedNetworkImage(
                                    imageUrl: e.url,
                                    fit: BoxFit.cover,
                                    memCacheWidth: 600,
                                    placeholder: (c, u) => Container(color: context.oklSurface),
                                    errorWidget: (c, u, err) =>
                                        Container(color: context.oklSurface),
                                  ),
                                  DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                        colors: [
                                          Colors.black.withValues(alpha: 0.82),
                                          Colors.black.withValues(alpha: 0.35),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        if (e.certified)
                                          Padding(
                                            padding: const EdgeInsets.only(bottom: 6),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 3,
                                              ),
                                              decoration: BoxDecoration(
                                                color: AppColors.primary.withValues(alpha: 0.9),
                                                borderRadius: BorderRadius.circular(999),
                                              ),
                                              child: const Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    LucideIcons.badgeCheck,
                                                    size: 11,
                                                    color: Colors.white,
                                                  ),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    'Certifié Oklifor',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.w800,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        Text(
                                          e.title,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                            height: 1.12,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          e.venue,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: Colors.white.withValues(alpha: 0.88),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          '${e.dayLabel} · ${e.time} · ${e.distance}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: Colors.white.withValues(alpha: 0.78),
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Positioned(
                                    right: 10,
                                    top: 0,
                                    bottom: 0,
                                    child: Center(
                                      child: Icon(
                                        LucideIcons.chevronRight,
                                        color: Colors.white.withValues(alpha: 0.85),
                                        size: 22,
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
                  ),
          ),
        ],
      ),
    );
  }
}

class ExploreSeeAllAmbiancesScreen extends StatelessWidget {
  final List<OklExploreAmbiance> ambiances;
  final String? contextHint;

  const ExploreSeeAllAmbiancesScreen({
    super.key,
    required this.ambiances,
    this.contextHint,
  });

  @override
  Widget build(BuildContext context) {
    final dark = context.oklMeetIsDark;
    final onTitle = dark ? Colors.white : context.oklOnSurface;
    final muted = dark
        ? Colors.white.withValues(alpha: 0.55)
        : context.oklOnSurfaceMuted(0.55);

    return Scaffold(
      backgroundColor: context.oklScaffold,
      appBar: AppBar(
        backgroundColor: context.oklScaffold,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: const OklAppBarBackButton(rootNavigator: true),
        title: Text(
          'Ambiances à proximité',
          style: TextStyle(
            color: onTitle,
            fontWeight: FontWeight.w800,
            fontSize: 17,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (contextHint != null && contextHint!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                contextHint!,
                style: TextStyle(color: muted, fontSize: 12.5, height: 1.35),
              ),
            ),
          Expanded(
            child: ambiances.isEmpty
                ? Center(
                    child: Text(
                      'Aucune ambiance pour ce filtre.',
                      style: TextStyle(color: muted, fontSize: 15),
                    ),
                  )
                : ListView.separated(
                    padding: EdgeInsets.fromLTRB(16, 4, 16, MediaQuery.paddingOf(context).bottom + 24),
                    itemCount: ambiances.length,
                    separatorBuilder: (context, _) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final a = ambiances[i];
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => OklFeedback.snack(
                            context,
                            'Ambiance « ${a.label} » — ${a.hint} (démo)',
                          ),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            height: 88,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: dark ? 0.35 : 0.08),
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
                                    imageUrl: a.url,
                                    fit: BoxFit.cover,
                                    memCacheWidth: 400,
                                    placeholder: (c, u) => Container(color: context.oklSurface),
                                    errorWidget: (c, u, e) =>
                                        Container(color: context.oklSurface),
                                  ),
                                  DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                        colors: [
                                          Colors.black.withValues(alpha: 0.75),
                                          Colors.transparent,
                                        ],
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          a.label,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 17,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          a.hint,
                                          style: TextStyle(
                                            color: Colors.white.withValues(alpha: 0.88),
                                            fontSize: 12.5,
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
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class ExploreSeeAllParticipationScreen extends StatelessWidget {
  final List<OklExploreParticipationAsk> asks;
  final String? contextHint;

  const ExploreSeeAllParticipationScreen({
    super.key,
    required this.asks,
    this.contextHint,
  });

  @override
  Widget build(BuildContext context) {
    final dark = context.oklMeetIsDark;
    final onTitle = dark ? Colors.white : context.oklOnSurface;
    final muted = dark
        ? Colors.white.withValues(alpha: 0.55)
        : context.oklOnSurfaceMuted(0.55);

    return Scaffold(
      backgroundColor: context.oklScaffold,
      appBar: AppBar(
        backgroundColor: context.oklScaffold,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: const OklAppBarBackButton(rootNavigator: true),
        title: Text(
          'Demandes de participation',
          style: TextStyle(
            color: onTitle,
            fontWeight: FontWeight.w800,
            fontSize: 17,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (contextHint != null && contextHint!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                contextHint!,
                style: TextStyle(color: muted, fontSize: 12.5, height: 1.35),
              ),
            ),
          Expanded(
            child: asks.isEmpty
                ? Center(
                    child: Text(
                      'Aucune demande pour ce filtre.',
                      style: TextStyle(color: muted, fontSize: 15),
                    ),
                  )
                : ListView.separated(
                    padding: EdgeInsets.fromLTRB(16, 4, 16, MediaQuery.paddingOf(context).bottom + 24),
                    itemCount: asks.length,
                    separatorBuilder: (context, _) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final p = asks[i];
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
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
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: dark
                                  ? Colors.white.withValues(alpha: 0.07)
                                  : context.oklSurface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: dark
                                    ? Colors.white.withValues(alpha: 0.12)
                                    : context.oklDivider,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipOval(
                                  child: CachedNetworkImage(
                                    imageUrl: p.avatarUrl,
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.cover,
                                    memCacheWidth: 160,
                                  ),
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
                                              p.name,
                                              style: TextStyle(
                                                color: onTitle,
                                                fontWeight: FontWeight.w800,
                                                fontSize: 15,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.primary.withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(999),
                                            ),
                                            child: Text(
                                              p.slot,
                                              style: TextStyle(
                                                color: AppColors.primary,
                                                fontWeight: FontWeight.w800,
                                                fontSize: 10,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        p.area,
                                        style: TextStyle(color: muted, fontSize: 12),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        p.ask,
                                        style: TextStyle(
                                          color: dark
                                              ? Colors.white.withValues(alpha: 0.78)
                                              : context.oklOnSurfaceMuted(0.78),
                                          fontSize: 13,
                                          height: 1.35,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Icon(LucideIcons.mapPin, size: 14, color: muted),
                                          const SizedBox(width: 4),
                                          Text(
                                            p.distance,
                                            style: TextStyle(
                                              color: muted,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 12,
                                            ),
                                          ),
                                          const Spacer(),
                                          Icon(
                                            LucideIcons.chevronRight,
                                            color: AppColors.primary,
                                            size: 18,
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
    );
  }
}

class ExploreSeeAllGatheringsScreen extends StatelessWidget {
  final List<OklExploreGathering> gatherings;
  final String? contextHint;

  const ExploreSeeAllGatheringsScreen({
    super.key,
    required this.gatherings,
    this.contextHint,
  });

  @override
  Widget build(BuildContext context) {
    final dark = context.oklMeetIsDark;
    final onTitle = dark ? Colors.white : context.oklOnSurface;
    final muted = dark
        ? Colors.white.withValues(alpha: 0.55)
        : context.oklOnSurfaceMuted(0.55);

    return Scaffold(
      backgroundColor: context.oklScaffold,
      appBar: AppBar(
        backgroundColor: context.oklScaffold,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: const OklAppBarBackButton(rootNavigator: true),
        title: Text(
          'Rassemblements & groupes',
          style: TextStyle(
            color: onTitle,
            fontWeight: FontWeight.w800,
            fontSize: 17,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (contextHint != null && contextHint!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                contextHint!,
                style: TextStyle(color: muted, fontSize: 12.5, height: 1.35),
              ),
            ),
          Expanded(
            child: gatherings.isEmpty
                ? Center(
                    child: Text(
                      'Aucun rassemblement pour ce filtre.',
                      style: TextStyle(color: muted, fontSize: 15),
                    ),
                  )
                : ListView.separated(
                    padding: EdgeInsets.fromLTRB(16, 4, 16, MediaQuery.paddingOf(context).bottom + 24),
                    itemCount: gatherings.length,
                    separatorBuilder: (context, _) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final g = gatherings[i];
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => OklFeedback.snack(
                            context,
                            'Groupe « ${g.title} » — rejoindre (démo)',
                          ),
                          child: Container(
                            height: 96,
                            decoration: BoxDecoration(
                              color: dark
                                  ? Colors.white.withValues(alpha: 0.07)
                                  : context.oklSurface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: dark
                                    ? Colors.white.withValues(alpha: 0.12)
                                    : context.oklDivider,
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                SizedBox(
                                  width: 96,
                                  child: CachedNetworkImage(
                                    imageUrl: g.url,
                                    fit: BoxFit.cover,
                                    memCacheWidth: 300,
                                    placeholder: (c, u) =>
                                        Container(color: context.oklScaffold),
                                    errorWidget: (c, u, e) =>
                                        Container(color: context.oklScaffold),
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          g.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: onTitle,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          g.subtitle,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(color: muted, fontSize: 11.5),
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Icon(
                                              LucideIcons.users,
                                              size: 13,
                                              color: AppColors.primary,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${g.going}',
                                              style: TextStyle(
                                                color: AppColors.primary,
                                                fontWeight: FontWeight.w800,
                                                fontSize: 12,
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Icon(LucideIcons.clock, size: 13, color: muted),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                g.when,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: muted,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                            Icon(LucideIcons.mapPin, size: 12, color: muted),
                                            const SizedBox(width: 2),
                                            Flexible(
                                              child: Text(
                                                g.distance,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: muted,
                                                  fontSize: 10,
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
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
