part of 'custom_text_field.dart';

class _TextField extends StatefulWidget {
  const _TextField({
    required this.label,
    this.hintText,
    this.prefixIcon,
    this.controller,
    this.obscureText = false,
    this.readOnly = false,
    this.keyboardType,
    this.onChanged,
    this.onSubmitted,
    this.errorText,
    this.validator,
    this.textInputAction,
    this.autofillHints,
  });

  final String label;
  final String? hintText;
  final IconData? prefixIcon;
  final TextEditingController? controller;
  final bool obscureText;
  final bool readOnly;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final String? errorText;
  final FormFieldValidator<String>? validator;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;

  @override
  State<_TextField> createState() => _TextFieldState();
}
