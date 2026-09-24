part of 'patient_profile_screens.dart';

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) => Container(width: 68, height: 68, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(20)), child: Icon(Icons.favorite_rounded, color: Colors.white, size: 32));
}
