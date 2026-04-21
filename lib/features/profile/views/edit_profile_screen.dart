import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/api/oklifor_api_exception.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/utils/okl_feedback.dart';
import '../../../core/utils/okl_image_crop.dart';
import '../../../core/utils/okl_pick_media_permissions.dart';
import '../../../core/widgets/okl_app_bar_icon_button.dart';
import '../../auth/providers/auth_api_provider.dart';
import '../models/user_profile.dart';

/// Édition riche du profil : visuels, texte, intention, langues.
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
  late String _goal;

  // Picked images (local preview)
  Uint8List? _avatarBytes;
  String _avatarFilename = 'avatar.jpg';
  Uint8List? _coverBytes;
  String _coverFilename = 'cover.jpg';

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

  // ──────────────────────────────────────────
  // Image picking
  // ──────────────────────────────────────────

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

  // ──────────────────────────────────────────
  // Save
  // ──────────────────────────────────────────

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

    setState(() => _saving = true);
    try {
      final p = widget.initial;
      final me = await ref.read(okliforApiClientProvider).uploadMyProfileFull(
            displayName: name,
            city: _city.text.trim().isEmpty ? p.city : _city.text.trim(),
            bio: _bio.text.trim(),
            relationGoal: _goal,
            languages: _languages.text.trim(),
            ethnicity: p.ethnicity,
            lifestyle: p.lifestyle,
            profession: p.profession,
            education: p.education,
            avatarBytes: _avatarBytes,
            avatarFilename: _avatarBytes != null ? _avatarFilename : null,
            coverBytes: _coverBytes,
            coverFilename: _coverBytes != null ? _coverFilename : null,
          );

      if (!mounted) return;
      me.applyToLocalSessions(); // rafraîchit ProfileSession
      Navigator.pop(context, ProfileSession.profile.value);
    } on OkliforApiException catch (e) {
      if (mounted) {
        OklFeedback.alert(context, title: 'Envoi impossible', message: e.message);
      }
    } catch (e) {
      if (mounted) {
        OklFeedback.alert(context, title: 'Envoi impossible', message: '$e');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ──────────────────────────────────────────
  // Build
  // ──────────────────────────────────────────

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
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _saving
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: AppColors.primary,
                      ),
                    ),
                  )
                : TextButton(
                    onPressed: _save,
                    child: const Text(
                      'Enregistrer',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
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
              // ── Invisible spacer to ensure hit testing on overlapping avatar ──
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AspectRatio(aspectRatio: 16 / 9, child: SizedBox.shrink()),
                  const SizedBox(height: 36),
                ],
              ),
              // ── Cover ──
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: _coverBytes != null
                      ? Image.memory(
                          _coverBytes!,
                          fit: BoxFit.cover,
                        )
                      : CachedNetworkImage(
                          imageUrl: p.coverUrlForDisplay,
                          fit: BoxFit.cover,
                          memCacheWidth: 900,
                          placeholder: (c, u) => Container(color: c.oklSurface),
                        ),
                ),
              ),
              // ── Cover button ──
              Positioned(
                right: 10,
                bottom: 10 + 36, // relative to new Stack bottom
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
              // ── Avatar ──
              Positioned(
                left: 16,
                bottom: 0, // correctly aligned with the new Stack bottom
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
                          child: _avatarBytes != null
                              ? Image.memory(
                                  _avatarBytes!,
                                  width: 96,
                                  height: 96,
                                  fit: BoxFit.cover,
                                )
                              : CachedNetworkImage(
                                  imageUrl: p.avatarUrlForDisplay,
                                  width: 96,
                                  height: 96,
                                  fit: BoxFit.cover,
                                  memCacheWidth: 192,
                                ),
                        ),
                      ),
                    ),
                    // ── Avatar button ──
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
          const SizedBox(height: 16), // Sized down because Stack carries 36px overlap now
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
              hintText: 'Bio, centres d\u2019intérêt, ce que tu cherches…',
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
          // Info row: upload notice
          if (_avatarBytes != null || _coverBytes != null)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.uploadCloud, size: 18, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Nouvelles images prêtes. Appuie sur Enregistrer pour les envoyer.',
                      style: TextStyle(
                        color: AppColors.primary.withValues(alpha: 0.9),
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