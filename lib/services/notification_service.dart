import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:typed_data';

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings settings =
        InitializationSettings(android: androidSettings);
    await _plugin.initialize(settings);
  }

  Future<void> showSOSNotification() async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'sos_channel', 'SOS Alerts',
      channelDescription: 'Critical SOS emergency alerts',
      importance: Importance.max,
      priority: Priority.high,
      ongoing: true,
      autoCancel: false,
      playSound: true,
      enableVibration: true,
    );
    const NotificationDetails details =
        NotificationDetails(android: androidDetails);
    await _plugin.show(1, '🚨 SOS ACTIVE', 'Emergency alert is active', details);
  }

  Future<void> showNearbyAlert(String victimName, String distance) async {
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.heavyImpact();

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'nearby_emergency_channel', 'Nearby Emergency Alerts',
      channelDescription: 'Someone nearby needs help!',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 1000, 500, 1000, 500, 1000]),
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      color: const Color(0xFFFF0000),
      ongoing: true,
      autoCancel: false,
    );
    final NotificationDetails details =
        NotificationDetails(android: androidDetails);
    await _plugin.show(
        999, '🚨 EMERGENCY NEARBY!', '$victimName needs help - $distance away', details);
  }

  Future<void> cancelNearbyAlert() async {
    await _plugin.cancel(999);
  }

  Future<void> stopSiren() async {
    await _plugin.cancel(1);
  }
}
