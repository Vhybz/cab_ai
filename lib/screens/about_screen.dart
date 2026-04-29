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
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF9FBF9),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildHeroHeader(colorScheme),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 100),
              child: Column(
                children: [
                  _buildBrandCard(isDark, colorScheme),
                  const SizedBox(height: 32),
                  _buildInfoSection(Icons.rocket_launch_rounded, 'OUR MISSION', 'Empowering Ghanaian farmers with AI to secure food production and improve yields through technology.', colorScheme),
                  const SizedBox(height: 24),
                  _buildInfoSection(Icons.groups_rounded, 'DEVELOPMENT TEAM', 'Built by Final Year IT Students from UENR, Sunyani, dedicated to agricultural innovation.', colorScheme),
                  const SizedBox(height: 24),
                  _buildInfoSection(Icons.memory_rounded, 'CORE TECHNOLOGY', 'Powered by Flutter, TensorFlow Lite, and Supabase for secure, real-time crop diagnostics.', colorScheme),
                  const SizedBox(height: 48),
                  _buildInstitutionBadge(isDark, colorScheme),
                  const SizedBox(height: 40),
                  Text('© ${DateTime.now().year} UENR IT Students', style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroHeader(ColorScheme colorScheme) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: colorScheme.primary,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text('About Cabbage Doctor', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.5)),
        centerTitle: true,
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [colorScheme.primary, colorScheme.secondary]),
          ),
          child: Opacity(
            opacity: 0.1,
            child: Icon(Icons.eco_rounded, size: 200, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildBrandCard(bool isDark, ColorScheme colorScheme) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: colorScheme.primary.withOpacity(0.2), width: 2)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(70),
            child: Image.asset('assets/images/c7.jpg', width: 140, height: 140, fit: BoxFit.cover),
          ),
        ),
        const SizedBox(height: 24),
        const Text('Cabbage Doctor AI', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -1)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(color: colorScheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Text('VERSION 1.0.1 (STABLE)', style: TextStyle(color: colorScheme.primary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
        ),
      ],
    );
  }

  Widget _buildInfoSection(IconData icon, String title, String content, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: colorScheme.primary),
            const SizedBox(width: 12),
            Text(title, style: TextStyle(color: colorScheme.primary, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
          ],
        ),
        const SizedBox(height: 12),
        Text(content, style: const TextStyle(fontSize: 15, height: 1.6, fontWeight: FontWeight.w500, color: Colors.grey)),
      ],
    );
  }

  Widget _buildInstitutionBadge(bool isDark, ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          const Icon(Icons.school_rounded, color: Colors.grey, size: 30),
          const SizedBox(height: 12),
          const Text('University of Energy and Natural Resources', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const Text('Department of IT • Sunyani, Ghana', style: TextStyle(color: Colors.grey, fontSize: 11)),
        ],
      ),
    );
  }
}
