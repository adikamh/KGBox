import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../pages/reset_password_page.dart';
import '../providers/auth_provider.dart';
import 'logout_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendReset() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();

    setState(() => _isLoading = true);

    try {
      final navigator = Navigator.of(context);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final result = await authProvider.forgotPassword(email);

      if (!mounted) return;

      if (result.success) {
        await showSuccessDialog(
          navigator.context,
          title: 'Link Terkirim',
          message: result.message ?? 'Link reset password telah dikirim ke email Anda.',
          onOk: () => navigator.pop(),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message ?? 'Gagal mengirim link reset')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: ForgotPasswordPage(
        emailController: _emailController,
        formKey: _formKey,
        isLoading: _isLoading,
        onResetPassword: _sendReset,
        onBackToLogin: () => Navigator.pop(context),
      ),
    );
  }
}
