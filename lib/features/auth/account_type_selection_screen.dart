import 'package:flutter/material.dart';

import '../../core/auth/models/account_role.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/medicare_widgets.dart';

class AccountTypeSelectionScreen extends StatelessWidget {
  const AccountTypeSelectionScreen({super.key, required this.onSelected});

  final ValueChanged<AccountRole> onSelected;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(leading: const BackButton()),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xl),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('اختر نوع الحساب', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.xs),
              Text('سجّل الدخول بالدور المرتبط بحسابك', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: AppSpacing.xl),
              _roleCard(context, role: AccountRole.patient, title: 'مريض', description: 'احجز مواعيدك وتابع رعايتك الصحية', icon: Icons.person_outline_rounded, color: AppColors.mint),
              const SizedBox(height: AppSpacing.md),
              _roleCard(context, role: AccountRole.doctor, title: 'طبيب', description: 'أدر مواعيدك وتابع مرضاك', icon: Icons.medical_information_outlined, color: AppColors.sky),
              const SizedBox(height: AppSpacing.md),
              _roleCard(context, role: AccountRole.organization, title: 'مؤسسة طبية', description: 'أدر عياداتك وأطباءك وخدماتك الطبية', icon: Icons.business_outlined, color: AppColors.peach),
              const SizedBox(height: AppSpacing.xl),
              Text('اختيار الدور يحدد شاشة الدخول. تفعيل الحسابات يتم عبر دعوات المؤسسة أو الطبيب.', style: Theme.of(context).textTheme.bodyMedium),
            ]),
          ),
        ),
      );

  Widget _roleCard(BuildContext context, {required AccountRole role, required String title, required String description, required IconData icon, required Color color}) => AppCard(
        child: InkWell(
          onTap: () => onSelected(role),
          borderRadius: BorderRadius.circular(20),
          child: Row(children: [
            Container(width: 52, height: 52, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(15)), child: Icon(icon, color: AppColors.primaryDark, size: 26)),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: Theme.of(context).textTheme.titleMedium), const SizedBox(height: 3), Text(description, style: Theme.of(context).textTheme.bodyMedium)])),
            const Icon(Icons.chevron_left_rounded, color: AppColors.muted),
          ]),
        ),
      );
}
