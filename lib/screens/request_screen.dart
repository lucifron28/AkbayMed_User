import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';
import 'package:http/http.dart' as http;

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

  Future<void> _searchFDAMedications(String query) async {
    if (query.isEmpty) {
      setState(() {
        _fdaSuggestions = [];
      });
      return;
    }

    setState(() {
      _isSearchingFDA = true;
    });

    try {
      final response = await http.get(
        Uri.parse('https://api.fda.gov/drug/label.json?search=openfda.generic_name:$query&limit=10'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['results'] != null) {
          final results = List<dynamic>.from(data['results']);
          final suggestions = <String>{};

          for (var result in results) {
            if (result['openfda'] != null &&
                result['openfda']['generic_name'] != null) {
              for (var name in result['openfda']['generic_name']) {
                suggestions.add(name.toString());
              }
            }
          }

          setState(() {
            _fdaSuggestions = suggestions.toList();
          });
        }
      } else {
        _logger.w('FDA API request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Error searching FDA medications: $e');
    } finally {
      setState(() {
        _isSearchingFDA = false;
      });
    }
  }

  Future<void> _requestMedication() async {
    if (_medicineNameController.text.isEmpty || _quantityController.text.isEmpty) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }
    final requestedMedication = {
      'medicine_name': _medicineNameController.text,
      'quantity': int.tryParse(_quantityController.text),
    };

  }


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