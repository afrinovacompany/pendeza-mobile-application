import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/config/theme/app_constants.dart';
import '../../app/config/theme/app_text_styles.dart';

/// A custom, reusable text form field for the entire application.
///
/// It standardizes the look and feel of all input fields, using the
/// pre-defined InputDecorationTheme from AppTheme. It also provides
/// a consistent way to handle validation and input control.
class CustomTextFormField extends StatelessWidget {
  final TextEditingController? controller;
  final String labelText;
  final String? hintText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool obscureText;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final bool? enabled;
  final int? maxLines;
  // ✅ FIX: Added the onChanged parameter
  final ValueChanged<String>? onChanged;

  const CustomTextFormField({
    super.key,
    this.controller,
    required this.labelText,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.keyboardType,
    this.obscureText = false,
    this.textInputAction,
    this.inputFormatters,
    this.enabled,
    this.maxLines = 1,
    // ✅ FIX: Added onChanged to the constructor
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          labelText,
          style: AppTextStyles.caption.copyWith(
            color: theme.textTheme.bodySmall?.color,
          ),
        ),
        const SizedBox(height: AppConstants.padXS),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: maxLines != null && maxLines! > 1
              ? TextInputType.multiline
              : keyboardType,
          obscureText: obscureText,
          textInputAction: textInputAction,
          inputFormatters: inputFormatters,
          enabled: enabled,
          style: theme.textTheme.bodyMedium,
          maxLines: maxLines,
          // ✅ FIX: Passed onChanged to the underlying TextFormField
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: prefixIcon != null
                ? Icon(
              prefixIcon,
              size: AppConstants.iconSizeM,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            )
                : null,
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }
}
