import 'package:akbaymed/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import '../app.dart';
import 'package:path/path.dart' as path;
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';
import 'dart:io';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final _supabase = Supabase.instance.client;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Color(0xFF004D40), // Dark teal
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFFE0F2F1), // Light teal
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFF004D40)), // Dark teal
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: const Color(0xFFB2DFDB), // Teal border
            height: 1.0,
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE0F2F1), Color(0xFFB2DFDB)], // Light teal gradient
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: const ProfileContent(),
      ),
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
  final _logger = Logger();
  bool _isLoading = true;
  bool _isUploading = false;
  String _name = 'Loading...';
  String _email = '';
  String? _avatarUrl;
  bool _isVerified = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        _logger.e('User not logged in');
        setState(() {
          _name = 'Not logged in';
          _isLoading = false;
        });
        return;
      }

      final data = await _supabase
          .from('users')
          .select('name, email, avatar_url, is_verified')
          .eq('id', userId)
          .single();

      setState(() {
        _name = data['name'] ?? 'No name found';
        _email = data['email'] ?? 'No email found';
        _avatarUrl = data['avatar_url'];
        _isVerified = data['is_verified'] ?? false;
        _isLoading = false;
      });
    } catch (e) {
      _logger.e('Error loading profile: $e');
      setState(() {
        _name = 'Error loading profile';
        _isLoading = false;
      });
    }
  }

  Future<void> _uploadAvatar() async {
    try {
      // For Android 13+ (API level 33+)
      final PermissionStatus photosStatus = await Permission.photos.request();
      // For older Android versions
      final PermissionStatus storageStatus = await Permission.storage.request();

      bool hasPermission = photosStatus.isGranted || storageStatus.isGranted;

      if (!hasPermission) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Storage permission is required')),
        );
        return;
      }

      final picker = ImagePicker();
      final imageFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 300,
        maxHeight: 300,
      );

      if (imageFile == null) {
        return;
      }

      setState(() {
        _isUploading = true;
      });

      final userId = _supabase.auth.currentUser!.id;
      final fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}${path.extension(imageFile.path)}';

      // Upload to Supabase
      final file = File(imageFile.path);
      final storageResponse = await _supabase
          .storage
          .from('avatars')
          .upload(fileName, file);

      // Get the public URL
      final imageUrl = _supabase.storage.from('avatars').getPublicUrl(fileName);

      // Update the user's profile in the database
      await _supabase
          .from('users')
          .update({'avatar_url': imageUrl})
          .eq('id', userId);

      setState(() {
        _avatarUrl = imageUrl;
        _isUploading = false;
      });
    } catch (e) {
      _logger.e('Error uploading avatar: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading image: ${e.toString()}')),
      );
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Center(
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: _isLoading ? null : _uploadAvatar,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundImage: _avatarUrl != null
                                ? NetworkImage(_avatarUrl!)
                                : const AssetImage('assets/images/default_profile.png') as ImageProvider,
                            backgroundColor: const Color(0xFFB2DFDB), // Teal background
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Color(0xFF00796B), // Teal
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(4),
                              child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                            ),
                          ),
                          if (_isUploading)
                            Positioned.fill(
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.black38,
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: CircularProgressIndicator(color: Colors.white),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _isLoading
                        ? const CircularProgressIndicator()
                        : Text(
                            _name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF004D40), // Dark teal
                            ),
                          ),
                    const SizedBox(height: 10),
                    Text(
                      _email,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF004D40), // Dark teal
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _isVerified ? 'Verified' : 'Not Verified',
                      style: TextStyle(
                        fontSize: 16,
                        color: _isVerified ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
