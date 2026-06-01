import 'package:flutter/material.dart';
import 'package:ieum/core/theme/app_colors.dart';

class CommonButton extends StatelessWidget {
  const CommonButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isOutlined = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool isOutlined;

  @override
  Widget build(BuildContext context) {
    if (isOutlined) {
      return OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 52),
          side: const BorderSide(color: AppColors.primaryBlue),
          foregroundColor: AppColors.primaryBlue,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(label),
      );
    }

    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size(double.infinity, 52),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: AppColors.onPrimaryFill(Theme.of(context).brightness),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(label),
    );
  }
}
