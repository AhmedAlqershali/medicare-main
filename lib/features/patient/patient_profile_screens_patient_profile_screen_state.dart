part of 'patient_profile_screens.dart';

class _PatientProfileScreenState extends State<PatientProfileScreen> {
var _patient = const PatientProfile(
name: '',
phone: '',
email: '',
birthDate: '',
gender: '',
problemLocation: null,
medicalNotes: null,
medicalNotesHistory: [],
);

@override
void initState() {
super.initState();
_loadProfile();
}

Future<void> _loadProfile() async {
try {
final profile =
await const PatientProfileRepositoryImpl()
    .getPatientProfile();

if (!mounted) return;

setState(() {
_patient = PatientProfile(
name: profile.name,
phone: profile.phone,
email: profile.email,
birthDate: profile.birthDate,
gender: profile.gender,
problemLocation: profile.problemLocation,
medicalNotes: profile.medicalNotes,
medicalNotesHistory:
profile.medicalNotesHistory,
);
});
} catch (error) {
if (!mounted) return;

ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: Text(error.toString()),
),
);
}
}

@override
Widget build(BuildContext context) => Scaffold(
appBar: AppBar(
title: const Text('الملف الشخصي'),
),
body: SafeArea(
child: SingleChildScrollView(
padding: const EdgeInsets.fromLTRB(
AppSpacing.lg,
AppSpacing.sm,
AppSpacing.lg,
AppSpacing.xl,
),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
_ProfileHeader(
patient: _patient,
onEdit: () async {
final updated =
await Navigator.of(context)
    .push<PatientProfile>(
MaterialPageRoute(
builder: (_) =>
EditPatientProfileScreen(
patient: _patient,
),
),
);

if (updated == null || !mounted) {
return;
}

try {
final repository =
const PatientProfileRepositoryImpl();

await repository.updatePatientProfile(
PatientProfileEntity(
name: updated.name,
phone: updated.phone,
email: updated.email,
birthDate: updated.birthDate,
gender: updated.gender,
),
);

await _loadProfile();
} catch (error) {
if (mounted) {
ScaffoldMessenger.of(context)
    .showSnackBar(
SnackBar(
content: Text(error.toString()),
),
);
}
}
},
),

const SizedBox(
height: AppSpacing.xl,
),

const SectionHeader(
title: 'المعلومات الشخصية',
),

const SizedBox(
height: AppSpacing.sm,
),

_InfoCard(
icon: Icons.badge_outlined,
label: 'الاسم الكامل',
value: _patient.name,
),

_InfoCard(
icon: Icons.phone_outlined,
label: 'رقم الهاتف',
value: _patient.phone,
),

_InfoCard(
icon: Icons.email_outlined,
label: 'البريد الإلكتروني',
value: _patient.email,
),

_InfoCard(
icon: Icons.cake_outlined,
label: 'تاريخ الميلاد',
value: _patient.birthDate,
),

_InfoCard(
icon: Icons.person_outline,
label: 'الجنس',
value: _patient.gender,
),

const SizedBox(
height: AppSpacing.lg,
),

const SectionHeader(
title: 'المعلومات الطبية',
),

const SizedBox(
height: AppSpacing.sm,
),

_InfoCard(
icon: Icons.accessibility_new_outlined,
label: 'مكان المشكلة',
value: _patient.problemLocation == null ||
_patient.problemLocation!
    .trim()
    .isEmpty
? 'غير محدد'
    : _patient.problemLocation!,
),

const SizedBox(
height: AppSpacing.sm,
),

_buildMedicalNotesHistory(),

const SizedBox(
height: AppSpacing.md,
),

_NavigationTile(
icon: Icons.settings_outlined,
title: 'الإعدادات',
onTap: () => Navigator.of(context).push(
MaterialPageRoute(
builder: (_) =>
const PatientSettingsScreen(),
),
),
),
],
),
),
),
);

Widget _buildMedicalNotesHistory() {
final notes = _patient.medicalNotesHistory;

if (notes.isEmpty) {
final legacyNote = _patient.medicalNotes;

if (legacyNote != null &&
legacyNote.trim().isNotEmpty) {
return AppCard(
child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
Row(
children: [
const Icon(
Icons.note_alt_outlined,
color: AppColors.primary,
),
const SizedBox(
width: AppSpacing.sm,
),
Text(
'الملاحظات الطبية',
style: Theme.of(context)
    .textTheme
    .titleMedium
    ?.copyWith(
fontWeight: FontWeight.bold,
),
),
],
),
const SizedBox(
height: AppSpacing.sm,
),
Text(
legacyNote,
style: Theme.of(context)
    .textTheme
    .bodyMedium,
),
],
),
);
}

return AppCard(
child: Row(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
const Icon(
Icons.note_alt_outlined,
color: AppColors.primary,
),
const SizedBox(
width: AppSpacing.sm,
),
Expanded(
child: Text(
'لا توجد ملاحظات طبية حتى الآن.',
style: Theme.of(context)
    .textTheme
    .bodyMedium,
),
),
],
),
);
}

return Column(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
Padding(
padding: const EdgeInsets.only(
bottom: AppSpacing.sm,
),
child: Text(
'الملاحظات الطبية',
style: Theme.of(context)
    .textTheme
    .titleMedium
    ?.copyWith(
fontWeight: FontWeight.bold,
),
),
),

...notes.reversed.map(
(note) {
final date = note.createdAt;

final dateText = date == null
? ''
    : '${date.day}/${date.month}/${date.year}';

return Padding(
padding: const EdgeInsets.only(
bottom: AppSpacing.sm,
),
child: AppCard(
child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
Row(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
const Icon(
Icons.note_alt_outlined,
color: AppColors.primary,
),
const SizedBox(
width: AppSpacing.sm,
),
const Expanded(
child: Text(
'ملاحظة طبية',
style: TextStyle(
fontWeight:
FontWeight.bold,
),
),
),
if (dateText.isNotEmpty)
Text(
dateText,
style: Theme.of(context)
    .textTheme
    .bodySmall,
),
],
),

const SizedBox(
height: AppSpacing.sm,
),

Text(
note.text,
style: Theme.of(context)
    .textTheme
    .bodyMedium,
),

if (note.doctorName != null &&
note.doctorName!
    .trim()
    .isNotEmpty) ...[
const SizedBox(
height: AppSpacing.sm,
),
Text(
'بواسطة: ${note.doctorName}',
style: Theme.of(context)
    .textTheme
    .bodySmall,
),
],
],
),
),
);
},
),
],
);
}
}
