import 'package:flutter/material.dart';

const doctorSpecialties = <String>[
// التخصصات القديمة
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

// التخصصات الجديدة
'الأمراض الجلدية والتناسلية',
'الأنف والأذن والحنجرة',
'المسالك البولية',
'طب الأعصاب',
'الطب النفسي',
'أمراض الكلى',
'أمراض الجهاز الهضمي والكبد',
'أمراض الصدر والجهاز التنفسي',
'طب الأورام',
'الأشعة والتصوير الطبي',
];

const Map<String, String> _arabicSpecialties = {
// التخصصات القديمة
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

// التخصصات الجديدة
'الأمراض الجلدية والتناسلية': 'الأمراض الجلدية والتناسلية',
'الأنف والأذن والحنجرة': 'الأنف والأذن والحنجرة',
'المسالك البولية': 'المسالك البولية',
'طب الأعصاب': 'طب الأعصاب',
'الطب النفسي': 'الطب النفسي',
'أمراض الكلى': 'أمراض الكلى',
'أمراض الجهاز الهضمي والكبد': 'أمراض الجهاز الهضمي والكبد',
'أمراض الصدر والجهاز التنفسي': 'أمراض الصدر والجهاز التنفسي',
'طب الأورام': 'طب الأورام',
'الأشعة والتصوير الطبي': 'الأشعة والتصوير الطبي',

// دعم القيم الإنجليزية القديمة المحفوظة في Firestore
'dermatology': 'الأمراض الجلدية والتناسلية',
'cardiology': 'أمراض القلب',
'pediatrics': 'أمراض الأطفال',
'neurology': 'طب الأعصاب',
'orthopedics': 'العظام',
'gynecology': 'أمراض النساء',
'dentistry': 'طب الأسنان',
'ophthalmology': 'أمراض العينين',
'general medicine': 'الطب العام',
'family medicine': 'طب الأسرة',
'anesthesia': 'التخدير',
'urology': 'المسالك البولية',
'endocrinology': 'أمراض الغدد',
};

const Map<String, String> _englishSpecialties = {
// التخصصات القديمة
'طب الأسرة': 'Family Medicine',
'طب الأطفال': 'Pediatrics',
'النساء والتوليد': 'Obstetrics and Gynecology',
'الأمراض الباطنية': 'Internal Medicine',
'الجراحة العامة': 'General Surgery',
'جراحة العظام': 'Orthopedic Surgery',
'طب القلب والأوعية الدموية': 'Cardiology',
'طب الطوارئ': 'Emergency Medicine',
'طب العيون': 'Ophthalmology',
'طب الأسنان': 'Dentistry',

// التخصصات الجديدة
'الأمراض الجلدية والتناسلية': 'Dermatology and Venereology',
'الأنف والأذن والحنجرة': 'Otolaryngology (ENT)',
'المسالك البولية': 'Urology',
'طب الأعصاب': 'Neurology',
'الطب النفسي': 'Psychiatry',
'أمراض الكلى': 'Nephrology',
'أمراض الجهاز الهضمي والكبد': 'Gastroenterology and Hepatology',
'أمراض الصدر والجهاز التنفسي': 'Pulmonology',
'طب الأورام': 'Oncology',
'الأشعة والتصوير الطبي': 'Radiology and Medical Imaging',

// دعم القيم الإنجليزية القديمة المحفوظة في Firestore
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
final isArabic =
Localizations.localeOf(context).languageCode == 'ar';

final mapping = isArabic ? _arabicSpecialties : _englishSpecialties;

return mapping[normalized] ?? specialty.trim();
}