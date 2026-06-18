import 'package:flutter/material.dart';
import 'calculator_screen.dart';
import 'theme/app_theme.dart';

/// Корневой виджет приложения.
class GlazingCalculatorApp extends StatelessWidget {
  const GlazingCalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Калькулятор стеклопакетов',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: const CalculatorScreen(),
    );
  }
}