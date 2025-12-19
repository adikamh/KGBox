import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/reset_password_screen.dart';
import 'screens/bestseller_screen.dart';
import 'screens/expired_screen.dart';
import 'screens/pengiriman_screen.dart';
import 'screens/supplier_screen.dart';
import 'screens/stok_produk_screen.dart';
import 'providers/auth_provider.dart';
import 'services/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    DevicePreview(enabled: true, builder: (context) => const WarehouseApp()),
  );
}

class WarehouseApp extends StatelessWidget {
  const WarehouseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        title: 'KGbox app',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        routes: {
          '/login': (ctx) => const LoginScreen(),
          '/register': (ctx) => const RegisterScreen(),
          '/forgot-password': (ctx) => const ResetPasswordScreen(),
          '/bestseller': (ctx) => const BestSellerScreen(),
          '/expired': (ctx) => const ExpiredScreen(),
          '/pengiriman': (ctx) => const PengirimanScreen(),
          '/supplier': (ctx) => const SupplierScreen(),
          '/stok_produk': (ctx) => const StokProdukScreen(),
        },
        home: const LoginScreen(),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return DevicePreview(enabled: true, builder: (context) => const WarehouseApp());
  }
}
