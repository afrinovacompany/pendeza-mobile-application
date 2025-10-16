import 'package:flutter/material.dart';

// --- Adjust these import paths to match your project structure ---
import '../../../../app/config/theme/app_constants.dart';
import '../../../../shared/widgets/custom_card.dart';
import '../../../../shared/widgets/profile_avatar.dart';

class OwnerDashboardScreen extends StatelessWidget {
  const OwnerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppConstants.padL),
          children: [
            // --- Header Section ---
            _buildHeader(context),
            const SizedBox(height: AppConstants.padXL),

            // --- Key Metrics Section ---
            // A grid layout is perfect for displaying key performance indicators (KPIs).
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: AppConstants.padM,
              mainAxisSpacing: AppConstants.padM,
              childAspectRatio: 1.2, // Adjust the shape of the cards
              children: [
                _buildKpiCard(context,
                    title: 'Today\'s Revenue',
                    value: 'TSh 350,000',
                    icon: Icons.trending_up_rounded,
                    color: Colors.green),
                _buildKpiCard(context,
                    title: 'Appointments',
                    value: '12 Today',
                    icon: Icons.calendar_today_rounded,
                    color: Colors.blue),
                _buildKpiCard(context,
                    title: 'New Clients',
                    value: '3 This Week',
                    icon: Icons.person_add_alt_1_rounded,
                    color: Colors.orange),
                _buildKpiCard(context,
                    title: 'Occupancy',
                    value: '75%',
                    icon: Icons.pie_chart_rounded,
                    color: Theme.of(context).colorScheme.primary),
              ],
            ),
            const SizedBox(height: AppConstants.padXL),

            // --- Upcoming Appointments List ---
            Text(
              'Upcoming Today',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppConstants.padS),
            _buildUpcomingAppointmentItem(context, clientName: 'Asha Juma', service: 'Gel Manicure', time: '2:00 PM'),
            _buildUpcomingAppointmentItem(context, clientName: 'David Mjema', service: 'Gent\'s Haircut', time: '3:30 PM'),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Dashboard',
              style: Theme.of(context).textTheme.displayMedium,
            ),
            Text(
              'Glamour Touch Salon', // This would come from salon data
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(178),
              ),
            ),
          ],
        ),
        const ProfileAvatar(
          imageUrl: null,
          fullName: 'Owner Name',
          radius: 30,
        ),
      ],
    );
  }

  Widget _buildKpiCard(BuildContext context,
      {required String title, required String value, required IconData icon, required Color color}) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, size: 30, color: color),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingAppointmentItem(BuildContext context, {required String clientName, required String service, required String time}) {
    return CustomCard(
      onTap: () {},
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.padM, vertical: AppConstants.padS),
      child: Row(
        children: [
          ProfileAvatar(fullName: clientName, radius: 22),
          const SizedBox(width: AppConstants.padM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  clientName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  service,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withAlpha(178),
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
