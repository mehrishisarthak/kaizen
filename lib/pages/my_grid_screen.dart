import 'package:flutter/material.dart';
import 'package:kaizen/pages/yield_analysis_screen.dart';
import 'package:kaizen/services/auth_service.dart';
import 'package:provider/provider.dart';
// We are no longer using animations, so 'dart:math' is removed.

// A mock enum to represent the grid status.
// We'll replace this with live data from Firebase.
enum GridStatus { online, offline, connecting }

// A mock data class for a single grid.
// We will replace this with a real model from Firebase.
class MockGrid {
  final String id;
  final String name;
  final GridStatus status;
  final double livePower;
  final int batteryHealth;

  MockGrid({
    required this.id,
    required this.name,
    required this.status,
    required this.livePower,
    required this.batteryHealth,
  });
}

// We can make this a StatelessWidget again as animations are removed.
class MyGridScreen extends StatelessWidget {
  MyGridScreen({super.key});

  // --- MOCK DATA FOR MULTIPLE GRIDS ---
  // We will replace this with a live stream from Firebase
  final List<MockGrid> _grids = [
    MockGrid(
      id: 'grid_1',
      name: 'Home Grid',
      status: GridStatus.online,
      livePower: 14.2,
      batteryHealth: 98,
    ),
    MockGrid(
      id: 'grid_2',
      name: 'Workshop Grid',
      status: GridStatus.connecting,
      livePower: 0.0,
      batteryHealth: 72,
    ),
    MockGrid(
      id: 'grid_3',
      name: 'Storage Unit',
      status: GridStatus.offline,
      livePower: 0.0,
      batteryHealth: 0,
    ),
  ];
  // ---

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
    // Get user info for the greeting
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;
    final String username = user?.displayName ?? 'Operator';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      // --- AppBar is Restored ---
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: Text(
          'KAIZEN',
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.appBarTheme.foregroundColor,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync, size: 26),
            onPressed: () {
              // TODO: Add logic to refresh data
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- GREETING ADDED ---
                Text(
                  _getGreeting(),
                  style: textTheme.titleLarge?.copyWith(color: Colors.grey[600]),
                ),
                Text(
                  username,
                  style: textTheme.displaySmall, // Scaled up
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 24),
                // --- Title is Restored ---
                Text(
                  'My Grids',
                  style: textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),
                // --- Multi-grid List is Kept ---
                ListView.builder(
                  itemCount: _grids.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    final grid = _grids[index];
                    return _buildGridSummaryCard(context, grid);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// A card for summarizing each grid in the list.
  Widget _buildGridSummaryCard(BuildContext context, MockGrid grid) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    final Color statusColor;
    final String statusValue;

    switch (grid.status) {
      case GridStatus.online:
        statusColor = colorScheme.secondary; // Green
        statusValue = 'Online';
        break;
      case GridStatus.offline:
        statusColor = colorScheme.error; // Red
        statusValue = 'Offline';
        break;
      case GridStatus.connecting:
        statusColor = Colors.grey;
        statusValue = 'Connecting...';
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: InkWell(
        onTap: () {
          // Navigate to the specific analysis screen for this grid
          Navigator.push(
            context,
            MaterialPageRoute(
              // TODO: Pass the grid.id to the analysis screen
              builder: (context) => const YieldAnalysisScreen(),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Grid Name ---
              Text(
                grid.name,
                style: textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              // --- Live Power ---
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
              // --- Status and Battery Rows ---
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