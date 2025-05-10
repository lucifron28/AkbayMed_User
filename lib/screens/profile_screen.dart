import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../app.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final _supabase = Supabase.instance.client;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await _supabase.auth.signOut();

              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const MyApp()),
                      (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: ProfileContent(),
    );
  }
}


class ProfileContent extends StatefulWidget {
  const ProfileContent({super.key});

  @override
  State<ProfileContent> createState() => _ProfileContentState();
}

class _ProfileContentState extends State<ProfileContent> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  String _name = 'Loading...';
  String _email = '';

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        setState(() {
          _name = 'Not logged in';
          _isLoading = false;
        });
        return;
      }

      final data = await _supabase
          .from('users')
          .select('name, email')
          .eq('id', userId)
          .single();

      setState(() {
        _name = data['name'] ?? 'No name found';
        _email = data['email'] ?? 'No email found';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _name = 'Error loading profile';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
        child: Column(
          children: [
            const SizedBox(height: 20),
            const CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage('https://via.placeholder.com/150'),
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : Text(
              _name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(_email),
          ],
        ),
      ),
    );
  }
}