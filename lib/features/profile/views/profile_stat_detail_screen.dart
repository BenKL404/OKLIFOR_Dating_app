import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/widgets/okl_app_bar_icon_button.dart';

/// Détail synthétique pour une stat du profil (vues, likes, etc.).
class ProfileStatDetailScreen extends StatelessWidget {
  final String title;
  final String value;
  final String? hint;

  const ProfileStatDetailScreen({
    super.key,
    required this.title,
    required this.value,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.oklScaffold,
      appBar: AppBar(
        backgroundColor: context.oklScaffold,
        leading: const OklAppBarBackButton(rootNavigator: true),
        automaticallyImplyLeading: false,
        title: Text(title),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        children: [
          Text(
            value,
            style: TextStyle(
              color: context.oklOnSurface,
              fontSize: 42,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hint ??
                'Données agrégées sur les 7 derniers jours. Bientôt : graphique et liste des visites.',
            style: TextStyle(
              color: context.oklOnSurfaceMuted(0.62),
              height: 1.45,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.oklSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: context.oklDivider),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.trendingUp, color: AppColors.primary, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Ta visibilité progresse : continue à compléter ton profil et à publier des statuts.',
                    style: TextStyle(color: context.oklOnSurfaceMuted(0.72), height: 1.35),
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
