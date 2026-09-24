import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.error_outline, color: Color(0xFFC84C4C), size: 40),
        const SizedBox(height: AppSpacing.md),
        Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
        if (onRetry != null) TextButton(onPressed: onRetry, child: const Text('حاول مرة أخرى')),
      ]);
}
