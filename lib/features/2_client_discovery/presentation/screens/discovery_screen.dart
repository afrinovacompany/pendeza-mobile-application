
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pendeza/app/services/service_locator.dart';
import 'package:pendeza/features/2_client_discovery/presentation/bloc/discovery_bloc.dart';
import 'package:pendeza/features/2_client_discovery/presentation/bloc/discovery_event.dart';
import 'package:pendeza/features/2_client_discovery/presentation/bloc/discovery_state.dart';
import 'package:pendeza/shared/widgets/empty_state_widget.dart';
import 'package:pendeza/shared/widgets/loading_indicator.dart';

import '../../../../app/config/theme/app_constants.dart';
import '../../../../shared/widgets/custom_card.dart';
import '../../../../shared/widgets/text_form_field.dart';
import '../../../../app/config/app_router.dart';
import '../../../../shared/models/salon_model.dart';

class DiscoveryScreen extends StatelessWidget {
  const DiscoveryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<DiscoveryBloc>()..add(FetchSalons()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Discover'),
          actions: [
            IconButton(
              icon: const Icon(Icons.filter_list_rounded),
              onPressed: () {},
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(AppConstants.padL),
          children: [
            const CustomTextFormField(
              labelText: 'Search',
              hintText: 'Search for salons, services, or locations...',
              prefixIcon: Icons.search_rounded,
            ),
            const SizedBox(height: AppConstants.padXL),
            _buildSectionTitle(context, title: 'Categories'),
            const SizedBox(height: AppConstants.padS),
            Wrap(
              spacing: AppConstants.padS,
              runSpacing: AppConstants.padS,
              children: [
                _buildCategoryChip(context, label: 'Haircuts', isSelected: true),
                _buildCategoryChip(context, label: 'Nails'),
                _buildCategoryChip(context, label: 'Massage'),
                _buildCategoryChip(context, label: 'Barbershop'),
                _buildCategoryChip(context, label: 'Spa'),
              ],
            ),
            const SizedBox(height: AppConstants.padXL),
            _buildSectionTitle(context, title: 'Nearby You'),
            const SizedBox(height: AppConstants.padS),
            BlocBuilder<DiscoveryBloc, DiscoveryState>(
              builder: (context, state) {
                if (state is DiscoveryLoading) {
                  return _buildLoadingState();
                }
                if (state is DiscoveryError) {
                  return EmptyStateWidget.error(
                    message: state.message,
                    onActionPressed: () {
                      context.read<DiscoveryBloc>().add(FetchSalons());
                    },
                  );
                }
                if (state is DiscoveryLoaded) {
                  if (state.salons.isEmpty) {
                    return const EmptyStateWidget.notFound(
                      message: "No salons found nearby. Check back later!",
                    );
                  }
                  return Column(
                    children: state.salons
                        .map((salon) => _buildSalonResultCard(
                      context,
                      salon: salon,
                      distance: '1.2 km', // Mock data
                      rating: 4.9, // Mock data
                    ))
                        .toList(),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      children: List.generate(
        3,
            (index) => const Padding(
          padding: EdgeInsets.only(bottom: AppConstants.padM),
          child: ShimmerPlaceholder(height: 100, width: double.infinity),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, {required String title}) {
    return Text(
      title,
      style: Theme.of(context)
          .textTheme
          .headlineSmall
          ?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildCategoryChip(BuildContext context,
      {required String label, bool isSelected = false}) {
    final theme = Theme.of(context);
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {},
      selectedColor: theme.colorScheme.primary,
      backgroundColor: theme.colorScheme.surface,
      labelStyle: TextStyle(
        color:
        isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
      ),
      shape: StadiumBorder(
        side: BorderSide(
            color: isSelected ? theme.colorScheme.primary : theme.dividerColor),
      ),
    );
  }

  Widget _buildSalonResultCard(BuildContext context,
      {required SalonModel salon,
        required String distance,
        required double rating}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.padM),
      child: CustomCard(
        onTap: () {
          context.push(AppRoutes.salonDetail, extra: salon);
        },
        padding: EdgeInsets.zero,
        child: Row(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: theme.dividerColor,
              ),
              child: const Center(
                  child: Icon(Icons.image_outlined, size: 30, color: Colors.grey)),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.padM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      salon.salonName,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppConstants.padXXS),
                    Text(
                      salon.serviceCategories.join(', '),
                      style: theme.textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppConstants.padS),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(rating.toString(),
                            style: theme.textTheme.bodySmall
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        const Text('  •  '),
                        Text(distance, style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

