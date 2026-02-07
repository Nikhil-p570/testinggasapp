// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'state/app_state.dart';

// Screens
import 'splash/splash_screen.dart';
import 'auth/login_screen.dart';
import 'auth/register_screen.dart';
import 'home/home_screen.dart';
import 'products/user_products_screen.dart';  // New product screen for users
import 'cart/cart_screen.dart';  // New cart screen
import 'profile/profile_screen.dart';
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ✅ ENABLE APP CHECK IN DEBUG MODE (DO NOT FORCE TOKEN)
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
  );

  runApp(const VyomaApp());
}

class VyomaApp extends StatelessWidget {
  const VyomaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: MaterialApp(
        title: 'Vyoma Delivery',
        debugShowCheckedModeBanner: false,

        theme: ThemeData(
          useMaterial3: true,
          primaryColor: const Color(0xFFE50914),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFE50914),
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: Colors.white,
          appBarTheme: const AppBarTheme(
            elevation: 0,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            centerTitle: true,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE50914),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(
                vertical: 14,
                horizontal: 20,
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(
                color: Color(0xFFE50914),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),

        routes: {
          '/login': (_) => LoginScreen(),
          '/register': (_) => const RegisterScreen(),
          '/home': (_) => const HomeScreen(),
          '/products': (_) => const UserProductsScreen(),  // User product page
          '/cart': (_) => const CartScreen(),// Cart page
          '/profile': (_) => const ProfileScreen(),  
        },

        home: const SplashScreen(),
      ),
    );
  }
}