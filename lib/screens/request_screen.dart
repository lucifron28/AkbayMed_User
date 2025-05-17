import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';

class RequestScreen extends StatefulWidget {
  const RequestScreen({super.key});

  @override
  State<RequestScreen> createState() => _RequestScreenState();
}

class _RequestScreenState extends State<RequestScreen> {
  final _supabase = Supabase.instance.client;
  final _logger = Logger();
  final _formKey = GlobalKey<FormState>();

  final _medicineNameController = TextEditingController();
  final _quantityController = TextEditingController();

  bool _isLoading = false;
  bool _isSearching = false;
  String? _selectedMedicationId;
  List<Map<String, dynamic>> _inventorySuggestions = [];

  @override
  void initState() {
    super.initState();
  }

  Future<void> _searchInventoryMedications(String query) async {
    if (query.isEmpty) {
      setState(() {
        _inventorySuggestions = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final response = await _supabase
          .from('medications')
          .select('id, name')
          .ilike('name', '%$query%')
          .limit(10);

      setState(() {
        _inventorySuggestions = List<Map<String, dynamic>>.from(response);
        _isSearching = false;
      });
    } catch (e) {
      _logger.e('Error searching inventory medications: $e');
      setState(() {
        _isSearching = false;
      });
    }
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedMedicationId == null && _medicineNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a medication from inventory'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final patientId = _supabase.auth.currentUser?.id;
      if (patientId == null) {
        throw Exception('User not logged in');
      }

      // Submit the request to the requests table using the correct schema
      await _supabase.from('requests').insert({
        'patient_id': patientId,
        'medication_id': _selectedMedicationId,
        'quantity': int.parse(_quantityController.text.trim()),
        'status': 'pending',
      });

      if (mounted) {
        _formKey.currentState!.reset();
        _medicineNameController.clear();
        _quantityController.clear();

        setState(() {
          _selectedMedicationId = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Medicine request submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _logger.e('Error submitting request: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting request: ${e.toString()}'),
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
  void dispose() {
    _medicineNameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Image.asset(
          'assets/images/akbaymed-logo.png',
          fit: BoxFit.fitWidth,
        ),
        title: const Text(
          'Request Medicine',
          style: TextStyle(
            color: Color(0xFF004D40), // Dark teal
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
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
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xffb0dab9), Color(0xffdad299)],
            stops: [0, 1],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Request Medicine',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF004D40), // Dark teal
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),

                        // Guide for medicine request
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0F2F1).withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF00796B), width: 1),
                          ),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Medication Request Guide:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF004D40),
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                '• Search for medications available in our inventory',
                                style: TextStyle(color: Color(0xFF004D40)),
                              ),
                              Text(
                                '• Select from the suggestions that appear',
                                style: TextStyle(color: Color(0xFF004D40)),
                              ),
                              Text(
                                '• Specify the quantity you need',
                                style: TextStyle(color: Color(0xFF004D40)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Medicine Name Input
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextFormField(
                              controller: _medicineNameController,
                              decoration: InputDecoration(
                                labelText: 'Medicine Name',
                                border: const OutlineInputBorder(),
                                prefixIcon: const Icon(Icons.medication, color: Color(0xFF00796B)),
                                suffixIcon: _isSearching
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: Padding(
                                          padding: EdgeInsets.all(12),
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Color(0xFF00796B),
                                          ),
                                        ),
                                      )
                                    : null,
                              ),
                              onChanged: (value) {
                                _searchInventoryMedications(value);
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter the medicine name';
                                }
                                return null;
                              },
                            ),
                            if (_inventorySuggestions.isNotEmpty)
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                decoration: BoxDecoration(
                                  border: Border.all(color: const Color(0xFFB2DFDB)),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                height: _inventorySuggestions.length * 40.0 > 200 ? 200 : _inventorySuggestions.length * 40.0,
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: _inventorySuggestions.length,
                                  itemBuilder: (context, index) {
                                    return ListTile(
                                      dense: true,
                                      title: Text(_inventorySuggestions[index]['name']),
                                      tileColor: const Color(0xFFE0F2F1),
                                      onTap: () {
                                        setState(() {
                                          _medicineNameController.text = _inventorySuggestions[index]['name'];
                                          _selectedMedicationId = _inventorySuggestions[index]['id'];
                                          _inventorySuggestions = [];
                                        });
                                      },
                                    );
                                  },
                                ),
                              ),
                          ],
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
                        const SizedBox(height: 24),

                        // Submit Button
                        ElevatedButton(
                          onPressed: _isLoading ? null : _submitRequest,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00796B), // Teal
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                            shadowColor: Colors.black.withValues(alpha: 0.2),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text(
                                  'Submit Request',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                        ),

                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 16),

                        // Request Guidelines
                        const Text(
                          'Request Guidelines',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF004D40), // Dark teal
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '• Requests are subject to medicine availability\n'
                          '• All requests will be reviewed by our medical team\n'
                          '• You will be contacted once your request is approved\n'
                          '• Please provide valid contact information in your profile\n'
                          '• Medicines will be provided based on genuine need',
                          style: TextStyle(fontSize: 14, color: Color(0xFF004D40)), // Dark teal
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
