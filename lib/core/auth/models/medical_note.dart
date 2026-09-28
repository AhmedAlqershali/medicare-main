import 'package:cloud_firestore/cloud_firestore.dart';

class MedicalNote {
  const MedicalNote({
    required this.id,
    required this.text,
    required this.createdAt,
    this.doctorId,
    this.doctorName,
  });

  final String id;
  final String text;
  final DateTime? createdAt;
  final String? doctorId;
  final String? doctorName;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text.trim(),
      'createdAt': createdAt?.toUtc().toIso8601String(),
      'doctorId': doctorId,
      'doctorName': doctorName,
    };
  }

  factory MedicalNote.fromMap(Map<String, dynamic> map) {
    DateTime? createdAt;

    final rawCreatedAt = map['createdAt'];

    if (rawCreatedAt is Timestamp) {
    createdAt = rawCreatedAt.toDate();
    } else if (rawCreatedAt is String) {
    createdAt = DateTime.tryParse(rawCreatedAt);
    }

    return MedicalNote(
    id: map['id']?.toString() ?? '',
    text: map['text']?.toString() ?? '',
    createdAt: createdAt,
    doctorId: map['doctorId']?.toString(),
    doctorName: map['doctorName']?.toString(),
    );

  }

  MedicalNote copyWith({
    String? id,
    String? text,
    DateTime? createdAt,
    String? doctorId,
    String? doctorName,
  }) {
    return MedicalNote(
      id: id ?? this.id,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
      doctorId: doctorId ?? this.doctorId,
      doctorName: doctorName ?? this.doctorName,
    );
  }
}
