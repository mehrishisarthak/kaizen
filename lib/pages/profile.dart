import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kaizen/pages/add_device_screen.dart'; 
import 'package:kaizen/pages/yield_analysis_screen.dart'; 
import 'package:kaizen/services/auth_service.dart';
import 'package:kaizen/services/theme_provider.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    // Listen to ThemeProvider changes for the UI
    final themeProvider = Provider.of<ThemeProvider>(context);
    final user = authService.currentUser;
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    String getInitials() {
      String name = user?.displayName ?? "K";
      if (name.isEmpty) return "K";
      return name[0].toUpperCase();
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                // --- THIS IS THE REDESIGNED WIDGET ---
                _buildUserProfileCard(context, user, getInitials()),
                const SizedBox(height: 24),

                // --- NEW PREFERENCES SECTION ---
                _buildSectionHeader(context, "Preferences"),
                const SizedBox(height: 16),
                _buildThemeSelector(context, themeProvider),
                const SizedBox(height: 24),

                // --- GENERAL SECTION ---
                _buildSectionHeader(context, "General"),
                const SizedBox(height: 16),
                _buildProfileOption(
                  context: context,
                  icon: Icons.add_rounded, // <-- Changed Icon
                  title: 'Add New Device', // <-- Changed Title
                  onTap: () {
                    // --- UPDATED NAVIGATION ---
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddDeviceScreen(),
                      ),
                    );
                  },
                ),
                _buildProfileOption(
                  context: context,
                  icon: Icons.analytics_outlined,
                  title: 'Generation Analysis',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        // TODO: This should navigate to an "All Grids" analysis screen
                        builder: (context) =>
                            const YieldAnalysisScreen(gridId: 'all'),
                      ),
                    );
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
                const SizedBox(height: 24),

                // --- DANGER ZONE ---
                _buildSectionHeader(context, "Danger Zone", isDanger: true),
                const SizedBox(height: 16),
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

  /// --- REDESIGNED WIDGET ---
  /// A card to neatly display the user's avatar and name in a Column.
  Widget _buildUserProfileCard(
      BuildContext context, User? user, String initials) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Card(
      // Using the more rounded radius from MyGridScreen for consistency
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 32.0),
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 50, // Increased size
                backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                child: Text(
                  initials,
                  style: textTheme.displaySmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                user?.displayName ?? 'Operator',
                style: textTheme.headlineMedium, // Show full name
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                user?.email ?? 'No email provided', // Show email
                style: textTheme.titleMedium?.copyWith(
                  color: Colors.grey,
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// A simple text header for sections.
  Widget _buildSectionHeader(BuildContext context, String title,
      {bool isDanger = false}) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        color: isDanger
            ? theme.colorScheme.error
            : theme.colorScheme.onSurface.withOpacity(0.6),
        fontWeight: FontWeight.bold,
      ),
    );
  }

  /// The UI for selecting the app's theme.
  Widget _buildThemeSelector(BuildContext context, ThemeProvider themeProvider) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Theme",
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 12),
            ToggleButtons(
              isSelected: [
                themeProvider.themeMode == ThemeMode.light,
                themeProvider.themeMode == ThemeMode.dark,
                themeProvider.themeMode == ThemeMode.system,
              ],
              onPressed: (index) {
                // --- FIX: This logic is now correct ---
                // We map the button index to the correct ThemeMode.
                const List<ThemeMode> modes = [
                  ThemeMode.light,
                  ThemeMode.dark,
                  ThemeMode.system
                ];
                themeProvider.setThemeMode(modes[index]);
              },
              borderRadius: BorderRadius.circular(8.0),
              fillColor: theme.colorScheme.primary,
              selectedColor: theme.colorScheme.onPrimary,
              color: isDark ? Colors.white70 : Colors.black54,
              constraints: BoxConstraints(
                minHeight: 40.0,
                // Adjusted width calculation to be robust
                minWidth: (MediaQuery.of(context).size.width - 72 - 32) / 3,
              ),
              children: const [
                Icon(Icons.light_mode_outlined),
                Icon(Icons.dark_mode_outlined),
                Icon(Icons.brightness_auto_outlined),
              ],
            ),
          ],
        ),
      ),
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
        isLogout ? theme.colorScheme.error : theme.colorScheme.onSurface;
    final iconColor =
        isLogout ? theme.colorScheme.error : theme.colorScheme.primary;

    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16), // Matches theme
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Row(
            children: [
              Icon(icon, color: iconColor),
              const SizedBox(width: 20),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
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