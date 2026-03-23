import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_colors.dart';
import '../theme/theme_extensions.dart';

/// Saisie PIN type verrouillage téléphone : pastilles + clavier numérique, sans bouton Valider.
/// [maxDigits] = 6 par défaut ; la saisie est limitée aux chiffres.
class OklPinCodeField extends StatefulWidget {
  const OklPinCodeField({
    super.key,
    this.maxDigits = 6,
    this.autofocus = true,
    this.onChanged,
    this.onComplete,
  });

  final int maxDigits;
  final bool autofocus;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onComplete;

  @override
  OklPinCodeFieldState createState() => OklPinCodeFieldState();
}

class OklPinCodeFieldState extends State<OklPinCodeField> {
  final _focus = FocusNode();
  final _hidden = TextEditingController();
  String _digits = '';

  @override
  void initState() {
    super.initState();
    _hidden.addListener(_syncFromField);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.autofocus) {
        _focus.requestFocus();
      }
    });
  }

  void _syncFromField() {
    final raw = _hidden.text;
    final only = raw.replaceAll(RegExp(r'[^0-9]'), '');
    final clipped = only.length > widget.maxDigits
        ? only.substring(0, widget.maxDigits)
        : only;
    if (clipped != raw) {
      _hidden.value = TextEditingValue(
        text: clipped,
        selection: TextSelection.collapsed(offset: clipped.length),
      );
      return;
    }
    if (clipped == _digits) return;
    setState(() => _digits = clipped);
    widget.onChanged?.call(clipped);
    if (clipped.length == widget.maxDigits) {
      widget.onComplete?.call(clipped);
    }
  }

  @override
  void dispose() {
    _hidden.removeListener(_syncFromField);
    _hidden.dispose();
    _focus.dispose();
    super.dispose();
  }

  /// Réinitialise la saisie (après erreur ou changement d’étape).
  void clear() {
    _hidden.clear();
    setState(() => _digits = '');
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.maxDigits;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _focus.requestFocus(),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(n, (i) {
              final filled = i < _digits.length;
              return Padding(
                padding: EdgeInsets.only(left: i == 0 ? 0 : 14),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: filled
                        ? AppColors.primary
                        : context.oklOnSurfaceMuted(0.18),
                    border: Border.all(
                      color: filled
                          ? AppColors.primary
                          : context.oklDivider,
                      width: filled ? 0 : 1.5,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 44,
          width: double.infinity,
          child: Center(
            child: TextField(
              controller: _hidden,
              focusNode: _focus,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              maxLength: n,
              obscureText: false,
              autocorrect: false,
              enableSuggestions: false,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.transparent,
                height: 1,
                fontSize: 1,
              ),
              cursorColor: Colors.transparent,
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                counterText: '',
              ),
            ),
          ),
        ),
      ],
    );
  }
}
