import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _supabase = Supabase.instance.client;
  final _logger = Logger();

  List<Map<String, dynamic>> _appointments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAppointments();
  }

  Future<void> _fetchAppointments() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not logged in');
      }

      // Fetch user's appointments with related donation and request information
      final appointmentsData = await _supabase
          .from('appointments')
          .select('''
            id, 
            appointment_date, 
            type,
            donation_id, 
            request_id,
            donations:donation_id(id, status, quantity, medication_id, medications:medication_id(name)),
            requests:request_id(id, status, quantity, medication_id, medications:medication_id(name))
          ''')
          .eq('user_id', userId)
          .order('appointment_date', ascending: false);

      setState(() {
        _appointments = List<Map<String, dynamic>>.from(appointmentsData);
        _isLoading = false;
      });
    } catch (e) {
      _logger.e('Error fetching appointments: $e');
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading appointments: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAppointmentDetails(Map<String, dynamic> appointment) {
    // Determine if it's a drop-off or pick-up
    // bool isDropOff = appointment['type'] == 'drop-off';
    bool isDropOff = appointment['donation_id'] != null;
    // Extract the relevant information based on type
    Map<String, dynamic>? details = isDropOff
        ? appointment['donations']
        : appointment['requests'];

    // Handle possibly null data
    if (details == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Appointment details not available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Get medication details
    Map<String, dynamic>? medication = details['medications'];
    final medicationName = medication != null ? medication['name'] : 'N/A';
    final quantity = details['quantity']?.toString() ?? 'N/A';
    final status = details['status'] ?? 'N/A';

    // Format date
    final appointmentDate = DateTime.parse(appointment['appointment_date']);
    final formattedDate = DateFormat('MMM dd, yyyy - h:mm a').format(appointmentDate);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: const Color(0xFFE0F2F1),
        title: Text(
          isDropOff ? 'Medication Drop-off' : 'Medication Pick-up',
          style: const TextStyle(
            color: Color(0xFF004D40),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _detailRow('Medication:', medicationName),
            const SizedBox(height: 8),
            _detailRow('Quantity:', quantity),
            const SizedBox(height: 8),
            _detailRow('Status:', status, getStatusColor(status)),
            const SizedBox(height: 8),
            _detailRow('Date:', formattedDate),
            const SizedBox(height: 8),
            _detailRow('Type:', isDropOff ? 'Drop-off' : 'Pick-up'),
            const SizedBox(height: 8),
            _detailRow('ID:', isDropOff ? details['id'] ?? 'N/A' : details['id'] ?? 'N/A'),
          ],
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF00796B),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, [Color? valueColor]) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF004D40),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: valueColor ?? const Color(0xFF00695C),
            ),
          ),
        ),
      ],
    );
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return const Color(0xFF00695C);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Home',
          style: TextStyle(
            color: Color(0xFF004D40),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFFE0F2F1),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF00796B)),
            onPressed: _fetchAppointments,
            tooltip: 'Refresh',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: const Color(0xFFB2DFDB),
            height: 1.0,
          ),
        ),
      ),
      body: Container(
        height: MediaQuery
            .of(context)
            .size
            .height,
        width: MediaQuery
            .of(context)
            .size
            .width,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE0F2F1), Color(0xFFB2DFDB)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(24, 24, 24, 8),
                child: Text(
                  'Your Appointments',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF004D40),
                  ),
                ),
              ),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Manage your medication donations and requests',
                  style: TextStyle(
                    color: Color(0xFF00695C),
                    fontSize: 14,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Expanded(
                child: _isLoading
                    ? const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF00796B),
                  ),
                )
                    : _appointments.isEmpty
                    ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 64,
                        color: Color(0xFF80CBC4),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No appointments yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: Color(0xFF004D40),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Your donation and request appointments will appear here',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF00695C),
                        ),
                      ),
                    ],
                  ),
                )
                    : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildAppointmentsTable(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppointmentsTable() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4.0, 4.0, 4.0, 16.0),
      child: Container(
        alignment: Alignment.topCenter,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.7),
          // Fixed: withValues → withOpacity
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              // Fixed: withValues → withOpacity
              blurRadius: 10,
              spreadRadius: 0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(4),
            child: Theme(
              data: Theme.of(context).copyWith(
                dividerColor: const Color(0xFFB2DFDB),
                dataTableTheme: DataTableThemeData(
                  headingTextStyle: const TextStyle(
                    color: Color(0xFF004D40),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  dataTextStyle: const TextStyle(
                    color: Color(0xFF00695C),
                    fontSize: 13,
                  ),
                  headingRowHeight: 48,
                  dataRowMinHeight: 56,
                  dividerThickness: 1,
                ),
              ),
              child: DataTable(
                columnSpacing: 16,
                dataRowMaxHeight: double.infinity,
                columns: const [
                  DataColumn(label: Text('Type')),
                  DataColumn(label: Text('Date')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Action')),
                ],
                rows: List<DataRow>.generate(
                  _appointments.length,
                      (index) {
                    final appointment = _appointments[index];

                    // Determine appointment type (drop-off or pick-up)
                    final isDropOff = appointment['donation_id'] != null;

                    // Get status data from the appropriate table
                    Map<String, dynamic>? details = isDropOff
                        ? appointment['donations']
                        : appointment['requests'];

                    final status = details?['status'] ?? 'N/A';

                    // Format appointment date
                    String formattedDate = 'N/A';
                    if (appointment['appointment_date'] != null) {
                      try {
                        final appointmentDate = DateTime.parse(
                            appointment['appointment_date']);
                        formattedDate = DateFormat('MMM dd\nyyyy').format(
                            appointmentDate);
                      } catch (e) {
                        _logger.e('Error parsing date: $e');
                      }
                    }

                    return DataRow(
                      cells: [
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isDropOff ? Icons.upload : Icons.download,
                                color: isDropOff
                                    ? const Color(0xFF00796B)
                                    : const Color(0xFF0097A7),
                                size: 18,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isDropOff ? 'Drop-off' : 'Pick-up',
                                style: TextStyle(
                                  color: isDropOff
                                      ? const Color(0xFF00796B)
                                      : const Color(0xFF0097A7),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        DataCell(
                          Text(
                            formattedDate,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: getStatusColor(status).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: getStatusColor(status).withValues(
                                    alpha: 0.5),
                              ),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: TextStyle(
                                color: getStatusColor(status),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          IconButton(
                            icon: const Icon(
                              Icons.info_outline,
                              color: Color(0xFF00796B),
                            ),
                            onPressed: () =>
                                _showAppointmentDetails(appointment),
                            tooltip: 'View Details',
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}