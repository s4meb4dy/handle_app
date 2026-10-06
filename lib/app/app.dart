import 'package:flutter/material.dart';

import '../ble/ble_service.dart';
import '../screens/home_screen.dart';

class HandleApp extends StatefulWidget {
  const HandleApp({super.key});

  @override
  State<HandleApp> createState() => _HandleAppState();
}

class _HandleAppState extends State<HandleApp> {
  final BleService bleService = BleService();

  @override
  void dispose() {
    bleService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'HANDLE',

      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,

        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4D8DFF),
          brightness: Brightness.dark,
        ),

        scaffoldBackgroundColor: const Color(0xFF0B0D10),

        sliderTheme: const SliderThemeData(
          showValueIndicator: ShowValueIndicator.always,
        ),
      ),

      home: HomeScreen(
        bleService: bleService,
      ),
    );
  }
}