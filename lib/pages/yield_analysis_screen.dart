import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:kaizen/models/grid_model.dart';
import 'package:kaizen/models/historical_data_model.dart';
import 'package:kaizen/services/auth_service.dart';
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
  
  // 'Power', 'Temperature', 'Humidity'
  String _selectedMetric = 'Power';

  Stream<DocumentSnapshot>? _gridStream;
  Stream<QuerySnapshot>? _historicalDataStream;

  @override
  void initState() {
    super.initState();
    final authService = Provider.of<AuthService>(context, listen: false);
    final String? userId = authService.currentUser?.uid;

    if (userId != null) {
      _gridStream = FirebaseFirestore.instance
          .collection('user_devices')
          .doc(userId)
          .collection('devices')
          .doc(widget.gridId)
          .snapshots();

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
      stream: _gridStream,
      builder: (context, gridSnapshot) {
        // 1. Determine Page Title
        String gridName = 'Analysis';
        if (gridSnapshot.hasData && gridSnapshot.data!.exists) {
          try {
            final grid = Grid.fromFirestore(gridSnapshot.data!);
            gridName = grid.name;
          } catch (_) {}
        }

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            title: Text(gridName, style: textTheme.titleLarge),
            centerTitle: true,
            actions: [
              // Dropdown to switch metrics
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: DropdownButton<String>(
                  value: _selectedMetric,
                  icon: Icon(Icons.arrow_drop_down, color: theme.colorScheme.primary),
                  underline: const SizedBox(), // Remove default underline
                  items: <String>['Power', 'Temperature', 'Humidity']
                      .map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value, style: textTheme.bodyMedium),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedMetric = newValue!;
                    });
                  },
                ),
              ),
            ],
          ),
          body: StreamBuilder<QuerySnapshot>(
            stream: _historicalDataStream,
            builder: (context, dataSnapshot) {
              // Loading
              if (dataSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              // Error
              if (dataSnapshot.hasError) {
                return Center(child: Text("Error loading history."));
              }

              // Empty State (Clean message)
              if (!dataSnapshot.hasData || dataSnapshot.data!.docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bar_chart, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        "No history available yet.",
                        style: textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Data will appear here once collected.",
                        style: textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
                      ),
                    ],
                  ),
                );
              }

              // Parsing
              final allDataPoints = dataSnapshot.data!.docs
                  .map((doc) => HistoricalDataPoint.fromFirestore(doc))
                  .toList();

              // Filtering
              final List<HistoricalDataPoint> filteredData =
                  _getFilteredData(allDataPoints);

              // Prepare Spots
              final List<FlSpot> spots = _createChartSpots(filteredData);

              // Calculate Summary (Sum for Power, Average for Temp/Hum)
              double summaryValue = 0.0;
              if (filteredData.isNotEmpty) {
                if (_selectedMetric == 'Power') {
                  summaryValue = filteredData.fold(0.0, (sum, item) => sum + item.power);
                } else if (_selectedMetric == 'Temperature') {
                  final sum = filteredData.fold(0.0, (s, i) => s + i.temperature);
                  summaryValue = sum / filteredData.length;
                } else {
                  final sum = filteredData.fold(0.0, (s, i) => s + i.humidity);
                  summaryValue = sum / filteredData.length;
                }
              }

              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSummaryCard(context, summaryValue),
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

  /// Filters data based on Day/Week/Month toggle
  List<HistoricalDataPoint> _getFilteredData(List<HistoricalDataPoint> allData) {
    int count;
    switch (_selectedTimeIndex) {
      case 0: count = 1; break;  // Day
      case 1: count = 7; break;  // Week
      case 2: count = 30; break; // Month
      default: count = 7;
    }
    return allData.take(count).toList();
  }

  /// Maps data to FlSpots based on selected metric
  List<FlSpot> _createChartSpots(List<HistoricalDataPoint> data) {
    if (data.isEmpty) return [];
    final reversedData = data.reversed.toList();
    
    return List.generate(reversedData.length, (index) {
      double yVal;
      switch (_selectedMetric) {
        case 'Temperature': yVal = reversedData[index].temperature; break;
        case 'Humidity':    yVal = reversedData[index].humidity; break;
        default:            yVal = reversedData[index].power; break;
      }
      return FlSpot(index.toDouble(), yVal);
    });
  }

  /// Dynamic Summary Card (Total vs Average)
  Widget _buildSummaryCard(BuildContext context, double value) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    String title;
    String unit;
    IconData icon;

    if (_selectedMetric == 'Power') {
      title = "Total Generated";
      unit = ""; // Unit removed as requested
      icon = Icons.bolt;
    } else if (_selectedMetric == 'Temperature') {
      title = "Average Temperature";
      unit = "°C";
      icon = Icons.thermostat;
    } else {
      title = "Average Humidity";
      unit = "%";
      icon = Icons.water_drop;
    }

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
                Icon(icon, color: theme.colorScheme.secondary, size: 40),
                const SizedBox(width: 8),
                Text(
                  value.toStringAsFixed(1),
                  style: textTheme.displaySmall,
                ),
                if (unit.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  Text(unit, style: textTheme.titleMedium?.copyWith(color: Colors.grey[600])),
                ]
              ],
            ),
          ],
        ),
      ),
    );
  }

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
        onPressed: (index) => setState(() => _selectedTimeIndex = index),
        renderBorder: false,
        borderRadius: BorderRadius.circular(10),
        constraints: BoxConstraints(
          minHeight: 40.0,
          minWidth: (MediaQuery.of(context).size.width - 40 - 32) / 3,
        ),
        children: const [Text('Day'), Text('Week'), Text('Month')],
      ),
    );
  }

  Widget _buildLineChartCard(BuildContext context, List<FlSpot> spots) {
    return Card(
      child: Container(
        height: 400,
        padding: const EdgeInsets.fromLTRB(16, 24, 24, 12),
        child: spots.isEmpty
            ? Center(child: Text("No data available", style: Theme.of(context).textTheme.bodyMedium))
            : LineChart(
                _getLineChartData(context, spots),
                duration: const Duration(milliseconds: 250),
              ),
      ),
    );
  }

  LineChartData _getLineChartData(BuildContext context, List<FlSpot> spots) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final gridColor = theme.brightness == Brightness.dark ? Colors.white10 : Colors.grey[300]!;
    
    // Calculate dynamic Y-Axis
    double minY = 0;
    double maxY = 10;
    if (spots.isNotEmpty) {
      minY = spots.map((e) => e.y).reduce((a, b) => a < b ? a : b);
      maxY = spots.map((e) => e.y).reduce((a, b) => a > b ? a : b);
      double padding = (maxY - minY) * 0.2; 
      if (padding == 0) padding = 5;
      minY = (minY - padding).floorToDouble();
      maxY = (maxY + padding).ceilToDouble();
      // Clamp min to 0 for non-temperature metrics if you want, 
      // but keeping it flexible for temp (which can be negative) is safer.
      if (_selectedMetric != 'Temperature' && minY < 0) minY = 0;
    }

    return LineChartData(
      gridData: FlGridData(
        show: true, 
        drawVerticalLine: false,
        getDrawingHorizontalLine: (_) => FlLine(color: gridColor, strokeWidth: 1),
      ),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            getTitlesWidget: (val, _) => Text(val.toInt().toString(), style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ),
        ),
        bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), // Clean look
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      minX: 0,
      maxX: (spots.length - 1).toDouble(),
      minY: minY,
      maxY: maxY,
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: colorScheme.secondary,
          barWidth: 4,
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