import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/api/oklifor_api_exception.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/utils/okl_feedback.dart';
import '../models/otp_route_extra.dart';
import '../providers/auth_api_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  Future<void> _onContinue() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty || phone.length < 8) return;
    final e164 = '+228$phone';
    setState(() => _isLoading = true);
    try {
      final api = ref.read(okliforApiClientProvider);
      await api.requestOtp(phone);
      if (mounted) context.go('/otp', extra: OtpRouteExtra(phoneE164: e164));
    } on OkliforApiException catch (e) {
      if (mounted) {
        OklFeedback.alert(context, title: 'Connexion', message: e.message);
      }
    } catch (e) {
      if (mounted) {
        OklFeedback.alert(context, title: 'Connexion', message: '$e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.oklScaffold,
      body: Stack(
        children: [
          // Ambient glow
          Positioned(
            top: -120, left: -80,
            child: Container(
              width: 320, height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [AppColors.primary.withAlpha(60), Colors.transparent],
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo + brand
                  const SizedBox(height: 60),
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 72, height: 72,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Center(
                            child: Text('♥', style: TextStyle(fontSize: 34, color: Colors.white)),
                          ),
                        ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
                        const SizedBox(height: 16),
                        Text(
                          'Oklifor',
                          style: TextStyle(
                            color: context.oklOnSurface,
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1,
                          ),
                        ).animate().fadeIn(delay: 200.ms),
                      ],
                    ),
                  ),
                  const SizedBox(height: 56),
                  // Titre
                  Text(
                    'Connexion',
                    style: TextStyle(
                      color: context.oklOnSurface,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ).animate().fadeIn(delay: 250.ms).slideX(begin: -0.2, end: 0),
                  const SizedBox(height: 6),
                  Text(
                    'Entrez votre numéro togolais',
                    style: TextStyle(color: context.oklOnSurfaceMuted(0.62), fontSize: 15),
                  ).animate().fadeIn(delay: 350.ms),
                  const SizedBox(height: 32),
                  // Champ téléphone — style Instagram/WhatsApp
                  Container(
                    decoration: BoxDecoration(
                      color: context.oklSurface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: context.oklDivider, width: 1),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
                          decoration: BoxDecoration(
                            border: Border(
                              right: BorderSide(color: context.oklDivider, width: 1),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Text('🇹🇬', style: TextStyle(fontSize: 18)),
                              const SizedBox(width: 8),
                              Text('+228',
                                  style: TextStyle(
                                    color: context.oklOnSurface,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  )),
                            ],
                          ),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            style: TextStyle(
                              color: context.oklOnSurface,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: const InputDecoration(
                              hintText: '90 00 00 00',
                              filled: false,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 16),
                            ),
                            onSubmitted: (_) => _onContinue(),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.15, end: 0),
                  const SizedBox(height: 16),
                  // Bouton
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _onContinue,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 17),
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20, width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.3))
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Text(
                                  'Recevoir le code',
                                  style: TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.w600),
                                ),
                                SizedBox(width: 8),
                                Icon(LucideIcons.arrowRight, size: 17),
                              ],
                            ),
                    ),
                  ).animate().fadeIn(delay: 500.ms),
                  const SizedBox(height: 32),
                  // Séparateur
                  Row(
                    children: [
                      Expanded(child: Divider(color: context.oklDivider)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text('ou',
                            style: TextStyle(color: context.oklOnSurfaceMuted(0.62), fontSize: 13)),
                      ),
                      Expanded(child: Divider(color: context.oklDivider)),
                    ],
                  ),
                  const SizedBox(height: 32),
                  // Bouton Google
                  _SocialButton(
                    label: 'Continuer avec Google',
                    icon: Text('G',
                        style: TextStyle(
                          color: context.oklOnSurface,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        )),
                    onTap: () {},
                  ).animate().fadeIn(delay: 600.ms),
                  const SizedBox(height: 40),
                  Center(
                    child: Text.rich(
                      TextSpan(
                        text: 'En continuant, vous acceptez nos ',
                        style: TextStyle(
                            color: context.oklOnSurfaceMuted(0.62), fontSize: 12),
                        children: [
                          TextSpan(
                            text: 'CGU',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const TextSpan(text: ' et la '),
                          TextSpan(
                            text: 'Politique de confidentialité',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ).animate().fadeIn(delay: 700.ms),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String label;
  final Widget icon;
  final VoidCallback onTap;

  const _SocialButton({
    required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: context.oklSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.oklDivider, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: context.oklOnSurface,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
