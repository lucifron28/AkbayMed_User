import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/home_screen.dart';
import 'screens/donation_screen.dart';
import 'screens/request_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/login_screen.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  int _selectedIndex = 0;
  final _supabase = Supabase.instance.client;

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
      debugShowCheckedModeBanner: false,
      title: 'AkbayMed',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),
      home: _checkAuth(),
    );
  }

  Widget _checkAuth() {
    // Check if user is authenticated
    final session = _supabase.auth.currentSession;

    if (session != null) {
      // User is authenticated, show app with bottom navigation
      return Scaffold(
        body: _screens[_selectedIndex],
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: const Color(0xFFE0F2F1), // Light teal background
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.home, color: _selectedIndex == 0 ? const Color(0xFF00796B) : Colors.grey), // Teal for selected
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite, color: _selectedIndex == 1 ? const Color(0xFF00796B) : Colors.grey),
              label: 'Donate',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.medical_services, color: _selectedIndex == 2 ? const Color(0xFF00796B) : Colors.grey),
              label: 'Request',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person, color: _selectedIndex == 3 ? const Color(0xFF00796B) : Colors.grey),
              label: 'Profile',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: const Color(0xFF00796B), // Teal for selected items
          unselectedItemColor: Colors.grey,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
          onTap: _onItemTapped,
        ),
      );
    } else {
      // User is not authenticated, show login screen
      return const LoginScreen();
    }
  }
}
