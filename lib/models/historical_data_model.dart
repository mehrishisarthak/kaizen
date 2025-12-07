import 'package:cloud_firestore/cloud_firestore.dart';

class HistoricalDataPoint {
  final DateTime timestamp;
  final double power;       // Was 'yield'
  final double temperature; // New
  final double humidity;    // New

  HistoricalDataPoint({
    required this.timestamp,
    required this.power,
    required this.temperature,
    required this.humidity,
  });

  factory HistoricalDataPoint.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return HistoricalDataPoint(
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      // Use null-coalescing to default to 0.0 if field is missing
      power: (data['livePower'] as num?)?.toDouble() ?? (data['yield'] as num?)?.toDouble() ?? 0.0,
      temperature: (data['temperature'] as num?)?.toDouble() ?? 0.0,
      humidity: (data['humidity'] as num?)?.toDouble() ?? 0.0,
    );
  }
}