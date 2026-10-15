import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/services/preferences_service.dart';
import 'core/services/biometric_service.dart';
import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/app_state_provider.dart';
import 'screens/splash_gate_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations for smartphone usability
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final prefsService = await PreferencesService.create();
  final biometricService = BiometricService();

  runApp(
    MultiProvider(
      providers: [
        Provider<PreferencesService>.value(value: prefsService),
        Provider<BiometricService>.value(value: biometricService),
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => ThemeProvider(prefsService),
        ),
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(prefsService, biometricService),
        ),
        ChangeNotifierProvider<AppStateProvider>(
          create: (_) => AppStateProvider(prefsService),
        ),
      ],
      child: const MyTransActionsApp(),
    ),
  );
}

class MyTransActionsApp extends StatelessWidget {
  const MyTransActionsApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final prefs = context.read<PreferencesService>();

    return MaterialApp(
      title: 'My Trans Actions',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      home: SplashGateScreen(prefs: prefs),
    );
  }
}
