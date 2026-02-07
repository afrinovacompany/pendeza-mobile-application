import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pendeza/app/config/theme/app_colors.dart';
import 'package:pendeza/app/config/theme/app_constants.dart';
import 'package:pendeza/features/5_admin_panel/presentation/bloc/admin_bloc.dart';
import 'package:pendeza/features/5_admin_panel/presentation/bloc/admin_state.dart';
import 'package:pendeza/shared/models/salon_model.dart';
import 'package:pendeza/shared/widgets/profile_avatar.dart';

class AdminManageSalonsScreen extends StatelessWidget {
  const AdminManageSalonsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Salons'),
        backgroundColor:
        isDark ? AppColors.darkSurfaceVariant : theme.colorScheme.surface,
        elevation: 1,
      ),
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
              clipBehavior: Clip.antiAlias,
              child: PaginatedDataTable2(
                columns: const [
                  DataColumn2(
                    label: Text('Salon Name'),
                    size: ColumnSize.L,
                  ),
                  DataColumn2(
                    label: Text('Address'),
                    size: ColumnSize.M,
                  ),
                  DataColumn2(
                    label: Text('Categories'),
                    size: ColumnSize.S,
                  ),
                ],
                source: SalonDataTableSource(
                  salons: state.salons,
                  context: context,
                ),
                columnSpacing: 20,
                horizontalMargin: 12,
                minWidth: 600,
                rowsPerPage: 20,
                sortArrowIcon: Icons.arrow_upward,
                sortAscending: true,
                dataRowHeight: 60,
                headingRowHeight: 56,
                headingRowColor: WidgetStateProperty.all(
                  theme.colorScheme.surface.withOpacity(0.5),
                ),
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
class SalonDataTableSource extends DataTableSource {
  final List<SalonModel> salons;
  final BuildContext context;

  SalonDataTableSource({
    required this.salons,
    required this.context,
  });

  @override
  DataRow? getRow(int index) {
    if (index >= salons.length) return null;
    final salon = salons[index];

    return DataRow2.byIndex(
      index: index,
      onSelectChanged: (isSelected) {
        if (isSelected != null && isSelected) {
          // TODO: Navigate to a detailed admin view for this salon
          // Example: context.go('/admin/salons/${salon.id}');
        }
      },
      cells: [
        // Salon Name Cell
        DataCell(
          Row(
            children: [
              ProfileAvatar(
                imageUrl: salon.primaryImage,
                fullName: salon.salonName,
                radius: 20,
              ),
              const SizedBox(width: AppConstants.padM),
              Expanded(
                child: Text(
                  salon.salonName,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        // Address Cell
        DataCell(
          Text(
            salon.address,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        // Categories Cell
        DataCell(
          Text(salon.serviceCategories.join(', ')),
        ),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => salons.length;

  @override
  int get selectedRowCount => 0;
}