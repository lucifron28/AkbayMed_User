import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
  final _expirationDateController = TextEditingController();

  bool _isLoading = false;
  bool _isSearchingFDA = false;
  DateTime? _selectedExpirationDate;
  String? _selectedMedicationId;
  List<String> _fdaSuggestions = [];

  @override
  void initState() {
    super.initState();
  }

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

  Future<void> _addNewMedication() async {
    try {
      final response = await _supabase
          .from('medications')
          .insert({
        'name': _medicineNameController.text.trim(),
        'category': 'Other', // Add a default category value
      })
          .select('id, name')
          .single();

      // Store the returned ID and update the state
      final newMedicationId = response['id'];

      setState(() {
        _selectedMedicationId = newMedicationId;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('New medication added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }

      return newMedicationId; // Return the ID for direct use
    } catch (e) {
      _logger.e('Error adding new medication: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add medication: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      rethrow; // Rethrow to handle in calling function
    }
  }

  @override
  void dispose() {
    _medicineNameController.dispose();
    _quantityController.dispose();
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
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF00796B), // Teal primary color
              onPrimary: Colors.white, // White text on primary color
              onSurface: Color(0xFF004D40), // Dark teal for text
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF00796B), // Teal for button text
              ),
            ), dialogTheme: DialogThemeData(backgroundColor: const Color(0xFFE0F2F1)),
          ),
          child: child!,
        );
      },
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

    if (_selectedMedicationId == null && _medicineNameController.text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select or enter a medication'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final donorId = _supabase.auth.currentUser?.id;
      if (donorId == null) {
        throw Exception('User not logged in');
      }

      // If no medication is selected but name is entered, add new one
      String medicationId = _selectedMedicationId ?? "";
      if (medicationId.isEmpty && _medicineNameController.text.isNotEmpty) {
        try {
          await _addNewMedication();
          medicationId = _selectedMedicationId ?? "";
          if (medicationId.isEmpty) {
            throw Exception('Failed to create medication');
          }
        } catch (e) {
          throw Exception('Error creating medication: $e');
        }
      }

      await _supabase.from('donations').insert({
        'donor_id': donorId,
        'medication_id': medicationId,
        'quantity': int.parse(_quantityController.text.trim()),
        'expiration_date': _selectedExpirationDate?.toIso8601String(),
      });

      if (mounted) {
        _formKey.currentState!.reset();
        _medicineNameController.clear();
        _quantityController.clear();
        _expirationDateController.clear();
        setState(() {
          _selectedExpirationDate = null;
          _selectedMedicationId = null;
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
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE0F2F1), Color(0xFFB2DFDB)], // Light teal gradient
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
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
                          'Donate Medicine',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF004D40), // Dark teal
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),

                        // Guide for medicine name
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
                                'Medication Name Guide:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF004D40),
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                '• Enter the generic name of the medication',
                                style: TextStyle(color: Color(0xFF004D40)),
                              ),
                              Text(
                                '• The system will suggest medications from the FDA database',
                                style: TextStyle(color: Color(0xFF004D40)),
                              ),
                              Text(
                                '• Example: "acetaminophen" instead of brand names',
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
                                suffixIcon: _isSearchingFDA
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
                                    : IconButton(
                                  icon: const Icon(Icons.add_circle, color: Color(0xFF00796B)),
                                  onPressed: _medicineNameController.text.isNotEmpty
                                      ? _addNewMedication
                                      : null,
                                  tooltip: 'Add as new medication',
                                ),
                              ),
                              onChanged: (value) {
                                _searchFDAMedications(value);
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter the medicine name';
                                }
                                return null;
                              },
                            ),
                            if (_fdaSuggestions.isNotEmpty)
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                decoration: BoxDecoration(
                                  border: Border.all(color: const Color(0xFFB2DFDB)),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                height: _fdaSuggestions.length * 40.0 > 200 ? 200 : _fdaSuggestions.length * 40.0,
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: _fdaSuggestions.length,
                                  itemBuilder: (context, index) {
                                    return ListTile(
                                      dense: true,
                                      title: Text(_fdaSuggestions[index]),
                                      tileColor: const Color(0xFFE0F2F1),
                                      onTap: () {
                                        setState(() {
                                          _medicineNameController.text = _fdaSuggestions[index];
                                          _fdaSuggestions = [];
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
                        const SizedBox(height: 24),

                        // Submit Button
                        ElevatedButton(
                          onPressed: _isLoading ? null : () async {
                            if (_medicineNameController.text.isNotEmpty) {
                              await _addNewMedication();
                            }
                            _submitDonation();
                          },
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

