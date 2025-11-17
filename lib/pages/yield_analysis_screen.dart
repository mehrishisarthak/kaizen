import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:kaizen/models/grid_model.dart';
import 'package:kaizen/models/historical_data_model.dart';
import 'package:kaizen/services/auth_service.dart';
import 'package:kaizen/services/theme.dart';
import 'package:provider/provider.dart';

class YieldAnalysisScreen extends StatefulWidget {
  final String gridId;

  const YieldAnalysisScreen({
    super.key,
    required this.gridId,
  });

  @override
  State<YieldAnalysisScreen> createState() => _YieldAnalysisScreenState();
}

class _YieldAnalysisScreenState extends State<YieldAnalysisScreen> {
  // 0 = Day, 1 = Week, 2 = Month
  int _selectedTimeIndex = 1;

  // Streams for live data
  Stream<DocumentSnapshot>? _gridStream;
  Stream<QuerySnapshot>? _historicalDataStream;

  @override
  void initState() {
    super.initState();
    final authService = Provider.of<AuthService>(context, listen: false);
    final String? userId = authService.currentUser?.uid;

    if (userId != null) {
      // Stream for this grid's details (e.g., name)
      _gridStream = FirebaseFirestore.instance
          .collection('user_devices')
          .doc(userId)
          .collection('devices')
          .doc(widget.gridId)
          .snapshots();

      // Stream for this grid's historical data
      // We order by timestamp descending to get the *latest* data first
      _historicalDataStream = FirebaseFirestore.instance
          .collection('user_devices')
          .doc(userId)
          .collection('devices')
          .doc(widget.gridId)
          .collection('historical_data')
          .orderBy('timestamp', descending: true)
          .snapshots();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return StreamBuilder<DocumentSnapshot>(
      // This stream fetches the grid's name for the AppBar
      stream: _gridStream,
      builder: (context, gridSnapshot) {
        String gridName = 'Yield Analysis';
        if (gridSnapshot.hasData && gridSnapshot.data!.exists) {
          try {
            // Try to parse the grid data
            final grid = Grid.fromFirestore(gridSnapshot.data!);
            gridName = grid.name;
          } catch (e) {
            // Handle cases where the document might exist but data is bad
            gridName = "Grid Analysis";
          }
        }

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            title: Text(
              gridName,
              style: textTheme.titleLarge,
            ),
            centerTitle: true,
          ),
          body: StreamBuilder<QuerySnapshot>(
            // This is the main stream for all our chart/yield data
            stream: _historicalDataStream,
            builder: (context, dataSnapshot) {
              // 1. Show loading indicator
              if (dataSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              // 2. Show error
              if (dataSnapshot.hasError) {
                return Center(child: Text("Error: ${dataSnapshot.error}"));
              }

              // 3. Show "No Data" message
              if (!dataSnapshot.hasData || dataSnapshot.data!.docs.isEmpty) {
                return Center(
                  child: Text(
                    "No historical data found for this grid.",
                    textAlign: TextAlign.center,
                    style: textTheme.titleMedium
                        ?.copyWith(color: Colors.grey[600]),
                  ),
                );
              }

              // 4. We have data! Parse it into our model.
              final allDataPoints = dataSnapshot.data!.docs
                  .map((doc) => HistoricalDataPoint.fromFirestore(doc))
                  .toList();

              // Filter data based on the toggle button
              final List<HistoricalDataPoint> filteredData =
                  _getFilteredData(allDataPoints);

              // Create FlSpot list for the chart
              final List<FlSpot> spots = _createChartSpots(filteredData);
              
              // Calculate total yield for the card
              final double totalYield = filteredData.fold(
                  0.0, (sum, item) => sum + item.yield);

              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTotalYieldCard(context, totalYield),
                      const SizedBox(height: 24),
                      _buildTimeSelector(context),
                      const SizedBox(height: 24),
                      _buildLineChartCard(context, spots),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  /// Filters the complete data list based on the toggle button
  List<HistoricalDataPoint> _getFilteredData(
      List<HistoricalDataPoint> allData) {
    
    // NOTE: This logic assumes you have one document per day.
    // We fetch with `descending: true`, so `take(7)` gets the 7 most recent days.
    
    switch (_selectedTimeIndex) {
      case 0: // Day (Last 1 day)
        return allData.take(1).toList();
      case 1: // Week (Last 7 days)
        return allData.take(7).toList();
      case 2: // Month (Last 30 days)
        return allData.take(30).toList();
      default:
        return allData.take(7).toList();
    }
  }

  /// Converts our data model into a list of [FlSpot] for the chart.
  /// Note: We reverse the list so the timeline goes from left (old) to right (new).
  List<FlSpot> _createChartSpots(List<HistoricalDataPoint> data) {
    if (data.isEmpty) return []; // Handle empty list
    
    final reversedData = data.reversed.toList();
    return List.generate(reversedData.length, (index) {
      return FlSpot(
        index.toDouble(), // X-axis (0, 1, 2...)
        reversedData[index].yield, // Y-axis
      );
    });
  }

  /// Card showing the total energy generated.
  Widget _buildTotalYieldCard(BuildContext context, double totalYield) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    String title = "Total Generated (This Week)";
    if (_selectedTimeIndex == 0) title = "Total Generated (Today)";
    if (_selectedTimeIndex == 2) title = "Total Generated (This Month)";

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Icon(Icons.bolt, color: theme.colorScheme.secondary, size: 40),
                const SizedBox(width: 8),
                Text(
                  // Format to 1 decimal place
                  totalYield.toStringAsFixed(1),
                  style: textTheme.displaySmall,
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    'kWh',
                    style: textTheme.titleMedium
                        ?.copyWith(color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Toggle buttons for Day/Week/Month.
  Widget _buildTimeSelector(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ToggleButtons(
        isSelected: [
          _selectedTimeIndex == 0,
          _selectedTimeIndex == 1,
          _selectedTimeIndex == 2,
        ],
        onPressed: (index) {
          // When a button is pressed, just update the state.
          // The StreamBuilder will automatically re-filter the data.
          setState(() {
            _selectedTimeIndex = index;
          });
        },
        renderBorder: false,
        borderRadius: BorderRadius.circular(10),
        constraints: BoxConstraints(
          minHeight: 40.0,
          // Adjusted width to be robust
          minWidth: (MediaQuery.of(context).size.width - 40 - 32) / 3,
        ),
        children: const [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text('Day'),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text('Week'),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text('Month'),
          ),
        ],
      ),
    );
  }

  /// Card containing the main FL_Chart LineChart.
  Widget _buildLineChartCard(BuildContext context, List<FlSpot> spots) {
    return Card(
      child: Container(
        height: 400,
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
        child: (spots.isEmpty)
            ? Center(
                child: Text(
                  "No data for this period.",
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: Colors.grey[600]),
                ),
              )
            : LineChart(
                _getLineChartData(context, spots),
                duration: const Duration(milliseconds: 250),
              ),
      ),
    );
  }

  // --- CHART DATA HELPERS ---
  LineChartData _getLineChartData(BuildContext context, List<FlSpot> spots) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final gridColor = theme.brightness == Brightness.dark
        ? AppTheme.kaizenChartGrid
        : Colors.grey[300]!;
    final titleColor = Colors.grey[600]!;

    // Find min/max Y values from the spots
    double minY = 0;
    double maxY = 10; // Default max
    if (spots.isNotEmpty) {
      minY = spots.map((spot) => spot.y).fold(spots.first.y, (prev, y) => y < prev ? y : prev);
      maxY = spots.map((spot) => spot.y).fold(spots.first.y, (prev, y) => y > prev ? y : prev);
      
      // Add padding
      double padding = (maxY - minY) * 0.1; // 10% padding
      if (padding == 0) padding = 1; // Add padding if min == max
      
      minY = (minY - padding).floorToDouble();
      maxY = (maxY + padding).ceilToDouble();

      // Ensure min is not negative if all values are positive
      if (minY < 0 && spots.every((spot) => spot.y >= 0)) {
        minY = 0;
      }
    }

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        getDrawingHorizontalLine: (value) => FlLine(
          color: gridColor,
          strokeWidth: 1,
        ),
        getDrawingVerticalLine: (value) => FlLine(
          color: gridColor,
          strokeWidth: 1,
        ),
      ),
      titlesData: FlTitlesData(
        show: true,
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            getTitlesWidget: (value, meta) => Text(
              value.toInt().toString(),
              style: TextStyle(color: titleColor, fontSize: 12),
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            // We'll just show the index for now
            // TODO: Format this to show dates
            getTitlesWidget: (value, meta) => Text(
              value.toInt().toString(),
              style: TextStyle(color: titleColor, fontSize: 12),
            ),
          ),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: gridColor),
      ),
      minX: 0,
      // maxX should be the number of spots - 1, or 0 if only one spot
      maxX: (spots.length - 1).toDouble() > 0 ? (spots.length - 1).toDouble() : 0,
      minY: minY,
      maxY: maxY,
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: colorScheme.secondary, // Use accent green
          barWidth: 5,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                colorScheme.secondary.withOpacity(0.3),
                colorScheme.secondary.withOpacity(0.0),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
    );
  }
}