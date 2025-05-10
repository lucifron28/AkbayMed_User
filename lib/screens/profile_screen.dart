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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: Colors.black54,
            height: 1.0,
          ),
        ),
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
  final _logger = Logger();
  bool _isLoading = true;
  bool _isUploading = false;
  String _name = 'Loading...';
  String _email = '';
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        logger.e('User not logged in');
        setState(() {
          _name = 'Not logged in';
          _isLoading = false;
        });
        return;
      }

      final data = await _supabase
          .from('users')
          .select('name, email, avatar_url')
          .eq('id', userId)
          .single();

      setState(() {
        _name = data['name'] ?? 'No name found';
        _email = data['email'] ?? 'No email found';
        _avatarUrl = data['avatar_url'];
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
    return SingleChildScrollView(
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
                        : const NetworkImage('https://via.placeholder.com/150'),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Icon(Icons.camera_alt, color: Colors.white, size: 18),
                    ),
                  ),
                  if (_isUploading)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
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