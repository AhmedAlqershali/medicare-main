import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/medicare_widgets.dart';
import '../../appointments/domain/entities/appointment_entity.dart';

class PatientAppointmentCard extends StatelessWidget {
  const PatientAppointmentCard({super.key, required this.appointment, required this.onView});
  final AppointmentEntity appointment;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) => AppCard(
        padding: EdgeInsets.zero,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
            decoration: const BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(appointment.date, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
              StatusBadge(label: appointment.status == AppointmentEntityStatus.cancelled ? 'ملغي' : appointment.status == AppointmentEntityStatus.completed ? 'مكتمل' : 'قادم', color: Colors.white),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                AppAvatar(initials: appointment.doctorInitials, size: 54, backgroundColor: Color(appointment.avatarColorValue)),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(appointment.doctorName, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(appointment.specialty, style: Theme.of(context).textTheme.bodyMedium),
                ])),
              ]),
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 11),
                decoration: BoxDecoration(color: AppColors.canvas, borderRadius: BorderRadius.circular(12)),
                child: Row(children: [
                  const Icon(Icons.schedule_outlined, color: AppColors.primary, size: 18),
                  const SizedBox(width: 7),
                  Text(appointment.time, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.ink, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  const Icon(Icons.location_on_outlined, color: AppColors.primary, size: 18),
                  const SizedBox(width: 5),
                  Flexible(child: Text(appointment.clinicName, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12))),
                ]),
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(width: double.infinity, child: PrimaryButton(label: 'عرض الموعد', onPressed: onView)),
            ]),
          ),
        ]),
      );
}
