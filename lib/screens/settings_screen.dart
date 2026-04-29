import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/app_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
          _buildSliverAppBar(context, provider, colorScheme),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionLabel('APPEARANCE & LANGUAGE'),
                  const SizedBox(height: 12),
                  _buildSettingsCard(isDark, [
                    SwitchListTile(
                      secondary: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.dark_mode_rounded, color: Colors.blue, size: 20)),
                      title: Text(provider.tr('Dark Mode'), style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text('Toggle app theme'),
                      value: provider.themeMode == ThemeMode.dark,
                      onChanged: (val) => provider.toggleTheme(val),
                    ),
                    const Divider(indent: 70, height: 1),
                    ListTile(
                      leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.translate_rounded, color: Colors.green, size: 20)),
                      title: Text(provider.tr('Language'), style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(provider.language),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => _showLanguageDialog(context, provider, isDark),
                    ),
                  ]),
                  
                  const SizedBox(height: 32),
                  _buildSectionLabel('NOTIFICATIONS'),
                  const SizedBox(height: 12),
                  _buildSettingsCard(isDark, [
                    SwitchListTile(
                      secondary: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.notifications_active_rounded, color: Colors.orange, size: 20)),
                      title: Text(provider.tr('Enable Notifications'), style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text('Get health and field reminders'),
                      value: provider.notificationsEnabled,
                      onChanged: (val) => provider.toggleNotifications(val),
                    ),
                  ]),

                  const SizedBox(height: 32),
                  _buildSectionLabel('SUPPORT & LEGAL'),
                  const SizedBox(height: 12),
                  _buildSettingsCard(isDark, [
                    _buildSimpleTile(context, Icons.help_center_rounded, 'Help & Support', Colors.purple, () => _showSupportDialog(context, isDark)),
                    const Divider(indent: 70, height: 1),
                    _buildSimpleTile(context, Icons.privacy_tip_rounded, 'Privacy Policy', Colors.blueGrey, () => _showPrivacyPolicy(context, isDark)),
                  ]),
                  
                  const SizedBox(height: 60),
                  Center(
                    child: Column(
                      children: [
                        const Text('Cabbage Doctor AI', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                        Text('v1.0.1 Stable Release', style: TextStyle(color: Colors.grey.withOpacity(0.5), fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, AppProvider provider, ColorScheme colorScheme) {
    return SliverAppBar(
      expandedHeight: 140,
      pinned: true,
      stretch: true,
      backgroundColor: colorScheme.primary,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: Text(
          provider.tr('Settings'), 
          style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 18, letterSpacing: -0.5)
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [colorScheme.primary, colorScheme.secondary],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                bottom: -20,
                child: Icon(Icons.settings_rounded, size: 150, color: Colors.white.withOpacity(0.1)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(text, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
    );
  }

  Widget _buildSettingsCard(bool isDark, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSimpleTile(BuildContext context, IconData icon, String title, Color color, VoidCallback onTap) {
    return ListTile(
      leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 20)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }

  void _showLanguageDialog(BuildContext context, AppProvider provider, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        title: Text(provider.tr('Language'), style: const TextStyle(fontWeight: FontWeight.w900)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _langItem(context, provider, 'English'),
            _langItem(context, provider, 'Twi'),
          ],
        ),
      ),
    );
  }

  Widget _langItem(BuildContext context, AppProvider provider, String lang) {
    return RadioListTile<String>(
      title: Text(lang, style: const TextStyle(fontWeight: FontWeight.bold)),
      value: lang,
      groupValue: provider.language,
      onChanged: (val) { provider.setLanguage(val!); Navigator.pop(context); },
    );
  }

  void _showSupportDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        title: const Text('Help & Support', style: TextStyle(fontWeight: FontWeight.w900)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _supportItem(Icons.email_outlined, 'Email Support', 'project0z1258@gmail.com', () => _launch('mailto:project0z1258@gmail.com')),
            _supportItem(Icons.chat_bubble_outline_rounded, 'WhatsApp Help', '0559650921', () => _launch('https://wa.me/233559650921')),
          ],
        ),
      ),
    );
  }

  Widget _supportItem(IconData icon, String title, String sub, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.green),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      subtitle: Text(sub, style: const TextStyle(fontSize: 12)),
      onTap: onTap,
    );
  }

  void _showPrivacyPolicy(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        title: const Text('Privacy Policy', style: TextStyle(fontWeight: FontWeight.w900)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        content: const SingleChildScrollView(
          child: Text('We value your privacy. Your scan data is used exclusively for disease classification and improving the AI models. Your location is used only for accurate localized weather data. We do not sell your personal farming information to any third parties.', style: TextStyle(fontSize: 14, height: 1.6)),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Got it'))],
      ),
    );
  }

  void _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
