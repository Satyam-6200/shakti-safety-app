import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../models/user_model.dart';
import 'location_service.dart';

class NearbyAlertService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocationService _locationService = LocationService();

  // Send alerts to nearby users when SOS is triggered
  Future<void> sendNearbyAlerts({
    required String victimId,
    required String victimName,
    required double victimLat,
    required double victimLong,
    required String victimAddress,
    required String sosEventId,
    double radiusInMeters = 2000,
  }) async {
    try {
      debugPrint('🚨 Sending nearby alerts...');
      debugPrint('📍 Victim: $victimName at $victimLat, $victimLong');

      List<Map<String, dynamic>> nearbyUsers =
          await _locationService.getNearbyUsers(
        currentUserId: victimId,
        currentLat: victimLat,
        currentLong: victimLong,
        radiusInMeters: radiusInMeters,
      );

      debugPrint('✅ Found ${nearbyUsers.length} nearby users');

      for (var user in nearbyUsers) {
        String userId = user['userId'];
        double distance = user['distance'];

        String distanceText = distance < 1000
            ? '${distance.toStringAsFixed(0)} meters'
            : '${(distance / 1000).toStringAsFixed(1)} km';

        await _firestore.collection('nearby_alerts').add({
          'victimId': victimId,
          'victimName': victimName,
          'receiverId': userId,
          'sosEventId': sosEventId,
          'distance': distance,
          'distanceText': distanceText,
          'latitude': victimLat,
          'longitude': victimLong,
          'victimAddress': victimAddress,
          'status': 'pending',
          'timestamp': FieldValue.serverTimestamp(),
        });

        debugPrint('🔔 Alert sent to: $userId ($distanceText)');
      }
    } catch (e) {
      debugPrint('Error sending nearby alerts: $e');
    }
  }

  // Listen to nearby alerts for current user
  Stream<QuerySnapshot> listenToNearbyAlerts(String userId) {
    return _firestore
        .collection('nearby_alerts')
        .where('receiverId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  // Accept alert
  Future<void> acceptAlert(String alertId, String responderId) async {
    await _firestore.collection('nearby_alerts').doc(alertId).update({
      'status': 'accepted',
      'responderId': responderId,
      'acceptedAt': FieldValue.serverTimestamp(),
    });
  }

  // Ignore alert
  Future<void> ignoreAlert(String alertId, String userId) async {
    await _firestore.collection('nearby_alerts').doc(alertId).update({
      'status': 'ignored',
      'ignoredBy': userId,
      'ignoredAt': FieldValue.serverTimestamp(),
    });
  }
}
