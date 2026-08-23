import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart' show openAppSettings;

import '../../../../app/config/theme/app_constants.dart';
import '../../../../app/utils/logger.dart';
import '../../../../app/utils/permission_handler.dart';
import '../../../../app/widgets/adaptive/adaptive_dialog.dart';
import '../../../../shared/widgets/primary_gradient_button.dart';
import '../../../../shared/widgets/text_form_field.dart';
import '../../../../shared/widgets/phone_number_input_field.dart';

import '../../../0_auth/data/models/user_model.dart';
import '../../../0_auth/presentation/bloc/auth_bloc.dart';
import '../../../0_auth/presentation/bloc/auth_event.dart';
import '../../../0_auth/presentation/bloc/auth_state.dart';
import '../../../0_auth/presentation/widgets/auth_chrome.dart';

/// Collects mandatory client profile fields after role selection.
///
/// Successful completion emits [Authenticated]; GoRouter then sends the
/// user to client home or a pending booking return path.
class ClientProfileSetupScreen extends StatefulWidget {
  const ClientProfileSetupScreen({super.key});

  @override
  State<ClientProfileSetupScreen> createState() =>
      _ClientProfileSetupScreenState();
}

class _ClientProfileSetupScreenState extends State<ClientProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  XFile? _pickedImage;
  bool _isUploading = false;

  Gender? _selectedGender;
  String _countryCode = '+255';

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    if (authState is ClientProfileSetupRequired) {
      final user = authState.user;

      if (user.fullName.isNotEmpty && user.fullName != 'New User') {
        _nameController.text = user.fullName;
      }

      if (user.phoneNumber != null && user.phoneNumber!.isNotEmpty) {
        final phone = user.phoneNumber!;
        if (phone.startsWith('+255')) {
          _phoneController.text = phone.substring(4);
        } else if (phone.startsWith('255')) {
          _phoneController.text = phone.substring(3);
        } else {
          _phoneController.text = phone;
        }
      }

      if (user.gender != null) {
        _selectedGender = user.gender;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _showMessage(String message, {bool isError = true}) {
    if (!mounted) return;
    showAdaptiveSnackBar(
      context: context,
      message: message,
      isError: isError,
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    if (source == ImageSource.camera) {
      final hasPermission = await PermissionService.requestCameraPermission();
      if (!hasPermission && mounted) {
        PermissionService.showPermissionDialog(
          context,
          title: 'common.permission_camera'.tr(),
          content: 'common.permission_message'.tr(),
          onConfirm: () => openAppSettings(),
        );
        return;
      }
    }

    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 800,
      );
      if (image != null) {
        setState(() => _pickedImage = image);
      }
    } catch (e, s) {
      log.e('Error picking image', error: e, stackTrace: s);
      _showMessage('onboarding.client.photo_error'.tr());
    }
  }

  void _showImageSourceActionSheet() {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: Text('common.choose_photo_title'.tr()),
        actions: <CupertinoActionSheetAction>[
          CupertinoActionSheetAction(
            child: Text('common.camera'.tr()),
            onPressed: () {
              Navigator.pop(context);
              _pickImage(ImageSource.camera);
            },
          ),
          CupertinoActionSheetAction(
            child: Text('common.gallery'.tr()),
            onPressed: () {
              Navigator.pop(context);
              _pickImage(ImageSource.gallery);
            },
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDestructiveAction: true,
          onPressed: () => Navigator.pop(context),
          child: Text('common.cancel'.tr()),
        ),
      ),
    );
  }

  Future<String?> _uploadProfilePicture(String userId) async {
    if (_pickedImage == null) return null;

    setState(() => _isUploading = true);
    try {
      final file = File(_pickedImage!.path);
      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_pictures')
          .child('$userId.jpg');

      final snapshot = await ref.putFile(file);
      final downloadUrl = await snapshot.ref.getDownloadURL();

      if (mounted) setState(() => _isUploading = false);
      return downloadUrl;
    } catch (e, s) {
      log.e('Error uploading profile picture', error: e, stackTrace: s);
      if (mounted) setState(() => _isUploading = false);
      _showMessage('onboarding.client.upload_error'.tr());
      return null;
    }
  }

  Future<void> _finishSetup() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_selectedGender == null) {
      _showMessage('onboarding.client.gender_error'.tr());
      return;
    }

    final authState = context.read<AuthBloc>().state;
    if (authState is! ClientProfileSetupRequired) return;

    String? imageUrl;
    if (_pickedImage != null) {
      imageUrl = await _uploadProfilePicture(authState.user.uid);
    }

    if (!mounted) return;

    final fullPhoneNumber = '$_countryCode${_phoneController.text.trim()}';

    context.read<AuthBloc>().add(
      CompleteClientProfile(
        uid: authState.user.uid,
        fullName: _nameController.text.trim(),
        phoneNumber: fullPhoneNumber,
        gender: _selectedGender!,
        profilePictureUrl: imageUrl,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          _showMessage(state.message);
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final isLoading = state is AuthLoading || _isUploading;

          String? existingImageUrl;
          if (state is ClientProfileSetupRequired) {
            existingImageUrl = state.user.profilePictureUrl;
          }

          return AuthScaffold(
            isLoading: isLoading,
            loadingMessage: 'onboarding.client.saving'.tr(),
            body: AuthPageBody(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AuthHeader(
                      title: 'onboarding.client.title'.tr(),
                      subtitle: 'onboarding.client.headline'.tr(),
                      leading: _buildPhotoPicker(
                        theme,
                        existingImageUrl,
                        isLoading,
                      ),
                    ),
                    const SizedBox(height: AuthChrome.headerGap),

                    CustomTextFormField(
                      controller: _nameController,
                      labelText: 'onboarding.client.name_label'.tr(),
                      hintText: 'onboarding.client.name_hint'.tr(),
                      prefixIcon: Icons.person_outline,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'onboarding.client.name_error_empty'.tr();
                        }
                        if (value.trim().length < 2) {
                          return 'onboarding.client.name_error_short'.tr();
                        }
                        return null;
                      },
                      enabled: !isLoading,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: AuthChrome.fieldGap),

                    PhoneNumberInputField(
                      controller: _phoneController,
                      enabled: !isLoading,
                      labelText: 'onboarding.client.phone_label'.tr(),
                      onCountryChanged: (country) {
                        setState(() {
                          _countryCode = country.dialCode ?? '+255';
                        });
                      },
                    ),
                    const SizedBox(height: AuthChrome.fieldGap),

                    Text(
                      'onboarding.client.gender_label'.tr(),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppConstants.padS),
                    Wrap(
                      spacing: AppConstants.padM,
                      runSpacing: AppConstants.padM,
                      children: [
                        _buildGenderChip(
                          Gender.male,
                          'onboarding.client.gender_male'.tr(),
                          Icons.male,
                          theme,
                          isLoading,
                        ),
                        _buildGenderChip(
                          Gender.female,
                          'onboarding.client.gender_female'.tr(),
                          Icons.female,
                          theme,
                          isLoading,
                        ),
                        _buildGenderChip(
                          Gender.other,
                          'onboarding.client.gender_other'.tr(),
                          Icons.transgender,
                          theme,
                          isLoading,
                        ),
                        _buildGenderChip(
                          Gender.preferNotToSay,
                          'onboarding.client.gender_prefer_not_say'.tr(),
                          Icons.do_not_disturb_alt,
                          theme,
                          isLoading,
                        ),
                      ],
                    ),
                    const SizedBox(height: AuthChrome.headerGap),

                    PrimaryGradientButton(
                      text: 'onboarding.client.button'.tr(),
                      onPressed: isLoading ? null : _finishSetup,
                      isLoading: isLoading,
                      height: AuthChrome.ctaHeight,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPhotoPicker(
    ThemeData theme,
    String? existingImageUrl,
    bool isLoading,
  ) {
    return Column(
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 56,
              backgroundColor:
                  theme.colorScheme.primary.withValues(alpha: 0.1),
              backgroundImage: _pickedImage != null
                  ? FileImage(File(_pickedImage!.path)) as ImageProvider
                  : (existingImageUrl != null
                      ? NetworkImage(existingImageUrl) as ImageProvider
                      : null),
              child: _pickedImage == null && existingImageUrl == null
                  ? Icon(
                      Icons.person_outline,
                      size: 48,
                      color: theme.colorScheme.primary,
                    )
                  : null,
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: isLoading ? null : _showImageSourceActionSheet,
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: theme.colorScheme.primary,
                  child: _isUploading
                      ? SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.colorScheme.onPrimary,
                          ),
                        )
                      : Icon(
                          CupertinoIcons.camera_fill,
                          color: theme.colorScheme.onPrimary,
                          size: 18,
                        ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.padS),
        Text(
          'common.optional'.tr(),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(
              alpha: AuthChrome.subtitleOpacity,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderChip(
    Gender gender,
    String label,
    IconData icon,
    ThemeData theme,
    bool isLoading,
  ) {
    final isSelected = _selectedGender == gender;
    final selectedFg = theme.colorScheme.onPrimary;
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 18,
            color: isSelected ? selectedFg : theme.colorScheme.primary,
          ),
          const SizedBox(width: AppConstants.padXS),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: isLoading
          ? null
          : (selected) {
              setState(() {
                _selectedGender = selected ? gender : null;
              });
            },
      selectedColor: theme.colorScheme.primary,
      checkmarkColor: selectedFg,
      labelStyle: TextStyle(
        color: isSelected ? selectedFg : theme.colorScheme.onSurface,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      backgroundColor: theme.colorScheme.surface,
      side: BorderSide(
        color: isSelected
            ? theme.colorScheme.primary
            : theme.colorScheme.outline.withValues(alpha: 0.4),
        width: isSelected ? 2 : 1,
      ),
    );
  }
}
