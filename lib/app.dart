import 'package:flutter/material.dart';

import 'screens/camera_screen.dart';
import 'screens/home_screen.dart';
import 'screens/statistics_screen.dart';

class ExpenseTrackerApp extends StatefulWidget {
  const ExpenseTrackerApp({super.key});

  @override
  State<ExpenseTrackerApp> createState() => _ExpenseTrackerAppState();
}

class _ExpenseTrackerAppState extends State<ExpenseTrackerApp> {
  var _selectedPage = 0;

  void _selectPage(int page) {
    setState(() => _selectedPage = page);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OCR Expense Tracker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: Scaffold(
        body: switch (_selectedPage) {
          0 => HomeScreen(onScan: () => _selectPage(1)),
          1 => CameraScreen(onSaved: () => _selectPage(0)),
          _ => const StatisticsScreen(),
        },
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedPage,
          onDestinationSelected: _selectPage,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long),
              label: 'Chi tiêu',
            ),
            NavigationDestination(
              icon: Icon(Icons.document_scanner_outlined),
              selectedIcon: Icon(Icons.document_scanner),
              label: 'Quét',
            ),
            NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart),
              label: 'Thống kê',
            ),
          ],
        ),
      ),
    );
  }
}
