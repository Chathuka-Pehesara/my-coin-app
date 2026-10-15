import 'package:flutter/material.dart';
import '../core/services/preferences_service.dart';
import '../core/services/biometric_service.dart';

class AuthProvider extends ChangeNotifier {
  final PreferencesService _prefs;
  final BiometricService _biometricService;

  bool _isLocked = true;
  bool _canUseBiometrics = false;

  AuthProvider(this._prefs, this._biometricService) {
    _checkSecurityState();
  }

  bool get isLocked => _isLocked;
  bool get isPinEnabled => _prefs.isPinEnabled;
  bool get isBiometricEnabled => _prefs.isBiometricEnabled;
  bool get canUseBiometrics => _canUseBiometrics;
  bool get isSecurityConfigured => isPinEnabled;

  Future<void> _checkSecurityState() async {
    _canUseBiometrics = await _biometricService.isBiometricsAvailable();
    if (!isPinEnabled) {
      _isLocked = false;
    } else {
      _isLocked = true;
    }
    notifyListeners();
  }

  Future<bool> unlockWithPin(String enteredPin) async {
    final storedPin = _prefs.pinCode;
    if (storedPin == null || storedPin.isEmpty) {
      _isLocked = false;
      notifyListeners();
      return true;
    }

    if (enteredPin == storedPin) {
      _isLocked = false;
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> unlockWithBiometrics() async {
    if (!isBiometricEnabled || !_canUseBiometrics) return false;

    final authenticated = await _biometricService.authenticate(
      reason: 'Unlock My Trans Actions',
    );

    if (authenticated) {
      _isLocked = false;
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> setPin(String newPin) async {
    await _prefs.setPin(pin: newPin, enabled: true);
    notifyListeners();
  }

  Future<void> setBiometrics(bool enabled) async {
    await _prefs.setBiometricEnabled(enabled);
    notifyListeners();
  }

  Future<void> disablePin() async {
    await _prefs.disablePin();
    _isLocked = false;
    notifyListeners();
  }

  void lockApp() {
    if (isPinEnabled) {
      _isLocked = true;
      notifyListeners();
    }
  }
}
