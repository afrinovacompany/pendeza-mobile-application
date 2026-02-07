import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pendeza/app/config/theme/app_constants.dart';
import 'package:pendeza/app/helpers/image_compressor_helper.dart';
import 'package:pendeza/features/0_auth/data/models/user_model.dart';
import 'package:pendeza/features/0_auth/presentation/bloc/auth_bloc.dart';
import 'package:pendeza/features/0_auth/presentation/bloc/auth_state.dart';
import 'package:pendeza/features/2_client_profile/presentation/bloc/profile_bloc.dart';
import 'package:pendeza/features/2_client_profile/presentation/bloc/profile_event.dart';
import 'package:pendeza/features/2_client_profile/presentation/bloc/profile_state.dart';
import 'package:pendeza/shared/widgets/primary_gradient_button.dart';
import 'package:pendeza/shared/widgets/profile_avatar.dart';
import 'package:pendeza/shared/widgets/text_form_field.dart';

class EditOwnerProfileScreen extends StatefulWidget {
  const EditOwnerProfileScreen({super.key});

  @override
  State<EditOwnerProfileScreen> createState() => _EditOwnerProfileScreenState();
}

class _EditOwnerProfileScreenState extends State<EditOwnerProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  Gender? _selectedGender;
  File? _selectedImage;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      _nameController = TextEditingController(text: authState.user.fullName);
      _phoneController = TextEditingController(text: authState.user.phoneNumber);
      _selectedGender = authState.user.gender;
    } else {
      _nameController = TextEditingController();
      _phoneController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      final compressed = await ImageCompressionHelper.compressImage(
        File(pickedFile.path),
      );
      setState(() {
        _selectedImage = compressed ?? File(pickedFile.path);
      });
    }
  }

  void _showImageSourcePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'common.choose_photo_title'.tr(),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(CupertinoIcons.camera_fill),
                title: Text('common.camera'.tr()),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(CupertinoIcons.photo_fill),
                title: Text('common.gallery'.tr()),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _saveProfile(String userId) {
    if (_formKey.currentState!.validate()) {
      // First update the profile image if selected
      if (_selectedImage != null) {
        context.read<ProfileBloc>().add(UpdateProfileImage(
          userId: userId,
          imageFile: _selectedImage!,
        ));
      }

      // Then update profile info
      context.read<ProfileBloc>().add(UpdateProfileInfo(
        userId: userId,
        data: {
          'fullName': _nameController.text.trim(),
          'phoneNumber': _phoneController.text.trim(),
          'gender': _selectedGender?.value,
        },
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    if (authState is! Authenticated) return const SizedBox.shrink();

    final user = authState.user;
    final theme = Theme.of(context);

    return BlocListener<ProfileBloc, ProfileState>(
      listener: (context, state) {
        if (state is ProfileImageUploading) {
          setState(() => _isUploading = true);
        } else if (state is ProfileUpdateSuccess) {
          setState(() => _isUploading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context);
        } else if (state is ProfileError) {
          setState(() => _isUploading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('owner.profile.edit_title'.tr()),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.padL),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Profile Image with Edit Button
                Stack(
                  children: [
                    GestureDetector(
                      onTap: _showImageSourcePicker,
                      child: _selectedImage != null
                          ? CircleAvatar(
                              radius: 60,
                              backgroundImage: FileImage(_selectedImage!),
                            )
                          : ProfileAvatar(
                              radius: 60,
                              fullName: user.fullName,
                              imageUrl: user.profilePictureUrl,
                            ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _showImageSourcePicker,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: theme.scaffoldBackgroundColor,
                              width: 3,
                            ),
                          ),
                          child: const Icon(
                            CupertinoIcons.camera_fill,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                    if (_isUploading)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'owner.profile.tap_to_change'.tr(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: AppConstants.padXL),

                // Full Name
                CustomTextFormField(
                  controller: _nameController,
                  labelText: 'onboarding.client.name_label'.tr(),
                  hintText: 'onboarding.client.name_hint'.tr(),
                  prefixIcon: CupertinoIcons.person,
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return 'onboarding.client.name_error_empty'.tr();
                    }
                    if (val.length < 2) {
                      return 'onboarding.client.name_error_short'.tr();
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppConstants.padL),

                // Phone Number
                CustomTextFormField(
                  controller: _phoneController,
                  labelText: 'onboarding.client.phone_label'.tr(),
                  hintText: 'e.g. 712345678',
                  prefixIcon: CupertinoIcons.phone,
                  keyboardType: TextInputType.phone,
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return 'Phone number is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppConstants.padL),

                // Gender Selection
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'onboarding.client.gender_label'.tr(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ),
                const SizedBox(height: AppConstants.padXS),

                Container(
                  padding: const EdgeInsets.all(AppConstants.padS),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(AppConstants.radiusValM),
                    border: Border.all(
                      color: theme.dividerColor.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Column(
                    children: Gender.values.map((g) {
                      String label;
                      switch (g) {
                        case Gender.male:
                          label = 'onboarding.client.gender_male'.tr();
                          break;
                        case Gender.female:
                          label = 'onboarding.client.gender_female'.tr();
                          break;
                        case Gender.other:
                          label = 'onboarding.client.gender_other'.tr();
                          break;
                        case Gender.preferNotToSay:
                          label = 'onboarding.client.gender_prefer_not_say'.tr();
                          break;
                      }
                      return RadioListTile<Gender>(
                        title: Text(label),
                        value: g,
                        groupValue: _selectedGender,
                        activeColor: theme.colorScheme.primary,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (val) => setState(() => _selectedGender = val),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: AppConstants.padXL * 1.5),

                // Save Button
                PrimaryGradientButton(
                  onPressed: _isUploading ? null : () => _saveProfile(user.uid),
                  text: _isUploading
                      ? 'common.loading'.tr()
                      : 'owner.profile.save_changes'.tr(),
                  height: 54,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
