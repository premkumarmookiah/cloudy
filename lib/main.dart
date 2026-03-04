import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/home_screen.dart';
import 'screens/calculator_screen.dart';
import 'screens/about_screen.dart';
import 'screens/example_screen.dart';
import 'utils/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.primaryDark,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const CloudLyApp());
}

class CloudLyApp extends StatelessWidget {
  const CloudLyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'cloud.ly — Cloud Cost Calculator',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      initialRoute: '/',
      routes: {
        '/': (_) => const HomeScreen(),
        '/calculator': (_) => const CalculatorScreen(),
        '/about': (_) => const AboutScreen(),
        '/example': (_) => const ExampleScreen(),
      },
    );
  }
}
