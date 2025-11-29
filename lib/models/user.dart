/// 👤 User Model
/// Represents a user in the INDULINK system (Customer, Supplier, or Admin)
class User {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final UserRole role;
  final String? profileImage;
  final List<String>? wishlist;
  final String? businessName;
  final String? businessDescription;
  final String? businessAddress;
  final String? businessLicense;
  final List<Address>? addresses;
  final bool isEmailVerified;
  final bool isActive;
  final NotificationPreferences? notificationPreferences;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
    required this.role,
    this.profileImage,
    this.wishlist,
    this.businessName,
    this.businessDescription,
    this.businessAddress,
    this.businessLicense,
    this.addresses,
    this.isEmailVerified = false,
    this.isActive = true,
    this.notificationPreferences,
    required this.createdAt,
    required this.updatedAt,
  });

  String get fullName => '$firstName $lastName';
  String get initials => '${firstName[0]}${lastName[0]}'.toUpperCase();

  bool get isCustomer => role == UserRole.customer;
  bool get isSupplier => role == UserRole.supplier;
  bool get isAdmin => role == UserRole.admin;

  // JSON Serialization
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? json['id'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      role: UserRole.fromString(json['role'] ?? 'customer'),
      profileImage: json['profileImage'],
      wishlist:
          json['wishlist'] != null ? List<String>.from(json['wishlist']) : null,
      businessName: json['businessName'],
      businessDescription: json['businessDescription'],
      businessAddress: json['businessAddress'],
      businessLicense: json['businessLicense'],
      addresses: json['addresses'] != null
          ? (json['addresses'] as List).map((e) => Address.fromJson(e)).toList()
          : null,
      isEmailVerified: json['isEmailVerified'] ?? false,
      isActive: json['isActive'] ?? true,
      notificationPreferences: json['notificationPreferences'] != null
          ? NotificationPreferences.fromJson(json['notificationPreferences'])
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'role': role.value,
      'profileImage': profileImage,
      'wishlist': wishlist,
      'businessName': businessName,
      'businessDescription': businessDescription,
      'businessAddress': businessAddress,
      'businessLicense': businessLicense,
      'addresses': addresses?.map((e) => e.toJson()).toList(),
      'isEmailVerified': isEmailVerified,
      'isActive': isActive,
      'notificationPreferences': notificationPreferences?.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  User copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    UserRole? role,
    String? profileImage,
    List<String>? wishlist,
    String? businessName,
    String? businessDescription,
    String? businessAddress,
    String? businessLicense,
    List<Address>? addresses,
    bool? isEmailVerified,
    bool? isActive,
    NotificationPreferences? notificationPreferences,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      profileImage: profileImage ?? this.profileImage,
      wishlist: wishlist ?? this.wishlist,
      businessName: businessName ?? this.businessName,
      businessDescription: businessDescription ?? this.businessDescription,
      businessAddress: businessAddress ?? this.businessAddress,
      businessLicense: businessLicense ?? this.businessLicense,
      addresses: addresses ?? this.addresses,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isActive: isActive ?? this.isActive,
      notificationPreferences:
          notificationPreferences ?? this.notificationPreferences,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// 🏷️ User Role Enum
enum UserRole {
  customer,
  supplier,
  admin;

  String get value {
    switch (this) {
      case UserRole.customer:
        return 'customer';
      case UserRole.supplier:
        return 'supplier';
      case UserRole.admin:
        return 'admin';
    }
  }

  String get displayName {
    switch (this) {
      case UserRole.customer:
        return 'Customer';
      case UserRole.supplier:
        return 'Supplier';
      case UserRole.admin:
        return 'Admin';
    }
  }

  static UserRole fromString(String value) {
    switch (value.toLowerCase()) {
      case 'customer':
        return UserRole.customer;
      case 'supplier':
        return UserRole.supplier;
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.customer;
    }
  }
}

/// 📍 Address Model
class Address {
  final String? id;
  final AddressLabel label;
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

  String get fullAddress {
    final parts = [
      addressLine1,
      if (addressLine2 != null && addressLine2!.isNotEmpty) addressLine2,
      city,
      state,
      postalCode,
      country,
    ];
    return parts.join(', ');
  }

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['_id'],
      label: AddressLabel.fromString(json['label'] ?? 'home'),
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
      'label': label.value,
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
}

/// 🏠 Address Label Enum
enum AddressLabel {
  home,
  work,
  other;

  String get value {
    return name;
  }

  String get displayName {
    return name[0].toUpperCase() + name.substring(1);
  }

  static AddressLabel fromString(String value) {
    switch (value.toLowerCase()) {
      case 'home':
        return AddressLabel.home;
      case 'work':
        return AddressLabel.work;
      case 'other':
        return AddressLabel.other;
      default:
        return AddressLabel.home;
    }
  }
}

/// 🔔 Notification Preferences Model
class NotificationPreferences {
  final bool orderUpdates;
  final bool promotions;
  final bool messages;
  final bool system;
  final bool emailNotifications;
  final bool pushNotifications;

  NotificationPreferences({
    this.orderUpdates = true,
    this.promotions = true,
    this.messages = true,
    this.system = true,
    this.emailNotifications = true,
    this.pushNotifications = true,
  });

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      orderUpdates: json['orderUpdates'] ?? true,
      promotions: json['promotions'] ?? true,
      messages: json['messages'] ?? true,
      system: json['system'] ?? true,
      emailNotifications: json['emailNotifications'] ?? true,
      pushNotifications: json['pushNotifications'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'orderUpdates': orderUpdates,
      'promotions': promotions,
      'messages': messages,
      'system': system,
      'emailNotifications': emailNotifications,
      'pushNotifications': pushNotifications,
    };
  }

  NotificationPreferences copyWith({
    bool? orderUpdates,
    bool? promotions,
    bool? messages,
    bool? system,
    bool? emailNotifications,
    bool? pushNotifications,
  }) {
    return NotificationPreferences(
      orderUpdates: orderUpdates ?? this.orderUpdates,
      promotions: promotions ?? this.promotions,
      messages: messages ?? this.messages,
      system: system ?? this.system,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      pushNotifications: pushNotifications ?? this.pushNotifications,
    );
  }
}
