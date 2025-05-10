import 'package:flutter/material.dart';

class  HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: Colors.black54,
            height: 1.0,
          ),
        ),
      ),

      body: Center(
        child: const Text('Home Screen'),
      ),
    );
  }
}