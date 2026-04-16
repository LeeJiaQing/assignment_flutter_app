// lib/features/auth/login_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/di/app_dependencies.dart';
import 'viewmodels/auth_view_model.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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
            // Navigate to main app
            Navigator.pushReplacementNamed(context, '/home');
          });
        }

        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo / App icon
                    Center(
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1C894E),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.sports_tennis,
                            color: Colors.white, size: 40),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Welcome text
                    const Center(
                      child: Text(
                        'Welcome! Nice to see you back again.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1C3A2A),
                        ),
                      ),
                    ),
                    const SizedBox(height: 36),

                    // Email field
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: 'Enter your email',
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
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Email is required'
                          : null,
                    ),
                    const SizedBox(height: 14),

                    // Password field
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        hintText: 'Password',
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
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: Colors.grey,
                          ),
                          onPressed: () =>
                              setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (v) => (v == null || v.isEmpty)
                          ? 'Password is required'
                          : null,
                    ),
                    const SizedBox(height: 8),

                    // Forgot password
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => _showForgotPasswordDialog(context, vm),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Forget Password?',
                          style: TextStyle(
                            color: Color(0xFF1C894E),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Error message
                    if (vm.errorMessage != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 12),
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

                    // Login button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6DCC98),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        onPressed: vm.isLoading
                            ? null
                            : () => _submit(context, vm),
                        child: vm.isLoading
                            ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                            : const Text(
                          'Login',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Sign up link
                    Center(
                      child: GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const RegisterScreen()),
                        ),
                        child: RichText(
                          text: const TextSpan(
                            text: 'New here? ',
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                            children: [
                              TextSpan(
                                text: 'Sign up now',
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

  Future<void> _submit(BuildContext context, AuthViewModel vm) async {
    if (!_formKey.currentState!.validate()) return;
    await vm.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
  }

  Future<void> _showForgotPasswordDialog(
    BuildContext context,
    AuthViewModel vm,
  ) async {
    final success = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ForgotPasswordDialog(
        vm: vm,
        initialEmail: _emailController.text,
      ),
    );

    if (!mounted || success != true) return;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      const SnackBar(
        content: Text(
            'Password updated successfully. Please login with your new password.'),
      ),
    );
  }
}

class _ForgotPasswordDialog extends StatefulWidget {
  const _ForgotPasswordDialog({required this.vm, required this.initialEmail});

  final AuthViewModel vm;
  final String initialEmail;

  @override
  State<_ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<_ForgotPasswordDialog> {
  late final TextEditingController _emailController;
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _codeSent = false;
  bool _codeVerified = false;
  bool _invalidEmail = false;
  bool _isBusy = false;
  String _message = '';
  int _secondsLeft = 0;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _emailController.dispose();
    _codeController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _secondsLeft = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        if (_secondsLeft > 0) {
          _secondsLeft--;
        } else {
          t.cancel();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AlertDialog(
        title: const Text('Reset Password'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  errorText: _invalidEmail ? 'Invalid email address.' : null,
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: _invalidEmail ? Colors.red : Colors.grey.shade400,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: _invalidEmail ? Colors.red : const Color(0xFF1C894E),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (_codeSent) ...[
                TextField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: const InputDecoration(
                    labelText: '6-digit verification code',
                    border: OutlineInputBorder(),
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 4),
                if (_secondsLeft > 0)
                  Text(
                    'Code expires in ${_secondsLeft}s',
                    style: const TextStyle(color: Colors.orange, fontSize: 12),
                  )
                else
                  const Text(
                    'Code expired. You can resend a new code.',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                const SizedBox(height: 12),
              ],
              TextField(
                controller: _newPasswordController,
                obscureText: _obscureNewPassword,
                enabled: _codeVerified,
                decoration: InputDecoration(
                  labelText: 'New password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureNewPassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                    onPressed: !_codeVerified
                        ? null
                        : () => setState(
                              () => _obscureNewPassword = !_obscureNewPassword,
                            ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                enabled: _codeVerified,
                decoration: InputDecoration(
                  labelText: 'Confirm new password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                    onPressed: !_codeVerified
                        ? null
                        : () => setState(
                              () => _obscureConfirmPassword =
                                  !_obscureConfirmPassword,
                            ),
                  ),
                ),
              ),
              if (_message.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  _message,
                  style: TextStyle(
                    color: _message.toLowerCase().contains('success')
                        ? Colors.green
                        : Colors.red,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isBusy
                ? null
                : () {
                    _timer?.cancel();
                    Navigator.of(context).pop(false);
                  },
            child: const Text('Close'),
          ),
          if (!_codeSent)
            ElevatedButton(
              onPressed: _isBusy ? null : _onSendCode,
              child: const Text('Send code'),
            )
          else ...[
            TextButton(
              onPressed: _isBusy || _secondsLeft > 0 ? null : _onResendCode,
              child: const Text('Resend code'),
            ),
            if (!_codeVerified)
              ElevatedButton(
                onPressed: _isBusy ? null : _onVerifyCode,
                child: const Text('Verify code'),
              ),
            if (_codeVerified)
              ElevatedButton(
                onPressed: _isBusy ? null : _onChangePassword,
                child: const Text('Change password'),
              ),
          ],
        ],
      ),
    );
  }

  Future<void> _onSendCode() async {
    FocusScope.of(context).unfocus();
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() {
        _invalidEmail = true;
        _message = 'Email is required.';
      });
      return;
    }

    setState(() {
      _isBusy = true;
      _invalidEmail = false;
      _message = '';
    });

    try {
      final exists = await widget.vm.doesEmailExist(email);
      if (!exists) {
        setState(() {
          _invalidEmail = true;
          _message = 'Invalid email address.';
        });
        return;
      }

      await widget.vm.sendPasswordResetCode(email);
      if (!mounted) return;
      setState(() {
        _codeSent = true;
        _message = 'Verification code sent to your email.';
      });
      _startCountdown();
    } catch (e) {
      if (!mounted) return;
      setState(() => _message = 'Failed to send code: $e');
    } finally {
      if (!mounted) return;
      setState(() => _isBusy = false);
    }
  }

  Future<void> _onResendCode() async {
    final email = _emailController.text.trim();
    setState(() {
      _isBusy = true;
      _message = '';
    });
    try {
      await widget.vm.sendPasswordResetCode(email);
      if (!mounted) return;
      setState(() => _message = 'New verification code sent.');
      _startCountdown();
    } catch (e) {
      if (!mounted) return;
      setState(() => _message = 'Failed to resend code: $e');
    } finally {
      if (!mounted) return;
      setState(() => _isBusy = false);
    }
  }

  Future<void> _onVerifyCode() async {
    final email = _emailController.text.trim();
    final code = _codeController.text.trim();
    if (_secondsLeft <= 0) {
      setState(() => _message = 'Code expired. Please resend and try again.');
      return;
    }
    if (code.length != 6) {
      setState(() => _message = 'Please enter the 6-digit verification code.');
      return;
    }

    setState(() {
      _isBusy = true;
      _message = '';
    });
    try {
      final verified = await widget.vm.verifyPasswordResetCode(
        email: email,
        code: code,
      );
      if (!mounted) return;
      if (verified) {
        _timer?.cancel();
        setState(() {
          _codeVerified = true;
          _message = 'Code verified. You can now set a new password.';
        });
      } else {
        setState(() => _message = 'Invalid code. Please try again.');
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _message = 'Invalid code. Please try again.');
    } finally {
      if (!mounted) return;
      setState(() => _isBusy = false);
    }
  }

  Future<void> _onChangePassword() async {
    final password = _newPasswordController.text;
    final confirm = _confirmPasswordController.text;

    if (password.length < 6) {
      setState(() => _message = 'Password must be at least 6 characters.');
      return;
    }
    if (password != confirm) {
      setState(() => _message = 'Password confirmation does not match.');
      return;
    }

    setState(() {
      _isBusy = true;
      _message = '';
    });
    try {
      await widget.vm.updatePassword(password);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _message = 'Failed to update password: $e');
    } finally {
      if (!mounted) return;
      setState(() => _isBusy = false);
    }
  }
}
