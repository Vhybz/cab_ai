import 'dart:io';
import 'package:flutter/material.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Farmer Profile'),
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
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildProfileHeader(colorScheme, provider),
                  const SizedBox(height: 24),
                  
                  if (!_isEditing) ...[
                    _buildViewMode(theme, colorScheme, provider),
                  ] else ...[
                    _buildEditMode(),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
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
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: colorScheme.primary, width: 2),
            ),
            child: CircleAvatar(
              radius: 60,
              backgroundColor: colorScheme.primary.withOpacity(0.1),
              backgroundImage: provider.avatarUrl != null ? NetworkImage(provider.avatarUrl!) : null,
              child: provider.avatarUrl == null 
                ? Icon(Icons.person_rounded, size: 80, color: colorScheme.primary)
                : null,
            ),
          ),
        ),
        if (_isEditing)
          CircleAvatar(
            backgroundColor: colorScheme.primary,
            radius: 18,
            child: const Icon(Icons.camera_alt_rounded, size: 18, color: Colors.white),
          ),
      ],
    );
  }

  Widget _buildViewMode(ThemeData theme, ColorScheme colorScheme, AppProvider provider) {
    return Column(
      children: [
        Text(
          '${_firstNameController.text} ${_surnameController.text}',
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          _selectedProfession ?? 'Farmer',
          style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 32),
        _buildInfoTile(Icons.email_outlined, 'Email', _userEmail ?? 'Not Set'),
        _buildInfoTile(Icons.wc_rounded, 'Gender', _selectedGender ?? 'Not Set'),
        _buildInfoTile(Icons.phone_rounded, 'Contact', _phoneController.text),
        _buildInfoTile(Icons.cake_rounded, 'Date of Birth', _dobController.text),
        _buildInfoTile(Icons.location_on_rounded, 'Region', _selectedRegion ?? 'Not Set'),
        const SizedBox(height: 40),
        OutlinedButton.icon(
          onPressed: () {
            provider.signOut();
            Navigator.pop(context);
          },
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Sign Out'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.redAccent,
            side: const BorderSide(color: Colors.redAccent),
            minimumSize: const Size(double.infinity, 50),
          ),
        ),
      ],
    );
  }

  Widget _buildEditMode() {
    return Column(
      children: [
        _buildTextField('First Name', _firstNameController, Icons.person_outline),
        const SizedBox(height: 16),
        _buildTextField('Surname', _surnameController, Icons.badge_outlined),
        const SizedBox(height: 16),
        TextFormField(
          controller: _dobController,
          readOnly: true,
          onTap: () => _selectDate(context),
          decoration: _inputDecoration('Date of Birth', Icons.calendar_today_outlined),
          validator: (v) => v!.isEmpty ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        _buildTextField('Phone Number', _phoneController, Icons.phone_android_rounded, TextInputType.phone),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _selectedProfession,
          isExpanded: true,
          decoration: _inputDecoration('Profession', Icons.work_outline),
          items: _professions.map((p) => DropdownMenuItem(value: p, child: Text(p, overflow: TextOverflow.ellipsis))).toList(),
          onChanged: (v) => setState(() => _selectedProfession = v),
          validator: (v) => v == null ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _selectedRegion,
          isExpanded: true,
          decoration: _inputDecoration('Region', Icons.map_outlined),
          items: _regions.map((r) => DropdownMenuItem(value: r, child: Text(r, overflow: TextOverflow.ellipsis))).toList(),
          onChanged: (v) => setState(() => _selectedRegion = v),
          validator: (v) => v == null ? 'Required' : null,
        ),
        const SizedBox(height: 40),
        FilledButton.icon(
          onPressed: _saveProfile,
          icon: const Icon(Icons.save_rounded),
          label: const Text('Save Changes'),
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey),
      title: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      subtitle: Text(value.isEmpty ? 'Not Set' : value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, [TextInputType? type]) {
    return TextFormField(
      controller: controller,
      keyboardType: type,
      decoration: _inputDecoration(label, icon),
      validator: (v) => v!.isEmpty ? 'Required' : null,
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}
