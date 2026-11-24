import 'package:flutter/material.dart';

import 'api.dart';
import 'auth_pages.dart';
import 'config/app_config.dart';
import 'gd6.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Future.wait([
    loadRegisteredAccounts(),
    loadAppSettings(),
    loadAuthToken(),
    loadOrders(),
  ]);
  runApp(const ShopEasyApp());
}

class ShopEasyApp extends StatelessWidget {
  const ShopEasyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: appThemeMode,
      builder: (context, themeMode, child) {
        return ValueListenableBuilder<double>(
          valueListenable: appFontSize,
          builder: (context, fontSize, child) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'Shop Easy',
              themeMode: themeMode,
              builder: (context, appChild) {
                final mediaQuery = MediaQuery.of(context);
                return MediaQuery(
                  data: mediaQuery.copyWith(
                    textScaler: TextScaler.linear(fontSize / 16),
                  ),
                  child: appChild ?? const SizedBox.shrink(),
                );
              },
              theme: ThemeData(
                useMaterial3: true,
                colorScheme: ColorScheme.fromSeed(
                  seedColor: const Color(0xFF17365D),
                  brightness: Brightness.light,
                ),
                scaffoldBackgroundColor: const Color(0xFFF4F6FA),
                cardColor: Colors.white,
                appBarTheme: const AppBarTheme(
                  backgroundColor: Color(0xFF17365D),
                  foregroundColor: Colors.white,
                  centerTitle: true,
                  elevation: 0,
                ),
              ),
              darkTheme: ThemeData(
                useMaterial3: true,
                brightness: Brightness.dark,
                colorScheme: ColorScheme.fromSeed(
                  seedColor: const Color(0xFF2878D0),
                  brightness: Brightness.dark,
                ),
                scaffoldBackgroundColor: const Color(0xFF12151C),
                cardColor: const Color(0xFF1E222D),
                appBarTheme: const AppBarTheme(
                  backgroundColor: Color(0xFF181C26),
                  foregroundColor: Colors.white,
                  centerTitle: true,
                  elevation: 0,
                ),
              ),
              home: userAccessToken != null
                  ? const ShopHomePage()
                  : const LoginPage(),
            );
          },
        );
      },
    );
  }
}
