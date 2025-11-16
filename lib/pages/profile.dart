import 'package:flutter/material.dart';
import 'package:kaizen/pages/yield_analysis_screen.dart';
import 'package:kaizen/services/auth_service.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatelessWidget {
  // --- FIX: Removed 'const' ---
  ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;
    final theme = Theme.of(context);

    // Get the first letter of the display name, or "K" as a fallback
    String getInitials() {
      String name = user?.displayName ?? "K";
      if (name.isEmpty) return "K";
      return name[0].toUpperCase();
    }

    return Scaffold(
      // Use theme color for background
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 30),
                _buildProfileAvatar(context, getInitials()),
                const SizedBox(height: 16),
                _buildGreetingText(context, user?.displayName),
                const SizedBox(height: 40),
                _buildProfileOption(
                  context: context,
                  icon: Icons.analytics_outlined,
                  title: 'Generation Analysis',
                  onTap: () {
                    // --- NAVIGATION ADDED ---
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const YieldAnalysisScreen(),
                      ),
                    );
                  },
                ),
                _buildProfileOption(
                  context: context,
                  icon: Icons.memory_rounded,
                  title: 'Setup Information',
                  onTap: () {
                    // TODO: Navigate to SetupScreen
                  },
                ),
                _buildProfileOption(
                  context: context,
                  icon: Icons.support_agent_outlined,
                  title: 'Get Help',
                  onTap: () {
                    // TODO: Navigate to HelpScreen
                  },
                ),
                const SizedBox(height: 20),
                _buildProfileOption(
                  context: context,
                  icon: Icons.logout_rounded,
                  title: 'Logout',
                  isLogout: true,
                  onTap: () {
                    authService.signOut();
                    // AuthWrapper will handle navigation
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Helper method to build the profile avatar.
  Widget _buildProfileAvatar(BuildContext context, String initials) {
    final theme = Theme.of(context);
    return CircleAvatar(
      radius: 40,
      backgroundColor: theme.colorScheme.surface,
      child: Text(
        initials,
        style: theme.textTheme.headlineMedium?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  /// Helper method to build the greeting text.
  Widget _buildGreetingText(BuildContext context, String? displayName) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          'Hello',
          style: theme.textTheme.titleLarge?.copyWith(
            color: Colors.grey,
            fontWeight: FontWeight.w400,
          ),
        ),
        Text(
          displayName ?? 'Operator',
          style: theme.textTheme.displaySmall,
        ),
      ],
    );
  }

  /// A reusable helper method to build each menu item tile.
  Widget _buildProfileOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    final theme = Theme.of(context);
    final color =
        isLogout ? theme.colorScheme.error : theme.colorScheme.primary;
    final textColor =
        isLogout ? theme.colorScheme.error : theme.colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12), // Matches theme
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          decoration: BoxDecoration(
            color: theme.cardTheme.color, // Use Card theme color
            borderRadius: BorderRadius.circular(12),
            boxShadow: theme.brightness == Brightness.light
                ? [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 5,
                    )
                  ]
                : null,
          ),
          child: Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 20),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: textColor,
                  ),
                ),
              ),
              if (!isLogout)
                const Icon(Icons.arrow_forward_ios,
                    color: Colors.grey, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}