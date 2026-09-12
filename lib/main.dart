import 'package:flutter/material.dart';

import 'core/theme.dart';
import 'features/auth/login_screen.dart';

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const StockBarApp());
}

class StockBarApp extends StatelessWidget {
  const StockBarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, currentMode, _) {
        return MaterialApp(
          title: 'StockBar Mobile',

          debugShowCheckedModeBanner: false,

          theme: AppTheme.lightTheme,

          darkTheme: AppTheme.darkTheme,

          themeMode: currentMode,

          home: const LoginScreen(),
        );
      },
    );
  }
}
