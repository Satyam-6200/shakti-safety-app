import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class VolumeSOSService {
  static const int _pressCountRequired = 5;
  static const int _timeWindowSeconds = 3;

  int _pressCount = 0;
  DateTime? _firstPressTime;
  VoidCallback? _onSOSTrigger;
  bool _isActive = false;
  Timer? _resetTimer;

  void startListening({required VoidCallback onSOSTrigger}) {
    _onSOSTrigger = onSOSTrigger;
    _isActive = true;
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
    debugPrint('🔊 Volume SOS listener started');
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (!_isActive) return false;
    if (event is KeyDownEvent) {
      bool isVolumeKey =
          event.logicalKey == LogicalKeyboardKey.audioVolumeUp ||
          event.logicalKey == LogicalKeyboardKey.audioVolumeDown;
      if (isVolumeKey) {
        _handleVolumePress();
        return false;
      }
    }
    return false;
  }

  void _handleVolumePress() {
    DateTime now = DateTime.now();
    if (_firstPressTime == null) {
      _firstPressTime = now;
      _pressCount = 1;
    } else {
      int timeDiff = now.difference(_firstPressTime!).inSeconds;
      if (timeDiff <= _timeWindowSeconds) {
        _pressCount++;
        _resetTimer?.cancel();
        if (_pressCount >= _pressCountRequired) {
          debugPrint('🚨 VOLUME SOS TRIGGERED!');
          _pressCount = 0;
          _firstPressTime = null;
          _onSOSTrigger?.call();
        } else {
          _resetTimer = Timer(Duration(seconds: _timeWindowSeconds), () {
            _pressCount = 0;
            _firstPressTime = null;
          });
        }
      } else {
        _firstPressTime = now;
        _pressCount = 1;
      }
    }
  }

  void stopListening() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    _resetTimer?.cancel();
    _isActive = false;
  }
}
