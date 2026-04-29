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
    'Crop Farmer', 'Commercial Farmer', 'Backyard Gardener',
    'Agricultural Student', 'Extension Officer', 'Researcher', 'Other'
  ];

  final List<String> _regions = [
    'Ahafo', 'Ashanti', 'Bono East', 'Brong Ahafo', 'Central', 'Eastern', 
    'Greater Accra', 'North East', 'Northern', 'Oti', 'Savannah',
    'Upper East', 'Upper West', 'Volta', 'Western', 'Western North'
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
      } finally {
        setState(() => _isLoading = false);
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
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF9FBF9),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildSliverAppBar(context, colorScheme, provider, isDark),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildStatsRow(provider, colorScheme, isDark),
                        const SizedBox(height: 32),
                        if (!_isEditing) _buildViewMode(theme, colorScheme, provider, isDark)
                        else _buildEditMode(isDark, theme, colorScheme),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, ColorScheme colorScheme, AppProvider provider, bool isDark) {
    return SliverAppBar(
      expandedHeight: 340,
      pinned: true,
      backgroundColor: isDark ? const Color(0xFF1B2E1C) : colorScheme.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: Icon(_isEditing ? Icons.close_rounded : Icons.edit_note_rounded, size: 28),
          onPressed: () => setState(() {
            _isEditing = !_isEditing;
            if (!_isEditing) _loadUserProfile();
          }),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                isDark ? const Color(0xFF1B2E1C) : colorScheme.primary,
                isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF9FBF9),
              ],
              stops: const [0.6, 1.0],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white24, width: 2)),
                    child: CircleAvatar(
                      radius: 65,
                      backgroundColor: Colors.white10,
                      backgroundImage: provider.avatarUrl != null ? NetworkImage(provider.avatarUrl!) : null,
                      child: provider.avatarUrl == null ? const Icon(Icons.person, size: 60, color: Colors.white) : null,
                    ),
                  ),
                  if (_isEditing)
                    GestureDetector(
                      onTap: _pickAvatar,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: colorScheme.secondary, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                        child: const Icon(Icons.camera_alt_rounded, size: 18, color: Colors.white),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                '${_firstNameController.text} ${_surnameController.text}',
                style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -0.5),
              ),
              Text(
                _selectedProfession ?? 'Dedicated Farmer',
                style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow(AppProvider provider, ColorScheme colorScheme, bool isDark) {
    return Row(
      children: [
        _buildStatCard('Total Scans', provider.history.length.toString(), Icons.qr_code_scanner_rounded, Colors.blue, isDark),
        const SizedBox(width: 12),
        _buildStatCard('Schedules', provider.schedules.length.toString(), Icons.event_available_rounded, Colors.orange, isDark),
        const SizedBox(width: 12),
        _buildStatCard('Rank', provider.isGuest ? 'Free' : 'Pro', Icons.stars_rounded, Colors.amber, isDark),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildViewMode(ThemeData theme, ColorScheme colorScheme, AppProvider provider, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('PERSONAL INFORMATION'),
        _buildInfoCard(isDark, [
          _buildInfoRow(Icons.email_rounded, 'Email Address', _userEmail ?? 'Not Set', isDark),
          _buildInfoRow(Icons.phone_iphone_rounded, 'Phone Number', _phoneController.text, isDark),
          _buildInfoRow(Icons.location_on_rounded, 'Region / Location', _selectedRegion ?? 'Not Set', isDark),
        ]),
        const SizedBox(height: 24),
        _buildSectionHeader('FARMING PROFILE'),
        _buildInfoCard(isDark, [
          _buildInfoRow(Icons.work_rounded, 'Profession', _selectedProfession ?? 'Not Set', isDark),
          _buildInfoRow(Icons.calendar_month_rounded, 'Birth Date', _dobController.text, isDark),
          _buildInfoRow(Icons.wc_rounded, 'Gender', _selectedGender ?? 'Not Set', isDark),
        ]),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            onPressed: () { provider.signOut(); Navigator.pop(context); },
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            label: const Text('Sign Out', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w900)),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.all(20),
              backgroundColor: Colors.redAccent.withOpacity(0.1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(title, style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
    );
  }

  Widget _buildInfoCard(bool isDark, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
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
            decoration: BoxDecoration(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: Colors.green, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                Text(value.isEmpty ? 'Not Provided' : value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditMode(bool isDark, ThemeData theme, ColorScheme colorScheme) {
    return Column(
      children: [
        _buildTextField('First Name', _firstNameController, Icons.person_outline, isDark),
        const SizedBox(height: 16),
        _buildTextField('Surname', _surnameController, Icons.badge_outlined, isDark),
        const SizedBox(height: 16),
        _buildTextField('Phone Number', _phoneController, Icons.phone_android_rounded, isDark, isPhone: true),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _selectedRegion,
          decoration: _inputDecoration('Region / Location', Icons.location_on_outlined, isDark),
          items: _regions.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
          onChanged: (v) => setState(() => _selectedRegion = v),
          validator: (v) => v == null ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _selectedProfession,
          decoration: _inputDecoration('Profession', Icons.work_outline, isDark),
          items: _professions.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
          onChanged: (v) => setState(() => _selectedProfession = v),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: _saveProfile,
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 60),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 4,
          ),
          child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        ),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, bool isDark, {bool isPhone = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
      decoration: _inputDecoration(label, icon, isDark),
      validator: (v) => v!.isEmpty ? 'Required' : null,
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon, bool isDark) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.green),
      filled: true,
      fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: Colors.grey.withOpacity(0.1))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: Colors.grey.withOpacity(0.1))),
    );
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
        final provider = Provider.of<AppProvider>(context, listen: false);
        provider.setUserName('${_firstNameController.text} ${_surnameController.text}');
        setState(() { _isEditing = false; _isLoading = false; });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile Updated!')));
      } catch (e) {
        setState(() => _isLoading = false);
      }
    }
  }
}
