import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../pages/dashboard_owner_page.dart';
import '../../pages/dashboard_staff_page.dart';
import '../../pages/login_page.dart';
import 'pop_up_Screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _obscurePassword = true;
  
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final result = await authProvider.login(
      usernameOrEmail: _usernameController.text.trim(),
      password: _passwordController.text.trim(),
    );

    if (result.success) {
      await showLoginSuccessPopUp(
        navigator.context,
        onComplete: () {
          if (authProvider.isOwner) {
            navigator.pushReplacement(
              MaterialPageRoute(
                builder: (_) => DashboardOwnerPage(
                  userRole: authProvider.currentUser?.role.name ?? 'owner',
                ),
              ),
            );
          } else {
            navigator.pushReplacement(
              MaterialPageRoute(
                builder: (_) => DashboardStaffPage(
                  userRole: authProvider.currentUser?.role.name ?? 'staff',
                ),
              ),
            );
          }
        },
      );
    } else {
      messenger.showSnackBar(SnackBar(content: Text(result.message!)));
    }
  }
  
  void _navigateToForgotPassword() {
    Navigator.pushNamed(context, '/forgot-password');
  }
  
  void _navigateToRegister() {
    Navigator.pushReplacementNamed(context, '/register');
  }
  
  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return LoginPage(
      usernameController: _usernameController,
      passwordController: _passwordController,
      formKey: _formKey,
      isLoading: context.watch<AuthProvider>().isLoading,
      obscurePassword: _obscurePassword,
      onToggleObscure: () {
        setState(() {
          _obscurePassword = !_obscurePassword;
        });
      },
      onLogin: _login,
      onForgotPassword: _navigateToForgotPassword,
      onRegister: _navigateToRegister,
    );
  }
}