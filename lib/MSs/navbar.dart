import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:sugmps/MSs/activitypage.dart';
import 'package:sugmps/MSs/statisticspage.dart';
import 'package:sugmps/MSs/homepage.dart';

class BottomNav extends StatefulWidget {
  const BottomNav({super.key});

  @override
  _BottomNavState createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  int _selectedIndex = 0;

  // Pages for each tab
  final List<Widget> _pages = const [
    Homepage(),
    Activitypage(),
    Statisticspage(),
    Center(
      child: Text(
        'Stats Page',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    ),
  ];

  // Handle tab taps
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index; // Update selected tab index
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Display the currently selected page
      body: _pages[_selectedIndex],

      // Bottom navigation bar
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped, // <-- Connected onTap callback
        selectedItemColor: Colors.white,
        unselectedItemColor: const Color.fromARGB(128, 255, 255, 255),
        backgroundColor: const Color.fromARGB(255, 76, 175, 100),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(FontAwesomeIcons.dumbbell),
            label: 'Exercise',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Stats'),
        ],
        iconSize: 30,
        selectedFontSize: 16,
        unselectedFontSize: 16,
      ),
    );
  }
}
