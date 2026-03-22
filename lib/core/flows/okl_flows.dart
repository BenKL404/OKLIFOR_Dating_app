import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../constants/app_colors.dart';
import '../theme/theme_extensions.dart';

/// Profils fictifs pour les écrans « même envie » / démos Sorties.
class OklFlowDemoPerson {
  final String name;
  final int age;
  final String area;
  final String imageUrl;
  final String tagline;

  const OklFlowDemoPerson({
    required this.name,
    required this.age,
    required this.area,
    required this.imageUrl,
    required this.tagline,
  });
}

const kOklFlowDemoPeople = <OklFlowDemoPerson>[
  OklFlowDemoPerson(
    name: 'Afi',
    age: 24,
    area: 'Agoè',
    imageUrl:
        'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400&q=80&auto=format&fit=crop',
    tagline: 'Soirée & danse',
  ),
  OklFlowDemoPerson(
    name: 'Kofi',
    age: 27,
    area: 'Kégué',
    imageUrl:
        'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&q=80&auto=format&fit=crop',
    tagline: 'Afterwork & jazz',
  ),
  OklFlowDemoPerson(
    name: 'Mawuli',
    age: 25,
    area: 'Bè',
    imageUrl:
        'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=400&q=80&auto=format&fit=crop',
    tagline: 'Club & nouvelles têtes',
  ),
  OklFlowDemoPerson(
    name: 'Sena',
    age: 23,
    area: 'Tokoin',
    imageUrl:
        'https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e?w=400&q=80&auto=format&fit=crop',
    tagline: 'Apéro & conversation',
  ),
];

/// Écrans riches de remplacement des toasts « démo » (navigation root).
class OklFlows {
  OklFlows._();

  static NavigatorState _rootNav(BuildContext context) =>
      Navigator.of(context, rootNavigator: true);

  static Future<void> pushResult(
    BuildContext context, {
    required IconData icon,
    Color? iconColor,
    Color? iconBackground,
    required String title,
    String? subtitle,
    List<String> bullets = const [],
    String primaryLabel = 'Fermer',
    IconData? primaryIcon,
  }) {
    return _rootNav(context).push<void>(
      MaterialPageRoute<void>(
        builder: (ctx) => OklFlowResultScreen(
          icon: icon,
          iconColor: iconColor ?? AppColors.primary,
          iconBackground: iconBackground,
          title: title,
          subtitle: subtitle,
          bullets: bullets,
          primaryLabel: primaryLabel,
          primaryIcon: primaryIcon,
        ),
      ),
    );
  }

  static Future<void> pushMap(
    BuildContext context, {
    required String placeTitle,
    required String locality,
    String? etaHint,
  }) {
    return _rootNav(context).push<void>(
      MaterialPageRoute<void>(
        builder: (ctx) => OklMapDirectionsScreen(
          placeTitle: placeTitle,
          locality: locality,
          etaHint: etaHint ?? 'Estimation trajet : 8–15 min en voiture (démo)',
        ),
      ),
    );
  }

  static Future<void> pushMatchingProfiles(
    BuildContext context, {
    required String headline,
    required String contextLabel,
    List<OklFlowDemoPerson> people = kOklFlowDemoPeople,
  }) {
    return _rootNav(context).push<void>(
      MaterialPageRoute<void>(
        builder: (ctx) => OklMatchingProfilesScreen(
          headline: headline,
          contextLabel: contextLabel,
          people: people,
        ),
      ),
    );
  }

  static Future<void> pushOutgoingCall(
    BuildContext context, {
    required String contactName,
    String? avatarUrl,
    bool video = false,
  }) {
    return _rootNav(context).push<void>(
      MaterialPageRoute<void>(
        builder: (ctx) => OklOutgoingCallScreen(
          contactName: contactName,
          avatarUrl: avatarUrl,
          video: video,
        ),
      ),
    );
  }

  static Future<void> pushNotificationDetail(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
    List<String> actions = const [],
  }) {
    return _rootNav(context).push<void>(
      MaterialPageRoute<void>(
        builder: (ctx) => OklNotificationDetailScreen(
          icon: icon,
          title: title,
          subtitle: subtitle,
          time: time,
          actions: actions,
        ),
      ),
    );
  }

  static Future<void> pushLiveViewer(
    BuildContext context, {
    required String hostName,
    required String imageUrl,
  }) {
    return _rootNav(context).push<void>(
      MaterialPageRoute<void>(
        builder: (ctx) => OklLiveViewerScreen(
          hostName: hostName,
          imageUrl: imageUrl,
        ),
      ),
    );
  }
}

