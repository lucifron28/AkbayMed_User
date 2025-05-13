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

}