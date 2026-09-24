part of 'patient_home_screen.dart';

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuthRepository.instance.session.currentUser;
    final name = user?.name ?? 'المستخدم';
    final parts = name.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
    final initials = parts.isEmpty ? 'م' : parts.length == 1 ? parts.first.substring(0, 1) : '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}';
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        AppAvatar(initials: initials, size: 50),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('مرحباً، $name', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 3),
          Text('نتمنى لك يوماً صحياً ومليئاً بالعافية', style: Theme.of(context).textTheme.bodyMedium),
        ])),
        IconButton(
          onPressed: _noop,
          icon: const Icon(Icons.notifications_none_rounded, size: 23),
          color: AppColors.ink,
          tooltip: 'الإشعارات',
          visualDensity: VisualDensity.compact,
        ),
        ]);
      }

  static void _noop() {}
}
