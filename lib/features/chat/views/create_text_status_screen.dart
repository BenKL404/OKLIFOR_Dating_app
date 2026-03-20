import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/widgets/okl_app_bar_icon_button.dart';

/// Résultat publié vers la liste des statuts.
class TextStatusPublishResult {
  final String text;
  final Color backgroundColor;

  const TextStatusPublishResult({
    required this.text,
    required this.backgroundColor,
  });
}

/// Création d'un statut texte (fond coloré, aperçu, publication démo).
class CreateTextStatusScreen extends StatefulWidget {
  const CreateTextStatusScreen({super.key});

  @override
  State<CreateTextStatusScreen> createState() => _CreateTextStatusScreenState();
}

class _CreateTextStatusScreenState extends State<CreateTextStatusScreen> {
  final _controller = TextEditingController();
  static const _palette = <Color>[
    Color(0xFF6B2D5C),
    Color(0xFF1E3A5F),
    Color(0xFF0D4D3F),
    Color(0xFF8B4513),
    Color(0xFF2C1810),
    Color(0xFF4A1942),
    Color(0xFF1A1A2E),
    Color(0xFFC0183A),
  ];

  int _selectedBg = 0;

  Color _darkerShade(Color c) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness((hsl.lightness * 0.52).clamp(0.08, 0.95)).toColor();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bg = _palette[_selectedBg.clamp(0, _palette.length - 1)];
    final text = _controller.text.trim();

    return Scaffold(
      backgroundColor: context.oklScaffold,
      appBar: AppBar(
        backgroundColor: context.oklScaffold,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Center(
            child: OklAppBarIconButton(
              icon: LucideIcons.x,
              onPressed: () {
                final n = Navigator.of(context, rootNavigator: true);
                if (n.canPop()) n.pop();
              },
            ),
          ),
        ),
        automaticallyImplyLeading: false,
        title: const Text('Statut texte'),
        actions: [
          TextButton(
            onPressed: text.isEmpty
                ? null
                : () {
                    Navigator.of(context, rootNavigator: true).pop(
                      TextStatusPublishResult(text: text, backgroundColor: bg),
                    );
                  },
            child: const Text(
              'Publier',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Text(
            'Aperçu',
            style: TextStyle(
              color: context.oklOnSurfaceMuted(0.55),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 10),
          AspectRatio(
            aspectRatio: 9 / 16,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [bg, _darkerShade(bg)],
                  ),
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Text(
                      text.isEmpty ? 'Écris quelque chose…' : text,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: text.isEmpty ? 0.45 : 1),
                        fontSize: text.length > 120 ? 18 : 24,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                        shadows: const [
                          Shadow(color: Colors.black54, blurRadius: 12),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 22),
          TextField(
            controller: _controller,
            maxLines: 5,
            maxLength: 280,
            style: TextStyle(color: context.oklOnSurface, height: 1.35),
            decoration: InputDecoration(
              hintText: 'Partage une pensée, une citation, une info…',
              hintStyle: TextStyle(
                color: (Theme.of(context).textTheme.bodyMedium?.color ??
                        context.oklOnSurfaceMuted(0.62))
                    .withValues(alpha: 0.85),
              ),
              filled: true,
              fillColor: context.oklSurface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 20),
          Text(
            'Couleur de fond',
            style: TextStyle(
              color: context.oklOnSurfaceMuted(0.55),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _palette.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final c = _palette[i];
                final sel = i == _selectedBg;
                return GestureDetector(
                  onTap: () => setState(() => _selectedBg = i),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: c,
                      border: Border.all(
                        color: sel ? AppColors.primary : context.oklDivider,
                        width: sel ? 3 : 1,
                      ),
                      boxShadow: sel
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.35),
                                blurRadius: 8,
                              ),
                            ]
                          : null,
                    ),
                    child: sel
                        ? const Icon(LucideIcons.check, color: Colors.white, size: 20)
                        : null,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'Astuce : les statuts disparaissent après 24 h (comportement type démo).',
            style: TextStyle(
              color: (Theme.of(context).textTheme.bodyMedium?.color ??
                      context.oklOnSurfaceMuted(0.62))
                  .withValues(alpha: 0.9),
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
