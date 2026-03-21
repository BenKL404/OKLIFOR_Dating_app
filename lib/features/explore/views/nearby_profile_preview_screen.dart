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
  /// Créneau du plan (ex. « Sam. 15 h »).
  final String? slot;
  /// Libellés et CTA orientés « demande de participation ».
  final bool participationAsk;

  const NearbyProfilePreviewScreen({
    super.key,
    required this.name,
    required this.area,
    required this.vibe,
    required this.distance,
    required this.avatarUrl,
    this.slot,
    this.participationAsk = false,
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
          if (participationAsk)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.28)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.userPlus, size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Cherche des participant·e·s',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
          if (slot != null && slot!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.clock, size: 16, color: context.oklOnSurfaceMuted(0.55)),
                const SizedBox(width: 6),
                Text(
                  slot!,
                  style: TextStyle(
                    color: context.oklOnSurfaceMuted(0.72),
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
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
            onPressed: () => OklFeedback.snack(
              context,
              participationAsk
                  ? 'Tu proposes de participer au plan de $name (démo)'
                  : 'Message à $name (démo)',
            ),
            icon: Icon(
              participationAsk ? LucideIcons.userPlus : LucideIcons.messageCircle,
              size: 20,
            ),
            label: Text(participationAsk ? 'Proposer de participer' : 'Envoyer un message'),
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
