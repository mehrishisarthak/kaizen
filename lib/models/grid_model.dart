import 'package:cloud_firestore/cloud_firestore.dart';

class Grid {
  final String id;
  final String name;
  final String status;
  final double livePower;
  final int batteryHealth;
  // You can add more fields here, like 'last_seen'

  Grid({
    required this.id,
    required this.name,
    required this.status,
    required this.livePower,
    required this.batteryHealth,
  });

  /// Factory constructor to create a Grid object from a Firestore document.
  factory Grid.fromFirestore(DocumentSnapshot doc) {
    // Make sure to cast the data to a Map
    Map<String, dynamic> data = doc.data()! as Map<String, dynamic>;

    return Grid(
      // Get the document ID
      id: doc.id,
      
      // Use null-aware operators to provide default values
      name: data['name'] ?? 'Unnamed Grid',
      
      // We'll store status as a String in Firebase
      status: data['status'] ?? 'offline',
      
      // Ensure data types are correct
      livePower: (data['livePower'] ?? 0.0).toDouble(),
      batteryHealth: (data['batteryHealth'] ?? 0).toInt(),
    );
  }
}