import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:kaizen/models/grid_model.dart';
import 'package:kaizen/pages/yield_analysis_screen.dart';
import 'package:kaizen/services/auth_service.dart';
import 'package:provider/provider.dart';

class MyGridScreen extends StatelessWidget {
  MyGridScreen({super.key});

  /// Gets a greeting based on the time of day.
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning,';
    }
    if (hour < 17) {
      return 'Good afternoon,';
    }
    return 'Good evening,';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;
    final String username = user?.displayName ?? 'Operator';

    // This is the live data stream from Firebase
    final String? userId = user?.uid;
    final Stream<QuerySnapshot>? devicesStream = userId != null
        ? FirebaseFirestore.instance
            .collection('user_devices') // Main collection
            .doc(userId) // User's document
            .collection('devices') // Subcollection of devices
            .snapshots()
        : null;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      // --- AppBar Removed ---
      
      // --- REFRESH FAB ADDED ---
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Add logic to refresh data
        },
        backgroundColor: theme.colorScheme.primary,
        child: Icon(Icons.sync, color: theme.colorScheme.onPrimary),
      ),
      
      body: SafeArea(
        // We wrap the whole body in the StreamBuilder to get the total power
        child: StreamBuilder<QuerySnapshot>(
          stream: devicesStream,
          builder: (context, snapshot) {
            
            // --- DATA LOGIC MOVED UP ---
            List<Grid> grids = [];
            double totalPower = 0.0;

            // 1. While data is loading
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            // 2. If an error occurs (we still show the UI)
            if (snapshot.hasError) {
              // We can show an error, but we'll build the rest of the UI
              // You could add a _buildErrorCard widget here
            }

            // 3. If data is successfully loaded, parse it
            if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
              grids = snapshot.data!.docs
                  .map((doc) => Grid.fromFirestore(doc))
                  .toList();
              
              // Calculate Total Power
              totalPower = grids.fold(0.0, (sum, grid) => sum + grid.livePower);
            }
            
            // 4. Build the UI
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- GREETING CARD ---
                    _buildGreetingCard(context, username),
                    const SizedBox(height: 24),

                    // --- TOTAL GENERATION CARD (ALWAYS PRESENT) ---
                    _buildTotalGenerationCard(context, totalPower),
                    const SizedBox(height: 24),

                    // --- "My Grids" title, only if grids exist ---
                    if (grids.isNotEmpty)
                      Text(
                        'My Grids',
                        style: textTheme.headlineMedium,
                      ),
                    if (grids.isNotEmpty) const SizedBox(height: 16),

                    // --- List of individual grids (if available) ---
                    if (grids.isNotEmpty)
                      ListView.builder(
                        itemCount: grids.length,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemBuilder: (context, index) {
                          final grid = grids[index];
                          return _buildGridSummaryCard(context, grid);
                        },
                      ),
                    
                    // --- "No grids" message (if available) ---
                    if (grids.isEmpty && !snapshot.hasError)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32.0),
                          child: Text(
                            "No grids found.\nAdd a new device from your profile.",
                            textAlign: TextAlign.center,
                            style: textTheme.titleMedium
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                        ),
                      ),
                    
                    // --- Error message ---
                    if (snapshot.hasError)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32.0),
                          child: Text(
                            "Error loading grids.\nPlease try again later.",
                            textAlign: TextAlign.center,
                            style: textTheme.titleMedium
                                ?.copyWith(color: theme.colorScheme.error),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// --- UPDATED WIDGET ---
  /// A stylized card for the user greeting.
  Widget _buildGreetingCard(BuildContext context, String username) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    // --- FIX: Wrapped in SizedBox to force full width ---
    return SizedBox(
      width: double.infinity,
      child: Card(
        // --- FIX: Increased border radius ---
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getGreeting(),
                style: textTheme.titleLarge?.copyWith(color: Colors.grey[600]),
              ),
              Text(
                username,
                style: textTheme.displaySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// --- UPDATED WIDGET ---
  /// A green card for showing total generation.
  Widget _buildTotalGenerationCard(BuildContext context, double totalPower) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    
    // Determine text color based on light/dark theme
    final Color textColor = theme.brightness == Brightness.dark
        ? Colors.white
        : colorScheme.secondary; // Dark green text on light green bg

    return Card(
      // Use the green accent color for the container
      color: colorScheme.secondary.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        // --- FIX: Increased border radius ---
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.secondary,
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total Live Generation',
              style: textTheme.titleMedium?.copyWith(color: textColor.withOpacity(0.8)),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Icon(Icons.bolt_rounded, color: textColor, size: 40),
                const SizedBox(width: 8),
                Text(
                  totalPower.toStringAsFixed(1), // Format to 1 decimal
                  style: textTheme.displaySmall?.copyWith(color: textColor),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    'kW',
                    style: textTheme.titleMedium?.copyWith(color: textColor.withOpacity(0.8)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// --- UPDATED WIDGET ---
  /// A card for summarizing each grid in the list.
  Widget _buildGridSummaryCard(BuildContext context, Grid grid) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    final Color statusColor;
    final String statusValue;

    switch (grid.status) {
      case 'online':
        statusColor = colorScheme.secondary; // Green
        statusValue = 'Online';
        break;
      case 'offline':
        statusColor = colorScheme.error; // Red
        statusValue = 'Offline';
        break;
      default: // 'connecting' or any other status
        statusColor = Colors.grey;
        statusValue = 'Connecting...';
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      // --- FIX: Increased border radius ---
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => YieldAnalysisScreen(gridId: grid.id),
            ),
          );
        },
        // --- FIX: Increased border radius ---
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                grid.name,
                style: textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Icon(Icons.bolt, color: colorScheme.secondary, size: 32),
                  const SizedBox(width: 8),
                  Text(
                    grid.livePower.toString(),
                    style: textTheme.headlineMedium,
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Text(
                      'kW',
                      style: textTheme.titleSmall
                          ?.copyWith(color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Divider(
                color: theme.brightness == Brightness.dark
                    ? Colors.grey[800]
                    : Colors.grey[200],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildStatusRow(
                      context: context,
                      icon: Icons.cloud_done,
                      title: 'Status',
                      value: statusValue,
                      valueColor: statusColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatusRow(
                      context: context,
                      icon: Icons.battery_charging_full,
                      title: 'Battery',
                      value: '${grid.batteryHealth}%',
                      valueColor: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// A reusable row for displaying a status item.
  Widget _buildStatusRow({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String value,
    required Color valueColor,
  }) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Row(
      children: [
        Icon(icon, color: Colors.grey, size: 16),
        const SizedBox(width: 8),
        Text(
          '$title: ',
          style: textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
        ),
        Expanded(
          child: Text(
            value,
            style: textTheme.bodyMedium?.copyWith(
              color: valueColor,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}