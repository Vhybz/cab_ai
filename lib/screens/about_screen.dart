import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_provider.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            backgroundColor: const Color(0xFF2E7D32),
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            centerTitle: true,
            leading: Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: Text(
                'About'.toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 10, letterSpacing: 3),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  Theme.of(context).brightness == Brightness.light ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: () => provider.toggleTheme(Theme.of(context).brightness == Brightness.light),
              ),
              const SizedBox(width: 8),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Image.asset(
                              'assets/images/c10.jpg',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Cabbage disease classification app',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF1B5E20), letterSpacing: -0.5),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFBC02D).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'v1.0.1 STABLE',
                            style: TextStyle(color: Color(0xFFFBC02D), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 64),
                  _buildSection('OUR MISSION', 'Empowering Ghanaian farmers with AI to secure food production and improve yields through cutting-edge diagnostics.'),
                  _buildSection('DEVELOPMENT TEAM', 'Crafted by Final Year IT Students from UENR, Sunyani. Our team is dedicated to solving real-world agricultural challenges using technology.'),
                  _buildSection('CORE TECHNOLOGY', 'The platform leverages Flutter for multi-platform reach, Google Gemini for expert agricultural advice, and Supabase for secure data orchestration.'),
                  
                  const SizedBox(height: 64),
                  const Divider(color: Color(0xFFE8F5E9)),
                  const SizedBox(height: 32),
                  Center(
                    child: Text(
                      '© ${DateTime.now().year} UENR IT STUDENTS'.toUpperCase(),
                      style: TextStyle(color: const Color(0xFF1B5E20).withValues(alpha: 0.2), fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 2),
                    ),
                  ),
                  const SizedBox(height: 64),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 48.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(color: Color(0xFF2E7D32), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 2),
          ),
          const SizedBox(height: 16),
          Text(
            content,
            style: const TextStyle(color: Colors.black54, fontSize: 16, height: 1.6, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
