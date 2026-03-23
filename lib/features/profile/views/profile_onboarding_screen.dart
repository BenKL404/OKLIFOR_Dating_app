import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/api/oklifor_api_exception.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/utils/okl_feedback.dart';
import '../../auth/providers/auth_api_provider.dart';

/// Premier lancement après inscription : informations minimales avant l’accueil.
class ProfileOnboardingScreen extends ConsumerStatefulWidget {
  const ProfileOnboardingScreen({super.key});

  @override
  ConsumerState<ProfileOnboardingScreen> createState() =>
      _ProfileOnboardingScreenState();
}

class _ProfileOnboardingScreenState extends ConsumerState<ProfileOnboardingScreen> {
  final _name = TextEditingController();
  final _city = TextEditingController();
  final _bio = TextEditingController();
  final _languages = TextEditingController();
  String _goal = 'Relation sérieuse';
  bool _saving = false;

  static const _goals = [
    'Relation sérieuse',
    'Amitié & sorties',
    'Sans pression',
    'Je découvre',
  ];

  @override
  void dispose() {
    _name.dispose();
    _city.dispose();
    _bio.dispose();
    _languages.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    await ref.read(okliforApiClientProvider).logout();
    if (mounted) context.go('/login');
  }

  Future<void> _submit() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      OklFeedback.alert(
        context,
        title: 'Prénom ou pseudo',
        message: 'Indique comment tu veux apparaître sur Oklifor.',
      );
      return;
    }
    final city = _city.text.trim();
    if (city.isEmpty) {
      OklFeedback.alert(
        context,
        title: 'Ville',
        message: 'Indique au moins ta ville ou ton quartier.',
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final me = await ref.read(okliforApiClientProvider).patchMyProfile(
            displayName: name,
            city: city,
            bio: _bio.text.trim(),
            relationGoal: _goal,
            languages: _languages.text.trim(),
            profileOnboardingCompleted: true,
          );
      me.applyToLocalSessions();
      if (mounted) context.go('/discovery');
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

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: context.oklScaffold,
        appBar: AppBar(
          backgroundColor: context.oklScaffold,
          automaticallyImplyLeading: false,
          title: const Text(
            'Bienvenue sur Oklifor',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          actions: [
            TextButton(
              onPressed: _saving ? null : _logout,
              child: Text(
                'Déconnexion',
                style: TextStyle(
                  color: context.oklOnSurfaceMuted(0.65),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        body: ListView(
          padding: EdgeInsets.fromLTRB(20, 8, 20, 24 + MediaQuery.paddingOf(context).bottom),
          children: [
            Text(
              'Quelques infos pour que les autres te découvrent. Tu pourras tout modifier plus tard dans ton profil.',
              style: TextStyle(
                color: context.oklOnSurfaceMuted(0.68),
                fontSize: 15,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            _label(context, 'Comment t’appeler ?'),
            const SizedBox(height: 8),
            _field(
              context,
              controller: _name,
              hint: 'Prénom ou pseudo',
              icon: LucideIcons.user,
            ),
            const SizedBox(height: 20),
            _label(context, 'Où habites-tu ?'),
            const SizedBox(height: 8),
            _field(
              context,
              controller: _city,
              hint: 'Ville ou quartier',
              icon: LucideIcons.mapPin,
            ),
            const SizedBox(height: 20),
            _label(context, 'À propos de toi (optionnel)'),
            const SizedBox(height: 8),
            TextField(
              controller: _bio,
              maxLines: 4,
              maxLength: 500,
              enabled: !_saving,
              style: TextStyle(color: context.oklOnSurface, height: 1.35),
              decoration: InputDecoration(
                hintText: 'Quelques lignes sur toi…',
                hintStyle: TextStyle(color: context.oklOnSurfaceMuted(0.5)),
                filled: true,
                fillColor: context.oklSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 20),
            _label(context, 'Tu cherches quoi ici ?'),
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
            const SizedBox(height: 20),
            _label(context, 'Langues (optionnel)'),
            const SizedBox(height: 8),
            _field(
              context,
              controller: _languages,
              hint: 'Ex. Français, Ewe',
              icon: LucideIcons.languages,
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _saving ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                    )
                  : const Text('Continuer', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(BuildContext context, String t) {
    return Text(
      t,
      style: TextStyle(
        color: context.oklOnSurfaceMuted(0.55),
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
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
      enabled: !_saving,
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
