import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';

class DonationScreen extends StatefulWidget {
  const DonationScreen({super.key});

  @override
  State<DonationScreen> createState() => _DonationScreenState();
}

class _DonationScreenState extends State<DonationScreen> {
  final _supabase = Supabase.instance.client;
  final _logger = Logger();
  final _formKey = GlobalKey<FormState>();

  final _medicineNameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _expirationDateController = TextEditingController();

  bool _isLoading = false;
  DateTime? _selectedExpirationDate;

  @override
  void dispose() {
    _medicineNameController.dispose();
    _quantityController.dispose();
    _descriptionController.dispose();
    _expirationDateController.dispose();
    super.dispose();
  }

  Future<void> _selectExpirationDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedExpirationDate ??
          DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );

    if (picked != null && picked != _selectedExpirationDate) {
      setState(() {
        _selectedExpirationDate = picked;
        _expirationDateController.text =
        "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

  Future<void> _submitDonation() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not logged in');
      }

      // Insert donation record into Supabase
      await _supabase.from('donations').insert({
        'user_id': userId,
        'medicine_name': _medicineNameController.text.trim(),
        'quantity': int.parse(_quantityController.text.trim()),
        'description': _descriptionController.text.trim(),
        'expiration_date': _selectedExpirationDate?.toIso8601String(),
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        _formKey.currentState!.reset();
        _medicineNameController.clear();
        _quantityController.clear();
        _descriptionController.clear();
        _expirationDateController.clear();
        setState(() {
          _selectedExpirationDate = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Medicine donation submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _logger.e('Error submitting donation: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting donation: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}