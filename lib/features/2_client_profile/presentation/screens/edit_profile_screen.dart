import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pendeza/app/config/theme/app_constants.dart';
import 'package:pendeza/features/0_auth/data/models/user_model.dart';
import 'package:pendeza/features/0_auth/presentation/bloc/auth_bloc.dart';
import 'package:pendeza/features/0_auth/presentation/bloc/auth_state.dart';
import 'package:pendeza/features/2_client_profile/presentation/bloc/profile_bloc.dart';
import 'package:pendeza/features/2_client_profile/presentation/bloc/profile_event.dart';
import 'package:pendeza/shared/widgets/primary_gradient_button.dart';
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

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    if (authState is! Authenticated) return const SizedBox.shrink();

    final user = authState.user;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('client.edit_profile.title'.tr()),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.padL),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomTextFormField(
                controller: _nameController,
                labelText: 'client.edit_profile.full_name'.tr(),
                hintText: 'client.edit_profile.name_hint'.tr(),
                validator: (val) => val!.isEmpty ? 'client.edit_profile.name_required'.tr() : null,
              ),
              const SizedBox(height: AppConstants.padL),
              CustomTextFormField(
                controller: _phoneController,
                labelText: 'client.edit_profile.phone'.tr(),
                hintText: 'client.edit_profile.phone_hint'.tr(),
                keyboardType: TextInputType.phone,
                validator: (val) => val!.isEmpty ? 'client.edit_profile.phone_required'.tr() : null,
              ),
              const SizedBox(height: AppConstants.padL),

              Text(
                'client.edit_profile.gender'.tr(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: AppConstants.padXS),

              // Custom Radio Group for Gender
              Container(
                padding: const EdgeInsets.all(AppConstants.padS),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(AppConstants.radiusValM),
                  border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
                ),
                child: Column(
                  children: Gender.values.map((g) {
                    return RadioListTile<Gender>(
                      title: Text(g.name[0].toUpperCase() + g.name.substring(1)),
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

              PrimaryGradientButton(
                onPressed: () => _saveProfile(user.uid),
                text: 'client.edit_profile.save'.tr(),
                height: 54,
              ),
            ],
          ),
        ),
      ),
    );
  }
}