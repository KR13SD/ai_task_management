import 'package:flutter/material.dart';

class AnalyticPage extends StatelessWidget{

  const AnalyticPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Task Analytic', style: TextStyle(color: Colors.white),),
        backgroundColor: Color(0xFF3B82F6),
        foregroundColor: Colors.white,
      ),
    );
  }
}