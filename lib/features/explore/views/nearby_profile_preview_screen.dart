import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/widgets/okl_app_bar_icon_button.dart';
import '../../../core/utils/okl_feedback.dart';

class NearbyProfilePreviewScreen extends StatelessWidget {
  final String name;
  final String area;
  final String vibe;
  final String distance;
  final String avatarUrl;

  const NearbyProfilePreviewScreen({
    super.key,
    required this.name,
    required this.area,
    required this.vibe,
    required this.distance,
    required this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.oklScaffold,
      appBar: AppBar(
        backgroundColor: context.oklScaffold,
        leading: const OklAppBarBackButton(rootNavigator: true),
        automaticallyImplyLeading: false,
        title: Text(name),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          Center(
            child: ClipOval(
              child: CachedNetworkImage(
                imageUrl: avatarUrl,
                width: 120,
                height: 120,
                fit: BoxFit.cover,
                memCacheWidth: 240,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            name,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.oklOnSurface,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.mapPin, size: 16, color: context.oklOnSurfaceMuted(0.55)),
              const SizedBox(width: 6),
              Text(area, style: TextStyle(color: context.oklOnSurfaceMuted(0.62))),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            distance,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: context.oklSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: context.oklDivider),
            ),
            child: Text(
              vibe,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.oklOnSurfaceMuted(0.72),
                fontSize: 15,
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => OklFeedback.snack(context, 'Message à $name (démo)'),
            icon: const Icon(LucideIcons.messageCircle, size: 20),
            label: const Text('Envoyer un message'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () => OklFeedback.snack(context, 'Profil masqué pour cette session (démo)'),
            child: const Text('Pas intéressé'),
          ),
        ],
      ),
    );
  }
}
