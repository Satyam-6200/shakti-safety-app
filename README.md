<div align="center">

# 🛡️ SHAKTI
### Women Safety Application

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)
![Kotlin](https://img.shields.io/badge/Kotlin-7F52FF?style=for-the-badge&logo=kotlin&logoColor=white)
![Android](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)

**"Your Safety, One Tap Away"**

*A community-powered emergency response system that reduces response time from 15 minutes to under 2 minutes*

[Features](#-features) • [Tech Stack](#-tech-stack) • [Architecture](#-architecture) • [Setup](#-setup) • [Screenshots](#-screenshots)

</div>

---

## 🚨 The Problem

Traditional emergency apps only alert pre-saved contacts who might be miles away. By the time help arrives, it's often too late. **SHAKTI** solves this by creating a community safety net where nearby verified users respond immediately.

---

## ✨ Features

### 🔴 Core Emergency Features
| Feature | Description |
|---------|-------------|
| **One-Tap SOS** | Single button triggers complete emergency protocol |
| **Community Alerts** | Notifies verified users within 2km radius instantly |
| **Live Responder Tracking** | Real-time helper location like Swiggy/Blinkit delivery |
| **Auto SMS** | Sends emergency SMS to contacts automatically (no user action needed) |
| **Background Shake** | Shake phone 3 times → SOS triggers even when app is closed |
| **Volume Button SOS** | Press volume 5 times rapidly → Emergency trigger |

### 🗺️ Safety Features
| Feature | Description |
|---------|-------------|
| **Safe Routes** | Walking route to nearest police station/hospital |
| **Safe Places Map** | Nearby police stations, hospitals, fire stations on map |
| **Emergency Calls** | Direct call to 112 (Police) and 1091 (Mahila Helpline) |
| **Live Location** | Real-time location sharing with emergency contacts |

### 🔒 Security Features
| Feature | Description |
|---------|-------------|
| **Email Verification** | Mandatory email verification before account access |
| **FCM Background Alerts** | Push notifications even on locked screen |
| **Alert Deduplication** | Smart system prevents notification spam |
| **Session Persistence** | Auto-login - no repeated logins needed |

---

## 🛠️ Tech Stack

### Frontend
```
Flutter (Dart) → Cross-platform mobile app
Material Design 3 → UI components
Provider → State management
StreamBuilder → Reactive real-time UI
AnimationController → Smooth SOS button pulse
```

### Backend & Database
```
Firebase Cloud Firestore → NoSQL real-time database
Firebase Authentication → Email/password + verification
Firebase Cloud Messaging → Background push notifications
Firebase Storage → Photos and documents
```

### Native Android (Kotlin)
```
ShaktiBackgroundService.kt → Foreground service for background shake
MainActivity.kt → Platform channel bridge (Flutter ↔ Native)
SmsManager → Direct auto SMS without user interaction
SensorManager → Accelerometer for shake detection (15 m/s² threshold)
BroadcastReceiver → Shake event relay to Flutter
```

### Location & Maps
```
Geolocator → Real-time GPS (< 20m accuracy)
Geocoding → Coordinates to human-readable address
Google Maps Flutter → Interactive map display
Google Places API → Nearby safe places search
Google Directions API → Safe walking route calculation
Haversine Formula → Precise 2km radius geo-query
```

### Communication
```
Flutter Local Notifications → In-app emergency alerts
Firebase Cloud Messaging → Background alerts
URL Launcher → Emergency calls and SMS
Kotlin SmsManager → Auto emergency SMS dispatch
```

---

## 🏗️ Architecture

```
shakti/
├── lib/
│   ├── main.dart                    # App entry + Firebase init + Auth state
│   ├── models/
│   │   ├── user_model.dart          # UserModel, EmergencyContact
│   │   └── sos_event_model.dart     # SOSEvent, ResponderLiveLocation
│   ├── services/
│   │   ├── auth_service.dart        # Firebase Auth + email verification
│   │   ├── sos_service.dart         # SOS trigger + emergency calls
│   │   ├── location_service.dart    # GPS + Firestore location tracking
│   │   ├── nearby_alert_service.dart# Geo-query + alert creation
│   │   ├── responder_service.dart   # Live responder tracking
│   │   ├── notification_service.dart# Local notifications + beep
│   │   ├── fcm_service.dart         # Firebase Cloud Messaging
│   │   ├── shake_sos_service.dart   # Background shake detection
│   │   ├── volume_sos_service.dart  # Volume button SOS
│   │   └── sms_service.dart         # Auto SMS via Kotlin bridge
│   └── screens/
│       ├── auth/
│       │   ├── splash_screen.dart
│       │   ├── login_screen.dart
│       │   ├── signup_screen.dart
│       │   └── registration_form_screen.dart
│       ├── home/
│       │   ├── home_screen.dart     # Main screen with SOS button
│       │   ├── sos_active_screen.dart
│       │   └── nearby_alert_dialog.dart
│       ├── map/
│       │   └── safe_route_screen.dart
│       ├── history/
│       │   └── history_screen.dart
│       ├── profile/
│       │   └── profile_screen.dart
│       ├── settings/
│       │   └── settings_screen.dart
│       └── responder/
│           └── responder_live_map.dart
├── android/
│   └── app/src/main/kotlin/com/example/shakti/
│       ├── MainActivity.kt          # Platform channels + SMS + Service control
│       └── ShaktiBackgroundService.kt # Foreground service for shake detection
└── pubspec.yaml
```

---

## 🔄 SOS Flow

```
User triggers SOS (tap/shake/volume)
         ↓
GPS Location fetched (< 20m accuracy)
         ↓
SOS Event created in Firestore
         ↓
Geo-query: Bounding Box → Haversine Formula → Find users within 2km
         ↓
Alert documents created for each nearby user
         ↓
Auto SMS sent to emergency contacts (Kotlin SmsManager)
         ↓
FCM push notification to nearby devices (even if app closed)
         ↓
Nearby device: Alert dialog shown with LOUD beep + vibration
         ↓
Helper taps "I'm Coming" → Live location tracking starts
         ↓
Victim sees "Help On The Way" with real-time helper location
         ↓
Victim taps "I'm Safe" → All alerts resolved
```

---

## 📊 Firestore Database Structure

```
users/
  {userId}/
    name, email, phone, isVerified
    emergencyContacts: [{name, phone, relation}]

user_locations/
  {userId}/
    latitude, longitude, accuracy, timestamp

nearby_alerts/
  {alertId}/
    victimId, receiverId, distance, status
    victimAddress, sosEventId, timestamp

responder_tracking/
  {sosEventId}_{responderId}/
    responderId, latitude, longitude, status
```

---

## ⚙️ Setup & Installation

### Prerequisites
- Flutter SDK 3.x
- Android Studio
- Firebase account
- Google Cloud account (for Maps API)

### 1. Clone Repository
```bash
git clone https://github.com/Satyam-6200/shakti-safety-app.git
cd shakti-safety-app
```

### 2. Firebase Setup
1. Create Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
2. Add Android app with package name `com.example.shakti`
3. Download `google-services.json` → place in `android/app/`
4. Enable **Email/Password** authentication
5. Create **Firestore Database** (asia-south1 region)
6. Enable **Firebase Cloud Messaging**

### 3. Google Maps API
1. Go to [console.cloud.google.com](https://console.cloud.google.com)
2. Enable: Maps SDK for Android, Places API, Directions API
3. Create API Key
4. Add to `android/app/src/main/AndroidManifest.xml`:
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_API_KEY_HERE"/>
```

### 4. Install Dependencies
```bash
flutter pub get
```

### 5. Run
```bash
flutter run
```

---

## 📱 Key Screens

| Screen | Description |
|--------|-------------|
| Home | SOS button + nearby users count + quick actions |
| SOS Active | Timer + alerts sent + responder tracking |
| Nearby Alert | Emergency popup on helper's device |
| Safe Routes | Map with police stations, hospitals, walking routes |
| History | Past SOS event records |
| Profile | User info + emergency contacts |
| Settings | Shake/volume toggle + notification preferences |

---

## 🔑 Android Permissions

```xml
ACCESS_FINE_LOCATION          → Precise GPS
ACCESS_BACKGROUND_LOCATION    → Always-on tracking
SEND_SMS                      → Auto emergency SMS
FOREGROUND_SERVICE            → Background shake service
FOREGROUND_SERVICE_HEALTH     → Accelerometer in background
HIGH_SAMPLING_RATE_SENSORS    → Fast shake detection
VIBRATE                       → Emergency haptics
WAKE_LOCK                     → Screen on during SOS
CAMERA                        → Live streaming (Phase 2)
USE_FULL_SCREEN_INTENT        → Lock screen alerts
```

---

## 📈 Impact

| Metric | Before SHAKTI | With SHAKTI |
|--------|--------------|-------------|
| Response Time | 15-20 minutes | < 2 minutes |
| Coverage | Pre-saved contacts only | 2km community radius |
| Notification | Manual call needed | Automatic |
| Background | App must be open | Works always |

---

## 🚀 Roadmap

- [x] SOS trigger with community alerts
- [x] Real-time responder tracking
- [x] Background shake detection
- [x] Auto SMS to emergency contacts
- [x] Safe routes map
- [ ] Live camera streaming during SOS
- [ ] Government ID verification
- [ ] Voice activation ("Hey Shakti")
- [ ] Smartwatch integration
- [ ] Offline mesh network

---

## 👨‍💻 Developer

**Satyam Kumar**
- GitHub: [@Satyam-6200](https://github.com/Satyam-6200)
- Email: mrsatyam-080@gmail.com
- B.Tech AI/ML | Full Stack Developer | Open Source Contributor

---

## 📄 License

This project is licensed under the MIT License.

---

<div align="center">

**Built with ❤️ for women's safety**

*SHAKTI - Your Safety, Our Priority*

⭐ Star this repo if you find it useful!

</div>