class OklFlowResultScreen extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color? iconBackground;
  final String title;
  final String? subtitle;
  final List<String> bullets;
  final String primaryLabel;
  final IconData? primaryIcon;

  const OklFlowResultScreen({
    super.key,
    required this.icon,
    required this.iconColor,
    this.iconBackground,
    required this.title,
    this.subtitle,
    this.bullets = const [],
    this.primaryLabel = 'Fermer',
    this.primaryIcon,
  });

  @override
  Widget build(BuildContext context) {
    final bg = iconBackground ?? AppColors.primary.withValues(alpha: 0.12);
    return Scaffold(
      backgroundColor: context.oklScaffold,
      appBar: AppBar(
        backgroundColor: context.oklScaffold,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.x, color: context.oklOnSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            children: [
              const Spacer(flex: 1),
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: bg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 40, color: iconColor),
              ),
              const SizedBox(height: 28),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: context.oklOnSurface,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
              if (subtitle != null && subtitle!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  subtitle!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: context.oklOnSurfaceMuted(0.62),
                    fontSize: 15,
                    height: 1.45,
                  ),
                ),
              ],
              if (bullets.isNotEmpty) ...[
                const SizedBox(height: 24),
                ...bullets.map(
                  (b) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(LucideIcons.check, size: 18, color: AppColors.primary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            b,
                            style: TextStyle(
                              color: context.oklOnSurfaceMuted(0.78),
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const Spacer(flex: 2),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => Navigator.pop(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: Icon(primaryIcon ?? LucideIcons.check, size: 20),
                  label: Text(primaryLabel, style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OklMapDirectionsScreen extends StatelessWidget {
  final String placeTitle;
  final String locality;
  final String etaHint;

  const OklMapDirectionsScreen({
    super.key,
    required this.placeTitle,
    required this.locality,
    required this.etaHint,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: context.oklScaffold,
      appBar: AppBar(
        backgroundColor: context.oklScaffold,
        title: Text(
          'Itinéraire',
          style: TextStyle(
            color: context.oklOnSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: context.oklOnSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.paddingOf(context).bottom + 24),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: AspectRatio(
              aspectRatio: 16 / 11,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: dark
                        ? [
                            const Color(0xFF1a2744),
                            const Color(0xFF0d1526),
                          ]
                        : [
                            const Color(0xFFE8EEF5),
                            const Color(0xFFD4DDE8),
                          ],
                  ),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CustomPaint(painter: _MapGridPainter(dark: dark)),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.mapPin, size: 48, color: AppColors.primary),
                          const SizedBox(height: 8),
                          Text(
                            placeTitle,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: dark ? Colors.white : context.oklOnSurface,
                              fontWeight: FontWeight.w800,
                              fontSize: 17,
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
          const SizedBox(height: 20),
          Text(
            locality,
            style: TextStyle(
              color: context.oklOnSurfaceMuted(0.62),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            etaHint,
            style: TextStyle(
              color: context.oklOnSurface,
              fontSize: 15,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          _MapInfoTile(
            icon: LucideIcons.navigation,
            title: 'Lancer la navigation',
            subtitle: 'Ouvre ton app Plans ou Google Maps avec ce point d’arrivée.',
          ),
          const SizedBox(height: 10),
          _MapInfoTile(
            icon: LucideIcons.users,
            title: 'Partager le lieu',
            subtitle: 'Envoie un lien ou un point de rendez-vous à ton groupe.',
          ),
        ],
      ),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  final bool dark;

  _MapGridPainter({required this.dark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (dark ? Colors.white : Colors.black).withValues(alpha: 0.06)
      ..strokeWidth = 1;
    const step = 32.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MapInfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _MapInfoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.oklSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.oklDivider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
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
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: context.oklOnSurfaceMuted(0.62),
                    fontSize: 13,
                    height: 1.35,
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

class OklMatchingProfilesScreen extends StatelessWidget {
  final String headline;
  final String contextLabel;
  final List<OklFlowDemoPerson> people;

  const OklMatchingProfilesScreen({
    super.key,
    required this.headline,
    required this.contextLabel,
    required this.people,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.oklScaffold,
      appBar: AppBar(
        backgroundColor: context.oklScaffold,
        title: Text(
          headline,
          style: TextStyle(
            color: context.oklOnSurface,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: context.oklOnSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.paddingOf(context).bottom + 24),
        children: [
          Text(
            contextLabel,
            style: TextStyle(
              color: context.oklOnSurfaceMuted(0.62),
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          ...people.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Material(
                color: context.oklSurface,
                borderRadius: BorderRadius.circular(16),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => Navigator.pop(context),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: CachedNetworkImage(
                            imageUrl: p.imageUrl,
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
                              child: Icon(LucideIcons.user, color: context.oklOnSurfaceMuted(0.4)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${p.name}, ${p.age}',
                                style: TextStyle(
                                  color: context.oklOnSurface,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                p.area,
                                style: TextStyle(
                                  color: context.oklOnSurfaceMuted(0.55),
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                p.tagline,
                                style: TextStyle(
                                  color: context.oklOnSurfaceMuted(0.72),
                                  fontSize: 12.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(LucideIcons.chevronRight, color: context.oklOnSurfaceMuted(0.45)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OklOutgoingCallScreen extends StatefulWidget {
  final String contactName;
  final String? avatarUrl;
  final bool video;

  const OklOutgoingCallScreen({
    super.key,
    required this.contactName,
    this.avatarUrl,
    this.video = false,
  });

  @override
  State<OklOutgoingCallScreen> createState() => _OklOutgoingCallScreenState();
}

class _OklOutgoingCallScreenState extends State<OklOutgoingCallScreen> {
  @override
  Widget build(BuildContext context) {
    final url = widget.avatarUrl;
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F14),
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: const Icon(LucideIcons.chevronDown, color: Colors.white70),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            const Spacer(),
            if (url != null && url.isNotEmpty)
              ClipOval(
                child: CachedNetworkImage(
                  imageUrl: url,
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                  memCacheWidth: 240,
                  placeholder: (c, u) => Container(
                    width: 120,
                    height: 120,
                    color: Colors.white12,
                  ),
                  errorWidget: (c, u, e) => Container(
                    width: 120,
                    height: 120,
                    color: Colors.white12,
                    child: const Icon(LucideIcons.user, color: Colors.white54, size: 48),
                  ),
                ),
              )
            else
              Container(
                width: 120,
                height: 120,
                decoration: const BoxDecoration(
                  color: Colors.white12,
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.user, color: Colors.white54, size: 48),
              ),
            const SizedBox(height: 24),
            Text(
              widget.contactName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.video ? 'Appel vidéo…' : 'Appel vocal…',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.65),
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Connexion sécurisée Oklifor (simulation)',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 12,
              ),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _CallCircleButton(
                  icon: LucideIcons.micOff,
                  label: 'Mute',
                  onTap: () {},
                ),
                const SizedBox(width: 28),
                _CallCircleButton(
                  icon: LucideIcons.phoneOff,
                  label: 'Raccrocher',
                  onTap: () => Navigator.pop(context),
                  destructive: true,
                ),
              ],
            ),
            SizedBox(height: MediaQuery.paddingOf(context).bottom + 32),
          ],
        ),
      ),
    );
  }
}

class _CallCircleButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  const _CallCircleButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = destructive ? AppColors.togoRed : Colors.white24;
    return Column(
      children: [
        Material(
          color: bg,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Icon(icon, color: Colors.white, size: 26),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class OklNotificationDetailScreen extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String time;
  final List<String> actions;

  const OklNotificationDetailScreen({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.time,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.oklScaffold,
      appBar: AppBar(
        backgroundColor: context.oklScaffold,
        title: const Text('Notification'),
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: context.oklOnSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.paddingOf(context).bottom + 24),
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: context.oklOnSurface,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      time,
                      style: TextStyle(
                        color: context.oklOnSurfaceMuted(0.5),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            subtitle,
            style: TextStyle(
              color: context.oklOnSurfaceMuted(0.78),
              fontSize: 15,
              height: 1.45,
            ),
          ),
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 28),
            Text(
              'Actions',
              style: TextStyle(
                color: context.oklOnSurface,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            for (final a in actions)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: context.oklSurface,
                  borderRadius: BorderRadius.circular(12),
                  child: ListTile(
                    title: Text(
                      a,
                      style: TextStyle(
                        color: context.oklOnSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    trailing: Icon(LucideIcons.chevronRight, color: context.oklOnSurfaceMuted(0.45)),
                    onTap: () => Navigator.pop(context),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class OklLiveViewerScreen extends StatelessWidget {
  final String hostName;
  final String imageUrl;

  const OklLiveViewerScreen({
    super.key,
    required this.hostName,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            memCacheWidth: 1080,
            placeholder: (c, u) => Container(color: const Color(0xFF111111)),
            errorWidget: (c, u, e) => Container(
              color: const Color(0xFF111111),
              child: const Center(
                child: Icon(LucideIcons.video, color: Colors.white24, size: 64),
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.55),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.7),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(LucideIcons.x, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.togoRed,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Row(
                          children: [
                            Icon(LucideIcons.radio, color: Colors.white, size: 14),
                            SizedBox(width: 6),
                            Text(
                              'LIVE',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hostName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Tu regardes un direct Oklifor (démo). Les lives réels arriveront avec la sortie publique.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.82),
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () => Navigator.pop(context),
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                              ),
                              icon: const Icon(LucideIcons.heart, size: 18),
                              label: const Text('Réagir'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white54),
                              ),
                              icon: const Icon(LucideIcons.messageCircle, size: 18),
                              label: const Text('Message'),
                            ),
                          ),
                        ],
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
  }
}
