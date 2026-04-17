import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../services/app_provider.dart';
import '../services/supabase_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final SupabaseService _supabaseService = SupabaseService();
  final ImagePicker _picker = ImagePicker();
  
  late TextEditingController _firstNameController;
  late TextEditingController _surnameController;
  late TextEditingController _phoneController;
  late TextEditingController _dobController;
  
  String? _selectedRegion;
  String? _selectedProfession;
  String? _selectedGender;
  String? _userEmail;
  bool _isEditing = false;
  bool _isLoading = true;
  bool _isLocationLoading = false;

  final List<String> _professions = [
    'Crop Farmer',
    'Commercial Farmer',
    'Backyard Gardener',
    'Agricultural Student',
    'Extension Officer',
    'Researcher',
    'Other'
  ];

  final List<String> _regions = [
    'Ahafo (Goaso)', 'Ashanti (Kumasi)', 'Bono East (Techiman)', 'Brong Ahafo (Sunyani)',
    'Central (Cape Coast)', 'Eastern (Koforidua)', 'Greater Accra (Accra)', 
    'North East (Nalerigu)', 'Northern (Tamale)', 'Oti (Dambai)', 'Savannah (Damongo)',
    'Upper East (Bolgatanga)', 'Upper West (Wa)', 'Volta (Ho)', 
    'Western (Sekondi-Takoradi)', 'Western North (Sefwi Wiaso)'
  ];

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _surnameController = TextEditingController();
    _phoneController = TextEditingController();
    _dobController = TextEditingController();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final profile = await _supabaseService.fetchUserProfile();
      _userEmail = _supabaseService.currentUser?.email;
      if (profile != null) {
        setState(() {
          _firstNameController.text = profile['first_name'] ?? '';
          _surnameController.text = profile['surname'] ?? '';
          _phoneController.text = profile['phone_number'] ?? '';
          _dobController.text = profile['dob'] ?? '';
          
          _selectedRegion = _regions.contains(profile['region']) ? profile['region'] : null;
          _selectedProfession = _professions.contains(profile['profession']) ? profile['profession'] : null;
          _selectedGender = profile['gender'];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _surnameController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (pickedFile != null) {
      setState(() => _isLoading = true);
      try {
        final provider = Provider.of<AppProvider>(context, listen: false);
        await provider.updateAvatar(File(pickedFile.path));
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile photo updated!')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime initialDate = DateTime.now().subtract(const Duration(days: 365 * 20));
    if (_dobController.text.isNotEmpty) {
      try {
        initialDate = DateFormat('yyyy-MM-dd').parse(_dobController.text);
      } catch (e) {}
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _isLocationLoading = true);
    try {
      final provider = Provider.of<AppProvider>(context, listen: false);
      await provider.useCurrentLocation();
      setState(() {
        final detected = provider.locationName;
        _selectedRegion = _regions.firstWhere(
          (r) => r.toLowerCase().contains(detected.toLowerCase()),
          orElse: () => _selectedRegion ?? _regions[1]
        );
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location updated to: ${provider.locationName}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting location: $e')),
        );
      }
    } finally {
      setState(() => _isLocationLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await _supabaseService.updateUserProfile(
          firstName: _firstNameController.text.trim(),
          surname: _surnameController.text.trim(),
          profession: _selectedProfession ?? '',
          region: _selectedRegion ?? '',
          phone: _phoneController.text.trim(),
          dob: _dobController.text,
          gender: _selectedGender ?? '',
        );
        
        if (mounted) {
          final provider = Provider.of<AppProvider>(context, listen: false);
          provider.setUserName('${_firstNameController.text} ${_surnameController.text}');
          
          setState(() {
            _isEditing = false;
            _isLoading = false;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully!')),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating profile: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final provider = Provider.of<AppProvider>(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Farmer Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          if (!_isLoading)
            IconButton(
              icon: Icon(_isEditing ? Icons.close_rounded : Icons.edit_rounded),
              onPressed: () => setState(() {
                _isEditing = !_isEditing;
                if (!_isEditing) _loadUserProfile();
              }),
            ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                _buildHeaderBackground(colorScheme, provider, isDark, theme),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        if (!_isEditing) ...[
                          _buildViewMode(theme, colorScheme, provider, isDark),
                        ] else ...[
                          _buildEditMode(isDark, theme),
                        ],
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildHeaderBackground(ColorScheme colorScheme, AppProvider provider, bool isDark, ThemeData theme) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : colorScheme.primary,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      child: Column(
        children: [
          _buildProfileHeader(colorScheme, provider),
          if (!_isEditing) ...[
            const SizedBox(height: 16),
            Text(
              '${_firstNameController.text} ${_surnameController.text}',
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              _selectedProfession ?? 'Farmer',
              style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProfileHeader(ColorScheme colorScheme, AppProvider provider) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        GestureDetector(
          onTap: _isEditing ? _pickAvatar : null,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white24,
            ),
            child: CircleAvatar(
              radius: 65,
              backgroundColor: Colors.white10,
              backgroundImage: provider.avatarUrl != null ? NetworkImage(provider.avatarUrl!) : null,
              child: provider.avatarUrl == null 
                ? const Icon(Icons.person_rounded, size: 80, color: Colors.white70)
                : null,
            ),
          ),
        ),
        if (_isEditing)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle),
            child: const Icon(Icons.camera_alt_rounded, size: 20, color: Colors.black87),
          ),
      ],
    );
  }

  Widget _buildViewMode(ThemeData theme, ColorScheme colorScheme, AppProvider provider, bool isDark) {
    return Column(
      children: [
        _buildInfoCard(isDark, [
          _buildInfoRow(Icons.email_outlined, 'Email', _userEmail ?? 'Not Set', isDark),
          _buildDivider(isDark),
          _buildInfoRow(Icons.wc_rounded, 'Gender', _selectedGender ?? 'Not Set', isDark),
          _buildDivider(isDark),
          _buildInfoRow(Icons.phone_rounded, 'Contact', _phoneController.text, isDark),
          _buildDivider(isDark),
          _buildInfoRow(Icons.cake_rounded, 'Date of Birth', _dobController.text, isDark),
          _buildDivider(isDark),
          _buildInfoRow(Icons.location_on_rounded, 'Region', _selectedRegion ?? 'Not Set', isDark),
        ]),
        const SizedBox(height: 32),
        ElevatedButton.icon(
          onPressed: () {
            provider.signOut();
            Navigator.pop(context);
          },
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: isDark ? Colors.red.withOpacity(0.2) : Colors.red[50],
            foregroundColor: Colors.redAccent,
            elevation: 0,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ],
    );
  }

  Widget _buildEditMode(bool isDark, ThemeData theme) {
    return Column(
      children: [
        _buildTextField('First Name', _firstNameController, Icons.person_outline, isDark),
        const SizedBox(height: 16),
        _buildTextField('Surname', _surnameController, Icons.badge_outlined, isDark),
        const SizedBox(height: 16),
        TextFormField(
          controller: _dobController,
          readOnly: true,
          onTap: () => _selectDate(context),
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
          decoration: _inputDecoration('Date of Birth', Icons.calendar_today_outlined, isDark),
          validator: (v) => v!.isEmpty ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
          decoration: _inputDecoration('Phone Number', Icons.phone_android_rounded, isDark),
          validator: (v) {
            if (v!.isEmpty) return 'Required';
            if (v.length < 10) return 'Must be 10 digits';
            return null;
          },
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _selectedProfession,
          isExpanded: true,
          dropdownColor: isDark ? const Color(0xFF2C2C2E) : Colors.white,
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
          decoration: _inputDecoration('Profession', Icons.work_outline, isDark),
          items: _professions.map((p) => DropdownMenuItem(value: p, child: Text(p, overflow: TextOverflow.ellipsis))).toList(),
          onChanged: (v) => setState(() => _selectedProfession = v),
          validator: (v) => v == null ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedRegion,
                isExpanded: true,
                dropdownColor: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                decoration: _inputDecoration('Region', Icons.map_outlined, isDark),
                items: _regions.map((r) => DropdownMenuItem(value: r, child: Text(r, overflow: TextOverflow.ellipsis))).toList(),
                onChanged: (v) => setState(() => _selectedRegion = v),
                validator: (v) => v == null ? 'Required' : null,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              height: 56,
              width: 56,
              decoration: BoxDecoration(
                color: isDark ? Colors.greenAccent.withOpacity(0.1) : Colors.green[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? Colors.greenAccent.withOpacity(0.3) : Colors.green.withOpacity(0.3)),
              ),
              child: IconButton(
                onPressed: _isLocationLoading ? null : _useCurrentLocation,
                icon: _isLocationLoading 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Icon(Icons.my_location_rounded, color: isDark ? Colors.greenAccent : Colors.green),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        FilledButton.icon(
          onPressed: _saveProfile,
          icon: const Icon(Icons.save_rounded),
          label: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 56),
            backgroundColor: isDark ? Colors.greenAccent : null,
            foregroundColor: isDark ? Colors.black : null,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(bool isDark, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(isDark ? 0.4 : 0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: isDark ? Colors.greenAccent : Colors.green, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(
                  value.isEmpty ? 'Not Set' : value,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(height: 1, indent: 70, color: isDark ? Colors.white10 : Colors.grey[200]);
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, bool isDark) {
    return TextFormField(
      controller: controller,
      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]'))],
      decoration: _inputDecoration(label, icon, isDark),
      validator: (v) => v!.isEmpty ? 'Required' : null,
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon, bool isDark) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: isDark ? Colors.grey : Colors.black54),
      prefixIcon: Icon(icon, color: isDark ? Colors.grey : Colors.green),
      filled: true,
      fillColor: isDark ? const Color(0xFF2C2C2E) : Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: isDark ? BorderSide.none : BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: isDark ? BorderSide.none : BorderSide(color: Colors.grey.shade300),
      ),
    );
  }
}
