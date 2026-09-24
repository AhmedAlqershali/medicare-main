import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

part 'custom_text_field_text_field.dart';
part 'custom_text_field_text_field_state.dart';

class CustomTextField extends StatelessWidget {
  const CustomTextField({
    super.key,
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
  Widget build(BuildContext context) => _TextField(
        label: label,
        hintText: hintText,
        prefixIcon: prefixIcon,
        controller: controller,
        obscureText: obscureText,
        readOnly: readOnly,
        keyboardType: keyboardType,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        errorText: errorText,
        validator: validator,
        textInputAction: textInputAction,
        autofillHints: autofillHints,
      );
}
