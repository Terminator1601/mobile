import 'package:flutter/material.dart';

import '../models/user.dart';
import 'auth_service.dart';
import 'user_service.dart';
import 'preferences_service.dart';

class AppState extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  final PreferencesService _prefs = PreferencesService();

  User? _currentUser;
  bool _isLoading = false;
  ThemeMode _themeMode = ThemeMode.dark;
  bool _notificationsEnabled = true;
  bool _locationSharingEnabled = true;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;
  ThemeMode get themeMode => _themeMode;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get locationSharingEnabled => _locationSharingEnabled;

  Future<void> initPreferences() async {
    await _prefs.init();
    _themeMode = _prefs.themeMode;
    _notificationsEnabled = _prefs.notificationsEnabled;
    _locationSharingEnabled = _prefs.locationSharingEnabled;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _prefs.setThemeMode(mode);
    notifyListeners();
  }

  Future<void> setNotificationsEnabled(bool value) async {
    _notificationsEnabled = value;
    await _prefs.setNotificationsEnabled(value);
    notifyListeners();
  }

  Future<void> setLocationSharingEnabled(bool value) async {
    _locationSharingEnabled = value;
    await _prefs.setLocationSharingEnabled(value);
    notifyListeners();
  }

  Future<void> tryAutoLogin() async {
    final loggedIn = await _authService.isLoggedIn();
    if (loggedIn) {
      try {
        _currentUser = await _userService.getMe();
        notifyListeners();
      } catch (_) {
        await _authService.logout();
      }
    }
  }

  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _authService.login(email: email, password: password);
      _currentUser = await _userService.getMe();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> register(
      String name, String email, String password, String gender) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _authService.register(
        name: name,
        email: email,
        password: password,
        gender: gender,
      );
      await _authService.login(email: email, password: password);
      _currentUser = await _userService.getMe();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _currentUser = null;
    notifyListeners();
  }

  Future<void> refreshUser() async {
    _currentUser = await _userService.getMe();
    notifyListeners();
  }
}
