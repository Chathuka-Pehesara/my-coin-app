import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/services/preferences_service.dart';
import '../providers/auth_provider.dart';
import 'onboarding/onboarding_screen.dart';
import 'auth/pin_lock_screen.dart';
import 'main_shell_screen.dart';

class SplashGateScreen extends StatefulWidget {
  final PreferencesService prefs;

  const SplashGateScreen({super.key, required this.prefs});

  @override
  State<SplashGateScreen> createState() => _SplashGateScreenState();
}

class _SplashGateScreenState extends State<SplashGateScreen> {
  late bool _hasSeenOnboarding;

  @override
  void initState() {
    super.initState();
    _hasSeenOnboarding = widget.prefs.hasCompletedOnboarding;
  }

  void _onFinishOnboarding() {
    setState(() {
      _hasSeenOnboarding = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasSeenOnboarding) {
      return OnboardingScreen(
        prefs: widget.prefs,
        onFinish: _onFinishOnboarding,
      );
    }

    final auth = context.watch<AuthProvider>();
    if (auth.isPinEnabled && auth.isLocked) {
      return const PinLockScreen();
    }

    return const MainShellScreen();
  }
}
