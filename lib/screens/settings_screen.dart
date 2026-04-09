import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          _buildSectionHeader('Appearance'),
          SwitchListTile(
            secondary: Icon(Icons.dark_mode_outlined, color: colorScheme.primary),
            title: const Text('Dark Mode'),
            subtitle: const Text('Toggle between light and dark themes'),
            value: provider.themeMode == ThemeMode.dark,
            onChanged: (bool value) {
              provider.toggleTheme(value);
            },
          ),
          
          _buildSectionHeader('Localization'),
          ListTile(
            leading: Icon(Icons.translate_rounded, color: colorScheme.primary),
            title: const Text('App Language'),
            subtitle: Text(provider.language),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _showLanguageDialog(context, provider),
          ),
          
          _buildSectionHeader('General'),
          SwitchListTile(
            secondary: Icon(Icons.notifications_none_rounded, color: colorScheme.primary),
            title: const Text('Notifications'),
            subtitle: const Text('Get crop health and watering reminders'),
            value: true,
            onChanged: (bool value) {},
          ),
          
          _buildSectionHeader('Account & Security'),
          ListTile(
            leading: Icon(Icons.lock_outline_rounded, color: colorScheme.primary),
            title: const Text('Privacy Policy'),
            onTap: () {},
          ),
          ListTile(
            leading: Icon(Icons.help_outline_rounded, color: colorScheme.primary),
            title: const Text('Help & Support'),
            onTap: () {},
          ),
          
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
              label: const Text('Logout', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.redAccent),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          const SizedBox(height: 40),
          Center(
            child: Text(
              'ca_ai v1.0.0',
              style: TextStyle(color: colorScheme.outline, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12, letterSpacing: 1.2),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context, AppProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language', style: TextStyle(fontWeight: FontWeight.bold)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _languageOption(context, provider, 'English'),
            _languageOption(context, provider, 'Twi'),
          ],
        ),
      ),
    );
  }

  Widget _languageOption(BuildContext context, AppProvider provider, String lang) {
    return RadioListTile<String>(
      title: Text(lang),
      value: lang,
      groupValue: provider.language,
      onChanged: (value) {
        if (value != null) provider.setLanguage(value);
        Navigator.pop(context);
      },
    );
  }
}
