import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../constants/app_colors.dart';
import '../security/okl_local_auth_service.dart';
import '../security/okl_security_pin_storage.dart';
import '../theme/theme_extensions.dart';
import '../utils/okl_feedback.dart';
import 'okl_pin_code_field.dart';
import '../../features/profile/models/settings_session.dart';

/// Affiche un écran de déverrouillage au retour de l’app si le verrouillage est activé
/// et qu’un PIN ou la biométrie est configuré.
class AppLockOverlay extends StatefulWidget {
  const AppLockOverlay({super.key, required this.child});

  final Widget child;

  @override
  State<AppLockOverlay> createState() => _AppLockOverlayState();
}

class _AppLockOverlayState extends State<AppLockOverlay> with WidgetsBindingObserver {
  bool _locked = false;
  bool _shouldLockOnNextResume = false;
  bool _hasPinStored = false;
  int _pinFieldSalt = 0;
  final _auth = OklLocalAuthService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (kIsWeb) return;
    if (state == AppLifecycleState.paused) {
      _shouldLockOnNextResume = true;
      return;
    }
    if (state == AppLifecycleState.resumed && _shouldLockOnNextResume) {
      _shouldLockOnNextResume = false;
      _evaluateLock();
    }
  }

  Future<void> _evaluateLock() async {
    final s = SettingsSession.settings.value;
    if (!s.securityScreenLock) return;
    final hasPin = await OklSecurityPinStorage.hasPin();
    final bioOk = s.securityBiometric && await _auth.deviceSupportsBiometrics();
    if (!hasPin && !bioOk) return;
    if (!mounted) return;
    setState(() {
      _locked = true;
      _hasPinStored = hasPin;
      _pinFieldSalt++;
    });
  }

  Future<void> _tryBiometricUnlock() async {
    if (!_locked || !mounted) return;
    final ok = await _auth.authenticateUnlock(
      localizedReason: 'Déverrouille Oklifor pour continuer.',
    );
    if (ok && mounted) {
      setState(() {
        _locked = false;
        _pinFieldSalt++;
      });
    }
  }

  Future<void> _onUnlockDigits(String s) async {
    if (!_hasPinStored || s.length < 4) return;
    final ok = await OklSecurityPinStorage.verify(s);
    if (!mounted) return;
    if (ok) {
      setState(() {
        _locked = false;
        _pinFieldSalt++;
      });
      return;
    }
    if (s.length == 6) {
      OklFeedback.snack(context, 'Code incorrect');
      setState(() => _pinFieldSalt++);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: SettingsSession.settings,
      builder: (context, _) {
        return Stack(
          fit: StackFit.expand,
          children: [
            widget.child,
            if (_locked) ...[
              ModalBarrier(
                dismissible: false,
                color: Colors.black.withValues(alpha: 0.55),
              ),
              Material(
                color: context.oklScaffold,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                    child: Column(
                      children: [
                        Icon(LucideIcons.lock, size: 56, color: AppColors.primary),
                        const SizedBox(height: 20),
                        Text(
                          'Oklifor est verrouillé',
                          style: TextStyle(
                            color: context.oklOnSurface,
                            fontWeight: FontWeight.w800,
                            fontSize: 22,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Saisis ton code ou utilise la biométrie.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: context.oklOnSurfaceMuted(0.62),
                            fontSize: 14,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 28),
                        if (SettingsSession.settings.value.securityBiometric)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _tryBiometricUnlock,
                                icon: const Icon(LucideIcons.fingerprint, size: 20),
                                label: const Text('Déverrouiller avec la biométrie'),
                              ),
                            ),
                          ),
                        if (_hasPinStored) ...[
                          Text(
                            'Code (4 à 6 chiffres)',
                            style: TextStyle(
                              color: context.oklOnSurfaceMuted(0.55),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          OklPinCodeField(
                            key: ValueKey(_pinFieldSalt),
                            maxDigits: 6,
                            autofocus: true,
                            onChanged: _onUnlockDigits,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
