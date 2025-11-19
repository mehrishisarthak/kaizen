import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:kaizen/services/auth_service.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:permission_handler/permission_handler.dart'; 
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
      duration: Duration(seconds: isError ? 5 : 3),
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


    // ignore: use_build_context_synchronously
    final authService = Provider.of<AuthService>(context, listen: false);
    final String? userId = authService.currentUser?.uid;
    if (userId == null) {
      setState(() => _isLoading = false);
      _showSnackBar("Authentication error. Please log in again.", isError: true);
      return;
    }


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
  // PHASE 2: DEVICE SYNC (FIXED WITH TIMEOUT)
  // ===========================================================
  Future<void> _sendConfigToDevice() async {
    if (!await Permission.location.request().isGranted) {
       _showSnackBar("Location permission denied. Cannot verify WiFi connection.", isError: true);
    }

    setState(() {
      _isLoading = true;
      _statusMessage = "Connecting to device...";
      _currentStep = ProvisioningStep.sendingToDevice;
    });


    await Future.delayed(const Duration(seconds: 2));


    try {
      final response = await http.post(
        Uri.parse('http://192.168.4.1/setup'),
        headers: {
          'Content-Type': 'application/json',
          'Connection': 'keep-alive', 
        },
        body: jsonEncode({
          'ssid': _targetSsid,
          'pass': _targetPassword,
          'token': _generatedToken,
        }),
      ).timeout(const Duration(seconds: 15));


      if (response.statusCode == 200) {
         await _waitForDeviceRegistration();
      } else {
         var body = jsonDecode(response.body);
         throw Exception(body['error'] ?? "Device rejected credentials.");
      }


    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
        _currentStep = ProvisioningStep.connectToHotspot;
      });
      
      _showSnackBar(
        "Connection Failed. Please ensure:\n1. You are connected to 'ESP32_Setup'\n2. Mobile Data is OFF\n\nError: $e", 
        isError: true
      );
    }
  }


  /// ✅ FIXED: Better timeout handling and error messages
  Future<void> _waitForDeviceRegistration() async {
    if (!mounted) return;
    
    setState(() {
      _statusMessage = "Device is connecting to WiFi and registering...";
    });


    final authService = Provider.of<AuthService>(context, listen: false);
    final String? userId = authService.currentUser?.uid;
    
    if (userId == null) {
      _showSnackBar("Authentication error", isError: true);
      return;
    }


    try {
      final deviceQuery = FirebaseFirestore.instance
          .collection('user_devices')
          .doc(userId)
          .collection('devices')
          .where('gridName', isEqualTo: _gridNameController.text.trim())
          .limit(1);


      // ✅ FIX: Reduced timeout to 30 seconds with better error handling
      final timeout = Duration(seconds: 30);
      final startTime = DateTime.now();
      
      int checkCount = 0;


      await for (final snapshot in deviceQuery.snapshots()) {
        checkCount++;
        
        // Update status message every 5 checks
        if (checkCount % 5 == 0 && mounted) {
          setState(() {
            int elapsed = DateTime.now().difference(startTime).inSeconds;
            _statusMessage = "Still waiting... ($elapsed seconds elapsed)";
          });
        }
        
        // Check timeout
        if (DateTime.now().difference(startTime) > timeout) {
          throw TimeoutException("Device registration timed out after 30 seconds");
        }


        if (snapshot.docs.isNotEmpty) {
          // Device found! Success!
          _handleSuccess();
          return;
        }
        
        await Future.delayed(const Duration(milliseconds: 500));
      }
    } on TimeoutException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _currentStep = ProvisioningStep.connectToHotspot;
      });
      _showSnackBar(
        "Timeout: ${e.message}\n\nPossible issues:\n• Wrong WiFi password\n• WiFi out of range\n• Device couldn't reach Cloud\n\nCheck ESP8266 Serial Monitor for errors", 
        isError: true
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _currentStep = ProvisioningStep.connectToHotspot;
      });
      _showSnackBar("Registration Error: $e\n\nCheck ESP8266 Serial Monitor", isError: true);
    }
  }


  void _handleSuccess() {
    if (!mounted) return;
    
    setState(() {
      _isLoading = false;
      _currentStep = ProvisioningStep.success;
    });
    
    _showSnackBar("Device registered successfully!");
    
    // AuthWrapper will handle navigation automatically
  }


  // ===========================================================
  // UI BUILDERS
  // ===========================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add New Grid"),
        automaticallyImplyLeading: _currentStep == ProvisioningStep.enterDetails,
      ),
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
            const SizedBox(height: 20),
            // ✅ ADDED: Cancel button during long operations
            if (_currentStep == ProvisioningStep.sendingToDevice)
              TextButton(
                onPressed: () {
                  setState(() {
                    _isLoading = false;
                    _currentStep = ProvisioningStep.connectToHotspot;
                  });
                },
                child: const Text("Cancel"),
              ),
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
            children: const [
              Text("1. Go to your phone's WiFi settings."),
              SizedBox(height: 5),
              Text("2. Connect to 'ESP32_Setup'."),
              SizedBox(height: 5),
              Text("3. IMPORTANT: Turn OFF Mobile Data temporarily."),
              SizedBox(height: 5),
              Text("4. Return to this app."),
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
    return Center(
      child: Column(
        children: const [
          SizedBox(height: 50),
          Icon(Icons.check_circle, size: 80, color: Colors.green),
          SizedBox(height: 20),
          Text("Success!", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          SizedBox(height: 10),
          Text("Device registered successfully!"),
          SizedBox(height: 10),
          Text("Navigating to home screen...", style: TextStyle(color: Colors.grey)),
          SizedBox(height: 20),
          CircularProgressIndicator(),
        ],
      ),
    );
  }


  @override
  void dispose() {
    _gridNameController.dispose();
    _ssidController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
