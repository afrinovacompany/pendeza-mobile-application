import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// --- Adjust these import paths to match your project structure ---
import '../../../../app/config/theme/app_colors.dart';
import '../../../../app/config/theme/app_constants.dart';
import '../../../../shared/widgets/custom_card.dart';


class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Analytics'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppConstants.padL),
        children: [
          // --- Weekly Revenue Chart ---
          _buildSectionTitle(context, title: 'Weekly Revenue', icon: CupertinoIcons.chart_bar_square),
          const SizedBox(height: AppConstants.padS),
          CustomCard(
            child: SizedBox(
              height: 200,
              child: _buildBarChart(context),
            ),
          ),
          const SizedBox(height: AppConstants.padXL),

          // --- Service Popularity Chart ---
          _buildSectionTitle(context, title: 'Service Popularity', icon: CupertinoIcons.chart_pie),
          const SizedBox(height: AppConstants.padS),
          CustomCard(
            child: SizedBox(
              height: 200,
              child: _buildPieChart(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, {required String title, required IconData icon}) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, color: theme.colorScheme.onSurface.withAlpha(178)),
        const SizedBox(width: AppConstants.padS),
        Text(title, style: theme.textTheme.headlineSmall),
      ],
    );
  }

  /// Builds a sample Bar Chart for weekly revenue using the corrected fl_chart API.
  Widget _buildBarChart(BuildContext context) {
    final theme = Theme.of(context);
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 500, // Max value on the Y-axis (e.g., 500k TSh)
        barTouchData: BarTouchData(enabled: true),
        titlesData: FlTitlesData(
          show: true,
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
              sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) {
                    // Show labels only for certain values on the Y-axis
                    if (value % 100 == 0 && value <= 500) {
                      return Text('${value.toInt()}k', style: const TextStyle(fontSize: 10));
                    }
                    return const Text('');
                  }
              )
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                // Show labels for each day of the week
                switch (value.toInt()) {
                  case 0:
                    return const Text('Mon', style: TextStyle(fontSize: 10));
                  case 1:
                    return const Text('Tue', style: TextStyle(fontSize: 10));
                  case 2:
                    return const Text('Wed', style: TextStyle(fontSize: 10));
                  case 3:
                    return const Text('Thu', style: TextStyle(fontSize: 10));
                  case 4:
                    return const Text('Fri', style: TextStyle(fontSize: 10));
                  case 5:
                    return const Text('Sat', style: TextStyle(fontSize: 10));
                  case 6:
                    return const Text('Sun', style: TextStyle(fontSize: 10));
                  default:
                    return const Text('');
                }
              },
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(color: theme.dividerColor, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        barGroups: [
          _makeBarGroup(0, 150), // Mon
          _makeBarGroup(1, 250), // Tue
          _makeBarGroup(2, 200), // Wed
          _makeBarGroup(3, 400), // Thu
          _makeBarGroup(4, 450), // Fri
          _makeBarGroup(5, 480), // Sat
          _makeBarGroup(6, 100), // Sun
        ],
      ),
    );
  }

  BarChartGroupData _makeBarGroup(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [BarChartRodData(toY: y, color: AppColors.primary, width: 16, borderRadius: const BorderRadius.all(Radius.circular(4)))],
    );
  }

  /// Builds a sample Pie Chart for service popularity using fl_chart.
  Widget _buildPieChart(BuildContext context) {
    return PieChart(
      PieChartData(
        pieTouchData: PieTouchData(
          touchCallback: (FlTouchEvent event, pieTouchResponse) {
            // Can be used for interactivity later
          },
        ),
        sectionsSpace: AppConstants.padXS,
        centerSpaceRadius: 40,
        sections: [
          PieChartSectionData(value: 40, title: '40%', titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white), color: AppColors.primary, radius: 60),
          PieChartSectionData(value: 30, title: '30%', titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white), color: AppColors.primaryLight, radius: 60),
          PieChartSectionData(value: 20, title: '20%', titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary), color: AppColors.accent, radius: 60),
          PieChartSectionData(value: 10, title: '10%', titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white), color: AppColors.accent2, radius: 60),
        ],
      ),
    );
  }
}

