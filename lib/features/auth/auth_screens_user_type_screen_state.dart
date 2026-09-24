part of 'auth_screens.dart';

class _UserTypeScreenState extends State<UserTypeScreen> {
  AccountRole _selectedRole = AccountRole.patient;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          leading: const BackButton(),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xl),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('اختر نوع الحساب', style: Theme.of(context).textTheme.headlineSmall),
              const Text('مرحبا سعيد'),
              const SizedBox(height: AppSpacing.xs),
              Text('لنقدم لك تجربة مناسبة لاحتياجاتك', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: AppSpacing.xl),
              _AccountTypeCard(
                title: 'مريض',
                description: 'احجز مواعيدك وتابع رعايتك الصحية',
                icon: Icons.person_outline_rounded,
                color: AppColors.mint,
                selected: _selectedRole == AccountRole.patient,
                onTap: () => setState(() => _selectedRole = AccountRole.patient),
              ),
              const SizedBox(height: AppSpacing.md),
              _AccountTypeCard(
                title: 'طبيب',
                description: 'أدر مواعيدك وتواصل مع مرضاك',
                icon: Icons.medical_information_outlined,
                color: AppColors.sky,
                selected: _selectedRole == AccountRole.doctor,
                onTap: () => setState(() => _selectedRole = AccountRole.doctor),
              ),
              const SizedBox(height: AppSpacing.md),
              _AccountTypeCard(
                title: 'مؤسسة طبية',
                description: 'أدر عياداتك وأطباءك وخدماتك الطبية',
                icon: Icons.business_outlined,
                color: AppColors.peach,
                selected: _selectedRole == AccountRole.organization,
                onTap: () => setState(() => _selectedRole = AccountRole.organization),
              ),
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(label: 'متابعة', onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute<void>(builder: (_) => RoleLoginScreen(role: _selectedRole)))),
            ]),
          ),
        ),
      );
}
