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
        title: Text(provider.tr('Settings'), style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(provider.tr('Appearance')),
            SwitchListTile(
              secondary: Icon(Icons.dark_mode_outlined, color: colorScheme.primary),
              title: Text(provider.tr('Dark Mode')),
              subtitle: Text(provider.tr('Toggle between light and dark themes')),
              value: provider.themeMode == ThemeMode.dark,
              onChanged: (bool value) {
                provider.toggleTheme(value);
              },
            ),
            
            _buildSectionHeader(provider.tr('Localization')),
            ListTile(
              leading: Icon(Icons.translate_rounded, color: colorScheme.primary),
              title: Text(provider.tr('App Language')),
              subtitle: Text(provider.language),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => _showLanguageDialog(context, provider),
            ),
            
            _buildSectionHeader(provider.tr('General')),
            SwitchListTile(
              secondary: Icon(Icons.notifications_none_rounded, color: colorScheme.primary),
              title: Text(provider.tr('Notifications')),
              subtitle: Text(provider.tr('Get crop health and watering reminders')),
              value: provider.notificationsEnabled,
              onChanged: (bool value) {
                provider.toggleNotifications(value);
              },
            ),
            
            _buildSectionHeader(provider.tr('Account & Security')),
            ListTile(
              leading: Icon(Icons.lock_outline_rounded, color: colorScheme.primary),
              title: Text(provider.tr('Privacy Policy')),
              onTap: () => _showPrivacyPolicy(context),
            ),
            ListTile(
              leading: Icon(Icons.help_outline_rounded, color: colorScheme.primary),
              title: Text(provider.tr('Help & Support')),
              onTap: () => _showHelpAndSupport(context),
            ),
            
            const SizedBox(height: 40),
            Center(
              child: Text(
                'cabage_ai v1.0.0',
                style: TextStyle(color: colorScheme.outline, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 11, letterSpacing: 1.2),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context, AppProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(provider.tr('Select Language'), style: const TextStyle(fontWeight: FontWeight.bold)),
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

  void _showPrivacyPolicy(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: const SingleChildScrollView(
          child: Text(
            'Your privacy is important to us. Cabbage Doctor AI collects image data for disease classification and location data for accurate weather reporting. \n\n1. Data Security: Your scans are stored securely in Supabase Cloud.\n2. Permissions: We require Camera, Storage, and Location access to function correctly.\n3. Third Parties: We do not sell your personal farming data to third parties.',
            style: TextStyle(fontSize: 14, height: 1.5),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showHelpAndSupport(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Support'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.email_outlined),
              title: Text('Email Us'),
              subtitle: Text('support@cabbagedoctor.uenr.edu.gh'),
            ),
            ListTile(
              leading: Icon(Icons.language),
              title: Text('Visit Website'),
              subtitle: Text('www.cabbagedoctor.gh'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }
}
