import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Listens to device accelerometer streams and notifies when a physical shake gesture occurs.
class ShakeDetectorService {
  static final ShakeDetectorService instance = ShakeDetectorService._internal();
  ShakeDetectorService._internal();

  StreamSubscription<UserAccelerometerEvent>? _subscription;
  VoidCallback? _onShake;

  // Configuration parameters
  final double shakeThreshold = 13.5; // m/s^2 acceleration threshold
  final int shakeCooldownMs = 900; // Debounce window between triggers

  DateTime _lastShakeTime = DateTime.fromMillisecondsSinceEpoch(0);
  double _lastX = 0.0;
  double _lastY = 0.0;
  double _lastZ = 0.0;

  bool _isListening = false;
  bool get isListening => _isListening;

  /// Starts listening for shake motions
  void startListening({required VoidCallback onShake}) {
    if (_isListening) {
      _onShake = onShake;
      return;
    }

    _onShake = onShake;
    _isListening = true;

    try {
      _subscription = userAccelerometerEventStream().listen(
        _handleAccelerometerEvent,
        onError: (error) {
          debugPrint('ShakeDetectorService sensor error (gracefully handled): $error');
          stopListening();
        },
        cancelOnError: false,
      );
    } catch (e) {
      debugPrint('ShakeDetectorService not supported on this platform: $e');
      _isListening = false;
    }
  }

  void _handleAccelerometerEvent(UserAccelerometerEvent event) {
    final now = DateTime.now();
    if (now.difference(_lastShakeTime).inMilliseconds < shakeCooldownMs) {
      return;
    }

    // Delta acceleration between frames
    final dx = event.x - _lastX;
    final dy = event.y - _lastY;
    final dz = event.z - _lastZ;

    _lastX = event.x;
    _lastY = event.y;
    _lastZ = event.z;

    final delta = sqrt(dx * dx + dy * dy + dz * dz);
    final magnitude = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);

    if (delta > shakeThreshold || magnitude > shakeThreshold) {
      _lastShakeTime = now;
      if (_onShake != null) {
        _onShake!();
      }
    }
  }

  /// Manually simulates a shake event (useful for tests, web demo, or debug trigger)
  void simulateShake() {
    _lastShakeTime = DateTime.now();
    _onShake?.call();
  }

  /// Stops sensor stream
  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
    _isListening = false;
  }
}
