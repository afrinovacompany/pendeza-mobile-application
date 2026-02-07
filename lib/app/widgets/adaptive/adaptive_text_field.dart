import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

import 'package:pendeza/app/config/platform_config.dart';
import 'package:pendeza/app/config/theme/app_colors.dart';
import 'package:pendeza/app/config/theme/adaptive_theme.dart';

/// A platform-adaptive text field.
/// Uses TextField with InputDecoration on Android and CupertinoTextField on iOS.
class AdaptiveTextField extends StatelessWidget {
  const AdaptiveTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.labelText,
    this.hintText,
    this.helperText,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.prefix,
    this.suffix,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.validator,
    this.autovalidateMode,
    this.fillColor,
    this.borderColor,
    this.focusedBorderColor,
    this.borderRadius,
    this.contentPadding,
    this.style,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? labelText;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final Widget? prefix;
  final Widget? suffix;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final bool autofocus;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final FormFieldValidator<String>? validator;
  final AutovalidateMode? autovalidateMode;
  final Color? fillColor;
  final Color? borderColor;
  final Color? focusedBorderColor;
  final BorderRadius? borderRadius;
  final EdgeInsets? contentPadding;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveFillColor = fillColor ??
        (isDark ? AppColors.darkSurface : AppColors.surface);
    final effectiveBorderColor = borderColor ??
        (isDark ? AppColors.darkBorder : AppColors.border);
    final effectiveFocusedColor = focusedBorderColor ??
        (isDark ? AppColors.primaryLight : AppColors.primary);
    final effectiveRadius = borderRadius ?? AdaptiveTheme.adaptiveInputRadius;
    final effectivePadding = contentPadding ?? AdaptiveTheme.adaptiveCardPadding;

    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final hintColor = isDark ? AppColors.darkTextTertiary : AppColors.textLight;
    final labelColor = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;

    final effectiveStyle = style ?? TextStyle(
      color: textColor,
      fontSize: 16,
      fontFamily: 'Poppins',
    );

    // Build prefix widget
    Widget? effectivePrefix = prefix;
    if (prefixIcon != null && effectivePrefix == null) {
      effectivePrefix = Padding(
        padding: const EdgeInsets.only(left: 12, right: 8),
        child: Icon(
          prefixIcon,
          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          size: AdaptiveTheme.adaptiveIconSize,
        ),
      );
    }

    // Build suffix widget
    Widget? effectiveSuffix = suffix;
    if (suffixIcon != null && effectiveSuffix == null) {
      effectiveSuffix = Padding(
        padding: const EdgeInsets.only(right: 12, left: 8),
        child: Icon(
          suffixIcon,
          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          size: AdaptiveTheme.adaptiveIconSize,
        ),
      );
    }

    return PlatformTextFormField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscureText,
      enabled: enabled,
      readOnly: readOnly,
      autofocus: autofocus,
      maxLines: maxLines,
      minLines: minLines,
      maxLength: maxLength,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      textCapitalization: textCapitalization,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      onTap: onTap,
      validator: validator,
      autovalidateMode: autovalidateMode,
      style: effectiveStyle,
      material: (_, _) => MaterialTextFormFieldData(
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          helperText: helperText,
          errorText: errorText,
          prefixIcon: prefixIcon != null
              ? Icon(prefixIcon, color: labelColor)
              : null,
          prefix: prefixIcon == null ? prefix : null,
          suffixIcon: suffixIcon != null
              ? Icon(suffixIcon, color: labelColor)
              : null,
          suffix: suffixIcon == null ? suffix : null,
          filled: true,
          fillColor: effectiveFillColor,
          labelStyle: TextStyle(color: labelColor, fontFamily: 'Poppins'),
          hintStyle: TextStyle(color: hintColor, fontFamily: 'Poppins'),
          helperStyle: TextStyle(color: labelColor, fontSize: 12, fontFamily: 'Poppins'),
          errorStyle: const TextStyle(color: AppColors.error, fontSize: 12, fontFamily: 'Poppins'),
          contentPadding: effectivePadding,
          border: OutlineInputBorder(
            borderRadius: effectiveRadius,
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: effectiveRadius,
            borderSide: BorderSide(color: effectiveBorderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: effectiveRadius,
            borderSide: BorderSide(color: effectiveFocusedColor, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: effectiveRadius,
            borderSide: const BorderSide(color: AppColors.error, width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: effectiveRadius,
            borderSide: const BorderSide(color: AppColors.error, width: 2),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: effectiveRadius,
            borderSide: BorderSide(color: effectiveBorderColor.withAlpha(128)),
          ),
        ),
      ),
      cupertino: (_, _) => CupertinoTextFormFieldData(
        placeholder: hintText ?? labelText,
        prefix: effectivePrefix,
        padding: effectivePadding,
        placeholderStyle: TextStyle(color: hintColor, fontFamily: 'Poppins'),
        decoration: BoxDecoration(
          color: effectiveFillColor,
          borderRadius: effectiveRadius,
          border: Border.all(
            color: errorText != null ? AppColors.error : effectiveBorderColor,
            width: errorText != null ? 1.5 : 1,
          ),
        ),
      ),
    );
  }
}

/// A platform-adaptive search field with search icon and clear button.
class AdaptiveSearchField extends StatefulWidget {
  const AdaptiveSearchField({
    super.key,
    this.controller,
    this.focusNode,
    this.hintText = 'Search...',
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.autofocus = false,
    this.enabled = true,
    this.backgroundColor,
    this.borderRadius,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final bool autofocus;
  final bool enabled;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;

  @override
  State<AdaptiveSearchField> createState() => _AdaptiveSearchFieldState();
}

class _AdaptiveSearchFieldState extends State<AdaptiveSearchField> {
  late TextEditingController _controller;
  bool _showClear = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(_updateClearVisibility);
    _showClear = _controller.text.isNotEmpty;
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    } else {
      _controller.removeListener(_updateClearVisibility);
    }
    super.dispose();
  }

