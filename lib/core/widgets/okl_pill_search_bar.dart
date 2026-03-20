import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/theme_extensions.dart';

/// Champ pill (même base que conversation / statut : surface, sans bordure au focus).
class OklPillSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final bool autofocus;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;

  const OklPillSearchBar({
    super.key,
    required this.controller,
    required this.focusNode,
    this.hintText = 'Rechercher…',
    this.autofocus = false,
    this.textInputAction = TextInputAction.search,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: context.oklSurface,
          borderRadius: BorderRadius.circular(999),
        ),
        child: ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, _) {
            return TextField(
              controller: controller,
              focusNode: focusNode,
              autofocus: autofocus,
              style: TextStyle(color: context.oklOnSurface),
              textInputAction: textInputAction,
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: TextStyle(color: context.oklOnSurfaceMuted(0.6)),
                isDense: true,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                border: InputBorder.none,
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 36,
                  minHeight: 36,
                ),
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Icon(
                    LucideIcons.search,
                    size: 18,
                    color: context.oklOnSurfaceMuted(0.6),
                  ),
                ),
                suffixIconConstraints: const BoxConstraints(
                  minWidth: 36,
                  minHeight: 36,
                ),
                suffixIcon: value.text.isNotEmpty
                    ? Padding(
                        padding: const EdgeInsets.only(right: 2),
                        child: IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: Icon(
                            LucideIcons.x,
                            size: 18,
                            color: context.oklOnSurfaceMuted(0.6),
                          ),
                          onPressed: () {
                            controller.clear();
                          },
                        ),
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
              ),
              onSubmitted: onSubmitted,
            );
          },
        ),
      ),
    );
  }
}
