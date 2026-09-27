part of 'doctor_profile_screens.dart';

class _DoctorEditProfileScreenState
extends State<DoctorEditProfileScreen> {
late final TextEditingController _phoneController =
TextEditingController(
text: widget.profile.phone,
);

late String _birthDate = widget.profile.birthDate;
late String _gender = widget.profile.gender;

@override
void dispose() {
_phoneController.dispose();
super.dispose();
}

@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(
title: const Text('تعديل الملف الشخصي'),
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
AppCard(
child: Row(
children: [
AppAvatar(
initials: _initials(widget.profile.name),
size: 64,
backgroundColor: AppColors.sky,
),
const SizedBox(width: AppSpacing.md),
Expanded(
child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
Text(
widget.profile.name,
style: Theme.of(context)
    .textTheme
    .titleMedium
    ?.copyWith(
fontWeight: FontWeight.w800,
),
),
const SizedBox(height: 4),
Text(
widget.profile.specialty,
style: Theme.of(context)
    .textTheme
    .bodyMedium
    ?.copyWith(
color: AppColors.primaryDark,
fontWeight: FontWeight.w700,
),
),
if (widget.profile.clinic.isNotEmpty) ...[
const SizedBox(height: 3),
Text(
widget.profile.clinic,
style: Theme.of(context)
    .textTheme
    .bodyMedium,
),
],
],
),
),
],
),
),

const SizedBox(height: AppSpacing.xl),

const SectionHeader(
title: 'معلومات الحساب',
),
const SizedBox(height: AppSpacing.sm),

_ReadOnlyField(
label: 'البريد الإلكتروني',
value: widget.profile.email,
icon: Icons.email_outlined,
),

const SizedBox(height: AppSpacing.md),

_ReadOnlyField(
label: 'التخصص',
value: widget.profile.specialty,
icon: Icons.medical_information_outlined,
),

const SizedBox(height: AppSpacing.md),

_ReadOnlyField(
label: 'العيادة',
value: widget.profile.clinic,
icon: Icons.local_hospital_outlined,
),

const SizedBox(height: AppSpacing.xl),

const SectionHeader(
title: 'المعلومات الشخصية',
),
const SizedBox(height: AppSpacing.sm),

CustomTextField(
label: 'رقم الهاتف',
prefixIcon: Icons.phone_outlined,
controller: _phoneController,
keyboardType: TextInputType.phone,
),

const SizedBox(height: AppSpacing.md),

_DateField(
label: 'تاريخ الميلاد',
value: _birthDate,
onTap: _selectBirthDate,
),

const SizedBox(height: AppSpacing.md),

DropdownButtonFormField<String>(
initialValue: _gender.isEmpty ? null : _gender,
decoration: const InputDecoration(
labelText: 'الجنس',
prefixIcon: Icon(
Icons.person_outline,
),
),
items: const [
DropdownMenuItem(
value: 'male',
child: Text('ذكر'),
),
DropdownMenuItem(
value: 'female',
child: Text('أنثى'),
),
],
onChanged: (value) {
if (value == null) return;

setState(() {
_gender = value;
});
},
),

const SizedBox(height: AppSpacing.xl),

SizedBox(
width: double.infinity,
child: PrimaryButton(
label: 'حفظ التغييرات',
icon: Icons.check_rounded,
onPressed: _save,
),
),
],
),
),
),
);
}

Future<void> _selectBirthDate() async {
final initialDate = _parseBirthDate(_birthDate);

final selected = await showDatePicker(
context: context,
initialDate: initialDate,
firstDate: DateTime(1900),
lastDate: DateTime.now(),
helpText: 'اختر تاريخ الميلاد',
cancelText: 'إلغاء',
confirmText: 'اختيار',
);

if (selected == null || !mounted) return;

setState(() {
_birthDate = _formatDate(selected);
});
}

void _save() {
final phone = _phoneController.text.trim();

if (phone.isEmpty) {
_showError('يرجى إدخال رقم الهاتف.');
return;
}

if (_birthDate.trim().isEmpty) {
_showError('يرجى اختيار تاريخ الميلاد.');
return;
}

if (_gender.trim().isEmpty) {
_showError('يرجى اختيار الجنس.');
return;
}

Navigator.of(context).pop(
DoctorProfile(
name: widget.profile.name,
specialty: widget.profile.specialty,
clinic: widget.profile.clinic,
email: widget.profile.email,
phone: phone,
birthDate: _birthDate,
gender: _gender,
),
);
}

void _showError(String message) {
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: Text(message),
),
);
}

static DateTime _parseBirthDate(String value) {
final parsed = DateTime.tryParse(value);

if (parsed != null) {
return parsed;
}

final parts = value.split('-');

if (parts.length == 3) {
final year = int.tryParse(parts[0]);
final month = int.tryParse(parts[1]);
final day = int.tryParse(parts[2]);

if (year != null &&
month != null &&
day != null) {
return DateTime(
year,
month,
day,
);
}
}

final now = DateTime.now();

return DateTime(
now.year - 30,
now.month,
now.day,
);
}

static String _formatDate(DateTime date) {
final year = date.year.toString().padLeft(4, '0');
final month = date.month.toString().padLeft(2, '0');
final day = date.day.toString().padLeft(2, '0');

return '$year-$month-$day';
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
}

class _ReadOnlyField extends StatelessWidget {
const _ReadOnlyField({
required this.label,
required this.value,
required this.icon,
});

final String label;
final String value;
final IconData icon;

@override
Widget build(BuildContext context) {
return InputDecorator(
decoration: InputDecoration(
labelText: label,
prefixIcon: Icon(icon),
),
child: Text(
value.isEmpty ? 'غير محدد' : value,
style: Theme.of(context).textTheme.bodyLarge,
),
);
}
}

class _DateField extends StatelessWidget {
const _DateField({
required this.label,
required this.value,
required this.onTap,
});

final String label;
final String value;
final VoidCallback onTap;

@override
Widget build(BuildContext context) {
final hasValue = value.trim().isNotEmpty;

return InkWell(
onTap: onTap,
borderRadius: BorderRadius.circular(12),
child: InputDecorator(
decoration: InputDecoration(
labelText: label,
prefixIcon: const Icon(
Icons.cake_outlined,
),
),
child: Text(
hasValue ? value : 'اختر تاريخ الميلاد',
style: Theme.of(context)
    .textTheme
    .bodyLarge
    ?.copyWith(
color: hasValue
? null
    : Theme.of(context).hintColor,
),
),
),
);
}
}