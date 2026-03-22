import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/flows/okl_flows.dart';
import '../../../core/theme/theme_extensions.dart';

/// Fiche riche pour une ambiance (Sorties).
class ExploreAmbianceDetailScreen extends StatelessWidget {
  final String label;
  final String hint;
  final String imageUrl;

  const ExploreAmbianceDetailScreen({
    super.key,
    required this.label,
    required this.hint,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final dark = context.oklMeetIsDark;
    final onTitle = dark ? Colors.white : context.oklOnSurface;
    final muted = dark
        ? Colors.white.withValues(alpha: 0.62)
        : context.oklOnSurfaceMuted(0.62);

    return Scaffold(
      backgroundColor: context.oklScaffold,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: context.oklScaffold,
            leading: IconButton(
              icon: Icon(LucideIcons.arrowLeft, color: onTitle),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    memCacheWidth: 900,
                    placeholder: (c, u) => Container(color: context.oklSurface),
                    errorWidget: (c, u, e) => Container(color: context.oklSurface),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.35),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.65),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          hint,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 14,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.paddingOf(context).bottom + 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ce qui se passe près de toi',
                    style: TextStyle(
                      color: onTitle,
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Les lieux et événements affichés dans Sorties sont mis en avant quand ils collent à cette ambiance. '
                    'Tu peux affiner avec les pastilles « Ton envie du moment ».',
                    style: TextStyle(color: muted, fontSize: 14, height: 1.45),
                  ),
                  const SizedBox(height: 20),
                  _AmbianceBullet(
                    icon: LucideIcons.mapPin,
                    text: 'Rayon par défaut autour de ta position — ajuste dans Rencontres si besoin.',
                  ),
                  _AmbianceBullet(
                    icon: LucideIcons.shield,
                    text: 'Privilégie les sorties certifiées Oklifor le soir.',
                  ),
                  _AmbianceBullet(
                    icon: LucideIcons.users,
                    text: 'Ouvre les profils avec la même envie pour coordonner un groupe.',
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => OklFlows.pushMatchingProfiles(
                        context,
                        headline: 'Même envie',
                        contextLabel:
                            'Membres ouverts à des plans proches de : $label. Envoie un message pour proposer un lieu ou un créneau.',
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: const Icon(LucideIcons.sparkles, size: 20),
                      label: const Text('Voir des profils avec la même envie'),
                    ),
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

class _AmbianceBullet extends StatelessWidget {
  final IconData icon;
  final String text;

  const _AmbianceBullet({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: context.oklOnSurfaceMuted(0.75),
                fontSize: 13.5,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Fiche rassemblement / groupe (Sorties).
class ExploreGatheringDetailScreen extends StatelessWidget {
  final String title;
  final String subtitle;
  final int going;
  final String when;
  final String distance;
  final String imageUrl;

  const ExploreGatheringDetailScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.going,
    required this.when,
    required this.distance,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final dark = context.oklMeetIsDark;
    final onTitle = dark ? Colors.white : context.oklOnSurface;
    final muted = dark
        ? Colors.white.withValues(alpha: 0.62)
        : context.oklOnSurfaceMuted(0.62);

    return Scaffold(
      backgroundColor: context.oklScaffold,
      appBar: AppBar(
        backgroundColor: context.oklScaffold,
        title: Text(
          'Rassemblement',
          style: TextStyle(color: onTitle, fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: onTitle),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.paddingOf(context).bottom + 24),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: AspectRatio(
              aspectRatio: 16 / 10,
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                memCacheWidth: 900,
                placeholder: (c, u) => Container(color: context.oklSurface),
                errorWidget: (c, u, e) => Container(color: context.oklSurface),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: TextStyle(
              color: onTitle,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(color: muted, fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _GatherChip(icon: LucideIcons.users, label: '$going intéressé·e·s'),
              _GatherChip(icon: LucideIcons.clock, label: when),
              _GatherChip(icon: LucideIcons.navigation, label: distance),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Organisation',
            style: TextStyle(
              color: onTitle,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Le groupe fixe un point de rendez-vous et partage les trajets. Tu recevras un fil de discussion '
            'dès que la sortie sera confirmée.',
            style: TextStyle(color: muted, fontSize: 14, height: 1.45),
          ),
          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed: () {
              OklFlows.pushResult(
                context,
                icon: LucideIcons.userPlus,
                title: 'Demande envoyée',
                subtitle:
                    'Les organisateurs verront ton profil et pourront valider ta place dans le groupe.',
                bullets: const [
                  'Tu peux suivre l’état dans Messages.',
                  'Pense à compléter ta bio pour rassurer le groupe.',
                ],
                primaryLabel: 'Compris',
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: const Icon(LucideIcons.send, size: 20),
            label: const Text('Demander à rejoindre'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => OklFlows.pushMatchingProfiles(
              context,
              headline: 'Qui part ?',
              contextLabel:
                  'Aperçu des membres qui s’intéressent à « $title ». Écris à quelqu’un pour covoiturer.',
            ),
            icon: const Icon(LucideIcons.messageCircle, size: 20),
            label: const Text('Voir les participant·e·s'),
          ),
        ],
      ),
    );
  }
}

class _GatherChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _GatherChip({required this.icon, required this.label});

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
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: context.oklOnSurface,
              fontWeight: FontWeight.w600,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }
}
