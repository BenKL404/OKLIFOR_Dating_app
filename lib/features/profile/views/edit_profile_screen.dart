import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/api/oklifor_api_exception.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/widgets/okl_app_bar_icon_button.dart';
import '../../../core/utils/okl_feedback.dart';
import '../../../core/utils/okl_image_crop.dart';
import '../../../core/utils/okl_pick_media_permissions.dart';
import '../../auth/providers/auth_api_provider.dart';
import '../models/user_profile.dart';

/// Édition du profil : texte + photo de couverture et avatar (upload API).
class EditProfileScreen extends ConsumerStatefulWidget {
  final UserProfile initial;

  const EditProfileScreen({super.key, required this.initial});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late final TextEditingController _name;
  late final TextEditingController _city;
  late final TextEditingController _bio;
  late final TextEditingController _languages;
  late final TextEditingController _ethnicity;
  late final TextEditingController _lifestyle;
  late final TextEditingController _profession;
  late final TextEditingController _education;
  late String _goal;

  Uint8List? _coverBytes;
  String _coverFilename = 'cover.jpg';
  Uint8List? _avatarBytes;
  String _avatarFilename = 'avatar.jpg';
  bool _saving = false;

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
    _ethnicity = TextEditingController(text: p.ethnicity);
    _lifestyle = TextEditingController(text: p.lifestyle);
    _profession = TextEditingController(text: p.profession);
    _education = TextEditingController(text: p.education);
    _goal = _goals.contains(p.relationGoal) ? p.relationGoal : _goals.first;
  }

  @override
  void dispose() {
    _name.dispose();
    _city.dispose();
    _bio.dispose();
    _languages.dispose();
    _ethnicity.dispose();
    _lifestyle.dispose();
    _profession.dispose();
    _education.dispose();
    super.dispose();
  }

  Future<ImageSource?> _pickImageSource() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: context.oklSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(LucideIcons.camera, color: ctx.oklOnSurface),
              title: Text('Prendre une photo', style: TextStyle(color: ctx.oklOnSurface)),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: Icon(LucideIcons.image, color: ctx.oklOnSurface),
              title: Text('Galerie', style: TextStyle(color: ctx.oklOnSurface)),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickCover() async {
    final source = await _pickImageSource();
    if (source == null || !mounted) return;
    if (!await OklPickMediaPermissions.ensureImageSource(context, source)) return;
    final x = await ImagePicker().pickImage(
      source: source,
      maxWidth: 2400,
      imageQuality: 88,
    );
    if (x == null || !mounted) return;
    final bytes = await cropPickedImageIfPossible(
      context: context,
      xFile: x,
      kind: OklImageCropKind.profileCover,
    );
    if (bytes == null || !mounted) return;
    setState(() {
      _coverBytes = bytes;
      _coverFilename = 'cover.jpg';
    });
  }

  Future<void> _pickAvatar() async {
    final source = await _pickImageSource();
    if (source == null || !mounted) return;
    if (!await OklPickMediaPermissions.ensureImageSource(context, source)) return;
    final x = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1200,
      imageQuality: 90,
    );
    if (x == null || !mounted) return;
    final bytes = await cropPickedImageIfPossible(
      context: context,
      xFile: x,
      kind: OklImageCropKind.profileAvatar,
    );
    if (bytes == null || !mounted) return;
    setState(() {
      _avatarBytes = bytes;
      _avatarFilename = 'avatar.jpg';
    });
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      OklFeedback.alert(
        context,
        title: 'Profil incomplet',
        message: 'Indique au moins un prénom ou un pseudo.',
      );
      return;
    }
    final city = _city.text.trim().isEmpty ? widget.initial.city : _city.text.trim();
    final bio = _bio.text.trim();
    final languages = _languages.text.trim();

    setState(() => _saving = true);
    try {
      final me = await ref.read(okliforApiClientProvider).uploadMyProfileFull(
            displayName: name,
            city: city,
            bio: bio,
            relationGoal: _goal,
            languages: languages,
            ethnicity: _ethnicity.text.trim(),
            lifestyle: _lifestyle.text.trim(),
            profession: _profession.text.trim(),
            education: _education.text.trim(),
            avatarBytes: _avatarBytes,
            avatarFilename: _avatarFilename,
            coverBytes: _coverBytes,
            coverFilename: _coverFilename,
          );
      me.applyToLocalSessions();
      if (mounted) Navigator.pop(context, me.toUserProfile());
    } on OkliforApiException catch (e) {
      if (mounted) {
        OklFeedback.alert(context, title: 'Enregistrement impossible', message: e.message);
      }
    } catch (e) {
      if (mounted) {
        OklFeedback.alert(context, title: 'Erreur', message: '$e');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _coverChild(UserProfile p) {
    if (_coverBytes != null) {
      return Image.memory(
        _coverBytes!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }
    final u = p.coverUrlForDisplay;
    if (u.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: u,
        fit: BoxFit.cover,
        memCacheWidth: 900,
        placeholder: (c, _) => Container(color: c.oklSurface),
        errorWidget: (c, _, _) => Container(color: c.oklSurface),
      );
    }
    return Container(
      color: context.oklSurface,
      alignment: Alignment.center,
      child: Icon(LucideIcons.image, color: context.oklOnSurfaceMuted(0.35), size: 48),
    );
  }

  Widget _avatarChild(UserProfile p) {
    if (_avatarBytes != null) {
      return Image.memory(
        _avatarBytes!,
        width: 96,
        height: 96,
        fit: BoxFit.cover,
      );
    }
    final u = p.avatarUrlForDisplay;
    if (u.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: u,
        width: 96,
        height: 96,
        fit: BoxFit.cover,
        memCacheWidth: 192,
      );
    }
    return Icon(LucideIcons.user, color: context.oklOnSurfaceMuted(0.35), size: 40);
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
            onPressed: _saving ? null : _save,
            child: _saving
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: AppColors.primary,
                    ),
                  )
                : const Text(
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
          // Hauteur explicite : l’avatar chevauchait la zone 16:9 avec bottom négatif, donc les taps
          // sur le badge « photo de profil » sortaient du hitTest du Stack (seule la couverture réagissait).
          LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final coverH = w * 9 / 16;
              const avatarBand = 56.0;
              return SizedBox(
                height: coverH + avatarBand,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: coverH,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            _coverChild(p),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      right: 10,
                      top: coverH - 42,
                      child: Material(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          onTap: _saving ? null : _pickCover,
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
                      top: coverH - 51,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _saving ? null : _pickAvatar,
                              customBorder: const CircleBorder(),
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: context.oklScaffold,
                                  border: Border.all(color: context.oklDivider, width: 2),
                                ),
                                child: CircleAvatar(
                                  radius: 48,
                                  backgroundColor: context.oklSurface,
                                  child: ClipOval(child: _avatarChild(p)),
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
                                onTap: _saving ? null : _pickAvatar,
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
              );
            },
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
            maxLength: 2000,
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
                  onTap: _saving ? null : () => setState(() => _goal = g),
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
          const SizedBox(height: 22),
          _sectionLabel(context, 'Origines & communautés'),
          const SizedBox(height: 8),
          _field(
            context,
            controller: _ethnicity,
            hint: 'Optionnel — ex. région, diaspora',
            icon: LucideIcons.globe,
            maxLength: 120,
          ),
          const SizedBox(height: 22),
          _sectionLabel(context, 'Mode de vie'),
          const SizedBox(height: 8),
          _field(
            context,
            controller: _lifestyle,
            hint: 'Rythme, sorties, sport…',
            icon: LucideIcons.sun,
            maxLength: 200,
          ),
          const SizedBox(height: 22),
          _sectionLabel(context, 'Travail & formation'),
          const SizedBox(height: 8),
          _field(
            context,
            controller: _profession,
            hint: 'Métier ou activité principale',
            icon: LucideIcons.briefcase,
            maxLength: 120,
          ),
          const SizedBox(height: 12),
          _field(
            context,
            controller: _education,
            hint: 'Formation ou parcours',
            icon: LucideIcons.graduationCap,
            maxLength: 120,
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
                    'Les textes et les nouvelles photos sont envoyés au serveur. '
                    'Les images sont visibles publiquement via ton profil (JPEG, PNG ou WebP). '
                    'La vérification d’identité reste dans Paramètres → Vérification.',
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
    int? maxLength,
  }) {
    return TextField(
      controller: controller,
      enabled: !_saving,
      maxLength: maxLength,
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
        counterText: maxLength != null ? '' : null,
      ),
    );
  }
}
