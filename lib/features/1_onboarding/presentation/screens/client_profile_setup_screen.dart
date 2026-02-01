import 'package:easy_localization/easy_localization.dart';
import 'dart:async'; // Required for Timer (Kept, but no longer used for username debounce)
import 'dart:io';    // Required for File
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:permission_handler/permission_handler.dart' show openAppSettings;

// Assume these imports exist based on your project structure
import '../../../../app/config/theme/app_constants.dart';
// import '../../../../app/services/service_locator.dart'; // No longer needed since AuthRepository.isUsernameTaken is removed
import '../../../../app/utils/logger.dart';
import '../../../../app/utils/permission_handler.dart';
import '../../../../shared/widgets/primary_gradient_button.dart';
import '../../../../shared/widgets/text_form_field.dart';
import '../../../../shared/widgets/phone_number_input_field.dart';

import '../../../0_auth/data/models/user_model.dart';
// import '../../../0_auth/domain/repositories/auth_repository.dart'; // No longer needed
import '../../../0_auth/presentation/bloc/auth_bloc.dart';
import '../../../0_auth/presentation/bloc/auth_event.dart';
import '../../../0_auth/presentation/bloc/auth_state.dart';

/// 🔥 CLIENT PROFILE SETUP SCREEN (WITHOUT USERNAME)
///
/// Collects mandatory fields:
/// - Full Name
/// - Phone Number (TZ default)
/// - Gender
/// - Profile Picture (optional)
class ClientProfileSetupScreen extends StatefulWidget {
  const ClientProfileSetupScreen({super.key});

  @override
  State<ClientProfileSetupScreen> createState() => _ClientProfileSetupScreenState();
}

