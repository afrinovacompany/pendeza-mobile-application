import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pendeza/features/2_client_booking/presentation/bloc/booking_bloc.dart';
import 'package:pendeza/features/2_client_booking/presentation/bloc/booking_event.dart';
import 'package:pendeza/features/2_client_booking/presentation/bloc/booking_state.dart';
import '../../../../app/config/theme/app_constants.dart';
import '../../../../app/config/theme/app_colors.dart';
import '../../../../app/utils/formatters.dart';
import '../../../../shared/widgets/custom_card.dart';
import '../../../../shared/widgets/primary_gradient_button.dart';
import '../../../../shared/models/service_model.dart';
import '../../../../app/config/app_router.dart';

import 'package:pendeza/shared/widgets/empty_state_widget.dart';
import 'package:pendeza/shared/widgets/loading_indicator.dart';




class ServiceSelectionScreen extends StatefulWidget {
  final String salonName;

  const ServiceSelectionScreen({super.key, required this.salonName});

  @override
  State<ServiceSelectionScreen> createState() => _ServiceSelectionScreenState();
}

class _ServiceSelectionScreenState extends State<ServiceSelectionScreen> {
  final Set<ServiceModel> _selectedServices = {};

  void _toggleServiceSelection(ServiceModel service) {
    setState(() {
      if (_selectedServices.contains(service)) {
        _selectedServices.remove(service);
      } else {
        _selectedServices.add(service);
      }
    });
  }

  void _proceedToTimeslotSelection() {
    if (_selectedServices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select at least one service to continue.')),
      );
      return;
    }
    context
        .read<BookingBloc>()
        .add(SelectServices(_selectedServices.toList()));
    // --- CHANGE IS HERE: Navigate directly to Timeslot Selection ---
    context.push(AppRoutes.timeslotSelection);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.salonName),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.only(
              bottom: AppConstants.padS,
              left: AppConstants.padL,
              right: AppConstants.padL,
            ),
            child: Text(
              'Select the services you would like to book:',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
        ),
      ),
      body: BlocBuilder<BookingBloc, BookingState>(
        builder: (context, state) {
          if (state is BookingInProgress) {
            if (state.status == BookingStatus.loadingServices) {
              return _buildLoadingState();
            }
            if (state.availableServices.isEmpty) {
              return const EmptyStateWidget.notFound(
                message:
                "This salon hasn't added any services yet. Please check back later.",
              );
            }
            return Stack(
              children: [
                ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    AppConstants.padL,
                    AppConstants.padS,
                    AppConstants.padL,
                    150,
                  ),
                  itemCount: state.availableServices.length,
                  itemBuilder: (context, index) {
                    final service = state.availableServices[index];
                    final isSelected = _selectedServices.contains(service);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppConstants.padM),
                      child: _ServiceSelectionCard(
                        service: service,
                        isSelected: isSelected,
                        onTap: () => _toggleServiceSelection(service),
                      ),
                    );
                  },
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: _buildFloatingFooter(theme),
                ),
              ],
            );
          }
          if (state is BookingFailure) {
            return EmptyStateWidget.error(
              message: state.error,
              onActionPressed: () {
                context.read<BookingBloc>().add(FetchServicesForSalon());
              },
            );
          }
          return _buildLoadingState();
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.padL),
      itemCount: 5,
      itemBuilder: (context, index) {
        return const Padding(
          padding: EdgeInsets.only(bottom: AppConstants.padM),
          child: ShimmerPlaceholder(width: double.infinity, height: 80),
        );
      },
    );
  }

  Widget _buildFloatingFooter(ThemeData theme) {
    final double totalPrice =
    _selectedServices.fold(0.0, (sum, service) => sum + service.price);
    final int totalDuration = _selectedServices.fold(
        0, (sum, service) => sum + service.durationMinutes);

    return Container(
      padding: const EdgeInsets.all(AppConstants.padL),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        boxShadow: theme.brightness == Brightness.light
            ? AppColors.lightShadowMd
            : AppColors.darkShadowMd,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppConstants.padL),
          topRight: Radius.circular(AppConstants.padL),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Price:',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    Text(
                      AppFormatters.formatCurrency(totalPrice),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    if (totalDuration > 0)
                      const SizedBox(height: AppConstants.padXXS),
                    Text(
                      'Approx. $totalDuration minutes',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppConstants.padM),
              Expanded(
                flex: 1,
                child: PrimaryGradientButton(
                  // --- CHANGE IS HERE: Update button text ---
                  text: 'NEXT: SELECT TIME',
                  onPressed: _selectedServices.isEmpty
                      ? null
                      : _proceedToTimeslotSelection,
                  iconData: CupertinoIcons.arrow_right,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ServiceSelectionCard extends StatelessWidget {
  final ServiceModel service;
  final bool isSelected;
  final VoidCallback onTap;

  const _ServiceSelectionCard({
    required this.service,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final borderColor = isSelected ? colorScheme.primary : Colors.transparent;
    final backgroundColor =
    isSelected ? colorScheme.primary.withOpacity(0.05) : theme.cardColor;

    return CustomCard(
      onTap: onTap,
      color: backgroundColor,
      padding: EdgeInsets.zero,
      child: Container(
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: borderColor, width: 4.0)),
        ),
        padding: const EdgeInsets.all(AppConstants.padM),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              isSelected
                  ? CupertinoIcons.check_mark_circled_solid
                  : CupertinoIcons.circle,
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.onSurface.withOpacity(0.4),
              size: 28,
            ),
            const SizedBox(width: AppConstants.padL),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppConstants.padXXS),
                  if (service.description.isNotEmpty)
                    Text(
                      service.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
