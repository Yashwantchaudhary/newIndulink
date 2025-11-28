class User {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final String role;
  final String? profileImage;
  final String? businessName; // For suppliers
  final List<Address> addresses;
  final List<String> wishlist;
  final DateTime? createdAt; // For Firebase
  final bool? isActive; // For Firebase

  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
    required this.role,
    this.profileImage,
    this.businessName,
    this.addresses = const [],
    this.wishlist = const [],
    this.createdAt,
    this.isActive,
  });

  String get fullName => '$firstName $lastName';

  String get name => fullName;

  factory User.fromJson(Map<String, dynamic> json) {
    final role = json['role'] ?? 'customer';
    print('User.fromJson: Raw JSON role: ${json['role']}, parsed role: $role');

    return User(
      id: json['_id'] ?? json['id'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      role: role,
      profileImage: json['profileImage'],
      businessName: json['businessName'],
      addresses: (json['addresses'] as List<dynamic>?)
              ?.map((e) => Address.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      wishlist: (json['wishlist'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'role': role,
      'profileImage': profileImage,
      if (businessName != null) 'businessName': businessName,
      'addresses': addresses.map((e) => e.toJson()).toList(),
      'wishlist': wishlist,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (isActive != null) 'isActive': isActive,
    };
  }
}

class Address {
  final String? id;
  final String label;
  final String fullName;
  final String phone;
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String state;
  final String postalCode;
  final String country;
  final bool isDefault;

  Address({
    this.id,
    required this.label,
    required this.fullName,
    required this.phone,
    required this.addressLine1,
    this.addressLine2,
    required this.city,
    required this.state,
    required this.postalCode,
    this.country = 'Nepal',
    this.isDefault = false,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['_id'],
      label: json['label'] ?? 'home',
      fullName: json['fullName'] ?? '',
      phone: json['phone'] ?? '',
      addressLine1: json['addressLine1'] ?? '',
      addressLine2: json['addressLine2'],
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      postalCode: json['postalCode'] ?? '',
      country: json['country'] ?? 'Nepal',
      isDefault: json['isDefault'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'label': label,
      'fullName': fullName,
      'phone': phone,
      'addressLine1': addressLine1,
      if (addressLine2 != null) 'addressLine2': addressLine2,
      'city': city,
      'state': state,
      'postalCode': postalCode,
      'country': country,
      'isDefault': isDefault,
    };
  }

  String get fullAddress {
    final parts = [
      addressLine1,
      if (addressLine2 != null) addressLine2,
      city,
      state,
      postalCode,
      country,
    ];
    return parts.join(', ');
  }
}
