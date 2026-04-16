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
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Logo / App icon
                    Image.asset(
                      'assets/images/logo.png',
                      width: 90,
                      height: 90,
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
    BuildContext screenContext,
    AuthViewModel vm,
  ) async {
    final emailController = TextEditingController(text: _emailController.text);
    final codeController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    var codeSent = false;
    var codeVerified = false;
    var invalidEmail = false;
    var isBusy = false;
    var message = '';
    var secondsLeft = 0;
    var obscureNewPassword = true;
    var obscureConfirmPassword = true;
    var isDialogOpen = true;
    Timer? timer;

    void startCountdown(void Function(void Function()) setState) {
      timer?.cancel();
      setState(() => secondsLeft = 60);
      timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) {
          t.cancel();
          return;
        }
        setState(() {
          if (secondsLeft > 0) {
            secondsLeft--;
          } else {
            t.cancel();
          }
        });
      });
    }

    try {
      await showDialog<void>(
        context: screenContext,
        barrierDismissible: false,
        builder: (dialogContext) {
          return PopScope(
            canPop: false,
            child: StatefulBuilder(
              builder: (builderContext, setState) {
                return AlertDialog(
                  title: const Text('Reset Password'),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                      TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          errorText:
                              invalidEmail ? 'Invalid email address.' : null,
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: invalidEmail
                                  ? Colors.red
                                  : Colors.grey.shade400,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: invalidEmail
                                  ? Colors.red
                                  : const Color(0xFF1C894E),
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (codeSent) ...[
                        TextField(
                          controller: codeController,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          decoration: const InputDecoration(
                            labelText: '6-digit verification code',
                            border: OutlineInputBorder(),
                            counterText: '',
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (secondsLeft > 0)
                          Text(
                            'Code expires in ${secondsLeft}s',
                            style: const TextStyle(
                              color: Colors.orange,
                              fontSize: 12,
                            ),
                          )
                        else
                          const Text(
                            'Code expired. You can resend a new code.',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                            ),
                          ),
                        const SizedBox(height: 12),
                      ],
                      TextField(
                        controller: newPasswordController,
                        obscureText: obscureNewPassword,
                        enabled: codeVerified,
                        decoration: InputDecoration(
                          labelText: 'New password',
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscureNewPassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                            onPressed: !codeVerified
                                ? null
                                : () => setState(
                                      () => obscureNewPassword =
                                          !obscureNewPassword,
                                    ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: confirmPasswordController,
                        obscureText: obscureConfirmPassword,
                        enabled: codeVerified,
                        decoration: InputDecoration(
                          labelText: 'Confirm new password',
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscureConfirmPassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                            onPressed: !codeVerified
                                ? null
                                : () => setState(
                                      () => obscureConfirmPassword =
                                          !obscureConfirmPassword,
                                    ),
                          ),
                        ),
                      ),
                      if (message.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          message,
                          style: TextStyle(
                            color: message.toLowerCase().contains('success')
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
                    onPressed: isBusy
                        ? null
                        : () {
                            isDialogOpen = false;
                            timer?.cancel();
                            Navigator.of(dialogContext).pop();
                          },
                    child: const Text('Close'),
                  ),
                  if (!codeSent)
                    ElevatedButton(
                      onPressed: isBusy
                          ? null
                          : () async {
                              FocusScope.of(builderContext).unfocus();
                              final email = emailController.text.trim();
                              if (email.isEmpty) {
                                setState(() {
                                  invalidEmail = true;
                                  message = 'Email is required.';
                                });
                                return;
                              }

                              setState(() {
                                isBusy = true;
                                invalidEmail = false;
                                message = '';
                              });

                              try {
                                final exists = await vm.doesEmailExist(email);
                                if (!exists) {
                                  setState(() {
                                    invalidEmail = true;
                                    message = 'Invalid email address.';
                                  });
                                  return;
                                }

                                await vm.sendPasswordResetCode(email);
                                setState(() {
                                  codeSent = true;
                                  message =
                                      'Verification code sent to your email.';
                                });
                                startCountdown(setState);
                              } catch (e) {
                                setState(() {
                                  message = 'Failed to send code: $e';
                                });
                              } finally {
                                if (!isDialogOpen) return;
                                setState(() => isBusy = false);
                              }
                            },
                      child: const Text('Send code'),
                    )
                  else ...[
                    TextButton(
                      onPressed: isBusy || secondsLeft > 0
                          ? null
                          : () async {
                              final email = emailController.text.trim();
                              setState(() {
                                isBusy = true;
                                message = '';
                              });
                              try {
                                await vm.sendPasswordResetCode(email);
                                setState(() {
                                  message = 'New verification code sent.';
                                });
                                startCountdown(setState);
                              } catch (e) {
                                setState(() {
                                  message = 'Failed to resend code: $e';
                                });
                              } finally {
                                if (!isDialogOpen) return;
                                setState(() => isBusy = false);
                              }
                            },
                      child: const Text('Resend code'),
                    ),
                    if (!codeVerified)
                      ElevatedButton(
                        onPressed: isBusy
                            ? null
                            : () async {
                                final email = emailController.text.trim();
                                final code = codeController.text.trim();
                                if (secondsLeft <= 0) {
                                  setState(() {
                                    message =
                                        'Code expired. Please resend and try again.';
                                  });
                                  return;
                                }
                                if (code.length != 6) {
                                  setState(() {
                                    message =
                                        'Please enter the 6-digit verification code.';
                                  });
                                  return;
                                }

                                setState(() {
                                  isBusy = true;
                                  message = '';
                                });
                                try {
                                  final verified =
                                      await vm.verifyPasswordResetCode(
                                    email: email,
                                    code: code,
                                  );
                                  if (verified) {
                                    timer?.cancel();
                                    setState(() {
                                      codeVerified = true;
                                      message =
                                          'Code verified. You can now set a new password.';
                                    });
                                  } else {
                                    setState(() {
                                      message =
                                          'Invalid code. Please try again.';
                                    });
                                  }
                                } catch (_) {
                                  setState(() {
                                    message =
                                        'Invalid code. Please try again.';
                                  });
                                } finally {
                                  if (!isDialogOpen) return;
                                  setState(() => isBusy = false);
                                }
                              },
                        child: const Text('Verify code'),
                      ),
                    if (codeVerified)
                      ElevatedButton(
                        onPressed: isBusy
                            ? null
                            : () async {
                                final password = newPasswordController.text;
                                final confirm = confirmPasswordController.text;

                                if (password.length < 6) {
                                  setState(() {
                                    message =
                                        'Password must be at least 6 characters.';
                                  });
                                  return;
                                }
                                if (password != confirm) {
                                  setState(() {
                                    message = 'Password confirmation does not match.';
                                  });
                                  return;
                                }

                                setState(() {
                                  isBusy = true;
                                  message = '';
                                });
                                try {
                                  await vm.updatePassword(password);
                                  if (!mounted) return;
                                  isDialogOpen = false;
                                  if (Navigator.of(dialogContext).canPop()) {
                                    Navigator.of(dialogContext).pop();
                                  }
                                  WidgetsBinding.instance.addPostFrameCallback((_) {
                                    if (!mounted) return;
                                    ScaffoldMessenger.maybeOf(screenContext)
                                        ?.showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Password updated successfully. Please login with your new password.'),
                                      ),
                                    );
                                  });
                                } catch (e) {
                                  setState(() {
                                    message = 'Failed to update password: $e';
                                  });
                                } finally {
                                  if (!isDialogOpen) return;
                                  setState(() => isBusy = false);
                                }
                              },
                        child: const Text('Change password'),
                      ),
                  ],
                  ],
                );
              },
            ),
          );
        },
      );
    } finally {
      timer?.cancel();
      emailController.dispose();
      codeController.dispose();
      newPasswordController.dispose();
      confirmPasswordController.dispose();
    }
  }
}
