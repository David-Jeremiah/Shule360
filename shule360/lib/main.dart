import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const ProviderScope(child: Shule360App()));
}

class Shule360App extends StatelessWidget {
  const Shule360App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shule360',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF1F4E5C),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}