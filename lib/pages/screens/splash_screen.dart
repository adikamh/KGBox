import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Simple10SecondSplash extends StatefulWidget {
  const Simple10SecondSplash({Key? key}) : super(key: key);

  @override
  State<Simple10SecondSplash> createState() => _Simple10SecondSplashState();
}

class _Simple10SecondSplashState extends State<Simple10SecondSplash> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    
    // Tunggu 10 detik lalu navigasi
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    });
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        child:Image.asset(
          'assets/logo/logo_tim.png',
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
      ),
    );
  }
}