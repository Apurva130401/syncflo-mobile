import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:provider/provider.dart';
import '../../core/auth_provider.dart';
import '../../core/theme.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _mfaController = TextEditingController();
  bool _obscurePassword = true;
  bool _isEmailFocused = false;
  bool _isPasswordFocused = false;
  bool _isMfaFocused = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _mfaController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.mfaRequired) {
      if (_mfaController.text.trim().length != 6) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid 6-digit code')),
        );
        return;
      }
      try {
        await auth.verifyMfa(_mfaController.text.trim());
      } catch (_) {
        // Error displayed in UI via consumer
      }
    } else {
      if (!_formKey.currentState!.validate()) return;
      try {
        await auth.login(_emailController.text.trim(), _passwordController.text);
      } catch (_) {
        // Error displayed in UI via consumer
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080808),
      body: Stack(
        children: [
          // --- Ambient Background Glow Orbs ---
          Positioned(
            top: -100,
            left: -100,
            width: 300,
            height: 300,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            right: -100,
            width: 300,
            height: 300,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.03),
              ),
            ),
          ),
          // Blur filter to smooth out the glow orbs
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 80.0, sigmaY: 80.0),
              child: Container(color: Colors.transparent),
            ),
          ),

          // --- Content ---
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/logo_login.png',
                            width: 36,
                            height: 36,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'SyncFlo AI',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 48),

                      // Titles
                      Consumer<AuthProvider>(
                        builder: (context, auth, _) {
                          return Column(
                            children: [
                              Text(
                                auth.mfaRequired ? 'Verify it is you' : 'Welcome back',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 30,
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                auth.mfaRequired
                                    ? 'Enter the code from your authenticator app.'
                                    : 'Please enter your details.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 48),

                      // Error Box
                      Consumer<AuthProvider>(
                        builder: (context, auth, _) {
                          if (auth.error == null) return const SizedBox.shrink();
                          return Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 24),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.1),
                              border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(LucideIcons.triangle_alert, color: AppColors.error, size: 16),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    auth.error!,
                                    style: TextStyle(
                                      color: AppColors.error,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                      // Inputs and Buttons
                      Consumer<AuthProvider>(
                        builder: (context, auth, _) {
                          if (auth.mfaRequired) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // MFA input field
                                Focus(
                                  onFocusChange: (hasFocus) {
                                    setState(() {
                                      _isMfaFocused = hasFocus;
                                    });
                                  },
                                  child: TextFormField(
                                    controller: _mfaController,
                                    keyboardType: TextInputType.number,
                                    textInputAction: TextInputAction.done,
                                    onFieldSubmitted: (_) => _submit(),
                                    maxLength: 6,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      letterSpacing: 8,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    decoration: InputDecoration(
                                      labelText: 'Authenticator Code',
                                      labelStyle: TextStyle(
                                        color: _isMfaFocused ? Colors.white70 : Colors.white38,
                                        fontSize: 15,
                                        letterSpacing: 0,
                                      ),
                                      floatingLabelStyle: const TextStyle(color: Colors.white70, letterSpacing: 0),
                                      filled: false,
                                      counterText: '',
                                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                                      enabledBorder: const UnderlineInputBorder(
                                        borderSide: BorderSide(color: Colors.white10),
                                      ),
                                      focusedBorder: const UnderlineInputBorder(
                                        borderSide: BorderSide(color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 48),

                                // Verify Button
                                SizedBox(
                                  height: 52,
                                  child: ElevatedButton(
                                    onPressed: auth.isLoading ? null : _submit,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: Colors.black,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(26),
                                      ),
                                      elevation: 0,
                                      padding: EdgeInsets.zero,
                                    ),
                                    child: auth.isLoading
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                                            ),
                                          )
                                        : const Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                'Verify Code',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              SizedBox(width: 8),
                                              Icon(LucideIcons.shield_check, size: 16),
                                            ],
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 36),

                                // Cancel back link
                                GestureDetector(
                                  onTap: auth.isLoading
                                      ? null
                                      : () {
                                          _mfaController.clear();
                                          auth.cancelMfa();
                                        },
                                  child: const Center(
                                    child: Text(
                                      'Cancel',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Email input field
                              Focus(
                                onFocusChange: (hasFocus) {
                                  setState(() {
                                    _isEmailFocused = hasFocus;
                                  });
                                },
                                child: TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  style: const TextStyle(color: Colors.white, fontSize: 17),
                                  decoration: InputDecoration(
                                    labelText: 'Email Address',
                                    labelStyle: TextStyle(
                                      color: _isEmailFocused ? Colors.white70 : Colors.white38,
                                      fontSize: 15,
                                    ),
                                    floatingLabelStyle: const TextStyle(color: Colors.white70),
                                    filled: false,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                                    enabledBorder: const UnderlineInputBorder(
                                      borderSide: BorderSide(color: Colors.white10),
                                    ),
                                    focusedBorder: const UnderlineInputBorder(
                                      borderSide: BorderSide(color: Colors.white),
                                    ),
                                    errorBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(color: AppColors.error),
                                    ),
                                    focusedErrorBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(color: AppColors.error),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Email is required';
                                    }
                                    final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                                    if (!regex.hasMatch(value.trim())) {
                                      return 'Please enter a valid email address';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(height: 28),

                              // Password input field
                              Focus(
                                onFocusChange: (hasFocus) {
                                  setState(() {
                                    _isPasswordFocused = hasFocus;
                                  });
                                },
                                child: TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) => _submit(),
                                  style: const TextStyle(color: Colors.white, fontSize: 17),
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    labelStyle: TextStyle(
                                      color: _isPasswordFocused ? Colors.white70 : Colors.white38,
                                      fontSize: 15,
                                    ),
                                    floatingLabelStyle: const TextStyle(color: Colors.white70),
                                    filled: false,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                                    enabledBorder: const UnderlineInputBorder(
                                      borderSide: BorderSide(color: Colors.white10),
                                    ),
                                    focusedBorder: const UnderlineInputBorder(
                                      borderSide: BorderSide(color: Colors.white),
                                    ),
                                    errorBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(color: AppColors.error),
                                    ),
                                    focusedErrorBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(color: AppColors.error),
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword ? LucideIcons.eye_off : LucideIcons.eye,
                                        color: Colors.white38,
                                        size: 20,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Password is required';
                                    }
                                    if (value.length < 6) {
                                      return 'Password must be at least 6 characters';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(height: 48),

                              // Sign In Button
                              SizedBox(
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: auth.isLoading ? null : _submit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.black,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(26),
                                    ),
                                    elevation: 0,
                                    padding: EdgeInsets.zero,
                                  ),
                                  child: auth.isLoading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                                          ),
                                        )
                                      : const Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              'Sign In',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            SizedBox(width: 8),
                                            Icon(LucideIcons.arrow_right, size: 16),
                                          ],
                                        ),
                                ),
                              ),
                              const SizedBox(height: 36),

                              // Create Account footer
                              Column(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (_) => const SignupScreen()),
                                      );
                                    },
                                    child: const Text(
                                      'Create Account',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Privacy',
                                        style: TextStyle(color: Colors.white24, fontSize: 12),
                                      ),
                                      SizedBox(width: 16),
                                      Text(
                                        '•',
                                        style: TextStyle(color: Colors.white12, fontSize: 12),
                                      ),
                                      SizedBox(width: 16),
                                      Text(
                                        'Terms',
                                        style: TextStyle(color: Colors.white24, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
