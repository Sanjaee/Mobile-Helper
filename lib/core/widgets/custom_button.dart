import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isPrimary;
  final double? width;
  final double height;
  final EdgeInsetsGeometry? padding;
  
  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isPrimary = true,
    this.width,
    this.height = 50,
    this.padding,
  });
  
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? AppColors.buttonPrimary : AppColors.buttonSecondary,
          foregroundColor: isPrimary ? AppColors.textOnPrimary : AppColors.textPrimary,
          side: BorderSide(
            color: isPrimary ? AppColors.buttonPrimary : AppColors.border,
            width: 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.textOnPrimary),
                ),
              )
            : Text(
                text,
                style: isPrimary ? AppTextStyles.buttonPrimary : AppTextStyles.buttonSecondary,
              ),
      ),
    );
  }
}

class CustomTextButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? textColor;
  
  const CustomTextButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.textColor,
  });
  
  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            )
          : Text(
              text,
              style: AppTextStyles.link.copyWith(
                color: textColor ?? AppColors.primary,
              ),
            ),
    );
  }
}
