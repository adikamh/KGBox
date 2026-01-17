import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:device_preview/device_preview.dart';
import 'screens/register_screen.dart';
import 'screens/reset_password_screen.dart';
import 'screens/bestseller_screen.dart';
import 'screens/expired_screen.dart';
import 'screens/pengiriman_screen.dart';
import 'screens/supplier_screen.dart';
import 'screens/stok_produk_screen.dart';
import 'pages/stok_owner_page.dart';
import 'providers/auth_provider.dart';
import 'services/firebase_options.dart';
import 'screens/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const WarehouseApp());
}

class WarehouseApp extends StatelessWidget {
  const WarehouseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => AuthProvider())],
      child: DevicePreview(
        enabled: true,
        builder: (context) => MaterialApp(
          title: 'KGbox',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(primarySwatch: Colors.blue),
          routes: {
            '/login': (ctx) => LoginScreen(),
            '/register': (ctx) => RegisterScreen(),
            '/forgot-password': (ctx) => ResetPasswordScreen(),
            '/bestseller': (ctx) => BestSellerScreen(),
            '/expired': (ctx) => ExpiredScreen(),
            '/pengiriman': (ctx) => PengirimanScreen(),
            '/stok': (ctx) => StokOwnerPage(),
            '/supplier': (ctx) => SupplierScreen(),
            '/stok_produk': (ctx) => StokProdukScreen(),
          },
          home: LoginScreen(),
          useInheritedMediaQuery: true,
        ),
      ),
    );
  }
}
