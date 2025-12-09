import 'package:flutter/material.dart';
import '../../app.dart';
import '../dashboard/dashboard_staff_page.dart';
import '../dashboard/dashboard_boss_page.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;

  final List<Map<String, String>> _availableAccounts = [
    {'username': 'boss', 'password': 'boss123', 'role': 'Owner/Boss'},
    {'username': 'staff', 'password': 'staff123', 'role': 'Staff Gudang'},
  ];

  void _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      await Future.delayed(const Duration(milliseconds: 1500));

      final username = _usernameController.text.trim();
      final password = _passwordController.text.trim();

      // Cek kredensial
      final account = _availableAccounts.firstWhere(
        (account) =>
            account['username'] == username && account['password'] == password,
        orElse: () => {},
      );

      if (account.isNotEmpty) {
        // Login berhasil - redirect ke dashboard sesuai role
        if (mounted) {
          if (account['role'] == 'Owner/Boss') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    EnhancedDashboardBossScreen(userRole: account['role']!),
              ),
            );
          } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => DashboardStaffPage(userRole: account['role']!),
                ),
              );
          }
        }
      } else {
        // Login gagal
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Username atau password salah'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showAvailableAccounts() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Akun Tersedia'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _availableAccounts.length,
            itemBuilder: (context, index) {
              final account = _availableAccounts[index];
              return ListTile(
                leading: const Icon(Icons.person),
                title: Text('${account['username']} (${account['role']})'),
                subtitle: Text('Password: ${account['password']}'),
                onTap: () {
                  _usernameController.text = account['username']!;
                  _passwordController.text = account['password']!;
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 40),

                  // Logo dan Judul
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 10,
                          color: Colors.black.withOpacity(0.1),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.warehouse,
                      size: 50,
                      color: Colors.blue,
                    ),
                  ),

                  const SizedBox(height: 24),

                  Text(
                    'WAREHOUSE APP',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: const Color.fromARGB(255, 0, 0, 0),
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Management System',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: const Color.fromARGB(179, 0, 0, 0)),
                  ),

                  const SizedBox(height: 40),

                  // Login Card
                  Card(
                    elevation: 8,
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          Text(
                            'Login',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),

                          const SizedBox(height: 24),

                          CustomTextField(
                            controller: _usernameController,
                            label: 'Username',
                            prefixIcon: Icons.person,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Username harus diisi';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          CustomTextField(
                            controller: _passwordController,
                            label: 'Password',
                            prefixIcon: Icons.lock,
                            obscureText: _obscurePassword,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Password harus diisi';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 24),

                          PrimaryButton(
                            onPressed: _isLoading ? null : _login,
                            text: _isLoading ? 'Loading...' : 'Login',
                            isLoading: _isLoading,
                          ),

                          const SizedBox(height: 16),

                          TextButton(
                            onPressed: _showAvailableAccounts,
                            child: const Text('Lihat Akun Tersedia'),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Footer
                  Text(
                    '© 2024 Warehouse Management System',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.white54),
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
