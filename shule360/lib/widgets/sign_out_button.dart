import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Drop this into any Scaffold's AppBar `actions` list to get a working
/// sign-out button on that screen — pops all the way back to the login
/// screen (the first route), not just one level up.
class SignOutButton extends StatelessWidget {
  const SignOutButton({super.key});

  Future<void> _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Sign Out',
      icon: const Icon(Icons.logout),
      onPressed: () => _signOut(context),
    );
  }
}