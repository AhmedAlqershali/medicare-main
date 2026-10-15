import 'package:flutter/material.dart';

const doctorSpecialties = <String>[
  'طب الأسرة',
  'طب الأطفال',
  'النساء والتوليد',
  'الأمراض الباطنية',
  'الجراحة العامة',
  'جراحة العظام',
  'طب القلب والأوعية الدموية',
  'طب الطوارئ',
  'طب العيون',
  'طب الأسنان',
];

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
  'طب الأسرة': 'طب الأسرة',
  'طب الأطفال': 'طب الأطفال',
  'النساء والتوليد': 'النساء والتوليد',
  'الأمراض الباطنية': 'الأمراض الباطنية',
  'الجراحة العامة': 'الجراحة العامة',
  'جراحة العظام': 'جراحة العظام',
  'طب القلب والأوعية الدموية': 'طب القلب والأوعية الدموية',
  'طب الطوارئ': 'طب الطوارئ',
  'طب العيون': 'طب العيون',
  'طب الأسنان': 'طب الأسنان',
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
  'طب الأسرة': 'Family Medicine',
  'طب الأطفال': 'Pediatrics',
  'النساء والتوليد': 'Obstetrics and Gynecology',
  'الأمراض الباطنية': 'Internal Medicine',
  'الجراحة العامة': 'General Surgery',
  'جراحة العظام': 'Orthopedics',
  'طب القلب والأوعية الدموية': 'Cardiology',
  'طب الطوارئ': 'Emergency Medicine',
  'طب العيون': 'Ophthalmology',
  'طب الأسنان': 'Dentistry',
};

String displayDoctorSpecialty(BuildContext context, String specialty) {
  final normalized = specialty.trim().toLowerCase();
  final isArabic = Localizations.localeOf(context).languageCode == 'ar';
  final mapping = isArabic ? _arabicSpecialties : _englishSpecialties;
  return mapping[normalized] ?? specialty.trim();
}
