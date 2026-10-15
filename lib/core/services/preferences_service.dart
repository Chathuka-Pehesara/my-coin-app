import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String _keyCurrency = 'pref_currency';
  static const String _keyMaskBalance = 'pref_mask_balance';
  static const String _keyPinCode = 'pref_pin_code';
  static const String _keyPinEnabled = 'pref_pin_enabled';
  static const String _keyBiometricEnabled = 'pref_biometric_enabled';
  static const String _keyOnboardingCompleted = 'pref_onboarding_completed';
  static const String _keyThemeMode = 'pref_theme_mode';

  final SharedPreferences _prefs;

  PreferencesService(this._prefs);

  static Future<PreferencesService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return PreferencesService(prefs);
  }

  // Currency (Initial default is LKR as requested)
  String get currencyCode => _prefs.getString(_keyCurrency) ?? 'LKR';
  Future<void> setCurrencyCode(String code) async {
    await _prefs.setString(_keyCurrency, code);
  }

  // Balance masking
  bool get isBalanceMasked => _prefs.getBool(_keyMaskBalance) ?? false;
  Future<void> setBalanceMasked(bool masked) async {
    await _prefs.setBool(_keyMaskBalance, masked);
  }

  // Security / PIN
  bool get isPinEnabled => _prefs.getBool(_keyPinEnabled) ?? false;
  String? get pinCode => _prefs.getString(_keyPinCode);

  Future<void> setPin({required String pin, required bool enabled}) async {
    await _prefs.setString(_keyPinCode, pin);
    await _prefs.setBool(_keyPinEnabled, enabled);
  }

  Future<void> disablePin() async {
    await _prefs.remove(_keyPinCode);
    await _prefs.setBool(_keyPinEnabled, false);
    await _prefs.setBool(_keyBiometricEnabled, false);
  }

  // Biometrics
  bool get isBiometricEnabled => _prefs.getBool(_keyBiometricEnabled) ?? false;
  Future<void> setBiometricEnabled(bool enabled) async {
    await _prefs.setBool(_keyBiometricEnabled, enabled);
  }

  // Onboarding
  bool get hasCompletedOnboarding => _prefs.getBool(_keyOnboardingCompleted) ?? false;
  Future<void> setOnboardingCompleted(bool completed) async {
    await _prefs.setBool(_keyOnboardingCompleted, completed);
  }

  // Theme
  String get themeMode => _prefs.getString(_keyThemeMode) ?? 'light';
  Future<void> setThemeMode(String mode) async {
    await _prefs.setString(_keyThemeMode, mode);
  }

  // Clear all
  Future<void> clearAll() async {
    await _prefs.clear();
  }
}
