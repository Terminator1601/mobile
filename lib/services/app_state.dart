import 'package:flutter/foundation.dart';

import '../models/user.dart';
import 'auth_service.dart';
import 'user_service.dart';

class AppState extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();

  User? _currentUser;
  bool _isLoading = false;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;

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
