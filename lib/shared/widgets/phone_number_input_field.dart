import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';

// --- Adjust these import paths to match your project structure ---
import '../../app/utils/validators.dart';

/// A custom widget for phone number input, featuring a country code picker.
///
/// It combines a country code selector with a text form field for the number,
/// providing a seamless user experience for international phone number entry.
class PhoneNumberInputField extends StatelessWidget {
  /// The controller for the phone number text field.
  final TextEditingController controller;

  /// The callback that is called when the country code changes.
  final ValueChanged<CountryCode> onCountryChanged;

  const PhoneNumberInputField({
    super.key,
    required this.controller,
    required this.onCountryChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Use the input decoration theme we defined in app_theme.dart
    final inputDecoration = theme.inputDecorationTheme;

    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.phone,
      validator: AppValidators.phone,
      style: theme.textTheme.bodyMedium,
      decoration: InputDecoration(
        hintText: '712 345 678',
        // The prefixIcon is where we place the CountryCodePicker
        prefixIcon: CountryCodePicker(
          onChanged: onCountryChanged,
          // Set the initial selection to Tanzania (TZ)
          initialSelection: 'TZ',
          favorite: const ['+255', 'TZ'], // Make TZ a favorite for easy access
          // Style the picker to match our app's theme
          textStyle: theme.textTheme.bodyMedium,
          dialogTextStyle: theme.textTheme.bodyMedium,
          searchStyle: theme.textTheme.bodyMedium,
          dialogBackgroundColor: theme.colorScheme.surface,
          // Customize the layout
          showCountryOnly: false,
          showOnlyCountryWhenClosed: false,
          alignLeft: false,
        ),
        // Apply the rest of the styling from our global theme
        filled: inputDecoration.filled,
        fillColor: inputDecoration.fillColor,
        contentPadding: inputDecoration.contentPadding,
        border: inputDecoration.border,
        enabledBorder: inputDecoration.enabledBorder,
        focusedBorder: inputDecoration.focusedBorder,
        errorBorder: inputDecoration.errorBorder,
      ),
    );
  }
}
