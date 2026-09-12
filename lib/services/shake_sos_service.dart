import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

class ShakeSOSService {
  static const _serviceChannel = MethodChannel('com.example.shakti/service');
  static const _shakeChannel = EventChannel('com.example.shakti/shake');

  VoidCallback? _onSOSTrigger;

  Future<void> startListening({required VoidCallback onSOSTrigger}) async {
    _onSOSTrigger = onSOSTrigger;
    try {
      await _serviceChannel.invokeMethod('startService');
      debugPrint('✅ Background shake service started');

      _shakeChannel.receiveBroadcastStream().listen((event) {
        if (event == 'shake_detected') {
          debugPrint('🚨 Background shake detected!');
          _onSOSTrigger?.call();
        }
      });
    } catch (e) {
      debugPrint('Shake service error: $e');
    }
  }

  Future<void> stopListening() async {
    try {
      await _serviceChannel.invokeMethod('stopService');
    } catch (e) {
      debugPrint('Error stopping shake service: $e');
    }
  }
}
