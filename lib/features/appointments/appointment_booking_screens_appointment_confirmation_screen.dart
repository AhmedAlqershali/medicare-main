part of 'appointment_booking_screens.dart';

class AppointmentConfirmationScreen extends StatelessWidget {
  const AppointmentConfirmationScreen({super.key, required this.data, required this.date, required this.time});

  final AppointmentBookingData data;
  final AppointmentDate date;
  final String time;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('تأكيد الموعد'), leading: const BackButton()),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.xl),
            child: Column(children: [
              Container(width: 88, height: 88, decoration: BoxDecoration(color: AppColors.mint, borderRadius: BorderRadius.circular(28)), child: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 54)),
              const SizedBox(height: AppSpacing.lg),
              Text('تم تأكيد الموعد', style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.xs),
              Text('تم حفظ موعدك في حسابك.', style: Theme.of(context).textTheme.bodyLarge, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.xl),
              AppCard(child: Column(children: [
                _ConfirmationRow(icon: Icons.person_outline, title: 'الطبيب', value: data.doctorName),
                const Divider(height: AppSpacing.lg),
                _ConfirmationRow(icon: Icons.local_hospital_outlined, title: 'العيادة', value: data.clinicName),
                const Divider(height: AppSpacing.lg),
                _ConfirmationRow(icon: Icons.calendar_month_outlined, title: 'التاريخ', value: '${date.day} ${date.number} ${date.month}'),
                const Divider(height: AppSpacing.lg),
                _ConfirmationRow(icon: Icons.schedule_outlined, title: 'الوقت', value: time),
              ])),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  label: 'عرض مواعيدي',
                  icon: Icons.calendar_month_outlined,
                  onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute<void>(builder: (_) => const AppointmentsScreen()),
                    (route) => route.isFirst,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(width: double.infinity, child: OutlinedButton(onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst), child: const Text('العودة للرئيسية'))),
            ]),
          ),
        ),
      );
}
