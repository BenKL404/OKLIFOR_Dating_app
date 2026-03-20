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
  bool _showPalette = false;

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
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [bg, _darkerShade(bg)],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      _TopIconButton(
                        icon: LucideIcons.x,
                        onPressed: () {
                          final n = Navigator.of(context, rootNavigator: true);
                          if (n.canPop()) {
                            n.pop();
                            return;
                          }
                          Navigator.of(context).pop();
                        },
                      ),
                      const Spacer(),
                      _TopIconButton(
                        icon: LucideIcons.palette,
                        onPressed: () =>
                            setState(() => _showPalette = !_showPalette),
                      ),
                      const SizedBox(width: 8),
                      OklAppBarIconButton(
                        icon: LucideIcons.send,
                        
                        onPressed: () {
                          if (text.isEmpty) return;
                          Navigator.of(context, rootNavigator: true).pop(
                            TextStatusPublishResult(
                              text: text,
                              backgroundColor: bg,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                if (_showPalette) const SizedBox(height: 12),
                if (_showPalette)
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
                            ),
                            child: sel
                                ? const Icon(LucideIcons.check,
                                    color: Colors.white, size: 20)
                                : null,
                          ),
                        );
                      },
                    ),
                  ),
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: TextField(
                        controller: _controller,
                        maxLines: null,
                        maxLength: 280,
                        autofocus: true,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: text.length > 120 ? 18 : 24,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Écrivez un statut',
                          hintStyle: TextStyle(
                            color: Colors.white.withValues(alpha: 0.25),
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            height: 1.25,
                          ),
                          counterText: '',
                          filled: false,
                          fillColor: Colors.transparent,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 70,
              color: Colors.black.withValues(alpha: 0.6),
              child: SafeArea(
                top: false,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _BottomTab(label: 'Vidéo', active: false),
                    _BottomTab(label: 'Photo', active: false),
                    _BottomTab(label: 'Message', active: true),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _TopIconButton({
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: 40,
      height: 40,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: Icon(
              icon,
              color: cs.onSurface,
              size: 19,
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomTab extends StatelessWidget {
  final String label;
  final bool active;

  const _BottomTab({
    required this.label,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = active ? Colors.white : Colors.white;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: active
          ? BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(999),
            )
          : null,
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }
}
