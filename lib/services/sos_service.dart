import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/user_model.dart';
import '../models/sos_event_model.dart';
import 'location_service.dart';
import 'nearby_alert_service.dart';
import 'sms_service.dart';

class SOSService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocationService _locationService = LocationService();
  final NearbyAlertService _nearbyAlertService = NearbyAlertService();
  final SMSService _smsService = SMSService();

  bool _isSOSActive = false;
  String? _activeSOSId;

  bool get isSOSActive => _isSOSActive;

  Future<SOSEvent?> triggerSOS(UserModel user) async {
    try {
      debugPrint('🚨 SOS Triggered for: ${user.name}');

      // Get location
      final position = await _locationService.getCurrentLocation();
      if (position == null) return null;

      final address = await _locationService.getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );

      // Create SOS event
      final sosData = {
        'userId': user.id,
        'userName': user.name,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
        'address': address,
        'timestamp': FieldValue.serverTimestamp(),
        'isActive': true,
      };

      final docRef = await _firestore.collection('sos_events').add(sosData);
      _activeSOSId = docRef.id;
      _isSOSActive = true;

      debugPrint('✅ SOS Event created: $_activeSOSId');

      final sosEvent = SOSEvent(
        id: docRef.id,
        userId: user.id,
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        address: address,
        timestamp: DateTime.now(),
        isActive: true,
      );

      // Send SMS to emergency contacts
      String smsMessage =
          '🚨 EMERGENCY ALERT 🚨\n\n'
          '${user.name} needs help!\n\n'
          'Location: $address\n\n'
          'Google Maps: https://maps.google.com/?q=${position.latitude},${position.longitude}\n\n'
          'Time: ${DateTime.now()}\n\n'
          'This is an automated message from SHAKTI Safety App.';

      List<String> phones =
          user.emergencyContacts.map((c) => c.phone).toList();
      await _smsService.sendBulkSMS(phoneNumbers: phones, message: smsMessage);

      // Alert nearby users
      await _nearbyAlertService.sendNearbyAlerts(
        victimId: user.id,
        victimName: user.name,
        victimLat: position.latitude,
        victimLong: position.longitude,
        victimAddress: address,
        sosEventId: docRef.id,
      );

      debugPrint('🚔 Alerting nearest police station...');

      return sosEvent;
    } catch (e) {
      debugPrint('Error triggering SOS: $e');
      return null;
    }
  }

  Future<void> cancelSOS() async {
    try {
      if (_activeSOSId != null) {
        await _firestore.collection('sos_events').doc(_activeSOSId).update({
          'isActive': false,
          'cancelledAt': FieldValue.serverTimestamp(),
        });
      }
      _isSOSActive = false;
      _activeSOSId = null;
    } catch (e) {
      debugPrint('Error cancelling SOS: $e');
    }
  }

  Future<void> resolveSOS(String sosEventId) async {
    try {
      await _firestore.collection('sos_events').doc(sosEventId).update({
        'isActive': false,
        'resolvedAt': FieldValue.serverTimestamp(),
      });
      _isSOSActive = false;
      _activeSOSId = null;
    } catch (e) {
      debugPrint('Error resolving SOS: $e');
    }
  }

  Future<void> makeEmergencyCall(String number) async {
    final Uri callUri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(callUri)) {
      await launchUrl(callUri);
    }
  }
}
