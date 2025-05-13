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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Donation',
          style: TextStyle(
            color: Color(0xFF004D40), // Dark teal
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFFE0F2F1), // Light teal
        elevation: 0,
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Donate Medicine',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF004D40), // Dark teal
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Medicine Name
                TextFormField(
                  controller: _medicineNameController,
                  decoration: const InputDecoration(
                    labelText: 'Medicine Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.medication, color: Color(0xFF00796B)), // Teal
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the medicine name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Quantity
                TextFormField(
                  controller: _quantityController,
                  decoration: const InputDecoration(
                    labelText: 'Quantity',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.numbers, color: Color(0xFF00796B)), // Teal
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the quantity';
                    }
                    if (int.tryParse(value) == null || int.parse(value) <= 0) {
                      return 'Please enter a valid quantity';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Expiration Date
                TextFormField(
                  controller: _expirationDateController,
                  decoration: InputDecoration(
                    labelText: 'Expiration Date',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.calendar_today, color: Color(0xFF00796B)), // Teal
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.calendar_month, color: Color(0xFF00796B)), // Teal
                      onPressed: _selectExpirationDate,
                    ),
                  ),
                  readOnly: true,
                  onTap: _selectExpirationDate,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select an expiration date';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Description
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description, color: Color(0xFF00796B)), // Teal
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please provide a description';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Submit Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _submitDonation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00796B), // Teal
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                    shadowColor: Colors.black.withAlpha(50),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          'Submit Donation',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),

                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),

                // Donation Guidelines
                const Text(
                  'Donation Guidelines',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF004D40), // Dark teal
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '• Medicines must not be expired\n'
                  '• Please ensure medicines are in their original packaging\n'
                  '• Include complete dosage information\n'
                  '• All donations will be reviewed by our medical team\n'
                  '• You will be contacted for pickup arrangements',
                  style: TextStyle(fontSize: 14, color: Color(0xFF004D40)), // Dark teal
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
