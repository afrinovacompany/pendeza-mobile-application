import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// --- Adjust these import paths to match your project structure ---
import '../../../../app/config/theme/app_constants.dart';
import '../../../../shared/widgets/custom_card.dart';

class InspirationScreen extends StatelessWidget {
  const InspirationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Using a DefaultTabController to manage the state of the tabs.
    return DefaultTabController(
      length: 2, // We have two tabs: Trends and Lookbook
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Inspiration Hub'),
          bottom: TabBar(
            indicatorColor: theme.colorScheme.primary,
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: theme.colorScheme.onSurface.withAlpha(178),
            tabs: const [
              Tab(icon: Icon(CupertinoIcons.chart_bar_alt_fill), text: 'Market Trends'),
              Tab(icon: Icon(CupertinoIcons.photo_on_rectangle), text: 'Lookbook'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            // --- Content for the "Market Trends" tab ---
            _MarketTrendsView(),
            // --- Content for the "Lookbook" tab ---
            _LookbookView(),
          ],
        ),
      ),
    );
  }
}

/// A private widget for the "Market Trends" view.
class _MarketTrendsView extends StatelessWidget {
  const _MarketTrendsView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppConstants.padL),
      children: [
        _buildTrendCard(
          context,
          title: 'Most Booked Service in Dar es Salaam',
          value: 'Hair Braiding',
          trend: '+15% this month',
          icon: CupertinoIcons.scissors,
        ),
        _buildTrendCard(
          context,
          title: 'Fastest Growing Trend',
          value: 'Nail Art (Chrome Finish)',
          trend: '+28% this month',
          icon: CupertinoIcons.sparkles,
        ),
        _buildTrendCard(
          context,
          title: 'Peak Booking Time',
          value: 'Saturdays, 2 PM - 5 PM',
          trend: 'Plan your staff accordingly',
          icon: CupertinoIcons.time_solid,
        ),
      ],
    );
  }

  Widget _buildTrendCard(BuildContext context,
      {required String title,
        required String value,
        required String trend,
        required IconData icon}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.padM),
      child: CustomCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary),
                const SizedBox(width: AppConstants.padS),
                Text(
                  title,
                  style: theme.textTheme.labelLarge
                      ?.copyWith(color: theme.colorScheme.onSurface.withAlpha(178)),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.padS),
            Text(
              value,
              style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppConstants.padXXS),
            Text(
              trend,
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.green.shade600),
            )
          ],
        ),
      ),
    );
  }
}

/// A private widget for the "Lookbook" view.
class _LookbookView extends StatelessWidget {
  const _LookbookView();

  @override
  Widget build(BuildContext context) {
    // A GridView is perfect for a visual lookbook.
    return GridView.builder(
      padding: const EdgeInsets.all(AppConstants.padL),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppConstants.padM,
        mainAxisSpacing: AppConstants.padM,
        childAspectRatio: 0.8, // Taller cards for images
      ),
      itemCount: 8, // Using mock data
      itemBuilder: (context, index) {
        return _buildLookbookItem(context, 'Style Name ${index + 1}');
      },
    );
  }

  Widget _buildLookbookItem(BuildContext context, String styleName) {
    final theme = Theme.of(context);
    return CustomCard(
      onTap: () {},
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              color: theme.dividerColor,
              child: Center(
                child: Icon(
                  CupertinoIcons.photo,
                  size: 40,
                  color: theme.colorScheme.onSurface.withAlpha(100),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppConstants.padS),
            child: Text(
              styleName,
              style: theme.textTheme.titleSmall,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
