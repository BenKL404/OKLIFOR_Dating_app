import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/api/oklifor_api_exception.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/flows/okl_flows.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/utils/okl_feedback.dart';
import '../../../core/widgets/okl_app_bar_icon_button.dart';
import '../models/otp_route_extra.dart';
import '../providers/auth_api_provider.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key, required this.extra});

  final OtpRouteExtra extra;

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isLoading = false;

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _clearBoxes() {
    for (final c in _controllers) {
      c.clear();
    }
  }

  void _onDigitEntered(int index, String value) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    final code = _controllers.map((c) => c.text).join();
    if (code.length == 6) _verify();
  }

  Future<void> _verify() async {
    final code = _controllers.map((c) => c.text).join();
    if (code.length != 6) return;
    setState(() => _isLoading = true);
    try {
      final api = ref.read(okliforApiClientProvider);
      final tokens = await api.verifyOtp(
        phoneE164: widget.extra.phoneE164,
        code: code,
      );
      await api.persistTokens(tokens);
      final me = await api.fetchMe();
      me.applyToLocalSessions();
      if (mounted) context.go('/discovery');
    } on OkliforApiException catch (e) {
      if (mounted) {
        OklFeedback.alert(
          context,
          title: 'Code incorrect',
          message: e.message,
        );
      }
    } catch (e) {
      if (mounted) {
        OklFeedback.alert(
          context,
          title: 'Vérification',
          message: '$e',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resendCode() async {
    try {
      await ref.read(okliforApiClientProvider).requestOtp(widget.extra.phoneE164);
      if (!mounted) return;
      _clearBoxes();
      await OklFlows.pushResult(
        context,
        icon: LucideIcons.mail,
        title: 'Code renvoyé',
        subtitle:
            'Un nouveau code a été demandé pour ${widget.extra.phoneE164}.',
        primaryLabel: 'OK',
      );
    } on OkliforApiException catch (e) {
      if (mounted) {
        OklFeedback.alert(
          context,
          title: 'Renvoi',
          message: e.message,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.oklScaffold,
      appBar: AppBar(
        backgroundColor: context.oklScaffold,
        leading: OklAppBarBackButton(onPressed: () => context.pop()),
        automaticallyImplyLeading: false,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Text(
                'Vérifie ton\nnuméro 📲',
                style: TextStyle(
                  color: context.oklOnSurface,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  height: 1.2,
                ),
              ).animate().fadeIn().slideY(begin: 0.2, end: 0),
              const SizedBox(height: 10),
              Text(
                'Code envoyé au ${widget.extra.phoneE164}',
                style: TextStyle(
                    color: context.oklOnSurfaceMuted(0.62), fontSize: 14),
              ).animate().fadeIn(delay: 150.ms),
              const SizedBox(height: 44),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(
                  6,
                  (i) => _OtpBox(
                    controller: _controllers[i],
                    focusNode: _focusNodes[i],
                    onChanged: (val) => _onDigitEntered(i, val),
                  ),
                )
                    .animate(interval: 55.ms)
                    .scale(begin: const Offset(0.6, 0.6), duration: 400.ms, curve: Curves.elasticOut)
                    .fade(),
              ),
              const SizedBox(height: 44),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verify,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 17),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20, width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.3))
                      : const Text(
                          'Confirmer',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                ),
              ).animate().fadeIn(delay: 400.ms),
              const SizedBox(height: 24),
              Center(
                child: TextButton.icon(
                  onPressed: _isLoading ? null : _resendCode,
                  icon: const Icon(LucideIcons.refreshCcw,
                      size: 15, color: AppColors.primary),
                  label: const Text('Renvoyer le code',
                      style: TextStyle(
                          color: AppColors.primary, fontWeight: FontWeight.w500)),
                ),
              ).animate().fadeIn(delay: 550.ms),
            ],
          ),
        ),
      ),
    );
  }
}

class _OtpBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 46,
      height: 58,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: context.oklOnSurface,
        ),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: context.oklSurface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: context.oklDivider, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: context.oklDivider, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),
        onChanged: onChanged,
      ),
    );
  }
}
