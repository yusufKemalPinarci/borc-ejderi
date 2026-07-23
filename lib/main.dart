import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme/app_theme.dart';
import 'features/game/presentation/game_controller.dart';
import 'features/game/presentation/screens/home_screen.dart';
import 'features/game/presentation/screens/onboarding_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const BorcEjderiApp(),
    ),
  );
}

class BorcEjderiApp extends ConsumerWidget {
  const BorcEjderiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameControllerProvider);

    return MaterialApp(
      title: 'Borç Ejderi',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: game.when(
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => Scaffold(body: Center(child: Text('$e'))),
        data: (state) =>
            state.onboarded ? const HomeScreen() : const OnboardingScreen(),
      ),
    );
  }
}
