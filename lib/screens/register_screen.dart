import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/username_service.dart';
import '../../pages/register_page.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  final UsernameService _usernameService = UsernameService();
  
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isCheckingUsername = false;
  bool _usernameAvailable = false;
  String _usernameError = '';
  
  void _checkUsername() async {
    final username = _usernameController.text.trim();
    
    if (username.isEmpty) {
      setState(() {
        _usernameError = '';
        _usernameAvailable = false;
      });
      return;
    }
    
    if (!UsernameService.isValidUsername(username)) {
      setState(() {
        _usernameError = 'Username hanya boleh huruf, angka, titik, dan underscore (3-20 karakter)';
        _usernameAvailable = false;
      });
      return;
    }
    
    setState(() {
      _isCheckingUsername = true;
      _usernameError = '';
    });
    
    await Future.delayed(const Duration(milliseconds: 500));
    
    final isAvailable = await _usernameService.isUsernameAvailable(username);
    
    if (mounted) {
      setState(() {
        _isCheckingUsername = false;
        _usernameAvailable = isAvailable;
        _usernameError = isAvailable ? '' : 'Username sudah digunakan';
      });
    }
  }
  
  Future<void> _registerOwner() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Validasi tambahan untuk username
    if (!_usernameAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username tidak tersedia')),
      );
      return;
    }
    
    // Validasi password match
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password tidak cocok')),
      );
      return;
    }
    
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final result = await authProvider.registerOwner(
      username: _usernameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      companyName: _companyNameController.text.trim(),
    );

    if (result.success) {
      // Automatically navigate to login page
      navigator.pushReplacementNamed('/login');
    } else {
      messenger.showSnackBar(SnackBar(content: Text(result.message!)));
    }
  }
  
  void _navigateToLogin() {
    Navigator.pushReplacementNamed(context, '/login');
  }
  
  @override
  void initState() {
    super.initState();
    _usernameController.addListener(_checkUsername);
  }
  
  @override
  void dispose() {
    _usernameController.dispose();
    _companyNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return RegisterPage(
      usernameController: _usernameController,
      companyNameController: _companyNameController,
      emailController: _emailController,
      passwordController: _passwordController,
      confirmPasswordController: _confirmPasswordController,
      formKey: _formKey,
      isLoading: context.watch<AuthProvider>().isLoading,
      obscurePassword: _obscurePassword,
      obscureConfirmPassword: _obscureConfirmPassword,
      isCheckingUsername: _isCheckingUsername,
      usernameAvailable: _usernameAvailable,
      usernameError: _usernameError,
      onToggleObscurePassword: () {
        setState(() {
          _obscurePassword = !_obscurePassword;
        });
      },
      onToggleObscureConfirmPassword: () {
        setState(() {
          _obscureConfirmPassword = !_obscureConfirmPassword;
        });
      },
      onRegister: _registerOwner,
      onNavigateToLogin: _navigateToLogin,
    );
  }
}