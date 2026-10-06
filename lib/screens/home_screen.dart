import 'package:flutter/material.dart';

import '../ble/ble_service.dart';
import 'content/content_screen.dart';
import 'gears/gears_screen.dart';
import 'settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  final BleService bleService;

  const HomeScreen({
    super.key,
    required this.bleService,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int currentIndex = 1;

  @override
  Widget build(BuildContext context) {
    final pages = [
      ContentScreen(
        bleService: widget.bleService,
      ),
      GearsScreen(
        bleService: widget.bleService,
      ),
      SettingsScreen(
        bleService: widget.bleService,
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: pages[currentIndex],
      ),

      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,

        onDestinationSelected: (index) {
          setState(() {
            currentIndex = index;
          });
        },

        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.image_outlined),
            selectedIcon: Icon(Icons.image),
            label: 'Контент',
          ),

          NavigationDestination(
            icon: Icon(Icons.settings_input_component_outlined),
            selectedIcon: Icon(Icons.settings_input_component),
            label: 'Передачи',
          ),

          NavigationDestination(
            icon: Icon(Icons.tune_outlined),
            selectedIcon: Icon(Icons.tune),
            label: 'Настройки',
          ),
        ],
      ),
    );
  }
}