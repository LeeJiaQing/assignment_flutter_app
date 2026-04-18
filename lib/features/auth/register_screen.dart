// lib/features/auth/register_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/di/app_dependencies.dart';
import 'viewmodels/auth_view_model.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocusNode = FocusNode();
  bool _obscurePassword = true;
  bool _hasInteractedWithPassword = false;

  bool get _showPasswordRequirements =>
      _passwordFocusNode.hasFocus || _hasInteractedWithPassword;

  @override
  void initState() {
    super.initState();
    _passwordFocusNode.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AuthViewModel(
        authRepository: context.read<AppDependencies>().authRepository,
      ),
      child: Builder(builder: (context) {
        final vm = context.watch<AuthViewModel>();

        if (vm.status == AuthStatus.success) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!context.mounted) return;
            Navigator.pushReplacementNamed(context, '/home');
          });
        }

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF1C3A2A)),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Create Account',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1C3A2A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Join CourtNow to book your favourite courts',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    const SizedBox(height: 32),

                    _buildLabel('Full Name'),
                    const SizedBox(height: 6),
                    _buildField(
                      controller: _nameController,
                      hint: 'Enter your full name',
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Name is required'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    _buildLabel('Email'),
                    const SizedBox(height: 6),
                    _buildField(
                      controller: _emailController,
                      hint: 'Enter your email',
                      keyboardType: TextInputType.emailAddress,
                      validator: _validateEmail,
                    ),
                    const SizedBox(height: 16),

                    _buildLabel('Password'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _passwordController,
                      focusNode: _passwordFocusNode,
                      obscureText: _obscurePassword,
                      onChanged: (_) {
                        if (!_hasInteractedWithPassword) {
                          setState(() => _hasInteractedWithPassword = true);
                        } else {
                          setState(() {});
                        }
                      },
                      decoration: _inputDecoration(
                        hint: 'Enter your password',
                        suffix: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: Colors.grey,
                          ),
                          onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (v) {
                        return _validatePassword(v);
                      },
                    ),
                    if (_showPasswordRequirements) ...[
                      const SizedBox(height: 8),
                      ..._passwordRequirementMessages(_passwordController.text)
                          .map(
                        (rule) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            '• $rule',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red.shade700,
                            ),
                          ),
                        ),
                      ),
                    ],

                    if (vm.errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Text(
                          vm.errorMessage!,
                          style: TextStyle(
                              color: Colors.red.shade700, fontSize: 13),
                        ),
                      ),
                    ],

                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1C894E),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        onPressed: vm.isLoading ? null : () => _submit(context, vm),
                        child: vm.isLoading
                            ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                            : const Text(
                          'Sign Up',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: RichText(
                          text: const TextSpan(
                            text: 'Already have an account? ',
                            style:
                            TextStyle(color: Colors.grey, fontSize: 14),
                            children: [
                              TextSpan(
                                text: 'Login',
                                style: TextStyle(
                                  color: Color(0xFF1C894E),
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildLabel(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: Color(0xFF1C3A2A),
    ),
  );

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) =>
      TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: _inputDecoration(hint: hint),
        validator: validator,
      );

  InputDecoration _inputDecoration({required String hint, Widget? suffix}) =>
      InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF1C894E)),
        ),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        suffixIcon: suffix,
      );

  Future<void> _submit(BuildContext context, AuthViewModel vm) async {
    if (!_formKey.currentState!.validate()) return;
    final email = _emailController.text.trim();

    final alreadyExists = await vm.doesEmailExist(email);
    if (alreadyExists) {
      if (!context.mounted) return;
      final goToSignIn = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Email already registered'),
          content: const Text(
            'This email has already signed up before. '
            'Please sign in or use a different email.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Use Different Email'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Go to Sign In'),
            ),
          ],
        ),
      );

      if (goToSignIn == true && context.mounted) {
        Navigator.pop(context);
      }
      return;
    }

    await vm.signUp(
      email: email,
      password: _passwordController.text,
      fullName: _nameController.text.trim(),
    );
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Email is required';
    if (!email.contains('@')) return 'Email must contain "@"';
    return null;
  }

  String? _validatePassword(String? value) {
    final requirements = _passwordRequirementMessages(value ?? '');
    if (requirements.isNotEmpty) {
      return requirements.first;
    }
    return null;
  }

  List<String> _passwordRequirementMessages(String password) {
    final missing = <String>[];
    if (password.isEmpty) missing.add('Password is required');
    if (password.length < 8) missing.add('At least 8 characters');
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      missing.add('At least 1 uppercase letter');
    }
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>\[\]\\/_\-+=~`]').hasMatch(password)) {
      missing.add('At least 1 special character');
    }
    return missing;
  }
}
