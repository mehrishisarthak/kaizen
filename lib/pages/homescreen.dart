import 'package:flutter/material.dart';
import 'package:kaizen/pages/my_grid_screen.dart';
import 'package:kaizen/pages/profile.dart';
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // The screens are now imported from their own files
  final List<Widget> _widgetOptions = <Widget>[
    MyGridScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.device_hub_outlined),
            activeIcon: Icon(Icons.device_hub),
            label: 'My Grid',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        // Theming is now handled by bottomNavigationBarTheme in app_theme.dart
      ),
    );
  }
}