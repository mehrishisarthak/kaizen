import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:kaizen/services/theme.dart';

class YieldAnalysisScreen extends StatefulWidget {
  const YieldAnalysisScreen({super.key});

  @override
  State<YieldAnalysisScreen> createState() => _YieldAnalysisScreenState();
}

class _YieldAnalysisScreenState extends State<YieldAnalysisScreen> {
  // 0 = Day, 1 = Week, 2 = Month
  int _selectedTimeIndex = 1;

  // Mock data lists for the line chart
  final List<FlSpot> daySpots = const [
    FlSpot(0, 1.2),
    FlSpot(4, 1.5),
    FlSpot(8, 1.4),
    FlSpot(12, 1.8),
    FlSpot(16, 1.5),
    FlSpot(20, 2.2),
    FlSpot(23, 1.8),
  ];

  final List<FlSpot> weekSpots = const [
    FlSpot(0, 20.1),
    FlSpot(1, 22.3),
    FlSpot(2, 21.8),
    FlSpot(3, 25.4),
    FlSpot(4, 23.1),
    FlSpot(5, 26.0),
    FlSpot(6, 24.5),
  ];

  final List<FlSpot> monthSpots = const [
    FlSpot(0, 100),
    FlSpot(4, 120),
    FlSpot(8, 110),
    FlSpot(12, 130),
    FlSpot(16, 150),
    FlSpot(20, 140),
    FlSpot(24, 165),
    FlSpot(28, 155),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        // Theming from AppTheme is applied
        title: Text(
          'Yield Analysis',
          style: textTheme.titleLarge,
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTotalYieldCard(context),
              const SizedBox(height: 24),
              _buildTimeSelector(context),
              const SizedBox(height: 24),
              _buildLineChartCard(context),
              const SizedBox(height: 24),
              _buildBreakdownCard(context),
            ],
          ),
        ),
      ),
    );
  }

  /// Card showing the total energy generated.
  Widget _buildTotalYieldCard(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total Generated (This Week)',
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
                  '162.1', // Example data
                  style: textTheme.displaySmall,
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    'kWh',
                    style: textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
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
    // Theme is applied automatically by ToggleButtonsTheme in AppTheme
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
          setState(() {
            _selectedTimeIndex = index;
          });
        },
        renderBorder: false,
        borderRadius: BorderRadius.circular(10),
        constraints: BoxConstraints(
          minHeight: 40.0,
          minWidth: (MediaQuery.of(context).size.width - 40) / 3,
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
  Widget _buildLineChartCard(BuildContext context) {
    return Card(
      child: Container(
        height: 300,
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
        child: LineChart(
          _getLineChartData(context),
          duration: const Duration(milliseconds: 250), // Animation duration
        ),
      ),
    );
  }

  /// Card for the Pie Chart and breakdown.
  Widget _buildBreakdownCard(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Source Breakdown',
              style: textTheme.titleMedium,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                SizedBox(
                  height: 120,
                  width: 120,
                  child: PieChart(
                    PieChartData(
                      sections: _getPieChartData(context),
                      centerSpaceRadius: 40,
                      sectionsSpace: 2,
                    ),
                    swapAnimationDuration: const Duration(milliseconds: 150),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Indicator(
                        color: theme.colorScheme.secondary, // accentColor
                        text: 'Source 1 (Steel Press)',
                      ),
                      const SizedBox(height: 8),
                      Indicator(
                        color: Colors.blueAccent,
                        text: 'Source 2 (Glass Kiln)',
                      ),
                      const SizedBox(height: 8),
                      Indicator(
                        color: Colors.orangeAccent,
                        text: 'Source 3 (Exhaust)',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- CHART DATA HELPERS ---

  /// Returns the correct LineChartData based on the selected time index.
  LineChartData _getLineChartData(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final gridColor = theme.brightness == Brightness.dark
        ? AppTheme.kaizenChartGrid
        : Colors.grey[300]!;
    final titleColor = Colors.grey[600]!;

    List<FlSpot> spots;
    double maxX;
    double minY;
    double maxY;

    switch (_selectedTimeIndex) {
      case 0: // Day
        spots = daySpots;
        maxX = 23;
        minY = 0;
        maxY = 3;
        break;
      case 1: // Week
        spots = weekSpots;
        maxX = 6;
        minY = 18;
        maxY = 28;
        break;
      case 2: // Month
        spots = monthSpots;
        maxX = 28;
        minY = 80;
        maxY = 180;
        break;
      default:
        spots = weekSpots;
        maxX = 6;
        minY = 18;
        maxY = 28;
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
      maxX: maxX,
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

  /// Returns data for the Pie Chart.
  List<PieChartSectionData> _getPieChartData(BuildContext context) {
    final theme = Theme.of(context);
    return [
      PieChartSectionData(
        color: theme.colorScheme.secondary,
        value: 40,
        title: '40%',
        radius: 40,
        titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
      ),
      PieChartSectionData(
        color: Colors.blueAccent,
        value: 35,
        title: '35%',
        radius: 40,
        titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
      ),
      PieChartSectionData(
        color: Colors.orangeAccent,
        value: 25,
        title: '25%',
        radius: 40,
        titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
      ),
    ];
  }
}

/// A small widget for the Pie Chart legend.
class Indicator extends StatelessWidget {
  const Indicator({
    super.key,
    required this.color,
    required this.text,
    this.size = 16,
  });
  final Color color;
  final String text;
  final double size;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    
    return Row(
      children: <Widget>[
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: textTheme.bodyMedium?.copyWith(
              color: textTheme.bodyLarge?.color?.withOpacity(0.7),
            ),
          ),
        )
      ],
    );
  }
}