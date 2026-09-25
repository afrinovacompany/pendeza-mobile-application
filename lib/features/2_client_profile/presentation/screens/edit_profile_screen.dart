import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pendeza/app/config/theme/app_colors.dart';
import 'package:pendeza/app/config/theme/app_text_styles.dart';
import 'package:pendeza/features/0_auth/data/models/user_model.dart';
import 'package:pendeza/features/0_auth/presentation/bloc/auth_bloc.dart';
import 'package:pendeza/features/0_auth/presentation/bloc/auth_state.dart';
import 'package:pendeza/features/2_client_profile/presentation/bloc/profile_bloc.dart';
import 'package:pendeza/features/2_client_profile/presentation/bloc/profile_event.dart';
import 'package:pendeza/shared/widgets/client_ui.dart';
import 'package:pendeza/shared/widgets/profile_avatar.dart';
import 'package:pendeza/shared/widgets/text_form_field.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  Gender? _selectedGender;

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      _nameController = TextEditingController(text: authState.user.fullName);
      _phoneController = TextEditingController(text: authState.user.phoneNumber);
      _selectedGender = authState.user.gender;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _saveProfile(String userId) {
    if (_formKey.currentState!.validate()) {
      context.read<ProfileBloc>().add(UpdateProfileInfo(
        userId: userId,
        data: {
          'fullName': _nameController.text.trim(),
          'phoneNumber': _phoneController.text.trim(),
          'gender': _selectedGender?.value,
        },
      ));
      Navigator.pop(context); // Go back after dispatching
    }
  }

  String _genderLabel(Gender gender) {
    switch (gender) {
      case Gender.male:
        return 'onboarding.client.gender_male'.tr();
      case Gender.female:
        return 'onboarding.client.gender_female'.tr();
      case Gender.other:
        return 'onboarding.client.gender_other'.tr();
      case Gender.preferNotToSay:
        return 'onboarding.client.gender_prefer_not_say'.tr();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    if (authState is! Authenticated) return const SizedBox.shrink();

    final user = authState.user;

    return Scaffold(
      backgroundColor: ClientTheme.background(context),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            ClientPageHeader(title: 'client.edit_profile.title'.tr()),
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(
                  ClientTheme.gutter,
                  22,
                  ClientTheme.gutter,
                  24 + MediaQuery.paddingOf(context).bottom,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _AvatarBlock(user: user),
                      const SizedBox(height: 24),
                      ClientCard(
                        radius: 24,
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          children: [
                            CustomTextFormField(
                              controller: _nameController,
                              labelText: 'client.edit_profile.full_name'.tr(),
                              hintText: 'client.edit_profile.name_hint'.tr(),
                              prefixIcon: CupertinoIcons.person,
                              validator: (val) => val!.isEmpty
                                  ? 'client.edit_profile.name_required'.tr()
                                  : null,
                            ),
                            const SizedBox(height: 18),
                            CustomTextFormField(
                              controller: _phoneController,
                              labelText: 'client.edit_profile.phone'.tr(),
                              hintText: 'client.edit_profile.phone_hint'.tr(),
                              prefixIcon: CupertinoIcons.phone,
                              keyboardType: TextInputType.phone,
                              validator: (val) => val!.isEmpty
                                  ? 'client.edit_profile.phone_required'.tr()
                                  : null,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        'client.edit_profile.gender'.tr().toUpperCase(),
                        style: ClientTheme.label(context),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          for (final gender in Gender.values)
                            _GenderPill(
                              label: _genderLabel(gender),
                              selected: _selectedGender == gender,
                              onTap: () =>
                                  setState(() => _selectedGender = gender),
                            ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      ClientPrimaryButton(
                        onPressed: () => _saveProfile(user.uid),
                        text: 'client.edit_profile.save'.tr(),
                        icon: CupertinoIcons.checkmark_alt,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarBlock extends StatelessWidget {
  final UserModel user;

  const _AvatarBlock({required this.user});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.primaryGradient,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: -4,
              ),
            ],
          ),
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ClientTheme.background(context),
            ),
            child: ProfileAvatar(
              imageUrl: user.profilePictureUrl,
              fullName: user.fullName,
              radius: 46,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          user.fullName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: ClientTheme.title(context),
        ),
        const SizedBox(height: 2),
        Text(user.email, style: ClientTheme.caption(context)),
      ],
    );
  }
}

class _GenderPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _GenderPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          gradient: selected ? AppColors.primaryGradient : null,
          color: selected ? null : ClientTheme.card(context),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: selected ? Colors.transparent : ClientTheme.border(context),
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(100),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (selected) ...[
                    const Icon(
                      CupertinoIcons.checkmark_alt,
                      size: 15,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 13.5,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                      color: selected
                          ? Colors.white
                          : ClientTheme.textPrimary(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
