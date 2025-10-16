import 'package:flutter/material.dart';

// --- Adjust these import paths to match your project structure ---
import '../../../../app/config/theme/app_constants.dart';
import '../../../../shared/widgets/custom_card.dart';
import '../../../../shared/widgets/profile_avatar.dart';
import '../../../../shared/widgets/text_form_field.dart';

class ClientDashboardScreen extends StatelessWidget {
  const ClientDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      // We don't need a main AppBar here because the MainScreen (our shell)
      // could have a persistent app bar if desired. Or we can build it per-screen.
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppConstants.padL),
          children: [
            // --- Header Section ---
            _buildHeader(context),
            const SizedBox(height: AppConstants.padXL),

            // --- Search Bar Section ---
            const CustomTextFormField(
              labelText: 'Find a Salon or Service',
              hintText: 'Nails, haircut, massage...',
              prefixIcon: Icons.search_rounded,
            ),
            const SizedBox(height: AppConstants.padXL),

            // --- Upcoming Appointment Section ---
            _buildSectionTitle(context, title: 'Your Next Appointment'),
            const SizedBox(height: AppConstants.padS),
            _buildAppointmentCard(context),
            const SizedBox(height: AppConstants.padXL),

            // --- Featured Salons Section ---
            _buildSectionTitle(context, title: 'Featured Salons'),
            const SizedBox(height: AppConstants.padS),
            _buildFeaturedSalonCard(context,
                salonName: 'Glamour Touch Salon',
                specialty: 'Nail Art & Spa',
                rating: 4.8),
            const SizedBox(height: AppConstants.padM),
            _buildFeaturedSalonCard(context,
                salonName: 'Gentlemen\'s Cut',
                specialty: 'Barbershop & Grooming',
                rating: 4.9),
          ],
        ),
      ),
    );
  }

  /// Builds the header widget with a welcome message and profile avatar.
  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Good Morning,',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(178),
              ),
            ),
            Text(
              'Jane Doe', // This would come from user data
              style: Theme.of(context).textTheme.displayMedium,
            ),
          ],
        ),
        const ProfileAvatar(
          // In a real app, you'd pass the user's image URL
          imageUrl: null, // Shows initials fallback
          fullName: 'Jane Doe',
          radius: 30,
        ),
      ],
    );
  }

  /// Builds a reusable title widget for different sections of the dashboard.
  Widget _buildSectionTitle(BuildContext context, {required String title}) {
    return Text(
      title,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }

  /// Builds a sample card for the "Next Appointment".
  Widget _buildAppointmentCard(BuildContext context) {
    return CustomCard(
      onTap: () {},
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppConstants.padM),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withAlpha(50),
              borderRadius: AppConstants.radiusM,
            ),
            child: Icon(
              Icons.calendar_month_rounded,
              color: Theme.of(context).colorScheme.primary,
              size: 30,
            ),
          ),
          const SizedBox(width: AppConstants.padM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Manicure & Pedicure',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppConstants.padXXS),
                Text(
                  'Today at 4:30 PM',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Theme.of(context).colorScheme.onSurface.withAlpha(150)),
        ],
      ),
    );
  }

  /// Builds a sample card for a "Featured Salon".
  Widget _buildFeaturedSalonCard(BuildContext context, {required String salonName, required String specialty, required double rating}) {
    return CustomCard(
      onTap: () {},
      padding: EdgeInsets.zero, // We handle padding manually for the image
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Placeholder for a salon image
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: Theme.of(context).dividerColor,
              // In a real app, you'd use an Image.network here
              // image: DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover),
            ),
            child: const Center(child: Icon(Icons.image, size: 40, color: Colors.grey)),
          ),
          Padding(
            padding: const EdgeInsets.all(AppConstants.padM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  salonName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppConstants.padXXS),
                Text(
                  specialty,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withAlpha(178),
                  ),
                ),
                const SizedBox(height: AppConstants.padS),
                Row(
                  children: [
                    Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                    const SizedBox(width: AppConstants.padXXS),
                    Text(
                      rating.toString(),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Icon(Icons.location_on_outlined, size: 16, color: Theme.of(context).colorScheme.onSurface.withAlpha(178)),
                    Text(
                      '2.5 km', // Placeholder distance
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
