import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';
import 'package:http/http.dart';

class RequestScreen extends StatefulWidget {
  const RequestScreen({super.key});

  @override
  State<RequestScreen> createState() => _RequestScreenState();
}

class _RequestScreenState extends State<RequestScreen> {
  final _supabase = Supabase.instance.client;
  final _logger = Logger();

  final _medicineNameController = TextEditingController();
  final _quantityController = TextEditingController();

  bool _isLoading = false;
  bool _isSearchingFDA = false;
  DateTime? _selectedExpirationDate;
  String? _selectedMedicationId;
  List<String> _fdaSuggestions = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request'),
      ),
      body: Center(
        child: const Text('Request Screen'),
      ),
    );
  }
}