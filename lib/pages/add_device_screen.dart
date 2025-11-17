import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:kaizen/services/auth_service.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:random_string/random_string.dart';

// Enum to manage the complex state
enum ProvisioningStep {
  showInstructions,
  enterDetails,
  provisioning,
  reconnecting,
}

class AddDeviceScreen extends StatefulWidget {
  const AddDeviceScreen({super.key});

  @override
  State<AddDeviceScreen> createState() => _AddDeviceScreenState();
}

class _AddDeviceScreenState extends State<AddDeviceScreen> {
  // Page State
  ProvisioningStep _currentStep = ProvisioningStep.showInstructions;
  bool _isLoading = false;
  String _statusMessage = "";
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  // Text field controllers
  final TextEditingController _gridNameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Network info
  String _homeSSID = "";
  final NetworkInfo _networkInfo = NetworkInfo();

  @override
  void initState() {
    super.initState();
    _getHomeWifi();
  }

  Future<void> _getHomeWifi() async {
    final String? ssid = await _networkInfo.getWifiName();
    if (ssid != null) {
      setState(() {
        _homeSSID = ssid.replaceAll('"', '');
      });
    }
  }

  @override
  void dispose() {
    _gridNameController.dispose();
    _passwordController.dispose();
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? Theme.of(context).colorScheme.error : Colors.green,
      ));
  }

  Future<void> _startProvisioning() async {
    if (_passwordController.text.isEmpty) {
      _showSnackBar("Please enter your WiFi password.", isError: true);
      return;
    }
    if (_gridNameController.text.isEmpty) {
      _showSnackBar("Please enter a name for your grid.", isError: true);
      return;
    }

    final String? currentWifi =
        (await _networkInfo.getWifiName())?.replaceAll('"', '');
    if (currentWifi == null ||
        !currentWifi.toLowerCase().contains('esp32_setup')) {
      _showSnackBar("Please connect to the 'ESP32_Setup' hotspot first.",
          isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
      _currentStep = ProvisioningStep.provisioning;
      _statusMessage = "Generating secure token...";
    });

    final authService = Provider.of<AuthService>(context, listen: false);
    final String? userId = authService.currentUser?.uid;
    if (userId == null) {
      _showSnackBar("You are not logged in. Please restart the app.",
          isError: true);
      setState(() => _isLoading = false);
      return;
    }

    final String token = randomAlphaNumeric(10);
    final String gridName = _gridNameController.text.trim();

    try {
      await FirebaseFirestore.instance
          .collection('provisioning_tokens')
          .doc(token)
          .set({
        'userId': userId,
        'gridName': gridName,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      _showSnackBar(
          "Error creating secure token. Check your internet connection.",
          isError: true);
      setState(() {
        _isLoading = false;
        _currentStep = ProvisioningStep.enterDetails;
      });
      return;
    }

    setState(() {
      _statusMessage = "Sending credentials to device...";
    });

    try {
      final response = await http
          .post(
            Uri.parse('http://192.168.4.1/setup'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'ssid': _homeSSID,
              'pass': _passwordController.text,
              'token': token,
            }),
          )
          .timeout(const Duration(seconds: 30));

      final Map<String, dynamic> espResponse = jsonDecode(response.body);

      if (espResponse['status'] == 'success') {
        _waitForReconnect();
      } else {
        _showSnackBar("Device reported an error: ${espResponse['error']}",
            isError: true);
        setState(() {
          _isLoading = false;
          _currentStep = ProvisioningStep.enterDetails;
        });
      }
    } catch (e) {
      _showSnackBar("Failed to connect to device. Is it in setup mode?",
          isError: true);
      setState(() {
        _isLoading = false;
        _currentStep = ProvisioningStep.enterDetails;
      });
    }
  }

  Future<void> _waitForReconnect() async {
    setState(() {
      _currentStep = ProvisioningStep.reconnecting;
      _statusMessage =
          "Credentials sent! Your device is now rebooting. Please reconnect your phone to your home WiFi ('$_homeSSID') to continue.";
    });

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text("Success! Reconnect to WiFi"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_statusMessage),
              const SizedBox(height: 20),
              const CircularProgressIndicator(),
            ],
          ),
        ),
      );
    }

    // --- FIX: Corrected the listener signature ---
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) async {
      if (results.contains(ConnectivityResult.wifi)) {
        final String? newSSID =
            (await _networkInfo.getWifiName())?.replaceAll('"', '');

        if (newSSID == _homeSSID) {
          _connectivitySubscription?.cancel();
          if (mounted) {
            Navigator.of(context).pop(); // Close the dialog
            Navigator.of(context).pop(); // Go back from AddDeviceScreen
            _showSnackBar("Device setup complete!", isError: false);
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text("Add New Grid", style: textTheme.titleLarge),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: _buildBody(context),
      ),
      // --- REMOVED: No longer using a separate bottom bar ---
    );
  }

  /// Builds the body of the scaffold based on the current step
  Widget _buildBody(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    switch (_currentStep) {
      // --- STEP 1: INSTRUCTIONS ---
      case ProvisioningStep.showInstructions:
        return Column(
          children: [
            _buildInstructions(context), // This is the Card
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                // --- FIX: Added explicit styling ---
                style: theme.elevatedButtonTheme.style,
                onPressed: () async {
                  final String? currentWifi =
                      (await _networkInfo.getWifiName())?.replaceAll('"', '');
                  if (currentWifi != null &&
                      currentWifi.toLowerCase().contains('esp32_setup')) {
                    setState(() {
                      _currentStep = ProvisioningStep.enterDetails;
                    });
                  } else {
                    _showSnackBar(
                        "You are not connected to the ESP32 hotspot. Please check your WiFi settings.",
                        isError: true);
                  }
                },
                child: const Text("I'm Connected to 'ESP32_Setup'"),
              ),
            ),
          ],
        );

      // --- STEP 2: ENTER DETAILS ---
      case ProvisioningStep.enterDetails:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.wifi_rounded,
                      color: theme.colorScheme.primary,
                      size: 40,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Your Home WiFi Network",
                              style: textTheme.bodyMedium),
                          Text(
                            _homeSSID.isEmpty ? "Not connected" : _homeSSID,
                            style: textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Form
            Text("Grid Name", style: textTheme.titleSmall),
            const SizedBox(height: 8),
            TextField(
              controller: _gridNameController,
              decoration: const InputDecoration(
                  hintText: "e.g., 'Home Grid'",
                  prefixIcon: Icon(Icons.grid_on_rounded),
                  // --- FIX: Using softer 16 radius ---
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(16)))),
            ),
            const SizedBox(height: 24),
            Text("Password for $_homeSSID", style: textTheme.titleSmall),
            const SizedBox(height: 8),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                  hintText: "Enter your home WiFi password",
                  prefixIcon: Icon(Icons.lock_outline_rounded),
                  // --- FIX: Using softer 16 radius ---
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(16)))),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                // --- FIX: Added explicit styling ---
                style: theme.elevatedButtonTheme.style,
                onPressed: _isLoading ? null : _startProvisioning,
                child: const Text("Start Setup"),
              ),
            ),
          ],
        );

      // --- STEP 3 & 4: LOADING / RECONNECTING ---
      case ProvisioningStep.provisioning:
      case ProvisioningStep.reconnecting:
        return Center(
          child: Padding(
            padding:
                EdgeInsets.only(top: MediaQuery.of(context).size.height / 5),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 24),
                Text(
                  _statusMessage,
                  style: textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
    }
  }

  /// --- Redesigned Instructions ---
  Widget _buildInstructions(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Let's Connect Your Grid",
              style: textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildInstructionStep(
              context,
              icon: Icons.power_settings_new_rounded,
              title: "1. Power on your device",
              subtitle:
                  "Plug in your new Kaizen Grid. It will automatically start its own WiFi hotspot. A light should begin blinking.",
            ),
            const Divider(height: 24),
            _buildInstructionStep(
              context,
              icon: Icons.wifi_find_rounded,
              title: "2. Connect to the hotspot",
              subtitle:
                  "Go to your phone's WiFi settings and connect to the network named 'ESP32_Setup'.",
            ),
            const Divider(height: 24),
            _buildInstructionStep(
              context,
              icon: Icons.check_circle_outline_rounded,
              title: "3. Return and continue",
              subtitle:
                  "Once you are connected, come back to this screen and tap the button below.",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionStep(BuildContext context,
      {required IconData icon,
      required String title,
      required String subtitle}) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
          foregroundColor: theme.colorScheme.primary,
          child: Icon(icon),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(subtitle,
                  style: textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
            ],
          ),
        ),
      ],
    );
  }
}