import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/app_provider.dart';
import '../services/supabase_service.dart';
import 'signup_screen.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final messenger = ScaffoldMessenger.of(context);
      final navigator = Navigator.of(context);
      
      try {
        final provider = Provider.of<AppProvider>(context, listen: false);

        final response = await provider.signIn(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );

        if (!mounted) return;

        if (response.user != null) {
          navigator.pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        if (!mounted) return;
        messenger.showSnackBar(
          SnackBar(
            content: Text(e is AuthException ? e.message : 'Login failed'),
            backgroundColor: const Color(0xFFC62828),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _handleForgotPassword() {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your email address first'),
          backgroundColor: Color(0xFFFBC02D),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Reset Password?', style: TextStyle(color: Color(0xFF1B5E20), fontWeight: FontWeight.bold)),
        content: Text('We will send a reset link to $email.', style: const TextStyle(color: Colors.black54)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              
              navigator.pop();
              setState(() => _isLoading = true);
              try {
                await SupabaseService().resetPassword(email);
                if (!mounted) return;
                _showSuccessDialog(email);
              } catch (e) {
                if (!mounted) return;
                messenger.showSnackBar(
                  SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
                );
              } finally {
                if (mounted) setState(() => _isLoading = false);
              }
            },
            child: const Text('Send Link', style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String email) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.mark_email_read_rounded, color: Color(0xFF2E7D32), size: 48),
        title: const Text('Email Sent', style: TextStyle(color: Color(0xFF1B5E20), fontWeight: FontWeight.bold)),
        content: Text('Check $email for reset instructions.', style: const TextStyle(color: Colors.black54)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK', style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold)))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Hero(
                  tag: 'app_logo',
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        'assets/images/c10.jpg',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Welcome Back',
                  style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: Color(0xFF1B5E20), letterSpacing: -1),
                ),
                Text(
                  'Sign in to manage your cabbage farm.',
                  style: TextStyle(color: Colors.black.withValues(alpha: 0.4), fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 48),

                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildTextField(
                        controller: _emailController,
                        label: 'EMAIL ADDRESS',
                        hint: 'Enter your email',
                        icon: Icons.alternate_email_rounded,
                        keyboardType: TextInputType.emailAddress,
                        inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Email is required';
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)) return 'Invalid email format';
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      _buildTextField(
                        controller: _passwordController,
                        label: 'PASSWORD',
                        hint: 'Enter your password',
                        icon: Icons.lock_outline_rounded,
                        obscure: _obscurePassword,
                        inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
                        suffix: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                            color: const Color(0xFF2E7D32).withValues(alpha: 0.3),
                            size: 20,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Password is required' : null,
                      ),
                      
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _handleForgotPassword,
                          child: const Text('Forgot password?', style: TextStyle(color: Color(0xFFFBC02D), fontWeight: FontWeight.w700, fontSize: 13)),
                        ),
                      ),
                      
                      const SizedBox(height: 32),

                      ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 4,
                          shadowColor: const Color(0xFF2E7D32).withValues(alpha: 0.3),
                        ),
                        child: _isLoading 
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Sign In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 1)),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      TextButton(
                        onPressed: () {
                          provider.setGuestUser();
                          if (!mounted) return;
                          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const HomeScreen()), (route) => false);
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF2E7D32),
                          padding: const EdgeInsets.symmetric(vertical: 18),
                        ),
                        child: const Text('Continue as Guest', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 48),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("New here? ", style: TextStyle(color: Colors.black.withValues(alpha: 0.4), fontWeight: FontWeight.w500)),
                      GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SignUpScreen())),
                        child: const Text('Create Account', style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.w800, decoration: TextDecoration.underline)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    IconData? icon,
    bool obscure = false,
    Widget? suffix,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0, left: 4),
          child: Text(
            label,
            style: TextStyle(color: const Color(0xFF1B5E20).withValues(alpha: 0.6), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2),
          ),
        ),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          validator: validator,
          inputFormatters: inputFormatters,
          style: const TextStyle(color: Color(0xFF1B5E20), fontSize: 15, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: const Color(0xFF2E7D32).withValues(alpha: 0.4)),
            prefixIcon: icon != null ? Icon(icon, color: const Color(0xFF2E7D32), size: 20) : null,
            filled: true,
            fillColor: const Color(0xFFF1F8E9),
            suffixIcon: suffix,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: const Color(0xFF2E7D32).withValues(alpha: 0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFD32F2F)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFD32F2F), width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
