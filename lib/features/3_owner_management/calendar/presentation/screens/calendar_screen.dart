import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

// --- Adjust these import paths to match your project structure ---
import '../../../../../app/config/theme/app_constants.dart';
import '../../../../../shared/widgets/custom_card.dart';
import '../../../../../shared/widgets/profile_avatar.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  // State variables to manage the calendar
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Schedule'),
        actions: [
          // Button to quickly jump back to today's date
          IconButton(
            icon: const Icon(Icons.today_rounded),
            onPressed: () {
              setState(() {
                _focusedDay = DateTime.now();
                _selectedDay = DateTime.now();
              });
            },
          )
        ],
      ),
      body: Column(
        children: [
          // --- The Calendar Widget ---
          CustomCard(
            padding: const EdgeInsets.all(AppConstants.padS),
            child: TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay; // update `_focusedDay` here as well
                });
              },
              calendarFormat: CalendarFormat.week, // A weekly view is often best for schedules
              headerStyle: HeaderStyle(
                titleCentered: true,
                formatButtonVisible: false, // Hide the format button
                titleTextStyle: theme.textTheme.titleMedium!,
              ),
              calendarStyle: CalendarStyle(
                // Style the markers for today and the selected day
                todayDecoration: BoxDecoration(
                  color: theme.colorScheme.primary.withAlpha(80),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),

          // --- Title for the appointment list ---
          Padding(
            padding: const EdgeInsets.all(AppConstants.padL),
            child: Row(
              children: [
                const Icon(Icons.list_alt_rounded),
                const SizedBox(width: AppConstants.padS),
                Text(
                  'Appointments for the selected day',
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
          ),

          // --- The list of appointments for the selected day ---
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: AppConstants.padL),
              children: [
                _buildAppointmentItem(context, clientName: 'Asha Juma', service: 'Gel Manicure', time: '2:00 PM'),
                _buildAppointmentItem(context, clientName: 'David Mjema', service: 'Gent\'s Haircut', time: '3:30 PM'),
                _buildAppointmentItem(context, clientName: 'Fatima Said', service: 'Hair Braiding', time: '4:00 PM'),
              ],
            ),
          )
        ],
      ),
    );
  }

  /// Helper widget to build a single appointment item for the list.
  Widget _buildAppointmentItem(BuildContext context,
      {required String clientName, required String service, required String time}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.padM),
      child: CustomCard(
        onTap: () {
          // TODO: Open appointment details dialog
        },
        child: Row(
          children: [
            ProfileAvatar(fullName: clientName, radius: 24),
            const SizedBox(width: AppConstants.padM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(clientName, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  Text(service, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppConstants.padS, vertical: AppConstants.padXS),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withAlpha(50),
                borderRadius: AppConstants.radiusS,
              ),
              child: Text(
                time,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
