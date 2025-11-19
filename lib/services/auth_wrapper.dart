import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:kaizen/pages/homescreen.dart';
import 'package:kaizen/pages/login_page.dart';
import 'package:kaizen/pages/add_device_screen.dart';
import 'package:kaizen/services/auth_service.dart';
import 'package:provider/provider.dart';


class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});


  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);


    // This outer stream checks the user's login status
    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, authSnapshot) {
        
        // Show loading spinner while checking auth
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }


        // --- 1. USER IS LOGGED IN ---
        if (authSnapshot.hasData) {
          final user = authSnapshot.data!;


          // --- 2. NOW, CHECK FOR DEVICES ---
          // This nested stream checks if the user has any devices registered
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('user_devices')
                .doc(user.uid)
                .collection('devices')
                .limit(1) // We only need to know if 1 or more exists
                .snapshots(),
            builder: (context, deviceSnapshot) {
              
              // Show loading spinner while checking for devices
              if (deviceSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              
              // Handle error while checking for devices
              if (deviceSnapshot.hasError) {
                return Scaffold(
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        const Text("Error checking device data."),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            // Force refresh by rebuilding
                            (context as Element).markNeedsBuild();
                          },
                          child: const Text("Retry"),
                        ),
                      ],
                    ),
                  ),
                );
              }


              // --- 3. THIS IS A NEW USER (no devices) ---
              if (!deviceSnapshot.hasData || deviceSnapshot.data!.docs.isEmpty) {
                // Navigate to the "Add Device" screen
                return const AddDeviceScreen();
              }


              // --- 4. THIS IS AN EXISTING USER (has devices) ---
              // Navigate to the main home screen
              return const HomeScreen();
            },
          );
        }


        // --- 5. USER IS LOGGED OUT ---
        // If authSnapshot has no data, show the LoginPage
        return const LoginPage();
      },
    );
  }
}
