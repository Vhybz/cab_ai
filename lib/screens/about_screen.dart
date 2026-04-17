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
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(provider.tr('About Cabbage Doctor'), style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // App Logo/Icon Replacement
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? Colors.white12 : colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: isDark ? Colors.white24 : colorScheme.primary.withOpacity(0.2), width: 2),
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/c7.jpg',
                  width: 140,
                  height: 140,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Cabbage Doctor AI',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -1),
            ),
            Text(
              'Version 1.0.0',
              style: TextStyle(
                color: isDark ? Colors.greenAccent : colorScheme.primary, 
                fontWeight: FontWeight.bold
              ),
            ),
            const SizedBox(height: 32),

            // Mission Statement
            _buildSection(
              context,
              Icons.rocket_launch_rounded,
              'Our Mission',
              'To empower smallholder farmers in Ghana by providing accessible, AI-driven crop diagnostic tools. We aim to reduce crop loss, improve yields, and contribute to national food security through modern technology.',
              isDark
            ),

            const SizedBox(height: 24),

            // Developers Section
            _buildSection(
              context,
              Icons.groups_rounded,
              'The Development Team',
              'Cabbage Doctor was conceptualized and built by five dedicated Final Year IT Students from the University of Energy and Natural Resources (UENR), Sunyani. This project serves as a testament to our commitment to applying Information Technology in solving real-world agricultural challenges.',
              isDark
            ),

            const SizedBox(height: 24),

            // Technology Stack
            _buildSection(
              context,
              Icons.memory_rounded,
              'Innovation & Technology',
              'Built using the Flutter framework for cross-platform excellence, the app leverages Deep Learning models via TensorFlow Lite for on-device disease classification. Our cloud infrastructure is powered by Supabase, ensuring your farm data is secure and synced across devices.',
              isDark
            ),

            const SizedBox(height: 24),

            // University Info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: isDark ? Colors.white10 : colorScheme.outlineVariant.withOpacity(0.5)),
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

  Widget _buildSection(BuildContext context, IconData icon, String title, String content, bool isDark) {
    final colorScheme = Theme.of(context).colorScheme;
    final primaryColor = isDark ? Colors.greenAccent : colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: primaryColor),
            const SizedBox(width: 12),
            Text(
              title.toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: primaryColor,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          content,
          style: TextStyle(
            fontSize: 15,
            height: 1.6,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
      ],
    );
  }
}
