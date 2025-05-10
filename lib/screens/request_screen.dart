import 'package:flutter/material.dart';

class RequestScreen extends StatelessWidget {
  const RequestScreen({super.key});

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