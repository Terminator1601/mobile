import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'services/app_state.dart';
import 'screens/auth_screen.dart';
import 'screens/home_shell.dart';
import 'screens/onboarding_screen.dart';

const kGradientPurple = Color(0xFF8B5CF6);
const kGradientPink = Color(0xFFEC4899);
const kGradientOrange = Color(0xFFF97316);
const kLiveRed = Color(0xFFEF4444);
const kUpcomingGreen = Color(0xFF10B981);

const kGradient = LinearGradient(
  colors: [kGradientPurple, kGradientPink, kGradientOrange],
);
const kGradientPurplePink = LinearGradient(
  colors: [kGradientPurple, kGradientPink],
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );
  final appState = AppState();
  await appState.initPreferences();
  appState.tryAutoLogin();
  runApp(
    ChangeNotifierProvider.value(
      value: appState,
      child: const EventDiscoveryApp(),
    ),
  );
}

class EventDiscoveryApp extends StatelessWidget {
  const EventDiscoveryApp({super.key});

  @override
  Widget build(BuildContext context) {
    final darkScheme = ColorScheme.dark(
      primary: kGradientPurple,
      secondary: kGradientPink,
      tertiary: kGradientOrange,
      surface: const Color(0xFF0A0A0F),
      surfaceContainerHighest: const Color(0xFF1A1A24),
      onSurface: Colors.white,
      onSurfaceVariant: const Color(0xFF717182),
      outline: Colors.white.withValues(alpha: 0.1),
    );

    final lightScheme = ColorScheme.light(
      primary: kGradientPurple,
      secondary: kGradientPink,
      tertiary: kGradientOrange,
      surface: Colors.white,
      surfaceContainerHighest: const Color(0xFFECECF0),
      onSurface: const Color(0xFF030213),
      onSurfaceVariant: const Color(0xFF717182),
      outline: Colors.black.withValues(alpha: 0.1),
    );

    final state = context.watch<AppState>();
    return MaterialApp(
      title: 'Event Discovery',
      debugShowCheckedModeBanner: false,
      themeMode: state.themeMode,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: lightScheme,
        scaffoldBackgroundColor: lightScheme.surface,
        appBarTheme: AppBarTheme(
          backgroundColor: lightScheme.surface.withValues(alpha: 0.8),
          surfaceTintColor: Colors.transparent,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: darkScheme,
        scaffoldBackgroundColor: darkScheme.surface,
        appBarTheme: AppBarTheme(
          backgroundColor: darkScheme.surface.withValues(alpha: 0.8),
          surfaceTintColor: Colors.transparent,
        ),
      ),
      home: const _AppHome(),
    );
  }
}

class _AppHome extends StatefulWidget {
  const _AppHome();

  @override
  State<_AppHome> createState() => _AppHomeState();
}

class _AppHomeState extends State<_AppHome> {
  bool? _onboardingComplete;

  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(
          () => _onboardingComplete = prefs.getBool('onboarding_complete') ?? false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_onboardingComplete == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!_onboardingComplete!) {
      return OnboardingScreen(
        onComplete: () => setState(() => _onboardingComplete = true),
      );
    }

    return Consumer<AppState>(
      builder: (context, state, _) {
        if (state.isLoggedIn) return const HomeShell();
        return const AuthScreen();
      },
    );
  }
}
