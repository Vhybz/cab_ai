import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_provider.dart';
import 'home_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  String? _selectedRegion;

  // List of major farming regions in Ghana for manual selection
  final Map<String, List<double>> _regions = {
    'Kumasi (Ashanti)': [6.6666, -1.6163],
    'Accra (Greater Accra)': [5.6037, -0.1870],
    'Tamale (Northern)': [9.4034, -0.8424],
    'Sunyani (Bono)': [7.3349, -2.3123],
    'Ho (Volta)': [6.6101, 0.4785],
    'Koforidua (Eastern)': [6.0784, -0.2713],
    'Takoradi (Western)': [4.8951, -1.7554],
    'Bolgatanga (Upper East)': [10.7856, -0.8514],
    'Wa (Upper West)': [10.0601, -2.5019],
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final provider = Provider.of<AppProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: colorScheme.onSurface,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Subtle background decoration
          Positioned(
            bottom: -150,
            left: -150,
            child: CircleAvatar(
              radius: 200,
              backgroundColor: colorScheme.primary.withOpacity(0.03),
            ),
          ),
          SafeArea(
            top: false,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 120),
                    Text(
                      'Create Account',
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: colorScheme.onSurface,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Join the community of modern farmers protecting their cabbage crops.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 48),

                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _buildTextField(
                            label: 'Full Name',
                            icon: Icons.person_outline_rounded,
                            colorScheme: colorScheme,
                          ),
                          const SizedBox(height: 20),
                          _buildTextField(
                            label: 'Email Address',
                            icon: Icons.alternate_email_rounded,
                            keyboardType: TextInputType.emailAddress,
                            colorScheme: colorScheme,
                          ),
                          const SizedBox(height: 20),
                          
                          // Region Selection
                          DropdownButtonFormField<String>(
                            value: _selectedRegion,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: 'Farm Region',
                              prefixIcon: const Icon(Icons.location_on_outlined),
                              filled: true,
                              fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            items: _regions.keys.map((String region) {
                              return DropdownMenuItem<String>(
                                value: region,
                                child: Text(region, overflow: TextOverflow.ellipsis),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedRegion = value;
                              });
                              if (value != null) {
                                final coords = _regions[value]!;
                                provider.setLocation(coords[0], coords[1], value);
                              }
                            },
                            hint: const Text('Select your region'),
                          ),
                          const SizedBox(height: 12),
                          
                          // GPS Button
                          TextButton.icon(
                            onPressed: () async {
                              await provider.useCurrentLocation();
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Location set to: ${provider.locationName}')),
                                );
                              }
                            },
                            icon: const Icon(Icons.my_location),
                            label: const Flexible(
                              child: Text(
                                'Use My Current GPS Location',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            style: TextButton.styleFrom(foregroundColor: colorScheme.primary),
                          ),
                          
                          const SizedBox(height: 20),
                          TextFormField(
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock_outline_rounded),
                              filled: true,
                              fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                ),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),

                    FilledButton(
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => const HomeScreen()),
                          (route) => false,
                        );
                      },
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 2,
                      ),
                      child: const Text('Create Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 16),

                    OutlinedButton.icon(
                      onPressed: () {
                        provider.setGuestUser();
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => const HomeScreen()),
                          (route) => false,
                        );
                      },
                      icon: const Icon(Icons.bolt_rounded, size: 20),
                      label: const Flexible(
                        child: Text(
                          'Quick Scan as Guest',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        side: BorderSide(color: colorScheme.primary.withOpacity(0.5)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                    const SizedBox(height: 32),

                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text("Already have an account?", style: TextStyle(color: colorScheme.onSurfaceVariant)),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Sign In', style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w900)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    required ColorScheme colorScheme,
  }) {
    return TextFormField(
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
