import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:kaizen/models/grid_model.dart';
import 'package:kaizen/pages/yield_analysis_screen.dart';
import 'package:kaizen/services/auth_service.dart';
import 'package:provider/provider.dart';

class MyGridScreen extends StatelessWidget {
  MyGridScreen({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;
    final String username = user?.displayName ?? 'Operator';
    final String? userId = user?.uid;

    final Stream<QuerySnapshot>? devicesStream = userId != null
        ? FirebaseFirestore.instance
            .collection('user_devices')
            .doc(userId)
            .collection('devices')
            .snapshots()
        : null;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      floatingActionButton: FloatingActionButton(
        onPressed: () {}, // Stream updates automatically, no logic needed
        backgroundColor: theme.colorScheme.primary,
        child: Icon(Icons.sync, color: theme.colorScheme.onPrimary),
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: devicesStream,
          builder: (context, snapshot) {
            List<Grid> grids = [];
            double totalLiveValue = 0.0;

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
              grids = snapshot.data!.docs
                  .map((doc) => Grid.fromFirestore(doc))
                  .toList();
              totalLiveValue = grids.fold(0.0, (sum, grid) => sum + grid.livePower);
            }

            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildGreetingCard(context, username),
                    const SizedBox(height: 24),
                    _buildTotalGenerationCard(context, totalLiveValue),
                    const SizedBox(height: 24),
                    if (grids.isNotEmpty)
                      Text(
                        'My Grids',
                        style: textTheme.headlineMedium,
                      ),
                    if (grids.isNotEmpty) const SizedBox(height: 16),
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
                    if (grids.isEmpty && !snapshot.hasError)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32.0),
                          child: Text(
                            "No grids found.",
                            style: textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
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

  Widget _buildGreetingCard(BuildContext context, String username) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return SizedBox(
      width: double.infinity,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_getGreeting(),
                  style: textTheme.titleLarge?.copyWith(color: Colors.grey[600])),
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

  Widget _buildTotalGenerationCard(BuildContext context, double totalValue) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    final Color textColor = theme.brightness == Brightness.dark
        ? Colors.white
        : colorScheme.secondary;

    return Card(
      color: colorScheme.secondary.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.secondary, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total Live Reading',
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
                  totalValue.toStringAsFixed(1),
                  style: textTheme.displaySmall?.copyWith(color: textColor),
                ),
                // kW removed here
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridSummaryCard(BuildContext context, Grid grid) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    Color statusColor;
    String statusValue;

    switch (grid.status) {
      case 'online':
        statusColor = Colors.green;
        statusValue = 'Online';
        break;
      case 'offline':
        statusColor = Colors.red;
        statusValue = 'Offline';
        break;
      default:
        statusColor = Colors.grey;
        statusValue = 'Connecting...';
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => YieldAnalysisScreen(gridId: grid.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Header: Name and Main Value ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      grid.name,
                      style: textTheme.titleLarge,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Row(
                    children: [
                      Icon(Icons.bolt, color: colorScheme.secondary, size: 28),
                      const SizedBox(width: 4),
                      Text(
                        grid.livePower.toString(),
                        style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      // kW removed here
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              Divider(color: Colors.grey.withOpacity(0.2)),
              const SizedBox(height: 8),

              // --- Data Grid (2x2) ---
              Row(
                children: [
                  // Column 1
                  Expanded(
                    child: Column(
                      children: [
                        _buildStatusRow(
                          context: context,
                          icon: Icons.cloud_done,
                          title: 'Status',
                          value: statusValue,
                          valueColor: statusColor,
                        ),
                        const SizedBox(height: 8),
                        _buildStatusRow(
                          context: context,
                          icon: Icons.thermostat,
                          title: 'Temp',
                          value: '${grid.temperature}°C',
                          valueColor: theme.colorScheme.onSurface,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Column 2
                  Expanded(
                    child: Column(
                      children: [
                        _buildStatusRow(
                          context: context,
                          icon: Icons.battery_charging_full,
                          title: 'Battery',
                          value: '${grid.batteryHealth}%',
                          valueColor: theme.colorScheme.onSurface,
                        ),
                        const SizedBox(height: 8),
                         _buildStatusRow(
                          context: context,
                          icon: Icons.water_drop,
                          title: 'Humidity',
                          value: '${grid.humidity}%',
                          valueColor: theme.colorScheme.onSurface,
                        ),
                      ],
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
          style: textTheme.bodyMedium?.copyWith(color: Colors.grey[600], fontSize: 12),
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