class _ClientProfileSetupScreenState extends State<ClientProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameController = TextEditingController();
  // Removed: final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();

  // Image State
  final ImagePicker _picker = ImagePicker();
  XFile? _pickedImage;
  bool _isUploading = false;

  // Form State
  Gender? _selectedGender;
  String _countryCode = '+255'; // Tanzania default

  // Removed: Username Validation State
  // Removed: bool _isCheckingUsername = false;
  // Removed: bool? _isUsernameAvailable;
  // Removed: Timer? _usernameDebounce;

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    if (authState is ClientProfileSetupRequired) {
      final user = authState.user;

      // Pre-fill name from Google or existing data
      if (user.fullName.isNotEmpty && user.fullName != 'New User') {
        _nameController.text = user.fullName;
      }

      // Pre-fill phone if exists
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

      // Pre-fill gender if exists
      if (user.gender != null) {
        _selectedGender = user.gender;
      }

      // Removed: Username suggestion logic
    }

    // Removed: Username listener setup
  }

  // Removed: _suggestUsername function

  @override
  void dispose() {
    _nameController.dispose();
    // Removed: _usernameController.dispose();
    _phoneController.dispose();
    // Removed: _usernameDebounce?.cancel();
    super.dispose();
  }

  // Removed: USERNAME AVAILABILITY CHECKING region and functions

  // ============================================================================
  // IMAGE PICKER
  // ============================================================================

  Future<void> _pickImage(ImageSource source) async {
    bool hasPermission = false;
    if (source == ImageSource.camera) {
      hasPermission = await PermissionService.requestCameraPermission();
    } else {
      hasPermission = await PermissionService.requestPhotosPermission();
    }

    if (!hasPermission && mounted) {
      PermissionService.showPermissionDialog(
        context,
        // Key: "common.permission_camera" / "common.permission_photos"
        title: source == ImageSource.camera ? 'common.permission_camera'.tr() : 'common.permission_photos'.tr(),
        // Key: "common.permission_message"
        content: 'common.permission_message'.tr(),
        onConfirm: () => openAppSettings(),
      );
      return;
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error picking image. Please try again.')), // Not in JSON, keeping hardcode or can add 'common.error'
        );
      }
    }
  }

  void _showImageSourceActionSheet() {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        // Key: "common.choose_photo_title"
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
          // Key: "common.cancel"
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

      UploadTask uploadTask = ref.putFile(file);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      setState(() => _isUploading = false);
      return downloadUrl;
    } catch (e, s) {
      log.e('Error uploading profile picture', error: e, stackTrace: s);
      setState(() => _isUploading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error uploading image. Please try again.')),
        );
      }
      return null;
    }
  }

  // ============================================================================
  // FORM SUBMISSION
  // ============================================================================

  Future<void> _finishSetup() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your gender')), // Hardcoded error message
      );
      return;
    }

    // Removed: Username availability check logic

    final authState = context.read<AuthBloc>().state;
    if (authState is! ClientProfileSetupRequired) return;

    // Upload profile picture if selected
    String? imageUrl;
    if (_pickedImage != null) {
      imageUrl = await _uploadProfilePicture(authState.user.uid);
    }

    // Prepare phone number
    final fullPhoneNumber = '$_countryCode${_phoneController.text.trim()}';

    // Dispatch completion event
    // NOTE: Assuming CompleteClientProfile is updated to accept null/omit username,
    // or the system handles its absence. We pass null for the username field here.
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

  // ============================================================================
  // UI BUILD
  // ============================================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final isLoading = state is AuthLoading || _isUploading;

        UserModel? currentUser;
        String? existingImageUrl;
        if (state is ClientProfileSetupRequired) {
          currentUser = state.user;
          existingImageUrl = currentUser.profilePictureUrl;
        }

        return Scaffold(
          appBar: AppBar(
            // Key: "onboarding.client.title"
            title: Text('onboarding.client.title'.tr()),
            backgroundColor: Colors.transparent,
            elevation: 0,
            automaticallyImplyLeading: false,
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.padL),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppConstants.padM),

                    // Key: "common.step"
                    Text(
                      'common.step'.tr(args: ['1', '1']),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppConstants.padS),

                    // Key: "onboarding.client.headline"
                    Text(
                      'onboarding.client.headline'.tr(),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppConstants.padXL),

                    // ========== PROFILE PICTURE (Optional) ==========
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
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
                                radius: 20,
                                backgroundColor: theme.colorScheme.primary,
                                child: _isUploading
                                    ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                                    : const Icon(
                                  CupertinoIcons.camera_fill,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: AppConstants.padS),
                    // Key: "common.optional"
                    Text(
                      'common.optional'.tr(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppConstants.padXL),

                    // ========== FULL NAME ==========
                    CustomTextFormField(
                      controller: _nameController,
                      // Key: "onboarding.client.name_label"
                      labelText: 'onboarding.client.name_label'.tr(),
                      // Key: "onboarding.client.name_hint"
                      hintText: 'onboarding.client.name_hint'.tr(),
                      prefixIcon: Icons.person_outline,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          // Key: "onboarding.client.name_error_empty"
                          return 'onboarding.client.name_error_empty'.tr();
                        }
                        if (value.trim().length < 2) {
                          // Key: "onboarding.client.name_error_short"
                          return 'onboarding.client.name_error_short'.tr();
                        }
                        return null;
                      },
                      enabled: !isLoading,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: AppConstants.padL),

                    // Removed: USERNAME field

                    // ========== PHONE NUMBER ==========
                    PhoneNumberInputField(
                      controller: _phoneController,
                      enabled: !isLoading,
                      onCountryChanged: (country) {
                        setState(() {
                          _countryCode = country.dialCode ?? '+255';
                        });
                      },
                    ),
                    const SizedBox(height: AppConstants.padL),

                    // ========== GENDER SELECTION ==========
                    // Key: "onboarding.client.gender_label"
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
                        _buildGenderChip(Gender.male, 'onboarding.client.gender_male'.tr(), Icons.male, theme, isLoading),
                        _buildGenderChip(Gender.female, 'onboarding.client.gender_female'.tr(), Icons.female, theme, isLoading),
                        _buildGenderChip(Gender.other, 'onboarding.client.gender_other'.tr(), Icons.transgender, theme, isLoading),
                        _buildGenderChip(Gender.preferNotToSay, 'onboarding.client.gender_prefer_not_say'.tr(), Icons.do_not_disturb_alt, theme, isLoading),
                      ],
                    ),
                    const SizedBox(height: AppConstants.padXXL),

                    // ========== SUBMIT BUTTON ==========
                    PrimaryGradientButton(
                      // Key: "onboarding.client.button"
                      text: 'onboarding.client.button'.tr(),
                      onPressed: isLoading ? null : _finishSetup,
                      isLoading: isLoading,
                    ),
                    const SizedBox(height: AppConstants.padL),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGenderChip(Gender gender, String label, IconData icon, ThemeData theme, bool isLoading) {
    final isSelected = _selectedGender == gender;
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: isSelected ? Colors.white : theme.colorScheme.primary),
          const SizedBox(width: AppConstants.padXS),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: isLoading ? null : (selected) {
        setState(() {
          _selectedGender = selected ? gender : null;
        });
      },
      selectedColor: theme.colorScheme.primary,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : theme.colorScheme.onSurface,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      backgroundColor: theme.colorScheme.surface,
      side: BorderSide(
        color: isSelected ? theme.colorScheme.primary : theme.dividerColor,
        width: isSelected ? 2 : 1,
      ),
    );
  }
}