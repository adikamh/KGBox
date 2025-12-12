import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../dashboard/dashboard_staff_page.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _username = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirm = TextEditingController();
  bool _isLoading = false;

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      await Future.delayed(const Duration(milliseconds: 1000));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Akun dibuat (demo)')));
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => DashboardStaffPage(userRole: 'New User')));
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final googleUser = await googleSignIn.signIn();
      if (googleUser != null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Signed up as ${googleUser.email}')));
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => DashboardStaffPage(userRole: 'Google User')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Google sign up failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account'), backgroundColor: const Color(0xFF5B86E5)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(controller: _username, decoration: const InputDecoration(labelText: 'Username', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)))) , validator: (v){ if (v==null||v.isEmpty) return 'Username harus diisi'; return null;},),
                  const SizedBox(height: 12),
                  TextFormField(controller: _email, decoration: const InputDecoration(labelText: 'Email', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)))) , validator: (v){ if (v==null||v.isEmpty) return 'Email harus diisi'; return null;},),
                  const SizedBox(height: 12),
                  TextFormField(controller: _password, obscureText: true, decoration: const InputDecoration(labelText: 'Password', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)))) , validator: (v){ if (v==null||v.length<6) return 'Password minimal 6 karakter'; return null;},),
                  const SizedBox(height: 12),
                  TextFormField(controller: _confirm, obscureText: true, decoration: const InputDecoration(labelText: 'Confirm Password', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)))) , validator: (v){ if (v==null||v!=_password.text) return 'Password tidak cocok'; return null;},),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: _isLoading?null:_register, child: Padding(padding: const EdgeInsets.symmetric(vertical: 12.0), child: Text(_isLoading? 'Loading...':'Register'))),
                  const SizedBox(height: 12),
                  Row(children: const [Expanded(child: Divider()), Padding(padding: EdgeInsets.symmetric(horizontal:8.0), child: Text('OR')), Expanded(child: Divider())]),
                  const SizedBox(height: 12),
                  Center(child: IconButton(onPressed: _signInWithGoogle, icon: Image.network('https://upload.wikimedia.org/wikipedia/commons/5/53/Google_%22G%22_Logo.svg', width:36, height:36))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
