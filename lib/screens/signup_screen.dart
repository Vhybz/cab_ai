import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/app_provider.dart';
import 'home_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dobController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _selectedRegion;
  String? _selectedGender;
  String? _selectedProfession;
  DateTime? _selectedDate;
  double _passwordStrength = 0;
  bool _showStrength = false;
  bool _isDetectingLocation = false;

  final List<String> _professions = [
    'Crop Farmer',
    'Commercial Farmer',
    'Backyard Gardener',
    'Agricultural Student',
    'Extension Officer',
    'Researcher',
    'Other'
  ];

  late Map<String, List<double>> _regions;

  @override
  void initState() {
    super.initState();
    _regions = {
      'Ahafo (Goaso)': [6.8043, -2.5186],
      'Ashanti (Kumasi)': [6.6666, -1.6163],
      'Bono East (Techiman)': [7.5833, -1.9333],
      'Brong Ahafo (Sunyani)': [7.3349, -2.3123],
      'Central (Cape Coast)': [5.1053, -1.2466],
      'Eastern (Koforidua)': [6.0784, -0.2713],
      'Greater Accra (Accra)': [5.6037, -0.1870],
      'North East (Nalerigu)': [10.5306, -0.3686],
      'Northern (Tamale)': [9.4034, -0.8424],
      'Oti (Dambai)': [8.0700, 0.1800],
      'Savannah (Damongo)': [9.0833, -1.8167],
      'Upper East (Bolgatanga)': [10.7856, -0.8514],
      'Upper West (Wa)': [10.0601, -2.5019],
      'Volta (Ho)': [6.6101, 0.4785],
      'Western (Sekondi-Takoradi)': [4.8951, -1.7554],
      'Western North (Sefwi Wiaso)': [6.1248, -2.4838],
    };
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _surnameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _checkPasswordStrength(String password) {
    if (!_showStrength && password.isNotEmpty) {
      setState(() => _showStrength = true);
    } else if (password.isEmpty) {
      setState(() => _showStrength = false);
    }

    double strength = 0;
    if (password.length >= 6) strength += 0.25;
    if (password.contains(RegExp(r'[A-Z]'))) strength += 0.25;
    if (password.contains(RegExp(r'[0-9]'))) strength += 0.25;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength += 0.25;
    
    setState(() {
      _passwordStrength = strength;
    });
  }

  Color _getStrengthColor() {
    if (_passwordStrength <= 0.25) return Colors.red;
    if (_passwordStrength <= 0.5) return Colors.orange;
    if (_passwordStrength <= 0.75) return Colors.yellow;
    return Colors.green;
  }

  String _getStrengthText() {
    if (_passwordStrength <= 0.25) return 'Weak';
    if (_passwordStrength <= 0.5) return 'Fair';
    if (_passwordStrength <= 0.75) return 'Good';
    return 'Strong';
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.greenAccent,
              onPrimary: Colors.black,
              surface: Color(0xFF1A1A1A),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dobController.text = DateFormat('MMM dd, yyyy').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context, listen: false);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, foregroundColor: Colors.white),
      body: Stack(
        children: [
          Positioned.fill(child: Image.asset('assets/images/c11.jpg', fit: BoxFit.cover)),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withOpacity(0.4), Colors.black.withOpacity(0.8), Colors.black],
                ),
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 28.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 10),
                      const Text(
                        'Create Profile',
                        style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -1),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tell us a bit about yourself to get started.',
                        style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 16),
                      ),
                      const SizedBox(height: 32),
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _firstNameController,
                                    style: const TextStyle(color: Colors.white),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                                    ],
                                    decoration: _inputDecoration('First Name', Icons.person_outline_rounded),
                                    validator: (v) => v!.isEmpty ? 'Required' : null,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    controller: _surnameController,
                                    style: const TextStyle(color: Colors.white),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                                    ],
                                    decoration: _inputDecoration('Surname', Icons.badge_outlined),
                                    validator: (v) => v!.isEmpty ? 'Required' : null,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _dobController,
                              readOnly: true,
                              onTap: () => _selectDate(context),
                              style: const TextStyle(color: Colors.white),
                              decoration: _inputDecoration('Date of Birth', Icons.calendar_today_rounded),
                              validator: (v) => v!.isEmpty ? 'Please select your birthday' : null,
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              value: _selectedGender,
                              dropdownColor: Colors.grey.shade900,
                              style: const TextStyle(color: Colors.white),
                              decoration: _inputDecoration('Gender', Icons.wc_rounded),
                              items: ['Male', 'Female', 'Other'].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                              onChanged: (v) => setState(() => _selectedGender = v),
                              validator: (v) => v == null ? 'Required' : null,
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              value: _selectedProfession,
                              isExpanded: true,
                              dropdownColor: Colors.grey.shade900,
                              style: const TextStyle(color: Colors.white),
                              decoration: _inputDecoration('Profession / Farmer Type', Icons.work_outline_rounded),
                              items: _professions.map((p) => DropdownMenuItem(value: p, child: Text(p, overflow: TextOverflow.ellipsis))).toList(),
                              onChanged: (v) => setState(() => _selectedProfession = v),
                              validator: (v) => v == null ? 'Required' : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              style: const TextStyle(color: Colors.white),
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(10),
                              ],
                              decoration: _inputDecoration('Phone Number', Icons.phone_android_rounded),
                              validator: (v) {
                                if (v!.isEmpty) return 'Required';
                                if (v.length < 10) return 'Must be 10 digits';
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _emailController, 
                              label: 'Email Address', 
                              icon: Icons.alternate_email_rounded, 
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) => v!.isEmpty ? 'Required for signing in' : (!v.contains('@') ? 'Invalid email' : null),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              onChanged: _checkPasswordStrength,
                              style: const TextStyle(color: Colors.white),
                              decoration: _inputDecoration('Password', Icons.lock_outline_rounded).copyWith(
                                suffixIcon: IconButton(icon: Icon(_obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: Colors.white70), onPressed: () => setState(() => _obscurePassword = !_obscurePassword)),
                              ),
                              validator: (v) => v!.length < 6 ? 'Min 6 characters' : null,
                            ),
                            
                            if (_showStrength) ...[
                              const SizedBox(height: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  LinearProgressIndicator(
                                    value: _passwordStrength,
                                    backgroundColor: Colors.white10,
                                    color: _getStrengthColor(),
                                    minHeight: 4,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Strength: ${_getStrengthText()}',
                                    style: TextStyle(color: _getStrengthColor(), fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ],
                            
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _confirmPasswordController,
                              obscureText: _obscureConfirmPassword,
                              style: const TextStyle(color: Colors.white),
                              decoration: _inputDecoration('Confirm Password', Icons.lock_reset_rounded).copyWith(
                                suffixIcon: IconButton(icon: Icon(_obscureConfirmPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: Colors.white70), onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword)),
                              ),
                              validator: (v) => v != _passwordController.text ? 'Passwords do not match' : null,
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              value: _selectedRegion,
                              isExpanded: true,
                              dropdownColor: Colors.grey.shade900,
                              style: const TextStyle(color: Colors.white),
                              decoration: _inputDecoration('Farm Region', Icons.location_on_outlined),
                              items: _regions.keys.map((r) => DropdownMenuItem(value: r, child: Text(r, overflow: TextOverflow.ellipsis))).toList(),
                              onChanged: (v) {
                                setState(() => _selectedRegion = v);
                                if (v != null) {
                                  final c = _regions[v]!;
                                  provider.setLocation(c[0], c[1], v);
                                }
                              },
                              validator: (v) => v == null ? 'Please select your region' : null,
                            ),
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: _isDetectingLocation ? null : () async {
                                setState(() => _isDetectingLocation = true);
                                try {
                                  await provider.useCurrentLocation();
                                  if (mounted) {
                                    final detectedLoc = provider.locationName;
                                    if (!_regions.containsKey(detectedLoc)) {
                                      _regions[detectedLoc] = [provider.lat, provider.lon];
                                    }
                                    setState(() {
                                      _selectedRegion = detectedLoc;
                                      _isDetectingLocation = false;
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Region detected: $detectedLoc')),
                                    );
                                  }
                                } catch (e) {
                                  if (mounted) setState(() => _isDetectingLocation = false);
                                }
                              },
                              icon: _isDetectingLocation 
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.greenAccent))
                                : const Icon(Icons.my_location, color: Colors.greenAccent),
                              label: Text(
                                _isDetectingLocation ? 'Detecting...' : 'Use Current GPS Location', 
                                style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      FilledButton(
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            try {
                              await provider.signUp(
                                email: _emailController.text,
                                password: _passwordController.text,
                                firstName: _firstNameController.text,
                                surname: _surnameController.text,
                                dob: _dobController.text,
                                gender: _selectedGender!,
                                profession: _selectedProfession!,
                                region: _selectedRegion!,
                                phone: _phoneController.text,
                              );
                              if (context.mounted) {
                                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const HomeScreen()), (route) => false);
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                              }
                            }
                          }
                        },
                        style: FilledButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 4),
                        child: const Text('Complete Registration', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () { provider.setGuestUser(); Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const HomeScreen()), (route) => false); },
                        icon: const Icon(Icons.bolt_rounded, size: 20),
                        label: const Text('Continue as Guest'),
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 18), side: const BorderSide(color: Colors.white38), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                      ),
                      const SizedBox(height: 32),
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Text("Already a member?", style: TextStyle(color: Colors.white70)),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Sign In', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.w900)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      prefixIcon: Icon(icon, color: Colors.white70),
      filled: true,
      fillColor: Colors.white.withOpacity(0.1),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.greenAccent)),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String label, required IconData icon, TextInputType? keyboardType, String? Function(String?)? validator}) {
    return TextFormField(controller: controller, keyboardType: keyboardType, validator: validator, style: const TextStyle(color: Colors.white), decoration: _inputDecoration(label, icon));
  }
}
