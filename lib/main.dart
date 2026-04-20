import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/auth_provider.dart';
import 'providers/appearance_provider.dart';
import 'screens/home_screen.dart';
import 'screens/admin_setup_screen.dart';

void main() {
  runApp(const ProviderScope(child: JustForYouApp()));
}

class JustForYouApp extends ConsumerWidget {
  const JustForYouApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final app = ref.watch(appearanceProvider);

    // Derive font family
    String? fontFamily;
    if (app.fontFamily == 'Monospace') fontFamily = 'Courier';
    if (app.fontFamily == 'Serif') fontFamily = 'Georgia';

    return MaterialApp(
      title: 'JustForYou',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1565C0)),
        useMaterial3: true,
        scaffoldBackgroundColor: app.backgroundColor,
        textTheme: fontFamily != null
            ? Typography.material2021().black.apply(fontFamily: fontFamily)
            : null,
      ),
      home: auth.loading
          ? const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            )
          : auth.setupDone
              ? const HomeScreen()
              : const AdminSetupScreen(),
    );
  }
}
