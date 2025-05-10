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
      );
    } else {
      // User is not authenticated, show login screen
      return const LoginScreen();
    }
  }
}