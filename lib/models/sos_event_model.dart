class SOSEvent {
  final String id;
  final String userId;
  final double latitude;
  final double longitude;
  final double? accuracy;
  final String address;
  final DateTime timestamp;
  final bool isActive;

  SOSEvent({
    required this.id,
    required this.userId,
    required this.latitude,
    required this.longitude,
    this.accuracy,
    required this.address,
    required this.timestamp,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'address': address,
      'timestamp': timestamp.toIso8601String(),
      'isActive': isActive,
    };
  }

  factory SOSEvent.fromMap(Map<String, dynamic> map) {
    return SOSEvent(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      accuracy: map['accuracy']?.toDouble(),
      address: map['address'] ?? '',
      timestamp: map['timestamp'] != null
          ? DateTime.parse(map['timestamp'])
          : DateTime.now(),
      isActive: map['isActive'] ?? true,
    );
  }
}

class ResponderLiveLocation {
  final String userId;
  final String name;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final String status;

  ResponderLiveLocation({
    required this.userId,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.status = 'on_way',
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
      'status': status,
    };
  }

  factory ResponderLiveLocation.fromMap(Map<String, dynamic> map) {
    return ResponderLiveLocation(
      userId: map['userId'] ?? '',
      name: map['name'] ?? 'Helper',
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      timestamp: map['timestamp'] != null
          ? DateTime.parse(map['timestamp'])
          : DateTime.now(),
      status: map['status'] ?? 'on_way',
    );
  }
}
