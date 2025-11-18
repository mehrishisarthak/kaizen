import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:kaizen/services/auth_service.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:permission_handler/permission_handler.dart'; // <--- IMPORT ADDED
import 'package:provider/provider.dart';
import 'package:random_string/random_string.dart';

enum ProvisioningStep {
  enterDetails,
  connectToHotspot,
  sendingToDevice,
  success,
}

class AddDeviceScreen extends StatefulWidget {
  const AddDeviceScreen({super.key});

  @override
  State<AddDeviceScreen> createState() => _AddDeviceScreenState();
}

class _AddDeviceScreenState extends State<AddDeviceScreen> {
  ProvisioningStep _currentStep = ProvisioningStep.enterDetails;
  bool _isLoading = false;
  String _statusMessage = "";
  
  String? _generatedToken;
  String? _targetSsid;
  String? _targetPassword;

  final TextEditingController _gridNameController = TextEditingController();
  final TextEditingController _ssidController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final NetworkInfo _networkInfo = NetworkInfo();

  @override
  void initState() {
    super.initState();
    _prefillCurrentWifi();
  }

  Future<void> _prefillCurrentWifi() async {
    // We also need permission here to prefill!
    if (await Permission.location.request().isGranted) {
      String? wifiName = await _networkInfo.getWifiName();
      if (wifiName != null && !wifiName.toLowerCase().contains("esp")) {
        setState(() {
          _ssidController.text = wifiName.replaceAll('"', '');
        });
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.red : Colors.green,
    ));
  }

  // ===========================================================
  // PHASE 1: CLOUD SYNC
  // ===========================================================
  Future<void> _generateAndSaveToken() async {
    if (_gridNameController.text.isEmpty || _ssidController.text.isEmpty || _passwordController.text.isEmpty) {
      _showSnackBar("Please fill in all fields.", isError: true);
      return;
    }

    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
       _showSnackBar("No Internet! Please connect to Home WiFi or Data.", isError: true);
       return;
    }

    // Optional check: only possible if we have permission, otherwise skip
    if (await Permission.location.isGranted) {
      String? currentWifi = await _networkInfo.getWifiName();
      if (currentWifi != null && currentWifi.toLowerCase().contains("esp")) {
        _showSnackBar("You are connected to the Device! Please disconnect and use Home WiFi/Data for this step.", isError: true);
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _statusMessage = "Securing connection with Cloud...";
    });

    final authService = Provider.of<AuthService>(context, listen: false);
    final String? userId = authService.currentUser?.uid;
    if (userId == null) return;

    final String token = randomAlphaNumeric(10);

