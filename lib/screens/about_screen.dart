import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About Cabbage Doctor'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Icon(Icons.eco, size: 80, color: Colors.green),
            const SizedBox(height: 16),
            const Text(
              'Cabbage Doctor',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const Text('Version 1.0.0'),
            const SizedBox(height: 32),
            const Text(
              'Cabbage Doctor is a final year project aimed at helping smallholder farmers in Ghana detect and manage cabbage diseases efficiently using AI.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 24),
            const Text(
              'Developed by:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Text('Final Year Computer Science Student'),
            const SizedBox(height: 16),
            const Text(
              'Supported by:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Text('Ghana Agricultural Research Institute'),
          ],
        ),
      ),
    );
  }
}
