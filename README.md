# Kaizen: Smart Grid & Energy Recovery System ⚡🌱

![Flutter](https://img.shields.io/badge/Flutter-3.0%2B-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-Serverless-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)
![IoT](https://img.shields.io/badge/Hardware-ESP32%2F8266-important?style=for-the-badge&logo=espressif&logoColor=white)
![Status](https://img.shields.io/badge/Status-Active_Development-success?style=for-the-badge)

**Kaizen** is an IoT-enabled ecosystem designed to monitor, analyze, and optimize energy recovery systems. It combines a sleek, cross-platform mobile application with a robust serverless backend and ESP-based hardware to provide real-time telemetry on power generation, temperature, and humidity.

> *Kaizen (改善) is the Japanese philosophy of continuous improvement.*

---

## 📸 App Gallery

The app features a modern Material 3 design with comprehensive monitoring tools.

| **Dashboard** | **Analytics** | **Profile & Settings** |
|:---:|:---:|:---:|
| <img src="assets/3.png" width="250" /> | <img src="assets/1.png" width="250" /> | <img src="assets/2.png" width="250" /> |
| *Real-time grid status* | *Weekly yield analysis* | *User preferences* |

| **Secure Auth** | **Device Setup** | **Dark Mode** |
|:---:|:---:|:---:|
| <img src="assets/6.png" width="250" /> | <img src="assets/4.png" width="250" /> | <img src="assets/10.png" width="250" /> |
| *Email & Google Sign-in* | *SoftAP Provisioning* | *System-wide theming* |

---

## 🛠️ The Hardware

The system is powered by custom IoT nodes (ESP8266/ESP32) that capture environmental data and voltage readings.

<img src="assets/9.jpg" width="100%" alt="Kaizen Hardware Prototype" />
*Prototype setup running on ESP NodeMCU*

---

## 🚀 Key Features

* **Real-Time Monitoring:** Live Websocket streams of Voltage (Power), Temperature, and Humidity via Firebase Firestore.
* **Smart Provisioning:** A secure "SoftAP" handshake mechanism to connect new IoT devices to the cloud without hardcoding WiFi credentials.
* **Historical Analysis:** Cloud Functions automatically aggregate live data into historical buckets for beautiful, interactive charts (Day/Week/Month).
* **Secure Authentication:** Full user management using Firebase Auth (Email/Password + Google OAuth) with email verification enforcement.
* **Themeable UI:** A modern Material 3 design with adaptive Light and Dark modes.
* **Hybrid Firmware:** Token-based provisioning with secure device-to-cloud communication.

---

## 🏗️ Technical Architecture

Kaizen uses a **Token-Based Provisioning Protocol** to ensure security:

1. **Token Gen:** The App generates a secure `token` and saves it to Firestore linked to the `userId`.
2. **Handshake:** The App connects to the Device's Hotspot (`ESP32_Setup`) and passes the `token` + `Home WiFi Credentials`.
3. **Verification:** The Device connects to the internet and hits a **Firebase Cloud Function** (`exchangeToken`).
4. **Binding:** The Cloud Function verifies the token, creates the device record in the user's DB, and mints a **Custom Auth Token** for the device.
5. **Telemetry:** The device uses this token to write secure data directly to Firestore.

### Tech Stack

| Component | Technology | Description |
| :--- | :--- | :--- |
| **Frontend** | Flutter (Dart) | Provider state management, Fl_Chart, Google Fonts. |
| **Backend** | Firebase | Firestore (NoSQL), Cloud Functions (Node.js). |
| **Auth** | Firebase Auth | Custom Claims for IoT devices, OAuth for users. |
| **Firmware** | C++ / Arduino | Runs on ESP8266/ESP32 NodeMCU. |

---

## 💻 Getting Started

### Prerequisites

* Flutter SDK (3.0+)
* Firebase CLI
* Node.js (for Cloud Functions)
* Arduino IDE or PlatformIO (for ESP firmware)
* ESP8266/ESP32 DevKit board
* USB-to-Serial adapter (for programming)

### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/kaizen.git
cd kaizen
```

### 2. Frontend Setup

```bash
# Install dependencies
flutter pub get

# Run the app
flutter run
```

### 3. Backend Setup (Firebase)

Initialize Firebase in your project root:

```bash
firebase init
# Select Firestore, Functions, and Authentication
```

Deploy the security rules and Cloud Functions found in `/functions`:

```bash
cd functions
npm install
firebase deploy --only functions
```

### 4. Hardware Setup - ESP8266/ESP32 Firmware

#### 4.1 Prerequisites

Before flashing the firmware, ensure you have:

- **Arduino IDE** (v1.8.19+) or **PlatformIO** extension
- **CH340 USB Driver** (for NodeMCU boards) - Download from [here](https://github.com/sparks2500/ch340g-ch340e-ch340c-windows-driver)
- **Required Libraries** installed in Arduino IDE:
  - `ESP8266WiFi` (built-in)
  - `ESP8266WebServer` (built-in)
  - `ESP8266HTTPClient` (built-in)
  - `ArduinoJson` by Benoit Blanchon (Install via Library Manager)
  - `SoftwareSerial` (built-in)

#### 4.2 Configuration & Credentials

Update the firmware file with your Firebase credentials:

```cpp
#define FIREBASE_API_KEY "YOUR_API_KEY_HERE"
#define FIREBASE_PROJECT_ID "YOUR_PROJECT_ID"
#define CLOUD_FUNCTION_URL "YOUR_CLOUD_FUNCTION_URL"
```

Find these values in your Firebase Console:
- **API Key:** Settings → Project Settings → Service Accounts
- **Project ID:** Visible in Firebase console URL
- **Cloud Function URL:** From Functions dashboard after deployment

#### 4.3 Hardware Connections

**Sensor Connections to Arduino/ESP via SoftwareSerial:**

```
ESP8266/ESP32           Arduino/Microcontroller
RX (GPIO5/D1)  <------>  TX (Pin 4)
TX (GPIO4/D2)  <------>  RX (Pin 5)

Arduino Sensor Pins:
- Voltage Sensor:   Analog A0
- Temperature:      DHT22 Pin 2
- Humidity:         DHT22 Pin 2 (same as Temp)
```

**Data Format from Arduino to ESP:**
```
VOLT:12.5,TEMP:24.0,HUM:60.5
```

The ESP8266 reads this data via Serial at 9600 baud and parses it automatically.

#### 4.4 Flashing the Firmware

**Using Arduino IDE:**

1. Open Arduino IDE
2. Go to **File → Preferences** and add this board manager URL:
   ```
   http://arduino.esp8266.com/stable/package_esp8266com_index.json
   ```
3. Go to **Tools → Board Manager**, search for "ESP8266", and install
4. Select **Tools → Board → Generic ESP8266 Module**
5. Set these options:
   - **CPU Frequency:** 80 MHz
   - **Flash Size:** 4M (1M SPIFFS)
   - **Upload Speed:** 115200
6. Connect your ESP via USB and select the appropriate COM port
7. Copy the firmware code into Arduino IDE and click **Upload**

**Expected Serial Output:**
```
╔════════════════════════════════╗
║    KAIZEN DEVICE BOOTING       ║
╚════════════════════════════════╝

⚠ No credentials found
→ Starting Provisioning Mode

┌─────────────────────────────┐
│ Hotspot: ESP32_Setup        │
│ IP: 192.168.4.1             │
└─────────────────────────────┘
```

#### 4.5 Provisioning Flow

Once the firmware boots:

1. **Device enters AP Mode** and broadcasts `ESP32_Setup` hotspot
2. **App discovers the hotspot** and displays it
3. **User selects the device** and enters WiFi credentials + receives provisioning token
4. **Device receives token** via `/setup` HTTP POST endpoint
5. **Device attempts WiFi connection** with provided credentials
6. **Upon success:**
   - Settings are saved to EEPROM
   - Device resets and enters Station Mode
   - Device exchanges token for Custom Token via Cloud Function
   - Device exchanges Custom Token for ID Token via Google Identity
7. **Device starts uploading** sensor data every 5 seconds

#### 4.6 Factory Reset (Clear Stored Credentials)

If you need to reset the device back to provisioning mode:

1. Uncomment the **[DANGER ZONE]** section in the firmware:
   ```cpp
   Serial.println("⚠ WIPING ALL SAVED DATA...");
   EEPROM.begin(512);
   for (int i = 0; i < 512; i++) {
     EEPROM.write(i, 0);
   }
   EEPROM.commit();
   Serial.println("✓ DATA WIPED! Comment this block out and re-upload.");
   while(true) { yield(); }
   ```
2. Upload the code
3. Wait for the wipe message to appear
4. Comment out those lines and re-upload
5. Device will restart in Provisioning Mode

#### 4.7 Firmware Architecture & Key Functions

**Main Modes:**

- **Provisioning Mode (AP Mode):**
  - Device broadcasts WiFi hotspot
  - Listens for POST requests on `/setup` endpoint
  - Validates WiFi connection before saving
  - Stores SSID, Password, and Provisioning Token in EEPROM

- **Station Mode (Normal Operation):**
  - Connects to home WiFi using stored credentials
  - Syncs time via NTP (required for HTTPS/SSL)
  - Exchanges provisioning token for Custom Token
  - Exchanges Custom Token for ID Token (60-minute expiry)
  - Reads sensor data from Arduino via SoftwareSerial (9600 baud)
  - Uploads live data every 5 seconds via Firestore REST API (PATCH)
  - Refreshes ID Token every 50 minutes

**Core Functions:**

```cpp
// Initialization
setup()                              // Boots device, loads settings
startProvisioningMode()              // Starts AP hotspot
startStationMode()                   // Connects to WiFi and initializes auth

// Provisioning
handleSetupRequest()                 // HTTP POST handler for WiFi credentials
saveSettings()                       // Saves to EEPROM
loadSettings()                       // Loads from EEPROM

// Authentication
getCustomToken()                     // Step 1: Cloud Function exchange
exchangeCustomTokenForIdToken()      // Step 2: Google Identity exchange
refreshIdToken()                     // Refreshes token before expiry

// Data Operations
readArduinoData()                    // Parses serial data from Arduino
pushDataToCloud()                    // PATCH request to Firestore

// Main Loop
loop()                               // Handles provisioning or data upload
```

**Data Upload Payload:**

The firmware sends data in Firestore's native format:

```json
{
  "fields": {
    "livePower": {
      "doubleValue": 12.50
    },
    "temperature": {
      "doubleValue": 24.0
    },
    "humidity": {
      "doubleValue": 60.5
    },
    "status": {
      "stringValue": "online"
    }
  }
}
```

#### 4.8 Troubleshooting

| Issue | Solution |
|-------|----------|
| Device won't connect to WiFi | Check SSID/password, ensure 2.4GHz network (not 5GHz) |
| Serial output is garbled | Verify baud rate is 115200 in Serial Monitor |
| Token exchange fails | Check API Key, Cloud Function URL, and Firebase rules |
| Data not uploading | Verify Firestore rules allow device writes, check ID Token expiry |
| Arduino data not read | Check SoftwareSerial pins (RX=D1, TX=D2), verify 9600 baud |
| HTTPS connection error | Ensure NTP time sync completed (check serial output) |

#### 4.9 Performance & Optimization

- **Upload Interval:** 5 seconds (configurable)
- **Token Refresh:** 50 minutes (before 60-minute expiry)
- **EEPROM Usage:** 512 bytes total (96 bytes credentials)
- **Firmware Size:** ~450 KB (fits on 4M flash)
- **Current Draw:** ~80-120mA (WiFi active), 10mA (sleep)

---

## 📂 Project Structure

```
lib/
├── models/           # Data models (Grid, HistoricalData)
├── pages/            # UI Screens (Home, YieldAnalysis, AddDevice)
├── services/         # Logic (AuthService, ThemeProvider)
├── main.dart         # Entry point
└── ...
functions/
├── index.js          # Node.js backend logic (Token exchange, History logger)
└── ...
firmware/
├── kaizen_firmware.ino    # ESP8266/ESP32 firmware (complete implementation)
├── platformio.ini         # PlatformIO configuration
└── README.md              # Hardware-specific setup guide
```

---

## 🔐 Security & Best Practices

* Do not commit API keys or service account files to version control.
* Restrict Firestore rules so only authenticated users and registered devices can read/write.
* Use HTTPS for all device–cloud communication in production.
* Rotate tokens and credentials periodically.
* Disable `client.setInsecure()` in production and use proper certificate validation.
* Store provisioning tokens securely and expire them after use.
* Validate all incoming JSON payloads on both device and backend.

---

## 🤝 Contributing

Contributions are welcome! Please fork the repository and submit a pull request for any features, bug fixes, or documentation improvements.

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📄 License

Distributed under the MIT License. See `LICENSE` for more information.

---

## 🔗 Resources

- [Arduino IDE Setup for ESP8266](https://arduino-esp8266.readthedocs.io/)
- [Firebase Firestore REST API](https://firebase.google.com/docs/firestore/use-rest-api)
- [ESP8266 WiFi Documentation](https://arduino-esp8266.readthedocs.io/en/latest/esp8266wifi/readme.html)
- [ArduinoJson Library](https://arduinojson.org/)
- [Firebase Cloud Functions](https://firebase.google.com/docs/functions)

---

**Developed with ❤️ by Sarthak Mehrishi**
