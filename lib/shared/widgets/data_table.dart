import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart'
    hide DataColumn, DataRow, DataCell, DataTable, DataTableSource;
import 'package:material_ui/material_ui.dart'
    show DataColumn, DataTableSource;
import '../../app/config/theme/app_constants.dart' show AppConstants;
import 'custom_card.dart';


/// A custom, styled data table for the application, built on top of `data_table_2`.
///
/// This widget provides a consistent look and feel for all data tables,
/// integrating with the app's theme for colors, text styles, and cards.
/// It's designed to be highly reusable for displaying various types of data.
class CustomDataTable extends StatelessWidget {
  /// The list of column definitions for the table.
  final List<DataColumn> columns;

  /// The data source for the table's rows.
  /// You will need to create a class that extends `DataTableSource`.
  final DataTableSource source;

  /// The title widget to display above the table.
  final Widget? title;

  /// The number of rows to display per page.
  final int rowsPerPage;

  const CustomDataTable({
    super.key,
    required this.columns,
    required this.source,
    this.title,
    this.rowsPerPage = 10,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return CustomCard(
      padding: EdgeInsets.zero, // Padding is handled by the table itself
      child: PaginatedDataTable2(
        columns: columns,
        source: source,
        rowsPerPage: rowsPerPage,

        // Styling Configuration
        minWidth: 600, // Provides a minimum width for horizontal scrolling on small screens
        border: TableBorder.all(color: theme.dividerColor, width: 1),
        headingRowColor: WidgetStateProperty.all(theme.colorScheme.surface.withValues(alpha: 0.5)),
        headingTextStyle: textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
        dataTextStyle: textTheme.bodySmall,
        columnSpacing: AppConstants.padM,
        horizontalMargin: AppConstants.padM,

        // Header
        header: title != null
            ? Padding(
          padding: const EdgeInsets.all(AppConstants.padM),
          child: title,
        )
            : null,

        // Paginator Styling
        // *** FIXED ERRORS HERE ***
        // Removed outdated parameters: pageSyncApproach, prevPageIcon, nextPageIcon.
        // The default paginator controls are now used.
        renderEmptyRowsInTheEnd: false,
        showFirstLastButtons: true,
      ),
    );
  }
}


// --- HOW TO CREATE A DataTableSource (EXAMPLE) ---
/*
// 1. Create a model for your data
class Client {
  final String name;
  final String phone;
  final int appointments;
  Client(this.name, this.phone, this.appointments);
}

// 2. Create a class that extends DataTableSource
class ClientDataSource extends DataTableSource {
  final List<Client> _clients = List.generate(
    100, (index) => Client('Client $index', '0712345$index', index % 5));

  @override
  DataRow? getRow(int index) {
    if (index >= _clients.length) return null;
    final client = _clients[index];
    return DataRow(cells: [
      DataCell(Text(client.name)),
      DataCell(Text(client.phone)),
      DataCell(Text(client.appointments.toString())),
    ]);
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => _clients.length;

  @override
  int get selectedRowCount => 0;
}
*/

