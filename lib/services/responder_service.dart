import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'location_service.dart';

class ResponderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocationService _locationService = LocationService();

  // Accept SOS and start tracking
  Future<void> acceptSOSAndTrack({
    required String alertId,
    required String sosEventId,
    required String responderId,
    required String responderName,
  }) async {
    try {
      final position = await _locationService.getCurrentLocation();
      if (position == null) return;

      await _firestore
          .collection('responder_tracking')
          .doc('${sosEventId}_$responderId')
          .set({
        'sosEventId': sosEventId,
        'responderId': responderId,
        'responderName': responderName,
        'alertId': alertId,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'status': 'on_way',
        'timestamp': FieldValue.serverTimestamp(),
        'startedAt': DateTime.now().toIso8601String(),
      });

      _startLiveTracking(sosEventId, responderId, responderName);
    } catch (e) {
      debugPrint('Error accepting SOS: $e');
    }
  }

  void _startLiveTracking(String sosEventId, String responderId, String name) {
    _locationService.getPositionStream().listen((position) async {
      try {
        await _firestore
            .collection('responder_tracking')
            .doc('${sosEventId}_$responderId')
            .update({
          'latitude': position.latitude,
          'longitude': position.longitude,
          'timestamp': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        debugPrint('Error updating responder location: $e');
      }
    });
  }

  // Get all responders for a SOS event
  Stream<QuerySnapshot> getRespondersForSOS(String sosEventId) {
    return _firestore
        .collection('responder_tracking')
        .where('sosEventId', isEqualTo: sosEventId)
        .snapshots();
  }

  // Mark as arrived
  Future<void> markAsArrived(String sosEventId, String responderId) async {
    await _firestore
        .collection('responder_tracking')
        .doc('${sosEventId}_$responderId')
        .update({
      'status': 'arrived',
      'arrivedAt': DateTime.now().toIso8601String(),
    });
  }
}
