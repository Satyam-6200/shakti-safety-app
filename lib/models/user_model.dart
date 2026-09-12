class EmergencyContact {
  final String name;
  final String phone;
  final String relation;

  EmergencyContact({
    required this.name,
    required this.phone,
    required this.relation,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'relation': relation,
    };
  }

  factory EmergencyContact.fromMap(Map<String, dynamic> map) {
    return EmergencyContact(
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      relation: map['relation'] ?? '',
    );
  }
}

class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? address;
  final String? profileImageUrl;
  final List<EmergencyContact> emergencyContacts;
  final bool isVerified;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.address,
    this.profileImageUrl,
    this.emergencyContacts = const [],
    this.isVerified = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'profileImageUrl': profileImageUrl,
      'emergencyContacts': emergencyContacts.map((c) => c.toMap()).toList(),
      'isVerified': isVerified,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      address: map['address'],
      profileImageUrl: map['profileImageUrl'],
      emergencyContacts: (map['emergencyContacts'] as List<dynamic>?)
              ?.map((c) => EmergencyContact.fromMap(c as Map<String, dynamic>))
              .toList() ??
          [],
      isVerified: map['isVerified'] ?? false,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }

  UserModel copyWith({
    String? name,
    String? phone,
    String? address,
    String? profileImageUrl,
    List<EmergencyContact>? emergencyContacts,
    bool? isVerified,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      emergencyContacts: emergencyContacts ?? this.emergencyContacts,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt,
    );
  }
}