    try {
      await FirebaseFirestore.instance.collection('provisioning_tokens').doc(token).set({
        'userId': userId,
        'gridName': _gridNameController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _generatedToken = token;
        _targetSsid = _ssidController.text.trim();
        _targetPassword = _passwordController.text;
        _isLoading = false;
        _currentStep = ProvisioningStep.connectToHotspot;
      });

    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar("Cloud Error: $e", isError: true);
    }
  }

  // ===========================================================
  // PHASE 2: DEVICE SYNC (UPDATED WITH PERMISSION HANDLER)
  // ===========================================================
  Future<void> _sendConfigToDevice() async {
    bool canVerifyWifi = false;

    // 1. Request Permission
    var status = await Permission.location.status;
    if (!status.isGranted) {
      status = await Permission.location.request();
    }

    if (status.isGranted) {
      canVerifyWifi = true;
    } else {
      // Permission denied. We can't verify, but we shouldn't stop the user.
      _showSnackBar("Location permission denied. Unable to verify connection to ESP32_Setup.", isError: true);
      // proceed anyway with a warning
    }

    // 2. Verify Connection (Only if permission granted)
    if (canVerifyWifi) {
      String? currentWifi = await _networkInfo.getWifiName();
      // Clean string (remove quotes if present)
      currentWifi = currentWifi?.replaceAll('"', '');

      bool connectedToEsp = currentWifi != null && 
                            (currentWifi.toLowerCase().contains("esp") || currentWifi.toLowerCase().contains("setup"));

      if (!connectedToEsp) {
         _showSnackBar("Warning: Phone does not seem to be connected to 'ESP32_Setup'. Attempting anyway...", isError: false);
         // We do NOT return here. We let it try, just in case the SSID detection failed.
      }
    }

    setState(() {
      _isLoading = true;
      _statusMessage = "Sending configuration to device...";
      _currentStep = ProvisioningStep.sendingToDevice;
    });

    try {
      // 3. Send HTTP POST to the Device
      final response = await http.post(
        Uri.parse('http://192.168.4.1/setup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'ssid': _targetSsid,
          'pass': _targetPassword,
          'token': _generatedToken,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
         _handleSuccess();
      } else {
         throw Exception("Device rejected credentials. Check password.");
      }

    } catch (e) {
      setState(() {
        _isLoading = false;
        _currentStep = ProvisioningStep.connectToHotspot;
      });
      _showSnackBar("Connection Failed. Are you definitely connected to ESP32_Setup?", isError: true);
    }
  }

  void _handleSuccess() {
    setState(() {
      _isLoading = false;
      _currentStep = ProvisioningStep.success;
    });
    
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pop();
        _showSnackBar("Setup Complete! Device is rebooting.");
      }
    });
  }

  // ... UI BUILDERS (Same as before) ...
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add New Grid")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: _buildCurrentStep(),
      ),
    );
  }

  Widget _buildCurrentStep() {
    if (_isLoading) {
      return Center(
        child: Column(
          children: [
            const SizedBox(height: 100),
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(_statusMessage, textAlign: TextAlign.center),
          ],
        ),
      );
    }

    switch (_currentStep) {
      case ProvisioningStep.enterDetails:
        return _buildPhase1Form();
      case ProvisioningStep.connectToHotspot:
        return _buildPhase2Instructions();
      case ProvisioningStep.success:
        return _buildSuccessView();
      default:
        return Container();
    }
  }

  Widget _buildPhase1Form() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Step 1: Cloud Setup", 
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)
        ),
        const SizedBox(height: 8),
        const Text("Enter your Home WiFi details below. We will save a secure token to the cloud first."),
        const SizedBox(height: 20),

        TextField(
          controller: _gridNameController,
          decoration: const InputDecoration(labelText: "Device Name (e.g. Bedroom)"),
        ),
        const SizedBox(height: 15),
        TextField(
          controller: _ssidController,
          decoration: const InputDecoration(labelText: "Home WiFi Name (SSID)"),
        ),
        const SizedBox(height: 15),
        TextField(
          controller: _passwordController,
          obscureText: true,
          decoration: const InputDecoration(labelText: "Home WiFi Password"),
        ),
        const SizedBox(height: 30),
        
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _generateAndSaveToken,
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(15)),
            child: const Text("Generate Secure Token"),
          ),
        ),
      ],
    );
  }

  Widget _buildPhase2Instructions() {
    return Column(
      children: [
        const Icon(Icons.wifi_tethering, size: 60, color: Colors.orange),
        const SizedBox(height: 20),
        const Text(
          "Step 2: Connect to Device", 
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)
        ),
        const SizedBox(height: 15),
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.orange)
          ),
          child: Column(
            children: [
              const Text("1. Go to your phone's WiFi settings."),
              const SizedBox(height: 5),
              const Text("2. Connect to 'ESP32_Setup'."),
              const SizedBox(height: 5),
              const Text("3. Return to this app."),
            ],
          ),
        ),
        const SizedBox(height: 30),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _sendConfigToDevice,
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(15)),
            child: const Text("I am Connected to ESP32_Setup"),
          ),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: () {
            setState(() => _currentStep = ProvisioningStep.enterDetails);
          }, 
          child: const Text("Go Back / Edit Details")
        )
      ],
    );
  }

  Widget _buildSuccessView() {
    return const Center(
      child: Column(
        children: [
          SizedBox(height: 50),
          Icon(Icons.check_circle, size: 80, color: Colors.green),
          SizedBox(height: 20),
          Text("Success!", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          SizedBox(height: 10),
          Text("Credentials sent. The device is rebooting."),
        ],
      ),
    );
  }
}