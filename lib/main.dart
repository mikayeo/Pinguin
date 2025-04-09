import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pinguin/screens/auth/login_screen.dart';
import 'package:pinguin/screens/auth/register_screen.dart';
import 'package:pinguin/screens/home/home_screen.dart';
import 'package:pinguin/providers/auth_provider.dart';
import 'package:pinguin/providers/account_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AccountProvider()),
      ],
      child: MaterialApp(
        title: 'Money Transfer App',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          ),
        ),
        initialRoute: '/login',
        routes: {
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/home': (context) => const HomeScreen(),
        },
      ),
    );
  }
}
