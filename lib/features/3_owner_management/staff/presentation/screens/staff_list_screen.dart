import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// --- Adjust these import paths to match your project structure ---
import '../../../../../app/config/theme/app_constants.dart';
import '../../../../../shared/widgets/custom_card.dart';
import '../../../../../shared/widgets/profile_avatar.dart';

import 'package:pendeza/shared/models/staff_model.dart';

// MOCK DATA - In a real app, this would come from a BLoC
final List<StaffModel> _mockStaff = [
  const StaffModel(
    id: 'staff1',
    salonId: 'salon1',
    name: 'Amina Hassan',
    role: 'Senior Stylist',
    serviceIds: ['s1', 's2', 's5'], // Corresponds to service IDs
  ),
  const StaffModel(
    id: 'staff2',
    salonId: 'salon1',
    name: 'John Bakari',
    role: 'Barber, Massage Therapist',
    serviceIds: ['s3', 's4'],
  ),
  const StaffModel(
    id: 'staff3',
    salonId: 'salon1',
    name: 'Zawadi Mwangi',
    role: 'Junior Nail Technician',
    serviceIds: ['s1'],
  ),
];

class StaffListScreen extends StatelessWidget {
  const StaffListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Staff'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(AppConstants.padL),
        itemCount: _mockStaff.length,
        itemBuilder: (context, index) {
          final staffMember = _mockStaff[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: AppConstants.padM),
            child: _buildStaffMemberItem(context, staff: staffMember),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Navigate to Add/Edit Staff Screen
          // For now, we'll just show a snackbar.
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Navigate to Add/Edit Staff Screen')),
          );
        },
        child: const Icon(Icons.person_add_alt_1_rounded),
      ),
    );
  }

  Widget _buildStaffMemberItem(BuildContext context, {required StaffModel staff}) {
    final theme = Theme.of(context);
    // In a real app, you would fetch the service names from their IDs.
    // For this UI example, we'll just show the count.
    final serviceCount = staff.serviceIds.length;

    return CustomCard(
      onTap: () {
        // TODO: Navigate to edit this specific staff member
      },
      child: Row(
        children: [
          ProfileAvatar(fullName: staff.name, radius: 28),
          const SizedBox(width: AppConstants.padM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  staff.name,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  staff.role,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: AppConstants.padXXS),
                // NEW: Displaying assigned services count
                if (serviceCount > 0)
                  Text(
                    'Performs $serviceCount services',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppConstants.padS),
          const Icon(CupertinoIcons.chevron_forward, size: 18),
        ],
      ),
    );
  }
}

