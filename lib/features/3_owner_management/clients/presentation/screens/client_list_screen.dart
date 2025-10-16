import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// --- Adjust these import paths to match your project structure ---
import '../../../../../app/config/theme/app_constants.dart';
import '../../../../../shared/widgets/data_table.dart';
import '../../../../../shared/widgets/profile_avatar.dart';

// --- DATA MODEL FOR THE TABLE ---
// In a real app, this would be in its own file in the `data/models` directory.
class ClientData {
  final String name;
  final String phone;
  final int totalAppointments;
  final DateTime lastVisit;

  ClientData({
    required this.name,
    required this.phone,
    required this.totalAppointments,
    required this.lastVisit,
  });
}

// --- DATATABLE SOURCE ---
// This class is responsible for providing the data to our CustomDataTable.
class ClientDataSource extends DataTableSource {
  final BuildContext context;
  final List<ClientData> _clients;

  ClientDataSource(this.context, this._clients);

  @override
  DataRow? getRow(int index) {
    if (index >= _clients.length) return null;
    final client = _clients[index];
    final theme = Theme.of(context);

    return DataRow.byIndex(
      index: index,
      cells: [
        DataCell(Row(
          children: [
            ProfileAvatar(fullName: client.name, radius: 18),
            const SizedBox(width: AppConstants.padM),
            Text(client.name, style: theme.textTheme.bodyMedium),
          ],
        )),
        DataCell(Text(client.phone)),
        DataCell(Text(client.totalAppointments.toString())),
        // Here you would format the date using AppFormatters
        DataCell(Text('${client.lastVisit.day}/${client.lastVisit.month}/${client.lastVisit.year}')),
        DataCell(
          Icon(CupertinoIcons.ellipsis, color: theme.colorScheme.onSurface.withAlpha(150)),
          onTap: () {
            // TODO: Show options menu or navigate to client detail
          },
        ),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;
  @override
  int get rowCount => _clients.length;
  @override
  int get selectedRowCount => 0;
}


class ClientListScreen extends StatefulWidget {
  const ClientListScreen({super.key});

  @override
  State<ClientListScreen> createState() => _ClientListScreenState();
}

class _ClientListScreenState extends State<ClientListScreen> {
  late final ClientDataSource _dataSource;

  // Using mock data for UI building purposes
  final List<ClientData> _clients = List.generate(
    50,
        (index) => ClientData(
      name: 'Client Name $index',
      phone: '0712 345 6$index',
      totalAppointments: (index * 2) % 10,
      lastVisit: DateTime.now().subtract(Duration(days: index * 5)),
    ),
  );

  @override
  void initState() {
    super.initState();
    _dataSource = ClientDataSource(context, _clients);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Clients'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppConstants.padM),
        child: CustomDataTable(
          // --- Define the table columns ---
          columns: const [
            DataColumn(label: Text('Name')),
            DataColumn(label: Text('Phone')),
            DataColumn(label: Text('Bookings')),
            DataColumn(label: Text('Last Visit')),
            DataColumn(label: Text('Actions')),
          ],
          // --- Provide the data source ---
          source: _dataSource,
          // --- Optional Title/Search Bar ---
          title: const TextField(
            decoration: InputDecoration(
              hintText: 'Search clients...',
              prefixIcon: Icon(CupertinoIcons.search),
              isDense: true,
            ),
          ),
        ),
      ),
    );
  }
}
