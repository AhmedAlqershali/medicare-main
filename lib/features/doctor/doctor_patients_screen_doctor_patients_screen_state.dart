part of 'doctor_patients_screen.dart';

class _DoctorPatientsScreenState extends State<DoctorPatientsScreen> {
final _searchController = TextEditingController();
String _query = '';
List<DoctorPatient> _patients = const [];

@override
void initState() {
super.initState();
_loadPatients();
}

Future<void> _loadPatients() async {
final doctorId =
FirebaseAuthRepository.instance.session.doctorId ?? '';
final organizationId =
FirebaseAuthRepository.instance.session.organizationId;

if (doctorId.isEmpty || organizationId == null || organizationId.isEmpty) return;

List<Patient> patients;
String? activeClinicId;

try {
final activeDoctor = await FirestoreDoctorRepository.instance
    .fetchDoctorByIdForOrganization(organizationId, doctorId);
if (activeDoctor == null || activeDoctor.clinicId == null) {
throw StateError('لا توجد عيادة نشطة مرتبطة بالطبيب الحالي.');
}
activeClinicId = activeDoctor.clinicId;
patients = await FirestorePatientRepository.instance
    .fetchPatientsForDoctor(
doctorId,
organizationId: organizationId,
);
} catch (error) {
if (mounted) {
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(content: Text(error.toString())),
);
}
return;
}

if (!mounted) return;

setState(() {
_patients = patients.map((patient) {
return DoctorPatient(
id: patient.id,
organizationId: patient.organizationId,
doctorId: doctorId,
clinicId: activeClinicId!,
firebaseUid: patient.firebaseUid ?? '',
name: patient.name,
initials: patient.initials,
age: _ageFromBirthDate(patient.birthDate),
gender: patient.gender ?? '',
birthDate: patient.birthDate ?? '',
email: patient.email,
phone: patient.phone ?? '',
lastAppointment: '',
                        status: switch (patient.status.name) {
                            'active' => 'نشط',
                            'pending' => 'قيد التفعيل',
                            'inactive' => 'غير نشط',
                            _ => 'غير معروف',
                        },
avatarColor: Colors.transparent,
notes: patient.notes ?? '',
problemLocation: patient.problemLocation,
);
}).toList();
});
}

String _ageFromBirthDate(String? birthDate) {
if (birthDate == null || birthDate.trim().isEmpty) return '';

final parsed = DateTime.tryParse(birthDate);
if (parsed == null) return '';

final today = DateTime.now();
var age = today.year - parsed.year;

if (today.month < parsed.month ||
(today.month == parsed.month && today.day < parsed.day)) {
age--;
}

return age >= 0 ? '$age سنة' : '';
}

@override
void dispose() {
_searchController.dispose();
super.dispose();
}

@override
Widget build(BuildContext context) {
final query = _query.trim().toLowerCase();
final patients = _patients
    .where(
(patient) =>
patient.name.toLowerCase().contains(query) ||
patient.email.toLowerCase().contains(query) ||
patient.phone.toLowerCase().contains(query) ||
patient.status.toLowerCase().contains(query),
)
    .toList();

final slivers = <Widget>[
SliverPadding(
padding: const EdgeInsets.fromLTRB(
AppSpacing.lg,
AppSpacing.sm,
AppSpacing.lg,
AppSpacing.md,
),
sliver: SliverToBoxAdapter(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
'ابحث في قائمة مرضاك ومعلومات المتابعة',
style: Theme.of(context).textTheme.bodyLarge,
),
const SizedBox(height: AppSpacing.md),
CustomTextField(
label: 'ابحث عن مريض',
prefixIcon: Icons.search_rounded,
controller: _searchController,
onChanged: (value) => setState(() => _query = value),
textInputAction: TextInputAction.search,
),
const SizedBox(height: AppSpacing.lg),
Text(
'${patients.length} مرضى',
style: Theme.of(context)
    .textTheme
    .bodyMedium
    ?.copyWith(fontWeight: FontWeight.w700),
),
],
),
),
),
];

if (patients.isEmpty) {
slivers.add(
const SliverFillRemaining(
hasScrollBody: false,
child: EmptyState(
title: 'لا توجد نتائج',
message: 'جرّب البحث باسم آخر.',
icon: Icons.person_search_outlined,
),
),
);
} else {
slivers.add(
SliverPadding(
padding: const EdgeInsets.fromLTRB(
AppSpacing.lg,
0,
AppSpacing.lg,
AppSpacing.xl,
),
sliver: SliverList(
delegate: SliverChildBuilderDelegate(
(context, index) {
final patient = patients[index];

return Padding(
padding: const EdgeInsets.only(
bottom: AppSpacing.sm,
),
child: _PatientCard(
patient: patient,
onTap: () async {
await Navigator.of(context).push<void>(
MaterialPageRoute<void>(
builder: (_) =>
DoctorPatientDetailsScreen(
patient: patient,
),
),
);

if (mounted) {
await _loadPatients();
}
},
),
);
},
childCount: patients.length,
),
),
),
);
}

return Scaffold(
appBar: AppBar(
title: const Text('المرضى'),
actions: [
IconButton(
onPressed: _openAddPatient,
icon: const Icon(Icons.person_add_alt_1_outlined),
tooltip: 'إضافة مريض',
),
],
),
body: SafeArea(
child: CustomScrollView(
physics: const BouncingScrollPhysics(),
slivers: slivers,
),
),
);
}

Future<void> _openAddPatient() async {
await Navigator.of(context).push<void>(
MaterialPageRoute<void>(
builder: (_) => const AddPatientScreen(),
),
);

if (mounted) {
await _loadPatients();
}
}
}
