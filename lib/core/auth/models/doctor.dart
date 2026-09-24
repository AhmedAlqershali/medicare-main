import 'package:cloud_firestore/cloud_firestore.dart';

import 'account_status.dart';

class Doctor {
  const Doctor({
    required this.id,
    required this.name,
    required this.email,
    required this.organizationId,
    required this.specialty,
    required this.status,
    required this.initials,
    this.availability = const {},
    this.clinic = '',
    this.clinicId,
    this.phone = '',
    this.location = '',
    this.rating = 0,
    this.reviews = 0,
    this.experience = '',
    this.bio = '',
    this.services = const [],
    this.firebaseUid,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String email;
  final String organizationId;
  final String specialty;
  final AccountStatus status;
  final String initials;
  final Map<String, List<String>> availability;
  final String clinic;
  final String? clinicId;
  final String phone;
  final String location;
  final double rating;
  final int reviews;
  final String experience;
  final String bio;
  final List<String> services;
  final String? firebaseUid;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'id': id,
      'name': name,
      'email': email,
      'organizationId': organizationId,
      'specialty': specialty,
      'status': status.name,
      'initials': initials,
      'availability': availability,
      'clinic': clinic,
      'clinicId': clinicId,
      'phone': phone,
      'location': location,
      'rating': rating,
      'reviews': reviews,
      'experience': experience,
      'bio': bio,
      'services': services,
    };
    map['firebaseUid'] = firebaseUid;
    if (createdAt != null) map['createdAt'] = createdAt!.toUtc().toIso8601String();
    if (updatedAt != null) map['updatedAt'] = updatedAt!.toUtc().toIso8601String();
    return map;
  }

  static Doctor fromMap(Map<String, dynamic> map, [String? documentId]) => Doctor(
        id: documentId ?? map['id'] as String? ?? '',
        name: map['name'] as String? ?? '',
        email: map['email'] as String? ?? '',
        organizationId: map['organizationId'] as String? ?? '',
        specialty: map['specialty'] as String? ?? '',
        status: _status(map['status']),
        initials: map['initials'] as String? ?? '',
        availability: _availability(map['availability']),
        clinic: map['clinic'] as String? ?? '',
        clinicId: map['clinicId'] as String?,
        phone: map['phone'] as String? ?? '',
        location: map['location'] as String? ?? '',
        rating: (map['rating'] as num?)?.toDouble() ?? 0,
        reviews: (map['reviews'] as num?)?.toInt() ?? 0,
        experience: map['experience'] as String? ?? '',
        bio: map['bio'] as String? ?? '',
        services: map['services'] is List ? (map['services'] as List).map((item) => item.toString()).toList() : const [],
        firebaseUid: map['firebaseUid'] as String?,
        createdAt: _dateFromMap(map['createdAt']),
        updatedAt: _dateFromMap(map['updatedAt']),
      );

  static DateTime? _dateFromMap(Object? value) => switch (value) {
        String value => DateTime.tryParse(value),
        Timestamp value => value.toDate(),
        _ => null,
      };

  static AccountStatus _status(Object? value) {
    final normalized = value?.toString().trim().toLowerCase();
    return switch (normalized) {
      'active' || 'نشط' => AccountStatus.active,
      'inactive' || 'غير متاح' => AccountStatus.inactive,
      'pending' || 'قيد الانتظار' => AccountStatus.pending,
      _ => AccountStatus.active,
    };
  }

  static Map<String, List<String>> _availability(Object? value) {
    if (value is! Map) return const {};
    return value.map((key, slots) => MapEntry(
      key.toString(),
      slots is List ? slots.map((slot) => slot.toString()).toList() : <String>[],
    ));
  }
}
