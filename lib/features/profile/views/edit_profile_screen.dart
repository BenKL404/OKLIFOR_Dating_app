import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/widgets/okl_app_bar_icon_button.dart';
import '../../../core/flows/okl_flows.dart';
import '../../../core/utils/okl_feedback.dart';
import '../models/user_profile.dart';

/// Édition riche du profil (démo) : visuels, texte, intention, langues.
class EditProfileScreen extends StatefulWidget {
  final UserProfile initial;

  const EditProfileScreen({super.key, required this.initial});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _name;
  late final TextEditingController _city;
  late final TextEditingController _bio;
  late final TextEditingController _languages;
  late String _goal;

  static const _goals = [
    'Relation sérieuse',
    'Amitié & sorties',
    'Sans pression',
    'Je découvre',
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.initial;
    _name = TextEditingController(text: p.displayName);
    _city = TextEditingController(text: p.city);
    _bio = TextEditingController(text: p.bio);
    _languages = TextEditingController(text: p.languages);
    _goal = _goals.contains(p.relationGoal) ? p.relationGoal : _goals.first;
  }

  @override
  void dispose() {
    _name.dispose();
    _city.dispose();
    _bio.dispose();
    _languages.dispose();
    super.dispose();
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) {
      OklFeedback.alert(
        context,
        title: 'Profil incomplet',
        message: 'Indique au moins un prénom ou un pseudo.',
      );
      return;
    }
    final updated = widget.initial.copyWith(
      displayName: name,
      city: _city.text.trim().isEmpty ? widget.initial.city : _city.text.trim(),
      bio: _bio.text.trim(),
      relationGoal: _goal,
      languages: _languages.text.trim(),
    );
    ProfileSession.set(updated);
    Navigator.pop(context, updated);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.initial;
    return Scaffold(
      backgroundColor: context.oklScaffold,
      appBar: AppBar(
        backgroundColor: context.oklScaffold,
        leading: const OklAppBarBackButton(),
        automaticallyImplyLeading: false,
        title: const Text('Modifier le profil'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text(
              'Enregistrer',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: CachedNetworkImage(
                    imageUrl: p.coverUrl,
                    fit: BoxFit.cover,
                    memCacheWidth: 900,
                    placeholder: (c, u) => Container(color: c.oklSurface),
                  ),
                ),
              ),
              Positioned(
                right: 10,
                bottom: 10,
                child: Material(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    onTap: () => OklFlows.pushResult(
                      context,
                      icon: LucideIcons.image,
                      title: 'Photo de couverture',
                      subtitle:
                          'Depuis la version complète, tu pourras choisir une image dans ta galerie ou Unsplash. Ici c’est une démo visuelle.',
                      primaryLabel: 'OK',
                    ),
                    borderRadius: BorderRadius.circular(10),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.camera, color: Colors.white, size: 16),
                          SizedBox(width: 6),
                          Text(
                            'Couverture',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 16,
                bottom: -36,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: context.oklScaffold,
                        border: Border.all(color: context.oklDivider, width: 2),
                      ),
                      child: CircleAvatar(
                        radius: 48,
                        backgroundColor: context.oklSurface,
                        child: ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: p.avatarUrl,
                            width: 96,
                            height: 96,
                            fit: BoxFit.cover,
                            memCacheWidth: 192,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Material(
                        color: AppColors.primary,
                        shape: const CircleBorder(),
                        child: InkWell(
                          onTap: () => OklFlows.pushResult(
                            context,
                            icon: LucideIcons.user,
                            title: 'Photo de profil',
                            subtitle:
                                'Tu pourras recadrer et valider une photo nette du visage. Simulation pour l’instant.',
                            primaryLabel: 'Compris',
                          ),
                          customBorder: const CircleBorder(),
                          child: const Padding(
                            padding: EdgeInsets.all(8),
                            child: Icon(
                              LucideIcons.camera,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 52),
          _sectionLabel(context, 'Identité affichée'),
          const SizedBox(height: 8),
          _field(
            context,
            controller: _name,
            hint: 'Prénom ou pseudo',
            icon: LucideIcons.user,
          ),
          const SizedBox(height: 12),
          _field(
            context,
            controller: _city,
            hint: 'Ville, quartier',
            icon: LucideIcons.mapPin,
          ),
          const SizedBox(height: 22),
          _sectionLabel(context, 'À propos de toi'),
          const SizedBox(height: 8),
          TextField(
            controller: _bio,
            maxLines: 5,
            maxLength: 500,
            style: TextStyle(color: context.oklOnSurface, height: 1.4),
            decoration: InputDecoration(
              hintText: 'Bio, centres d’intérêt, ce que tu cherches…',
              hintStyle: TextStyle(
                color: context.oklOnSurfaceMuted(0.62).withValues(alpha: 0.85),
              ),
              filled: true,
              fillColor: context.oklSurface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 22),
          _sectionLabel(context, 'Intention sur Oklifor'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _goals.map((g) {
              final sel = g == _goal;
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => setState(() => _goal = g),
                  borderRadius: BorderRadius.circular(999),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: sel ? AppColors.primary.withValues(alpha: 0.22) : context.oklSurface,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: sel ? AppColors.primary : context.oklDivider,
                        width: sel ? 1.5 : 1,
                      ),
                    ),
                    child: Text(
                      g,
                      style: TextStyle(
                        color: sel ? context.oklOnSurface : context.oklOnSurfaceMuted(0.62),
                        fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 22),
          _sectionLabel(context, 'Langues parlées'),
          const SizedBox(height: 8),
          _field(
            context,
            controller: _languages,
            hint: 'Ex. Français, Ewe, English',
            icon: LucideIcons.languages,
          ),
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: context.oklSurface,
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
                    'Les modifications sont enregistrées sur cet appareil (démo). '
                    'La vérification du compte se fait depuis Paramètres → Vérification et certificat.',
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
        ],
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String t) {
    return Text(
      t,
      style: TextStyle(
        color: context.oklOnSurfaceMuted(0.55),
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _field(
    BuildContext context, {
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      style: TextStyle(color: context.oklOnSurface),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: context.oklOnSurfaceMuted(0.62).withValues(alpha: 0.85)),
        prefixIcon: Icon(icon, color: context.oklOnSurfaceMuted(0.62), size: 18),
        filled: true,
        fillColor: context.oklSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      ),
    );
  }
}
