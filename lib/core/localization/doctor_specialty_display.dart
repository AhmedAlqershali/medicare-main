import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

const Map<String, String> _arabicSpecialties = {
  'dermatology': 'الأمراض الجلدية',
  'cardiology': 'أمراض القلب',
  'pediatrics': 'أمراض الأطفال',
  'neurology': 'أمراض الجهاز العصبي',
  'orthopedics': 'العظام',
  'gynecology': 'أمراض النساء',
  'dentistry': 'طب الأسنان',
  'ophthalmology': 'أمراض العينين',
  'general medicine': 'الطب العام',
  'family medicine': 'طب الأسرة',
  'anesthesia': 'التخدير',
  'urology': 'أمراض المسالك',
  'endocrinology': 'أمراض الغدد',
};

const Map<String, String> _englishSpecialties = {
  'dermatology': 'Dermatology',
  'cardiology': 'Cardiology',
  'pediatrics': 'Pediatrics',
  'neurology': 'Neurology',
  'orthopedics': 'Orthopedics',
  'gynecology': 'Gynecology',
  'dentistry': 'Dentistry',
  'ophthalmology': 'Ophthalmology',
  'general medicine': 'General Medicine',
  'family medicine': 'Family Medicine',
  'anesthesia': 'Anesthesia',
  'urology': 'Urology',
  'endocrinology': 'Endocrinology',
};

String displayDoctorSpecialty(BuildContext context, String specialty) {
  final normalized = specialty.trim().toLowerCase();
  final isArabic = Localizations.of(context).locale.languageCode == 'ar';
  final mapping = isArabic ? _arabicSpecialties : _englishSpecialties;
  return mapping[normalized] ?? specialty.trim();
}
