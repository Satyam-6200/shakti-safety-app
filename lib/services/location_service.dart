import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class LocationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  LocationSettings get _locationSettings => const LocationSettings(
    accuracy: LocationAccuracy.bestForNavigation,
    distanceFilter: 5,
  );

  // Get current location
  Future<Position?> getCurrentLocation() async {
    try {
      LocationPermission permission = await checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        permission = await requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          return null;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: _locationSettings,
      );

      if (position.accuracy > 20) {
        await Future.delayed(const Duration(seconds: 2));
        position = await Geolocator.getCurrentPosition(
          locationSettings: _locationSettings,
        );
      }

      debugPrint('📍 Location: ${position.latitude}, ${position.longitude} (${position.accuracy}m)');
      return position;
    } catch (e) {
      debugPrint('Error getting location: $e');
      return null;
    }
  }

  // Position stream
  Stream<Position> getPositionStream() {
    return Geolocator.getPositionStream(locationSettings: _locationSettings);
  }

  // Get address from coordinates
  Future<String> getAddressFromCoordinates(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        String address = [
          place.name,
          place.subLocality,
          place.locality,
          place.administrativeArea,
          place.postalCode,
        ].where((p) => p != null && p.isNotEmpty).join(', ');
        return address.isNotEmpty ? address : 'Unknown location';
      }
      return 'Unknown location';
    } catch (e) {
      return 'Lat: ${lat.toStringAsFixed(4)}, Long: ${lng.toStringAsFixed(4)}';
    }
  }

  // Start continuous location tracking
  Future<void> startLocationTracking(String userId) async {
    try {
      LocationPermission permission = await checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) return;

      debugPrint('📍 Location tracking started for: $userId');

      getPositionStream().listen((Position position) async {
        if (position.accuracy <= 30) {
          await _firestore.collection('user_locations').doc(userId).set({
            'latitude': position.latitude,
            'longitude': position.longitude,
            'accuracy': position.accuracy,
            'timestamp': FieldValue.serverTimestamp(),
          });
        }
      });
    } catch (e) {
      debugPrint('Error starting location tracking: $e');
    }
  }

  // Get nearby users within radius
  Future<List<Map<String, dynamic>>> getNearbyUsers({
    required String currentUserId,
    required double currentLat,
    required double currentLong,
    double radiusInMeters = 2000,
  }) async {
    try {
      double latDelta = radiusInMeters / 111000;
      double longDelta = radiusInMeters / (111000 * 0.7);

      QuerySnapshot snapshot = await _firestore
          .collection('user_locations')
          .where('latitude', isGreaterThan: currentLat - latDelta)
          .where('latitude', isLessThan: currentLat + latDelta)
          .get();

      List<Map<String, dynamic>> nearbyUsers = [];
      for (var doc in snapshot.docs) {
        if (doc.id == currentUserId) continue;
        var data = doc.data() as Map<String, dynamic>;
        double distance = Geolocator.distanceBetween(
          currentLat, currentLong,
          data['latitude'], data['longitude'],
        );
        if (distance <= radiusInMeters) {
          nearbyUsers.add({'userId': doc.id, 'distance': distance, ...data});
        }
      }
      return nearbyUsers;
    } catch (e) {
      debugPrint('Error getting nearby users: $e');
      return [];
    }
  }

  Future<LocationPermission> checkPermission() => Geolocator.checkPermission();
  Future<LocationPermission> requestPermission() => Geolocator.requestPermission();
}
