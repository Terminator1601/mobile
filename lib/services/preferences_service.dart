import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const _keyThemeMode = 'theme_mode';
  static const _keyNotifications = 'notifications_enabled';
  static const _keyLocationSharing = 'location_sharing_enabled';

  late final SharedPreferences _prefs;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
  }

  ThemeMode get themeMode {
    final value = _prefs.getString(_keyThemeMode) ?? 'dark';
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.dark;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.system => 'system',
      _ => 'dark',
    };
    await _prefs.setString(_keyThemeMode, value);
  }

  bool get notificationsEnabled =>
      _prefs.getBool(_keyNotifications) ?? true;

  Future<void> setNotificationsEnabled(bool value) async {
    await _prefs.setBool(_keyNotifications, value);
  }

  bool get locationSharingEnabled =>
      _prefs.getBool(_keyLocationSharing) ?? true;

  Future<void> setLocationSharingEnabled(bool value) async {
    await _prefs.setBool(_keyLocationSharing, value);
  }
}
