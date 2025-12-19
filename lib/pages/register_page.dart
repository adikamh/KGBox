import 'package:flutter/material.dart';

class RegisterPage extends StatelessWidget {
  final TextEditingController usernameController; // Diganti: username saja
  final TextEditingController companyNameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final GlobalKey<FormState> formKey;
  final bool isLoading;
  final bool obscurePassword;
  final bool obscureConfirmPassword;
  final bool isCheckingUsername; // Untuk loading indicator
  final bool usernameAvailable; // Untuk checkmark/error icon
  final String usernameError; // Error message untuk username
  final VoidCallback onToggleObscurePassword;
  final VoidCallback onToggleObscureConfirmPassword;
  final VoidCallback onRegister;
  final VoidCallback onNavigateToLogin;

  const RegisterPage({
    super.key,
    required this.companyNameController,
    required this.usernameController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.formKey,
    required this.isLoading,
    required this.obscurePassword,
    required this.obscureConfirmPassword,
    required this.isCheckingUsername,
    required this.usernameAvailable,
    required this.usernameError,
    required this.onToggleObscurePassword,
    required this.onToggleObscureConfirmPassword,
    required this.onRegister,
    required this.onNavigateToLogin,
  });

  @override
  Widget build(BuildContext context) {
    final gradientStart = const Color(0xFF2965C0);
    final gradientEnd = const Color(0xFF3EA343);
    final textTheme = Theme.of(context).textTheme;

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
                        Icons.business_rounded,
                        size: 48,
                        color: Color(0xFF2965C0),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),
                  
                  // Title
                  const Text(
                    'REGISTRASI OWNER',
                    style: TextStyle(
                      fontSize: 28,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  
                  const SizedBox(height: 6),
                  
                  const Text(
                    'Buat akun untuk mengelola bisnis Anda',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Registration Card
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
                          // Header Section
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
                                'Data Owner',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Form Section
                          Form(
                            key: formKey,
                            child: Column(
                              children: [
                                // NAMA GUDANG (company name) - tampilkan pertama
                                TextFormField(
                                  controller: companyNameController,
                                  decoration: InputDecoration(
                                    labelText: 'Nama Gudang*',
                                    prefixIcon: const Icon(Icons.storefront_outlined),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    hintText: 'Nama gudang / bisnis Anda',
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Nama gudang harus diisi';
                                    }
                                    return null;
                                  },
                                ),

                                const SizedBox(height: 12),

                                // USERNAME FIELD (untuk login dan display)
                                TextFormField(
                                  controller: usernameController,
                                  decoration: InputDecoration(
                                    labelText: 'Username*',
                                    prefixIcon: const Icon(Icons.person_outline),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    hintText: 'username.anda (untuk login)',
                                    suffixIcon: isCheckingUsername
                                        ? const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          )
                                        : usernameController.text.isNotEmpty
                                            ? Icon(
                                                usernameAvailable 
                                                    ? Icons.check_circle 
                                                    : Icons.error,
                                                color: usernameAvailable 
                                                    ? Colors.green 
                                                    : Colors.red,
                                              )
                                            : null,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Username wajib diisi';
                                    }
                                    if (!RegExp(r'^[a-zA-Z0-9._]+$').hasMatch(value)) {
                                      return 'Hanya huruf, angka, titik, underscore';
                                    }
                                    if (value.length < 3 || value.length > 20) {
                                      return 'Username 3-20 karakter';
                                    }
                                    if (!usernameAvailable) {
                                      return 'Username sudah digunakan';
                                    }
                                    return null;
                                  },
                                ),

                                // Username Error Message
                                if (usernameError.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4, left: 12),
                                    child: Text(
                                      usernameError,
                                      style: TextStyle(
                                        color: Colors.red.shade700,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),

                                // Username Info
                                Container(
                                  margin: const EdgeInsets.only(top: 8, bottom: 16),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[50],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.blue[100]!),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Row(
                                        children: [
                                          Icon(Icons.info_outline, size: 16, color: Colors.blue),
                                          SizedBox(width: 8),
                                          Text(
                                            'Username Anda:',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blue,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '• Untuk login sistem',
                                        style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                                      ),
                                      Text(
                                        '• Juga sebagai nama display',
                                        style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                                      ),
                                      Text(
                                        '• Bisa menggunakan titik dan underscore',
                                        style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                                      ),
                                    ],
                                  ),
                                ),

                                // Email
                                TextFormField(
                                  controller: emailController,
                                  decoration: InputDecoration(
                                    labelText: 'Email*',
                                    prefixIcon: const Icon(Icons.email_outlined),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    hintText: 'contoh@email.com',
                                  ),
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Email harus diisi';
                                    }
                                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                                      return 'Email tidak valid';
                                    }
                                    return null;
                                  },
                                ),

                                const SizedBox(height: 16),

                                // Password
                                TextFormField(
                                  controller: passwordController,
                                  obscureText: obscurePassword,
                                  decoration: InputDecoration(
                                    labelText: 'Password*',
                                    prefixIcon: const Icon(Icons.lock_outline),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        obscurePassword
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                      ),
                                      onPressed: onToggleObscurePassword,
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Password harus diisi';
                                    }
                                    if (value.length < 8) {
                                      return 'Password minimal 8 karakter';
                                    }
                                    if (!RegExp(r'[A-Z]').hasMatch(value)) {
                                      return 'Harus mengandung huruf besar';
                                    }
                                    if (!RegExp(r'[0-9]').hasMatch(value)) {
                                      return 'Harus mengandung angka';
                                    }
                                    return null;
                                  },
                                ),

                                const SizedBox(height: 16),

                                // Confirm Password
                                TextFormField(
                                  controller: confirmPasswordController,
                                  obscureText: obscureConfirmPassword,
                                  decoration: InputDecoration(
                                    labelText: 'Konfirmasi Password*',
                                    prefixIcon: const Icon(Icons.lock_reset_outlined),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        obscureConfirmPassword
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                      ),
                                      onPressed: onToggleObscureConfirmPassword,
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Konfirmasi password harus diisi';
                                    }
                                    if (value != passwordController.text) {
                                      return 'Password tidak cocok';
                                    }
                                    return null;
                                  },
                                ),

                                const SizedBox(height: 24),

                                // Password Requirements
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey[300]!),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Password harus mengandung:',
                                        style: textTheme.bodySmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      _buildRequirement('Minimal 8 karakter'),
                                      _buildRequirement('Minimal 1 huruf besar (A-Z)'),
                                      _buildRequirement('Minimal 1 angka (0-9)'),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 28),

                                // Register Button
                                SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: ElevatedButton(
                                    onPressed: isLoading ? null : onRegister,
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
                                                'Daftar Sekarang',
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

                                // Login Link
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text('Sudah punya akun?'),
                                    TextButton(
                                      onPressed: isLoading ? null : onNavigateToLogin,
                                      child: Text(
                                        'Login di sini',
                                        style: TextStyle(
                                          color: gradientStart,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
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

  Widget _buildRequirement(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 16,
            color: Colors.green[600],
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}