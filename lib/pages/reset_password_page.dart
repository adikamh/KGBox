import 'package:flutter/material.dart';

class ForgotPasswordPage extends StatelessWidget {
  final TextEditingController emailController;
  final GlobalKey<FormState> formKey;
  final bool isLoading;
  final VoidCallback onResetPassword;
  final VoidCallback onBackToLogin;

  const ForgotPasswordPage({
    super.key,
    required this.emailController,
    required this.formKey,
    required this.isLoading,
    required this.onResetPassword,
    required this.onBackToLogin,
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
                  // Logo/Icon
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha((0.15 * 255).round()),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.lock_reset_rounded,
                        size: 48,
                        color: Color(0xFF2965C0),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),
                  
                  // Title
                  const Text(
                    'RESET PASSWORD',
                    style: TextStyle(
                      fontSize: 28,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  
                  const SizedBox(height: 6),
                  
                  const Text(
                    'Masukkan email atau username Anda',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Reset Card
                  Container(
                    constraints: const BoxConstraints(maxWidth: 480),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha((0.95 * 255).round()),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha((0.18 * 255).round()),
                          blurRadius: 30,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          // Header
                          Row(
                            children: [
                              Container(
                                width: 4,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: gradientStart,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Reset Password',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Instructions
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.blue[100]!),
                            ),
                            child: const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.info_outline, size: 20, color: Colors.blue),
                                    SizedBox(width: 8),
                                    Text(
                                      'Informasi',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Masukkan email atau username Anda. Kami akan mengirimkan link reset password ke email terdaftar.',
                                  style: TextStyle(fontSize: 13, color: Colors.black87),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Form
                          Form(
                            key: formKey,
                            child: Column(
                              children: [
                                // Email/Username Field
                                TextFormField(
                                  controller: emailController,
                                  decoration: InputDecoration(
                                    labelText: 'Email atau Username',
                                    prefixIcon: const Icon(Icons.email_outlined),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    hintText: 'email@contoh.com atau username',
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Email atau username harus diisi';
                                    }
                                    return null;
                                  },
                                ),

                                const SizedBox(height: 28),

                                // Reset Button
                                SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: ElevatedButton(
                                    onPressed: isLoading ? null : onResetPassword,
                                    style: ElevatedButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: Ink(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [gradientStart, gradientEnd],
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Center(
                                        child: isLoading
                                            ? const SizedBox(
                                                width: 24,
                                                height: 24,
                                                child: CircularProgressIndicator(
                                                  color: Colors.white,
                                                  strokeWidth: 2.5,
                                                ),
                                              )
                                            : const Text(
                                                'Kirim Reset Link',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 20),

                                // Back to Login
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton(
                                    onPressed: isLoading ? null : onBackToLogin,
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(color: gradientStart),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                    ),
                                    child: Text(
                                      'Kembali ke Login',
                                      style: TextStyle(
                                        color: gradientStart,
                                        fontWeight: FontWeight.bold,
                                      ),
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
                  
                  // Footer
                  const Text(
                    '© 2024 Warehouse Management System',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}