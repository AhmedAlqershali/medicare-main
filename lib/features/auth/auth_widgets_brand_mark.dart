part of 'auth_widgets.dart';

class _BrandMark extends StatelessWidget {
  const _BrandMark({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(size * .28)),
        child: Icon(Icons.add_rounded, color: Colors.white, size: size * .52),
      );
}
