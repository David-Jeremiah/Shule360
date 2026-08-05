import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'models/app_user.dart';
import 'models/school.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: Shule360Root()));
}

const _defaultSeed = Color(0xFF1F4E5C);

/// Root of the app. Listens to auth state, then to the signed-in user's
/// School document, and rebuilds the WHOLE MaterialApp's theme whenever
/// that school's branding changes — this is what makes color changes in
/// School Settings apply live across every screen, not just one.
class Shule360Root extends StatelessWidget {
  const Shule360Root({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        final firebaseUser = authSnapshot.data;
        if (firebaseUser == null) {
          return const _ThemedApp(seedColor: _defaultSeed, home: LoginScreen());
        }

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('users').doc(firebaseUser.uid).snapshots(),
          builder: (context, userSnapshot) {
            if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
              return const _ThemedApp(
                seedColor: _defaultSeed,
                home: Scaffold(body: Center(child: CircularProgressIndicator())),
              );
            }
            final appUser = AppUser.fromMap(userSnapshot.data!.id, userSnapshot.data!.data()!);

            return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance.collection('schools').doc(appUser.schoolId).snapshots(),
              builder: (context, schoolSnapshot) {
                var seed = _defaultSeed;
                String? logoUrl;
                if (schoolSnapshot.hasData && schoolSnapshot.data!.exists) {
                  final school = School.fromMap(schoolSnapshot.data!.id, schoolSnapshot.data!.data()!);
                  seed = _colorFromHex(school.primaryColorHex);
                  logoUrl = school.logoUrl;
                }
                return _ThemedApp(
                  seedColor: seed,
                  home: HomeScreen(user: appUser, schoolLogoUrl: logoUrl),
                );
              },
            );
          },
        );
      },
    );
  }
}

Color _colorFromHex(String hex) {
  final cleaned = hex.replaceAll('#', '');
  final value = int.tryParse('FF$cleaned', radix: 16);
  return value != null ? Color(value) : _defaultSeed;
}

class _ThemedApp extends StatelessWidget {
  final Color seedColor;
  final Widget home;

  const _ThemedApp({required this.seedColor, required this.home});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shule360',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: seedColor,
        useMaterial3: true,
        cardTheme: const CardThemeData(elevation: 0),
        appBarTheme: const AppBarTheme(centerTitle: false, elevation: 0),
      ),
      home: home,
    );
  }
}