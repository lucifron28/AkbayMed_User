import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/donation_screen.dart';
import 'screens/request_screen.dart';
import 'screens/profile_screen.dart';

class MyApp extends StatefulWidget {
  const MyApp ({super.key});

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  int _selectedIndex = 0;

  // List of screens for navigation
  final List<Widget> _screens = [
    const HomeScreen(),
    const DonationScreen(),
    const RequestScreen(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AkbayMed',
      theme: ThemeData(
        useMaterial3: true, // Material 3 design
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        body: _screens[_selectedIndex], // Show selected screen
        bottomNavigationBar: BottomNavigationBar(
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Donate'),
            BottomNavigationBarItem(icon: Icon(Icons.medical_services), label: 'Request'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}