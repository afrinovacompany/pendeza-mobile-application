import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pendeza/app/config/theme/app_constants.dart';
import 'package:pendeza/app/utils/validators.dart';
import 'package:pendeza/features/3_owner_management/services/presentation/bloc/services_bloc.dart';
import 'package:pendeza/features/3_owner_management/services/presentation/bloc/services_state.dart';
import 'package:pendeza/shared/models/staff_model.dart';
import 'package:pendeza/shared/widgets/custom_card.dart';
import 'package:pendeza/shared/widgets/primary_gradient_button.dart';
import 'package:pendeza/shared/widgets/text_form_field.dart';

class AddEditStaffScreen extends StatefulWidget {
  final StaffModel? staff;

  const AddEditStaffScreen({super.key, this.staff});

  @override
  State<AddEditStaffScreen> createState() => _AddEditStaffScreenState();
}

class _AddEditStaffScreenState extends State<AddEditStaffScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _roleController;
  late final Set<String> _selectedServiceIds;

  bool get _isEditing => widget.staff != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.staff?.name);
    _roleController = TextEditingController(text: widget.staff?.role);
    _selectedServiceIds = widget.staff?.serviceIds.toSet() ?? {};
  }

  @override
  void dispose() {
    _nameController.dispose();
    _roleController.dispose();
    super.dispose();
  }

  void _onServiceToggled(String serviceId) {
    setState(() {
      if (_selectedServiceIds.contains(serviceId)) {
        _selectedServiceIds.remove(serviceId);
      } else {
        _selectedServiceIds.add(serviceId);
      }
    });
  }

  void _saveStaff() {
    if (_formKey.currentState?.validate() ?? false) {
      // In a real app, you would create or update a StaffModel
      // and dispatch an event to a StaffBloc.
      final newStaffData = StaffModel(
        id: widget.staff?.id ?? '', // Handled by backend if new
        salonId: widget.staff?.salonId ?? '', // Handled by backend/bloc
        name: _nameController.text.trim(),
        role: _roleController.text.trim(),
        serviceIds: _selectedServiceIds.toList(),
      );

      print('Saving Staff: ${newStaffData.name}');
      print('Service IDs: ${_selectedServiceIds.toList()}');

      // TODO: context.read<StaffBloc>().add(SaveStaffRequested(newStaffData));
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Staff Member' : 'Add Staff Member'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.padL),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CustomTextFormField(
                controller: _nameController,
                labelText: 'Staff Member Name',
                hintText: 'e.g., Amina Hassan',
                validator: (value) => AppValidators.notEmpty(value),
              ),
              const SizedBox(height: AppConstants.padL),
              CustomTextFormField(
                controller: _roleController,
                labelText: 'Role / Title',
                hintText: 'e.g., Senior Stylist',
                validator: (value) => AppValidators.notEmpty(value),
              ),
              const SizedBox(height: AppConstants.padXL),
              Text(
                'Services Performed',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppConstants.padS),
              _buildServiceSelectionList(),
              const SizedBox(height: AppConstants.padXL),
              PrimaryGradientButton(
                text: _isEditing ? 'SAVE CHANGES' : 'ADD STAFF MEMBER',
                onPressed: _saveStaff,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServiceSelectionList() {
    // This widget listens to the ServicesBloc to get the list of services.
    // Make sure ServicesBloc is provided in the widget tree above this screen.
    return BlocBuilder<ServicesBloc, ServicesState>(
      builder: (context, state) {
        if (state is ServicesLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is ServicesError) {
          return Center(child: Text('Error: ${state.message}'));
        }
        // FIX: The state name was changed from ServicesLoaded to ServicesLoadSuccess
        if (state is ServicesLoadSuccess) {
          if (state.services.isEmpty) {
            return const CustomCard(
              child: Text(
                  'No services found. Please add services before assigning them to staff.'),
            );
          }
          return CustomCard(
            padding: EdgeInsets.zero,
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: state.services.length,
              itemBuilder: (context, index) {
                final service = state.services[index];
                final isSelected = _selectedServiceIds.contains(service.id);
                return CheckboxListTile(
                  title: Text(service.name),
                  subtitle: Text('${service.durationMinutes} min'),
                  value: isSelected,
                  onChanged: (bool? value) {
                    _onServiceToggled(service.id);
                  },
                );
              },
              separatorBuilder: (context, index) => const Divider(height: 1),
            ),
          );
        }
        return const Text('Please add services first.');
      },
    );
  }
}
