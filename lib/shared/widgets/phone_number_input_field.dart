import 'package:country_code_picker/country_code_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A custom widget for phone number input with country code picker.
class PhoneNumberInputField extends StatelessWidget {
  /// The controller for the phone number text field.
  final TextEditingController controller;

  /// The callback that is called when the country code changes.
  final ValueChanged<CountryCode> onCountryChanged;

  /// Whether the field is enabled or disabled
  final bool enabled;

  /// Optional label text
  final String? labelText;

  /// Optional hint text
  final String? hintText;

  /// The initial country code to display (e.g., '+255' or 'TZ')
  final String? initialCountryCode;

  const PhoneNumberInputField({
    super.key,
    required this.controller,
    required this.onCountryChanged,
    this.enabled = true,
    this.labelText,
    this.hintText,
    this.initialCountryCode, // FIX: Added this parameter
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final inputDecoration = theme.inputDecorationTheme;

    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.phone,
      enabled: enabled,
      style: theme.textTheme.bodyMedium,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly, // Only digits
        LengthLimitingTextInputFormatter(9), // Max 9 digits for TZ
      ],
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'common.phone_required'.tr();
        }

        if (value.length != 9) {
          return 'common.phone_error_length'.tr();
        }

        if (!value.startsWith('6') && !value.startsWith('7')) {
          return 'common.phone_error_prefix'.tr();
        }

        return null;
      },
      decoration: InputDecoration(
        labelText: labelText ?? 'onboarding.client.phone_label'.tr(),
        hintText: hintText ?? '712345678',
        prefixIcon: CountryCodePicker(
          onChanged: enabled ? onCountryChanged : null,
          // FIX: Use the provided initialCountryCode or default to 'TZ'
          initialSelection: initialCountryCode ?? 'TZ',
          favorite: const ['+255', 'TZ'],
          enabled: enabled,
          textStyle: theme.textTheme.bodyMedium?.copyWith(
            color: enabled
                ? theme.colorScheme.onSurface
                : theme.colorScheme.onSurface.withValues(alpha: 0.38),
          ),
          dialogTextStyle: theme.textTheme.bodyMedium,
          searchStyle: theme.textTheme.bodyMedium,
          dialogBackgroundColor: theme.colorScheme.surface,
          showCountryOnly: false,
          showOnlyCountryWhenClosed: false,
          alignLeft: false,
        ),
        filled: inputDecoration.filled,
        fillColor: inputDecoration.fillColor,
        contentPadding: inputDecoration.contentPadding,
        border: inputDecoration.border,
        enabledBorder: inputDecoration.enabledBorder,
        focusedBorder: inputDecoration.focusedBorder,
        errorBorder: inputDecoration.errorBorder,
        disabledBorder: inputDecoration.disabledBorder,
      ),
    );
  }
}