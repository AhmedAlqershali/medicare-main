import 'package:flutter_test/flutter_test.dart';
import 'package:medicare/core/auth/models/medical_note.dart';

void main() {
  test('medical notes preserve all entries and sort newest first', () {
    final first = MedicalNote(
      id: 'note-a',
      text: 'المريض يعاني من...',
      createdAt: DateTime.utc(2026, 10, 5, 11, 10),
      doctorUid: 'doctor-1',
      doctorName: 'دكتور أحمد',
    );
    final second = MedicalNote(
      id: 'note-b',
      text: 'تمت المتابعة...',
      createdAt: DateTime.utc(2026, 10, 7, 15, 20),
      doctorUid: 'doctor-1',
      doctorName: 'دكتور أحمد',
    );
    final third = MedicalNote(
      id: 'note-c',
      text: 'يحتاج مراجعة...',
      createdAt: DateTime.utc(2026, 10, 8, 9, 40),
      doctorUid: 'doctor-1',
      doctorName: 'دكتور أحمد',
    );

    final notes = MedicalNote.sortNewestFirst([first, second, third]);

    expect(notes.map((note) => note.id), ['note-c', 'note-b', 'note-a']);
    expect(notes.map((note) => note.text), [
      'يحتاج مراجعة...',
      'تمت المتابعة...',
      'المريض يعاني من...',
    ]);
    expect(notes, contains(first));
    expect(notes, contains(second));
    expect(notes, contains(third));
  });
}
