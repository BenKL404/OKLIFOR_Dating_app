import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../constants/app_colors.dart';

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
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(999),
        ),
        child: ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, _) {
            return TextField(
              controller: controller,
              focusNode: focusNode,
              autofocus: autofocus,
              style: const TextStyle(color: AppColors.textPrimary),
              textInputAction: textInputAction,
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: const TextStyle(color: AppColors.textSecondary),
                isDense: true,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                border: InputBorder.none,
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 36,
                  minHeight: 36,
                ),
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(left: 6),
                  child: Icon(
                    LucideIcons.search,
                    size: 18,
                    color: AppColors.textSecondary,
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
                          icon: const Icon(
                            LucideIcons.x,
                            size: 18,
                            color: AppColors.textSecondary,
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