  void _updateClearVisibility() {
    final shouldShow = _controller.text.isNotEmpty;
    if (shouldShow != _showClear) {
      setState(() => _showClear = shouldShow);
    }
  }

  void _handleClear() {
    _controller.clear();
    widget.onClear?.call();
    widget.onChanged?.call('');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = widget.backgroundColor ??
        (isDark ? AppColors.darkSurface : AppColors.surface);
    final iconColor = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final effectiveRadius = widget.borderRadius ?? BorderRadius.circular(12);

    if (PlatformConfig.useCupertino) {
      return CupertinoSearchTextField(
        controller: _controller,
        focusNode: widget.focusNode,
        placeholder: widget.hintText,
        onChanged: widget.onChanged,
        onSubmitted: widget.onSubmitted,
        autofocus: widget.autofocus,
        enabled: widget.enabled,
        backgroundColor: bgColor,
        borderRadius: effectiveRadius,
        prefixIcon: Icon(
          CupertinoIcons.search,
          color: iconColor,
        ),
        style: TextStyle(
          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          fontFamily: 'Poppins',
        ),
        placeholderStyle: TextStyle(
          color: isDark ? AppColors.darkTextTertiary : AppColors.textLight,
          fontFamily: 'Poppins',
        ),
      );
    }

    return TextField(
      controller: _controller,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      enabled: widget.enabled,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      style: TextStyle(
        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
        fontFamily: 'Poppins',
      ),
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: TextStyle(
          color: isDark ? AppColors.darkTextTertiary : AppColors.textLight,
          fontFamily: 'Poppins',
        ),
        filled: true,
        fillColor: bgColor,
        prefixIcon: Icon(Icons.search, color: iconColor),
        suffixIcon: _showClear
            ? IconButton(
                icon: Icon(Icons.clear, color: iconColor, size: 20),
                onPressed: _handleClear,
              )
            : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: effectiveRadius,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: effectiveRadius,
          borderSide: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.border,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: effectiveRadius,
          borderSide: BorderSide(
            color: isDark ? AppColors.primaryLight : AppColors.primary,
            width: 2,
          ),
        ),
      ),
    );
  }
}

/// A platform-adaptive password field with visibility toggle.
class AdaptivePasswordField extends StatefulWidget {
  const AdaptivePasswordField({
    super.key,
    this.controller,
    this.focusNode,
    this.labelText,
    this.hintText = 'Enter password',
    this.errorText,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.autovalidateMode,
    this.textInputAction,
    this.autofocus = false,
    this.enabled = true,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? labelText;
  final String hintText;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FormFieldValidator<String>? validator;
  final AutovalidateMode? autovalidateMode;
  final TextInputAction? textInputAction;
  final bool autofocus;
  final bool enabled;

  @override
  State<AdaptivePasswordField> createState() => _AdaptivePasswordFieldState();
}

class _AdaptivePasswordFieldState extends State<AdaptivePasswordField> {
  bool _obscureText = true;

  void _toggleVisibility() {
    setState(() => _obscureText = !_obscureText);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;

    return AdaptiveTextField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      labelText: widget.labelText,
      hintText: widget.hintText,
      errorText: widget.errorText,
      obscureText: _obscureText,
      enabled: widget.enabled,
      autofocus: widget.autofocus,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      validator: widget.validator,
      autovalidateMode: widget.autovalidateMode,
      textInputAction: widget.textInputAction,
      keyboardType: TextInputType.visiblePassword,
      prefixIcon: PlatformConfig.useCupertino
          ? CupertinoIcons.lock
          : Icons.lock_outline,
      suffix: GestureDetector(
        onTap: _toggleVisibility,
        child: Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Icon(
            _obscureText
                ? (PlatformConfig.useCupertino
                    ? CupertinoIcons.eye
                    : Icons.visibility_outlined)
                : (PlatformConfig.useCupertino
                    ? CupertinoIcons.eye_slash
                    : Icons.visibility_off_outlined),
            color: iconColor,
            size: AdaptiveTheme.adaptiveIconSize,
          ),
        ),
      ),
    );
  }
}

/// A platform-adaptive multiline text area.
class AdaptiveTextArea extends StatelessWidget {
  const AdaptiveTextArea({
    super.key,
    this.controller,
    this.focusNode,
    this.labelText,
    this.hintText,
    this.errorText,
    this.maxLines = 5,
    this.minLines = 3,
    this.maxLength,
    this.onChanged,
    this.validator,
    this.autovalidateMode,
    this.enabled = true,
    this.showCounter = true,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? labelText;
  final String? hintText;
  final String? errorText;
  final int maxLines;
  final int minLines;
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final AutovalidateMode? autovalidateMode;
  final bool enabled;
  final bool showCounter;

  @override
  Widget build(BuildContext context) {
    return AdaptiveTextField(
      controller: controller,
      focusNode: focusNode,
      labelText: labelText,
      hintText: hintText,
      errorText: errorText,
      maxLines: maxLines,
      minLines: minLines,
      maxLength: showCounter ? maxLength : null,
      onChanged: onChanged,
      validator: validator,
      autovalidateMode: autovalidateMode,
      enabled: enabled,
      keyboardType: TextInputType.multiline,
      textInputAction: TextInputAction.newline,
    );
  }
}
