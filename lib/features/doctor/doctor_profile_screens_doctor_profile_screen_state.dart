part of 'doctor_profile_screens.dart';

class _DoctorProfileScreenState
extends State<DoctorProfileScreen> {
var _profile = const DoctorProfile(
name: '',
specialty: '',
clinic: '',
organizationName: '',
email: '',
phone: '',
birthDate: '',
gender: '',
);

String? _error;
bool _isLoading = true;

@override
void initState() {
super.initState();
_loadProfile();
}

Future<void> _loadProfile() async {
final session =
FirebaseAuthRepository.instance.session;

final doctorId = session.doctorId;
final organizationId = session.organizationId;

if (doctorId == null ||
doctorId.isEmpty ||
organizationId == null ||
organizationId.isEmpty) {
if (!mounted) return;

setState(() {
_isLoading = false;
_error = 'لا توجد جلسة طبيب نشطة.';
});
return;
}

try {
final doctor =
await FirestoreDoctorRepository.instance
    .fetchDoctorByIdForOrganization(
organizationId,
doctorId,
);

if (!mounted) return;

if (doctor == null) {
setState(() {
_isLoading = false;
_error = 'لم يتم العثور على ملف الطبيب.';
});
return;
}

final organization =
await FirestoreOrganizationRepository.instance
    .fetchOrganizationById(
organizationId,
);

String clinicName = doctor.clinic;

final clinicId = doctor.clinicId;

if (clinicId != null &&
clinicId.trim().isNotEmpty) {
final clinic =
await FirestoreClinicRepository.instance
    .fetchClinicById(
organizationId,
clinicId,
);

if (clinic != null) {
final fetchedClinicName =
clinic['name']?.toString().trim();

if (fetchedClinicName != null &&
fetchedClinicName.isNotEmpty) {
clinicName = fetchedClinicName;
}
}
}

if (!mounted) return;

setState(() {
_isLoading = false;
_error = null;

_profile = DoctorProfile(
name: doctor.name,
specialty: doctor.specialty,
clinic: clinicName,
organizationName:
organization?.name ?? '',
email: doctor.email,
phone: doctor.phone,
birthDate: doctor.birthDate,
gender: doctor.gender,
);
});
} catch (error) {
if (!mounted) return;

setState(() {
_isLoading = false;
_error = error.toString();
});
}
}

@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(
title: const Text('الملف الشخصي'),
),
body: SafeArea(
child: _isLoading
? const Center(
child: CircularProgressIndicator(),
)
    : SingleChildScrollView(
padding: const EdgeInsets.fromLTRB(
AppSpacing.lg,
AppSpacing.sm,
AppSpacing.lg,
AppSpacing.xl,
),
child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
if (_error != null) ...[
AppCard(
child: Row(
children: [
const Icon(
Icons.error_outline,
color: Color(0xFFC84C4C),
),
const SizedBox(
width: AppSpacing.sm,
),
Expanded(
child: Text(
_error!,
style: const TextStyle(
color: Color(0xFFC84C4C),
fontWeight:
FontWeight.w700,
),
),
),
],
),
),
const SizedBox(
height: AppSpacing.md,
),
],

AppCard(
child: Row(
children: [
AppAvatar(
initials:
_initials(_profile.name),
size: 72,
backgroundColor:
AppColors.sky,
),
const SizedBox(
width: AppSpacing.md,
),
Expanded(
child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
Text(
_profile.name.isEmpty
? 'طبيب'
    : _profile.name,
style: Theme.of(context)
    .textTheme
    .titleMedium
    ?.copyWith(
fontSize: 18,
fontWeight:
FontWeight.w800,
),
),
const SizedBox(
height: 4,
),
Text(
_profile.specialty.isEmpty
? 'التخصص غير محدد'
    : _profile.specialty,
style: Theme.of(context)
    .textTheme
    .bodyMedium
    ?.copyWith(
color:
AppColors.primaryDark,
fontWeight:
FontWeight.w700,
),
),
const SizedBox(
height: 3,
),
Text(
_profile.clinic.isEmpty
? 'العيادة غير محددة'
    : _profile.clinic,
style: Theme.of(context)
    .textTheme
    .bodyMedium,
),
],
),
),
IconButton(
onPressed: _editProfile,
icon: const Icon(
Icons.edit_outlined,
),
tooltip:
'تعديل الملف الشخصي',
),
],
),
),

const SizedBox(
height: AppSpacing.xl,
),

const SectionHeader(
title: 'المعلومات المهنية',
),

const SizedBox(
height: AppSpacing.sm,
),

_InfoTile(
icon: Icons.badge_outlined,
label: 'التخصص',
value: _profile.specialty.isEmpty
? 'غير محدد'
    : _profile.specialty,
),

_InfoTile(
icon: Icons.business_outlined,
label: 'المؤسسة',
value:
_profile.organizationName.isEmpty
? 'غير محددة'
    : _profile.organizationName,
),

_InfoTile(
icon: Icons.local_hospital_outlined,
label: 'العيادة',
value: _profile.clinic.isEmpty
? 'غير محددة'
    : _profile.clinic,
),

const SizedBox(
height: AppSpacing.lg,
),

const SectionHeader(
title: 'المعلومات الشخصية',
),

const SizedBox(
height: AppSpacing.sm,
),

_InfoTile(
icon: Icons.email_outlined,
label: 'البريد الإلكتروني',
value: _profile.email,
),

_InfoTile(
icon: Icons.phone_outlined,
label: 'رقم الهاتف',
value: _profile.phone.isEmpty
? 'غير مضاف'
    : _profile.phone,
),

_InfoTile(
icon: Icons.cake_outlined,
label: 'تاريخ الميلاد',
value: _profile.birthDate.isEmpty
? 'غير مضاف'
    : _profile.birthDate,
),

_InfoTile(
icon: Icons.person_outline,
label: 'الجنس',
value:
_genderLabel(_profile.gender),
),

const SizedBox(
height: AppSpacing.lg,
),

const SectionHeader(
title: 'الإعدادات',
),

const SizedBox(
height: AppSpacing.sm,
),

_SettingTile(
icon:
Icons.calendar_month_outlined,
title: 'جدول الطبيب',
onTap: () {
Navigator.of(context).push(
MaterialPageRoute<void>(
builder: (_) =>
const DoctorScheduleScreen(),
),
);
},
),

_SettingTile(
icon: Icons.edit_outlined,
title: 'تعديل الملف الشخصي',
onTap: _editProfile,
),

_SettingTile(
icon:
Icons.notifications_none_rounded,
title: 'الإشعارات',
onTap: () => _showMessage(
context,
'لا توجد إشعارات جديدة.',
),
),

_SettingTile(
icon: Icons.brightness_6_outlined,
title: 'المظهر',
onTap: () => _showMessage(
context,
'المظهر مضبوط على الوضع الفاتح.',
),
),

_SettingTile(
icon:
Icons.support_agent_outlined,
title: 'المساعدة',
onTap: () => _showMessage(
context,
'يسعدنا مساعدتك.',
),
),

_SettingTile(
icon: Icons.info_outline,
title: 'عن Medicare',
onTap: () => _showMessage(
context,
'Medicare للرعاية الصحية.',
),
),

_SettingTile(
icon: Icons.logout_rounded,
title: 'تسجيل الخروج',
color: const Color(0xFFC84C4C),
onTap: () =>
_showLogoutDialog(context),
),
],
),
),
),
);
}

