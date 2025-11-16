import 'package:flutter/material.dart';
import 'package:kaizen/services/auth_wrapper.dart';
import 'package:kaizen/services/theme.dart';
import 'package:kaizen/services/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:kaizen/services/auth_service.dart';

void main() async {
  // Ensure widgets are initialized before running the app
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();

  runApp(
    // Provide both AuthService and ThemeProvider to the widget tree
    MultiProvider(
      providers: [
        Provider<AuthService>(
          create: (_) => AuthService(),
        ),
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Consumer listens to ThemeProvider changes and rebuilds the MaterialApp
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Kaizen',
          debugShowCheckedModeBanner: false,

          // --- Theme Configuration ---
          themeMode: themeProvider.themeMode, // Controlled by Provider
          theme: AppTheme.lightTheme,         // Your light theme
          darkTheme: AppTheme.darkTheme,      // Your dark theme

          // --- Home Screen ---
          // The AuthWrapper now handles navigation.
          home: const AuthWrapper(),
        );
      },
    );
  }
}