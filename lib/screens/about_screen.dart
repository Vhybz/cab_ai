import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_provider.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(provider.tr('About Cabbage Doctor')),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // App Logo/Icon
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.eco_rounded, size: 80, color: colorScheme.primary),
            ),
            const SizedBox(height: 24),
            const Text(
              'Cabbage Doctor AI',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -1),
            ),
            Text(
              'Version 1.0.0',
              style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),

            // Mission Statement
            _buildSection(
              context,
              Icons.rocket_launch_rounded,
              'Our Mission',
              'To empower smallholder farmers in Ghana by providing accessible, AI-driven crop diagnostic tools. We aim to reduce crop loss, improve yields, and contribute to national food security through modern technology.',
            ),

            const SizedBox(height: 24),

            // Developers Section
            _buildSection(
              context,
              Icons.groups_rounded,
              'The Development Team',
              'Cabbage Doctor was conceptualized and built by five dedicated Final Year IT Students from the University of Energy and Natural Resources (UENR), Sunyani. This project serves as a testament to our commitment to applying Information Technology in solving real-world agricultural challenges.',
            ),

            const SizedBox(height: 24),

            // Technology Stack
            _buildSection(
              context,
              Icons.memory_rounded,
              'Innovation & Technology',
              'Built using the Flutter framework for cross-platform excellence, the app leverages Deep Learning models via TensorFlow Lite for on-device disease classification. Our cloud infrastructure is powered by Supabase, ensuring your farm data is secure and synced across devices.',
            ),

            const SizedBox(height: 24),

            // University Info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.school_rounded, color: Colors.grey, size: 32),
                  const SizedBox(height: 12),
                  Text(
                    'University of Energy and Natural Resources (UENR)',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Department of Information Technology\nSunyani, Ghana',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 12, height: 1.5),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 48),
            Text(
              '© ${DateTime.now().year} UENR IT Students',
              style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, IconData icon, String title, String content) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: colorScheme.primary),
            const SizedBox(width: 12),
            Text(
              title.toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: colorScheme.primary,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          content,
          style: const TextStyle(
            fontSize: 15,
            height: 1.6,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
