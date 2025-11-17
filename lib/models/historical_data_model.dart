import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a single data point in our yield analysis chart.
class HistoricalDataPoint {
  final Timestamp timestamp;
  final double yield;

  HistoricalDataPoint({
    required this.timestamp,
    required this.yield,
  });

  /// Factory constructor to create a HistoricalDataPoint from a Firestore document.
  factory HistoricalDataPoint.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data()! as Map<String, dynamic>;

    return HistoricalDataPoint(
      timestamp: data['timestamp'] ?? Timestamp.now(),
      yield: (data['yield'] ?? 0.0).toDouble(),
    );
  }
}