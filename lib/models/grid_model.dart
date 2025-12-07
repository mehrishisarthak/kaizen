import 'package:cloud_firestore/cloud_firestore.dart';

class Grid {
  final String id;
  final String name;
  final double livePower; // actually voltage based on your ESP code
  final String status;
  final int batteryHealth;
  final double temperature;
  final double humidity;

  Grid({
    required this.id,
    required this.name,
    required this.livePower,
    required this.status,
    required this.batteryHealth,
    required this.temperature,
    required this.humidity,
  });

  factory Grid.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Grid(
      id: doc.id,
      name: data['name'] ?? 'Unknown Grid',
      // Handle potential int/double mismatch from Firestore
      livePower: (data['livePower'] as num?)?.toDouble() ?? 0.0,
      status: data['status'] ?? 'unknown',
      batteryHealth: (data['batteryHealth'] as num?)?.toInt() ?? 0,
      // New fields from ESP
      temperature: (data['temperature'] as num?)?.toDouble() ?? 0.0,
      humidity: (data['humidity'] as num?)?.toDouble() ?? 0.0,
    );
  }
}