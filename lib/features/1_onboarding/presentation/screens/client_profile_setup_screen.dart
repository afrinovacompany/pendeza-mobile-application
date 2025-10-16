import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// --- Adjust these import paths to match your project structure ---
import '../../../../app/config/theme/app_constants.dart';
import '../../../../shared/widgets/primary_gradient_button.dart';
import '../../../../shared/widgets/profile_avatar.dart';
import '../../../../shared/widgets/text_form_field.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../0_auth/data/models/user_model.dart';
import '../../../0_auth/presentation/bloc/auth_bloc.dart';
import '../../../0_auth/presentation/bloc/auth_event.dart';
import '../../../0_auth/presentation/bloc/auth_state.dart';

class ClientProfileSetupScreen extends StatefulWidget {
  const ClientProfileSetupScreen({super.key});

  @override
  State<ClientProfileSetupScreen> createState() =>
      _ClientProfileSetupScreenState();
}

class _ClientProfileSetupScreenState extends State<ClientProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  // In a real app, this would hold the image file the user picks
  // File? _profileImage;

  @override
  void initState() {
    super.initState();
    // Pre-fill the text field if the user already has a name (e.g., from Google Sign-In)
    final authState = context.read<AuthBloc>().state;
    if (authState is ClientProfileSetupRequired) {
      // Avoid pre-filling with the default "New User" value
      if (authState.user.fullName != 'New User') {
        _nameController.text = authState.user.fullName;
      }
    }
  }


  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _finishSetup() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final authState = context.read<AuthBloc>().state;
    if (authState is ClientProfileSetupRequired) {
      // Dispatch the event to the AuthBloc to save the data
      context.read<AuthBloc>().add(
        CompleteClientProfile(
          uid: authState.user.uid,
          fullName: _nameController.text.trim(),
        ),
      );
    }
  }

  void _pickImage() {
    // TODO: Implement image picking logic (e.g., using image_picker package)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Image picker functionality not yet implemented.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        // Get the current user's data from the state
        UserModel? currentUser;
        if (state is ClientProfileSetupRequired) {
          currentUser = state.user;
        } else if (state is AuthLoading && context.select((AuthBloc bloc) => bloc.state) is ClientProfileSetupRequired) {
          // If loading, try to get user from previous state
          final prevState = context.select((AuthBloc bloc) => bloc.state);
          if(prevState is ClientProfileSetupRequired){
            currentUser = prevState.user;
          }
        }


        return Scaffold(
          appBar: AppBar(
            title: const Text('Complete Your Profile'),
            backgroundColor: Colors.transparent,
            elevation: 0,
            automaticallyImplyLeading: false, // Prevents a back button
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.padL),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppConstants.padL),
                    Center(
                      child: Stack(
                        children: [
                          ProfileAvatar(
                            radius: 60,
                            fullName: currentUser?.fullName ?? '?',
                            imageUrl: currentUser?.profilePictureUrl,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _pickImage,
                              child: CircleAvatar(
                                radius: 20,
                                backgroundColor: theme.colorScheme.primary,
                                child: const Icon(CupertinoIcons.camera_fill, color: Colors.white, size: 20),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: AppConstants.padXL),
                    CustomTextFormField(
                      controller: _nameController,
                      labelText: 'Your Full Name',
                      hintText: 'e.g., Jane Doe',
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                      enabled: !isLoading,
                    ),
                    const SizedBox(height: AppConstants.padXL * 2),
                    PrimaryGradientButton(
                      text: 'FINISH SETUP',
                      onPressed: isLoading ? null : _finishSetup,
                      isLoading: isLoading,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

