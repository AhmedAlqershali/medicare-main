part of 'doctors_screens.dart';

class _DoctorsEmptyState extends StatelessWidget {
  const _DoctorsEmptyState();

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: EmptyState(title: 'لم نجد أطباء مطابقين لبحثك', message: 'جرّب تغيير كلمة البحث أو اختيار تخصص مختلف', icon: Icons.person_search_outlined),
        ),
      );
}
