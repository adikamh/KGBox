import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

class LoginPage extends StatelessWidget {
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final GlobalKey<FormState> formKey;
  final bool isLoading;
  final bool obscurePassword;
  final VoidCallback onToggleObscure;
  final VoidCallback onLogin;
  final VoidCallback onForgotPassword;
  final VoidCallback onRegister;

  const LoginPage({
    super.key,
    required this.usernameController,
    required this.passwordController,
    required this.formKey,
    required this.isLoading,
    required this.obscurePassword,
    required this.onToggleObscure,
    required this.onLogin,
    required this.onForgotPassword,
    required this.onRegister,
  });

  @override
  Widget build(BuildContext context) {
    final gradientStart = const Color(0xFF2965C0);
    final gradientEnd = const Color(0xFF3EA343);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [gradientStart, gradientEnd],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black.withAlpha((0.15 * 255).round()), blurRadius: 20, offset: const Offset(0, 8))],
                    ),
                    child: const Center(
                      child: Icon(Icons.warehouse_rounded, size: 48, color: Color(0xFF2965C0)),
                    ),
                  ),

                  const SizedBox(height: 18),
                  const Text('WAREHOUSE', style: TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2)),
                  const SizedBox(height: 6),
                  const Text('Management System', style: TextStyle(fontSize: 14, color: Colors.white70)),

                  const SizedBox(height: 24),

                  // Login Card
                  Container(
                    constraints: const BoxConstraints(maxWidth: 480),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha((0.95 * 255).round()),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [BoxShadow(color: Colors.black.withAlpha((0.18 * 255).round()), blurRadius: 30, offset: const Offset(0, 12))],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(width: 4, height: 28, decoration: BoxDecoration(color: gradientStart, borderRadius: BorderRadius.circular(4))),
                              const SizedBox(width: 12),
                              const Text('Login', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                            ],
                          ),

                          const SizedBox(height: 18),

                          Form(
                            key: formKey,
                            child: Column(
                              children: [
                                // Username
                                TextFormField(
                                  controller: usernameController,
                                  decoration: InputDecoration(
                                    labelText: 'Username', // Tetap "Username"
                                    prefixIcon: const Icon(Icons.person_outline),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    hintText: 'masukkan username Anda', // Hint update
                                  ),
                                  validator: (v) => (v == null || v.isEmpty) ? 'Username harus diisi' : null,
                                ),
                                const SizedBox(height: 12),

                                // Password
                                TextFormField(
                                  controller: passwordController,
                                  obscureText: obscurePassword,
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    prefixIcon: const Icon(Icons.lock_outline),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    suffixIcon: IconButton(
                                      icon: Icon(obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                                      onPressed: onToggleObscure,
                                    ),
                                  ),
                                  validator: (v) => (v == null || v.isEmpty) ? 'Password harus diisi' : null,
                                ),

                                const SizedBox(height: 18),

                                // Gradient Login Button
                                SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: ElevatedButton(
                                    onPressed: isLoading ? null : onLogin,
                                    style: ElevatedButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    ),
                                    child: Ink(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(colors: [gradientStart, gradientEnd]),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Center(
                                        child: isLoading
                                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                            : const Text('Login', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 14),

                                // Inline polished: "Daftar atau Lupa password"
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: RichText(
                                    textAlign: TextAlign.center,
                                    text: TextSpan(
                                      style: TextStyle(color: Colors.grey[700], fontSize: 14),
                                      children: [
                                        TextSpan(
                                          text: 'Daftar',
                                          style: TextStyle(color: gradientStart, fontWeight: FontWeight.bold),
                                          recognizer: TapGestureRecognizer()..onTap = onRegister,
                                        ),
                                        TextSpan(text: ' atau ', style: TextStyle(color: Colors.grey[700])),
                                        TextSpan(
                                          text: 'Lupa password?',
                                          style: TextStyle(color: gradientStart, fontWeight: FontWeight.bold),
                                          recognizer: TapGestureRecognizer()..onTap = onForgotPassword,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),
                  const Text('© 2024 Warehouse Management System', style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
