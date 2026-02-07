import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pendeza/app/config/theme/app_colors.dart';
import 'package:pendeza/app/config/theme/app_constants.dart';
import 'package:pendeza/app/config/theme/app_text_styles.dart';
import 'package:pendeza/features/0_auth/data/models/user_model.dart';
import 'package:pendeza/features/5_admin_panel/presentation/bloc/admin_bloc.dart';
import 'package:pendeza/features/5_admin_panel/presentation/bloc/admin_state.dart';
import 'package:pendeza/features/5_admin_panel/presentation/dialog/admin_role_dialog.dart';
import 'package:pendeza/shared/widgets/profile_avatar.dart';

class AdminManageUsersScreen extends StatelessWidget {
  const AdminManageUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Users'),
        backgroundColor:
        isDark ? AppColors.darkSurfaceVariant : theme.colorScheme.surface,
        elevation: 1,
      ),
      // Use the scaffold's background color
      backgroundColor: isDark
          ? AppColors.darkBackground
          : theme.scaffoldBackgroundColor.withAlpha(245),
      body: BlocBuilder<AdminBloc, AdminState>(
        builder: (context, state) {
          if (state is AdminLoading || state is AdminInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is AdminError) {
            return Center(child: Text(state.message));
          }
          if (state is AdminLoaded) {
            return Card(
              elevation: 0,
              // Use theme's surface color
              color: theme.colorScheme.surface,
              margin: const EdgeInsets.all(AppConstants.padM),
              shape: RoundedRectangleBorder(
                borderRadius: AppConstants.radiusL,
                side: BorderSide(
                  color:
                  isDark ? AppColors.darkBorder : theme.dividerColor,
                  width: 1,
                ),
              ),
              clipBehavior: Clip.antiAlias, // Clip the datatable to the card's shape
              child: PaginatedDataTable2(
                columns: const [
                  DataColumn2(
                    label: Text('Name'),
                    size: ColumnSize.L, // Give more space for name
                  ),
                  DataColumn2(
                    label: Text('Contact'),
                    size: ColumnSize.M,
                  ),
                  DataColumn2(
                    label: Text('Role'),
                    size: ColumnSize.S,
                  ),
                ],
                source: UserDataTableSource(
                  users: state.users,
                  adminBloc: context.read<AdminBloc>(),
                  context: context,
                ),
                columnSpacing: 20,
                horizontalMargin: 12,
                minWidth: 600,
                rowsPerPage: 20,
                sortArrowIcon: Icons.arrow_upward,
                sortAscending: true,
                // Apply theme
                dataRowHeight: 60,
                headingRowHeight: 56,
                headingRowColor: WidgetStateProperty.all(
                  theme.colorScheme.surface.withOpacity(0.5),
                ),
                // ** FIX: Removed the problematic dataRowColor line **
              ),
            );
          }
          return const Center(child: Text('Unknown state.'));
        },
      ),
    );
  }
}

/// Data source for the PaginatedDataTable2
class UserDataTableSource extends DataTableSource {
  final List<UserModel> users;
  final AdminBloc adminBloc;
  final BuildContext context;

  UserDataTableSource({
    required this.users,
    required this.adminBloc,
    required this.context,
  });

  @override
  DataRow? getRow(int index) {
    if (index >= users.length) return null;
    final user = users[index];

    return DataRow2.byIndex(
      index: index,
      onSelectChanged: (isSelected) {
        if (isSelected != null && isSelected) {
          _showRoleDialog(context, user);
        }
      },
      cells: [
        // Name Cell
        DataCell(
          Row(
            children: [
              ProfileAvatar(
                imageUrl: user.profilePictureUrl,
                fullName: user.fullName,
                radius: 20,
              ),
              const SizedBox(width: AppConstants.padM),
              Expanded(
                child: Text(
                  user.fullName,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        // Contact Cell
        DataCell(
          Text(user.email.isEmpty ? user.phoneNumber ?? 'N/A' : user.email),
        ),
        // Role Cell
        DataCell(_buildRoleChip(user.role)),
      ],
    );
  }

  void _showRoleDialog(BuildContext context, UserModel user) {
    showDialog(
      context: context,
      builder: (dialogContext) => AdminRoleDialog(
        user: user,
        adminBloc: adminBloc,
      ),
    );
  }

  Widget _buildRoleChip(String? role) {
    Color color;
    switch (role) {
      case 'admin':
        color = AppColors.error;
        break;
      case 'owner':
        color = AppColors.accent2;
        break;
      case 'client':
        color = AppColors.success;
        break;
      default:
        color = AppColors.textSecondary;
    }
    return Chip(
      label: Text(
        role ?? 'N/A',
        style: AppTextStyles.bodySmall.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: color.withOpacity(0.1),
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => users.length;

  @override
  int get selectedRowCount => 0;
}