Future<void> _editProfile() async {
final updated =
await Navigator.of(context).push<DoctorProfile>(
MaterialPageRoute(
builder: (_) => DoctorEditProfileScreen(
profile: _profile,
),
),
);

if (updated == null || !mounted) return;

final doctorId =
FirebaseAuthRepository.instance.session.doctorId;

final organizationId =
FirebaseAuthRepository.instance.session.organizationId;

if (doctorId == null ||
doctorId.isEmpty ||
organizationId == null ||
organizationId.isEmpty) {
return;
}

try {
await FirestoreDoctorRepository.instance
    .updateDoctorProfile(
doctorId: doctorId,
organizationId: organizationId,
phone: updated.phone,
birthDate: updated.birthDate,
gender: updated.gender,
);

if (!mounted) return;

setState(() {
_profile = updated;
});

ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content:
Text('تم تحديث الملف الشخصي بنجاح.'),
),
);
} catch (error) {
if (!mounted) return;

ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: Text(error.toString()),
),
);
}
}

static String _initials(String name) {
final parts = name
    .trim()
    .split(RegExp(r'\s+'))
    .where((part) => part.isNotEmpty)
    .toList();

if (parts.isEmpty) return 'ط';

if (parts.length == 1) {
return parts.first.substring(0, 1);
}

return '${parts.first.substring(0, 1)}'
'${parts.last.substring(0, 1)}';
}

static String _genderLabel(String gender) {
switch (gender.trim().toLowerCase()) {
case 'male':
return 'ذكر';
case 'female':
return 'أنثى';
default:
return 'غير مضاف';
}
}

static void _showMessage(
BuildContext context,
String message,
) {
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: Text(message),
),
);
}

static Future<void> _showLogoutDialog(
BuildContext context,
) async {
await showDialog<void>(
context: context,
builder: (dialogContext) {
return AlertDialog(
title: const Text('تسجيل الخروج'),
content: const Text(
'هل أنت متأكد من تسجيل الخروج؟',
),
actions: [
TextButton(
onPressed: () =>
Navigator.of(dialogContext).pop(),
child: const Text('إلغاء'),
),
FilledButton(
onPressed: () {
Navigator.of(dialogContext).pop();
AuthNavigation.openSignedOutFlow(
context,
);
},
child: const Text('تسجيل الخروج'),
),
],
);
},
);
}
}
