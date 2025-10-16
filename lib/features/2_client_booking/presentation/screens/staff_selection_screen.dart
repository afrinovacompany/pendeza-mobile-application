import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pendeza/features/2_client_booking/presentation/bloc/booking_bloc.dart';
import 'package:pendeza/features/2_client_booking/presentation/bloc/booking_event.dart';
import 'package:pendeza/features/2_client_booking/presentation/bloc/booking_state.dart';
import 'package:pendeza/shared/models/staff_model.dart';
import '../../../../app/config/app_router.dart';
import '../../../../app/config/theme/app_constants.dart';
import '../../../../app/config/theme/app_colors.dart';
import '../../../../shared/widgets/custom_card.dart';
import '../../../../shared/widgets/primary_gradient_button.dart';
import '../../../../shared/widgets/profile_avatar.dart';

class StaffSelectionScreen extends StatefulWidget {
  const StaffSelectionScreen({super.key});

  @override
  State<StaffSelectionScreen> createState() => _StaffSelectionScreenState();
}

class _StaffSelectionScreenState extends State<StaffSelectionScreen> {
  StaffModel? _selectedStaff;

  // A unique ID to represent the "Any Staff" option
  static const String _anyStaffId = 'any_available';

  // MOCK DATA - This would come from the BookingBloc in a real app
  final List<StaffModel> _allStaff = const [
    StaffModel(id: 'staff1', salonId: 'sal1', name: 'Amina Hassan', role: 'Senior Stylist, Nail Technician', rating: 4.8, serviceIds: ['s1', 's2', 's5']),
    StaffModel(id: 'staff2', salonId: 'sal1', name: 'John Bakari', role: 'Barber, Massage Therapist', rating: 4.9, serviceIds: ['s3', 's4']),
    StaffModel(id: 'staff3', salonId: 'sal1', name: 'Zawadi Mwangi', role: 'Nail Technician', rating: 4.7, serviceIds: ['s1', 's2']),
  ];

  @override
  void initState() {
    super.initState();
    // Default selection to "Any Available"
    _selectedStaff = const StaffModel(id: _anyStaffId, salonId: '', name: 'Any Available Staff', role: 'We\'ll pick the best fit for your services', serviceIds: [],);
  }

  void _selectStaff(StaffModel staff) {
    setState(() {
      _selectedStaff = staff;
    });
  }

  void _proceedToTimeslotSelection() {
    if (_selectedStaff == null) return;
    context.read<BookingBloc>().add(SelectStaff(_selectedStaff!));
    context.push(AppRoutes.timeslotSelection);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Your Stylist'),
      ),
      body: BlocBuilder<BookingBloc, BookingState>(
        builder: (context, state) {
          if (state is BookingInProgress) {

            // START OF INTELLIGENT FILTERING LOGIC
            final selectedServiceIds = state.selectedServices.map((s) => s.id).toSet();

            final qualifiedStaff = _allStaff.where((staff) {
              // Check if the staff's service list contains all selected services
              return selectedServiceIds.every((serviceId) => staff.serviceIds.contains(serviceId));
            }).toList();
            // END OF LOGIC

            return Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(AppConstants.padL),
                    children: [
                      _buildStaffCard(
                        staff: const StaffModel(
                          id: _anyStaffId,
                          salonId: '',
                          name: 'Any Available Staff',
                          role: 'No preference on who does the service.',
                          serviceIds: [],
                        ),
                        isSelected: _selectedStaff?.id == _anyStaffId,
                        onTap: () => _selectStaff(const StaffModel(
                          id: _anyStaffId, salonId: '', name: 'Any Available Staff', role: 'We\'ll pick the best fit for your services', serviceIds: [],
                        )),
                        iconOverride: Icons.person_search_rounded,
                      ),

                      if (qualifiedStaff.isNotEmpty) ...[
                        const Divider(height: AppConstants.padXL),
                        ...qualifiedStaff.map((staff) => Padding(
                          padding: const EdgeInsets.only(bottom: AppConstants.padM),
                          child: _buildStaffCard(
                            staff: staff,
                            isSelected: _selectedStaff?.id == staff.id,
                            onTap: () => _selectStaff(staff),
                          ),
                        )),
                      ] else ...[
                        const Padding(
                          padding: EdgeInsets.all(AppConstants.padXL),
                          child: Text(
                            'No single staff member can perform all selected services. Try booking separately or select "Any Available".',
                            textAlign: TextAlign.center,
                          ),
                        )
                      ]
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(AppConstants.padL),
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    boxShadow: theme.brightness == Brightness.light
                        ? AppColors.lightShadowMd
                        : AppColors.darkShadowMd,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(AppConstants.padL),
                      topRight: Radius.circular(AppConstants.padL),
                    ),
                  ),
                  child: PrimaryGradientButton(
                    text: 'NEXT: SELECT DATE & TIME',
                    onPressed: _selectedStaff != null ? _proceedToTimeslotSelection : null,
                    iconData: CupertinoIcons.arrow_right,
                  ),
                ),
              ],
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildStaffCard({
    required StaffModel staff,
    required bool isSelected,
    required VoidCallback onTap,
    IconData? iconOverride,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final borderColor = isSelected ? colorScheme.primary : Colors.transparent;
    final backgroundColor =
    isSelected ? colorScheme.primary.withOpacity(0.05) : theme.cardColor;

    return CustomCard(
      onTap: onTap,
      color: backgroundColor,
      padding: EdgeInsets.zero,
      child: Container(
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: borderColor, width: 4.0)),
        ),
        padding: const EdgeInsets.all(AppConstants.padM),
        child: Row(
          children: [
            if (iconOverride != null)
              Padding(
                padding: const EdgeInsets.only(right: AppConstants.padM),
                child: Icon(iconOverride, color: colorScheme.primary, size: 40),
              )
            else
              Padding(
                padding: const EdgeInsets.only(right: AppConstants.padM),
                child: ProfileAvatar(fullName: staff.name, radius: 28),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    staff.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppConstants.padXXS),
                  Text(
                    staff.role,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected
                  ? CupertinoIcons.check_mark_circled_solid
                  : CupertinoIcons.circle,
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.onSurface.withOpacity(0.4),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}
