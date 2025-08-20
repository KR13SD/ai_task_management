import 'package:flutter/material.dart';

class AboutAppPage extends StatelessWidget {
  const AboutAppPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("About App")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text("AI Task Manager",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text("Version: 1.0.0"),
            SizedBox(height: 10),
            Text(
              "This app helps you manage tasks, track progress, and analyze productivity with AI-powered insights.",
            ),
          ],
        ),
      ),
    );
  }
}
