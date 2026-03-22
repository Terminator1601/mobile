# Event Discovery Mobile App

Flutter app for location-based social event discovery.

## Prerequisites

- Flutter SDK 3.2+
- Android Studio or Xcode
- A Google Maps API key

## Setup

```bash
cd mobile
flutter pub get
```

### Google Maps API Key

**Android**: Add your API key in `android/app/src/main/AndroidManifest.xml`:

```xml
<meta-data
  android:name="com.google.android.geo.API_KEY"
  android:value="YOUR_API_KEY"/>
```

**iOS**: Add your API key in `ios/Runner/AppDelegate.swift`:

```swift
GMSServices.provideAPIKey("YOUR_API_KEY")
```

### Backend URL

The API client defaults to `http://10.0.2.2:8000` (Android emulator localhost).
Update the `_baseUrl` in `lib/services/api_client.dart` for your environment.

### Run

```bash
flutter run
```

flutter run -d 001583531000475 --release