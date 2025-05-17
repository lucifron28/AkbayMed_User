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
    return Scaffold(
      appBar: AppBar(
        leading: Image.asset(
          'assets/images/akbaymed-logo.png',
          fit: BoxFit.fitWidth,
        ),
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Color(0xFF004D40), // Dark teal
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFE0F2F1), // Light teal
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFF004D40)), // Dark teal
            tooltip: 'Logout',
            onPressed: () {
              showDialog(
                barrierColor: Colors.black54,
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  backgroundColor: const Color(0xFFC3EFED),
                  actions: [
                    TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFF0D8E76), // Dark teal
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.red, // Dark teal
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
                        final supabase = Supabase.instance.client;

                        await supabase.auth.signOut();
                        if (context.mounted) {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                          );
                        }
                      },
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );
            }
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
            colors: [Color(0xffb0dab9), Color(0xffdad299)],
            stops: [0, 1],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
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
  int _donationCount = 0; // New field for donation count

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
          .select('name, email, avatar_url, is_verified, donation_count')
          .eq('id', userId)
          .single();

      setState(() {
        _name = data['name'] ?? 'No name found';
        _email = data['email'] ?? 'No email found';
        _avatarUrl = data['avatar_url'];
        _isVerified = data['is_verified'] ?? false;
        _donationCount = data['donation_count'] ?? 0;
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: _isVerified ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _isVerified ? Colors.green.withOpacity(0.5) : Colors.red.withOpacity(0.5),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _isVerified ? Icons.verified : Icons.warning,
                                color: _isVerified ? Colors.green : Colors.red,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _isVerified ? 'Verified' : 'Not Verified',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: _isVerified ? Colors.green : Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    
                    // Donation count card
                    Container(
                      width: MediaQuery.of(context).size.width * 0.9,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            spreadRadius: 0,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Donation Statistics',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF004D40),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Column(
                                children: [
                                  Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF00796B).withOpacity(0.1),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(0xFF00796B),
                                        width: 2,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        _donationCount.toString(),
                                        style: const TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF00796B),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Total Donations',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF004D40),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (_donationCount == 0)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                'You haven\'t made any donations yet. Start donating to help others!',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Color(0xFF00796B),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          if (_donationCount > 0)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00796B).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Thank you for your ${_donationCount} contribution${_donationCount > 1 ? 's' : ''}! Your generosity is making a difference.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xFF00796B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
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

