import 'package:cloud_firestore/cloud_firestore.dart';

class MedicalNote {
  const MedicalNote({
    required this.id,
    required this.text,
    required this.createdAt,
    this.doctorUid,
    this.doctorName,
  });

  final String id;
  final String text;
  final DateTime createdAt;
  final String? doctorUid;
  final String? doctorName;

  MedicalNote copyWith({
    String? id,
    String? text,
    DateTime? createdAt,
    String? doctorUid,
    String? doctorName,
  }) =>
      MedicalNote(
        id: id ?? this.id,
        text: text ?? this.text,
        createdAt: createdAt ?? this.createdAt,
        doctorUid: doctorUid ?? this.doctorUid,
        doctorName: doctorName ?? this.doctorName,
      );

  factory MedicalNote.fromMap(String id, Map<String, dynamic> map) {
    final createdAt = map['createdAt'];
    return MedicalNote(
      id: id,
      text: map['text'] as String? ?? '',
      createdAt: createdAt is Timestamp
          ? createdAt.toDate()
          : DateTime.tryParse(createdAt.toString()) ?? DateTime.now(),
      doctorUid: map['doctorUid'] as String?,
      doctorName: map['doctorName'] as String?,
    );
  }

  static List<MedicalNote> sortNewestFirst(List<MedicalNote> notes) {
    final sorted = List<MedicalNote>.from(notes);
    sorted.sort((first, second) => second.createdAt.compareTo(first.createdAt));
    return sorted;
  }
}
