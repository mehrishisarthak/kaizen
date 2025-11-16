import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kaizen/pages/homescreen.dart';
import 'package:kaizen/pages/login_page.dart';
import 'package:kaizen/services/auth_service.dart';
import 'package:provider/provider.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        // Show loading spinner while waiting
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // If user is logged in, show the HomeScreen
        if (snapshot.hasData) {
          // Changed to HomeScreen to include the BottomNavBar
          return const HomeScreen();
        }

        // If user is logged out, show the LoginPage
        return const LoginPage();
      },
    );
  }
}