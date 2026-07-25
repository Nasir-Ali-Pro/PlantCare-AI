import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/garden_provider.dart';
import '../../widgets/app_card.dart';
import '../../services/api/supabase_service.dart';

class AuthScreen extends StatefulWidget {
  final VoidCallback onAuthenticated;

  const AuthScreen({super.key, required this.onAuthenticated});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();

  bool _isSignUp = false;
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _showVerificationBanner = false;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _toggleFormMode() {
    setState(() {
      _isSignUp = !_isSignUp;
      _showVerificationBanner = false;
      _formKey.currentState?.reset();
      _nameController.clear();
      _emailController.clear();
      _passwordController.clear();
      _confirmPasswordController.clear();
    });
  }

  Future<void> _submitAuthForm() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final gardenProvider = Provider.of<GardenProvider>(context, listen: false);

    try {
      if (_isSignUp) {
        final String displayName = _nameController.text.trim();
        final String email = _emailController.text.trim();
        final String password = _passwordController.text;

        await gardenProvider.registerUser(displayName, email, password);
        if (!mounted) return;

        setState(() {
          _showVerificationBanner = true;
          _isSignUp = false;
          _passwordController.clear();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Account created! Please check your email to verify your address, $displayName.'),
            backgroundColor: AppColors.primary,
            duration: const Duration(seconds: 5),
          ),
        );
      } else {
        final String email = _emailController.text.trim();
        final String password = _passwordController.text;

        await gardenProvider.authenticateUser(email, password);
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Signed in successfully.'),
            backgroundColor: AppColors.primary,
          ),
        );
        widget.onAuthenticated();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: AppColors.onSurface, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(e.toString().replaceAll('Exception: ', ''))),
            ],
          ),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your email address first.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    try {
      if (!SupabaseService().isConfigured) {
        throw Exception('Service not configured.');
      }
      await SupabaseService().client.auth.resetPasswordForEmail(email);
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.mark_email_read_rounded, color: AppColors.primary),
              SizedBox(width: 10),
              Text('Email Sent', style: TextStyle(color: Colors.white)),
            ],
          ),
          content: Text(
            'A password reset link has been sent to $email. Please check your inbox.',
            style: const TextStyle(color: Colors.white70, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not send reset email: ${e.toString().replaceAll("Exception: ", "")}'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  void _handleGuestBypass() {
    final gardenProvider = Provider.of<GardenProvider>(context, listen: false);
    gardenProvider.continueAsGuestUser();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Continuing as guest. Some features are limited.'),
        backgroundColor: AppColors.warning,
      ),
    );

    widget.onAuthenticated();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary.withValues(alpha: 0.08),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1.5),
                        ),
                        child: const Icon(
                          Icons.eco_rounded,
                          size: 55,
                          color: AppColors.primary,
                        ),
                      ).animate().scale(duration: 300.ms, curve: Curves.easeOut),
                      const SizedBox(height: 16),
                      Text(
                        'PlantCare',
                        style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 28),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Your plant health companion',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.onSurfaceMuted,
                              fontSize: 13,
                              letterSpacing: 0.3,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                if (_showVerificationBanner)
                  Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.mark_email_unread_rounded, color: AppColors.primary, size: 22),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Verify Your Email',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'A verification link was sent to your inbox. Please verify your email, then sign in below.',
                                style: TextStyle(color: Colors.white70, fontSize: 12.5, height: 1.4),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ).animate().fade(duration: 300.ms).slideY(begin: -0.1),

                Form(
                  key: _formKey,
                  child: AppCard(
                    borderRadius: 16,
                    elevated: true,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildFormTab('Log In', !_isSignUp),
                            _buildFormTab('Sign Up', _isSignUp),
                          ],
                        ),
                        Divider(color: AppColors.border, height: 32),

                        if (_isSignUp) ...[
                          _buildTextField(
                            controller: _nameController,
                            hintText: 'Full Name',
                            icon: Icons.person_rounded,
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) return 'Please enter your name.';
                              return null;
                            },
                          ).animate().fade(duration: 300.ms).slideY(begin: -0.1),
                          const SizedBox(height: 16),
                        ],

                        _buildTextField(
                          controller: _emailController,
                          hintText: 'Email Address',
                          icon: Icons.email_rounded,
                          keyboardType: TextInputType.emailAddress,
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'Please enter email.';
                            if (!val.contains('@') || !val.contains('.')) return 'Invalid email address.';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        _buildTextField(
                          controller: _passwordController,
                          hintText: 'Password',
                          icon: Icons.lock_rounded,
                          obscureText: _obscurePassword,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                              color: AppColors.onSurfaceFaint,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          validator: (val) {
                            if (val == null || val.isEmpty) return 'Please enter password.';
                            if (val.length < 6) return 'Password must be at least 6 characters.';
                            return null;
                          },
                        ),
                        const SizedBox(height: 6),

                        if (!_isSignUp)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _handleForgotPassword,
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                                minimumSize: const Size(0, 32),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                'Forgot Password?',
                                style: TextStyle(color: AppColors.primary, fontSize: 12.5, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),

                        if (_isSignUp) ...[
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _confirmPasswordController,
                            hintText: 'Confirm Password',
                            icon: Icons.lock_clock_rounded,
                            obscureText: _obscurePassword,
                            validator: (val) {
                              if (val != _passwordController.text) return 'Passwords do not match.';
                              return null;
                            },
                          ).animate().fade(duration: 300.ms).slideY(begin: 0.1),
                          const SizedBox(height: 20),
                        ] else
                          const SizedBox(height: 12),

                        ElevatedButton(
                          onPressed: _isLoading ? null : _submitAuthForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.onSurface,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 4,
                            shadowColor: AppColors.primary.withValues(alpha: 0.3),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : Text(
                                  _isSignUp ? 'Create Account' : 'Sign In',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.3),
                                ),
                        ),
                      ],
                    ),
                  ),
                ).animate().fade(delay: 100.ms, duration: 300.ms).slideY(begin: 0.05),
                const SizedBox(height: 24),

                Center(
                  child: TextButton.icon(
                    onPressed: _handleGuestBypass,
                    icon: const Icon(Icons.arrow_forward_rounded, color: AppColors.warning, size: 18),
                    label: const Text(
                      'Continue as Guest',
                      style: TextStyle(
                        color: AppColors.warning,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 4,
                  children: [
                    const Text(
                      'By continuing you agree to our',
                      style: TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pushNamed('/privacy-policy'),
                      child: const Text(
                        'Privacy Policy',
                        style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const Text(' & ', style: TextStyle(color: Colors.white38, fontSize: 11)),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pushNamed('/terms-of-service'),
                      child: const Text(
                        'Terms of Service',
                        style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormTab(String title, bool isSelected) {
    return GestureDetector(
      onTap: _toggleFormMode,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          border: isSelected ? const Border(bottom: BorderSide(color: AppColors.primary, width: 2.0)) : null,
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? AppColors.onSurface : AppColors.onSurfaceFaint,
            fontWeight: FontWeight.bold,
            fontSize: 14,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(color: AppColors.onSurface, fontSize: 13.5),
      validator: validator,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: AppColors.onSurfaceFaint, fontSize: 13),
        prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: AppColors.surfaceHighlight,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }
}
