import 'package:flutter/material.dart';

// --- Adjust these import paths to match your project structure ---
import '../../../../app/config/theme/app_constants.dart';
import '../../../../shared/widgets/primary_gradient_button.dart';
import '../../../../shared/widgets/text_form_field.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../0_auth/presentation/bloc/auth_bloc.dart';
import '../../../0_auth/presentation/bloc/auth_event.dart';
import '../../../0_auth/presentation/bloc/auth_state.dart';

class OwnerOnboardingScreen extends StatefulWidget {
  const OwnerOnboardingScreen({super.key});

  @override
  State<OwnerOnboardingScreen> createState() => _OwnerOnboardingScreenState();
}

class _OwnerOnboardingScreenState extends State<OwnerOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _salonNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _categoriesController = TextEditingController();

  @override
  void dispose() {
    _salonNameController.dispose();
    _addressController.dispose();
    _categoriesController.dispose();
    super.dispose();
  }

  void _completeSetup() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final authState = context.read<AuthBloc>().state;
    if (authState is OwnerProfileSetupRequired) {
      // Split the categories string into a list, trimming whitespace.
      final categories = _categoriesController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      // Dispatch the event to the AuthBloc to create the salon.
      context.read<AuthBloc>().add(
        CompleteOwnerProfile(
          ownerId: authState.user.uid,
          salonName: _salonNameController.text.trim(),
          address: _addressController.text.trim(),
          serviceCategories: categories,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Set Up Your Business'),
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
                    Text(
                      'Tell us about your salon',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.displayMedium,
                    ),
                    Text(
                      'This information will be visible to clients.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurface.withAlpha(178),
                      ),
                    ),
                    const SizedBox(height: AppConstants.padXL),

                    CustomTextFormField(
                      controller: _salonNameController,
                      labelText: 'Salon Name',
                      hintText: 'e.g., Glamour Touch Salon',
                      validator: (value) =>
                      (value ?? '').trim().isEmpty ? 'Please enter your salon name' : null,
                      enabled: !isLoading,
                    ),
                    const SizedBox(height: AppConstants.padL),
                    CustomTextFormField(
                      controller: _addressController,
                      labelText: 'Full Address',
                      hintText: 'e.g., 123 Mbezi Beach, Dar es Salaam',
                      validator: (value) =>
                      (value ?? '').trim().isEmpty ? 'Please enter your address' : null,
                      enabled: !isLoading,
                    ),
                    const SizedBox(height: AppConstants.padL),
                    CustomTextFormField(
                      controller: _categoriesController,
                      labelText: 'Service Categories',
                      hintText: 'e.g., Nails, Hair, Massage (comma-separated)',
                      validator: (value) =>
                      (value ?? '').trim().isEmpty ? 'Please enter at least one category' : null,
                      enabled: !isLoading,
                    ),
                    const SizedBox(height: AppConstants.padXL * 2),

                    PrimaryGradientButton(
                      text: 'COMPLETE SETUP',
                      onPressed: isLoading ? null : _completeSetup,
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
