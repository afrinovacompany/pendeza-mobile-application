

import 'package:easy_localization/easy_localization.dart';
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
import '../../../../shared/widgets/custom_snackbar.dart';
import '../../../../app/utils/navigation_guard.dart';

class ServiceSelectionScreen extends StatefulWidget {
  final String salonName;

  const ServiceSelectionScreen({
    super.key,
    required this.salonName,
  });

  @override
  State<ServiceSelectionScreen> createState() => _ServiceSelectionScreenState();
}

class _ServiceSelectionScreenState extends State<ServiceSelectionScreen>
    with SingleTickerProviderStateMixin, NavigationGuard {
  final Set<ServiceModel> _selectedServices = {};
  late AnimationController _pulseController;
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    final currentState = context.read<BookingBloc>().state;
    if (currentState is BookingInProgress) {
      _selectedServices.addAll(currentState.selectedServices);
    }

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.offset > 10 && !_isScrolled) {
      setState(() => _isScrolled = true);
    } else if (_scrollController.offset <= 10 && _isScrolled) {
      setState(() => _isScrolled = false);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _toggleServiceSelection(ServiceModel service) {
    setState(() {
      if (_selectedServices.contains(service)) {
        _selectedServices.remove(service);
      } else {
        _selectedServices.add(service);
      }
    });
  }

  void _proceedToTimeSelection() {
    if (_selectedServices.isEmpty) {
      CustomSnackBar.show(
        context,
        message: 'client.booking.error_no_service'.tr(),
        type: SnackBarType.warning,
      );
      return;
    }

    // Prevent double navigation on rapid button taps
    guardedNavigate(() {
      context.read<BookingBloc>().add(ServicesSelected(_selectedServices.toList()));

      final currentState = context.read<BookingBloc>().state;
      if (currentState is BookingInProgress) {
        final salonId = currentState.salon.id;
        context.push(AppRoutes.timeslotSelection.replaceFirst(':salonId', salonId));
      } else {
        CustomSnackBar.show(
          context,
          message: 'client.booking.error_process_lost'.tr(),
          type: SnackBarType.error,
        );
        context.pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: _isScrolled ? 4 : 0,
        backgroundColor: _isScrolled
            ? theme.appBarTheme.backgroundColor
            : Colors.transparent,
        title: AnimatedOpacity(
          opacity: _isScrolled ? 1.0 : 0.0,
          duration: AppConstants.durationFast,
          child: Text(widget.salonName),
        ),
      ),
      body: BlocBuilder<BookingBloc, BookingState>(
        builder: (context, state) {
          if (state is BookingInProgress) {
            if (state.status == BookingStatus.loadingServices) {
              return _buildLoadingState();
            }
            if ((state.status == BookingStatus.selectingServices ||
                state.status == BookingStatus.selectingTime ||
                state.status == BookingStatus.reviewing) &&
                state.availableServices.isEmpty) {
              return EmptyStateWidget.notFound(
                message: "client.booking.empty_services".tr(),
              );
            }
            if (state.status == BookingStatus.selectingServices ||
                state.status == BookingStatus.selectingTime ||
                state.status == BookingStatus.reviewing) {
              return Stack(
                children: [
                  // Gradient background
                  _buildGradientBackground(theme),
                  // Content
                  CustomScrollView(
                    controller: _scrollController,
                    slivers: [
                      // Hero header
                      _buildHeroHeader(theme),
                      // Service list
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(
                          AppConstants.padL,
                          AppConstants.padM,
                          AppConstants.padL,
                          180,
                        ),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                                (context, index) {
                              final service = state.availableServices[index];
                              final isSelected = _selectedServices.contains(service);
                              return TweenAnimationBuilder<double>(
                                duration: Duration(milliseconds: 150 + (index * 50)),
                                tween: Tween(begin: 0.0, end: 1.0),
                                builder: (context, value, child) {
                                  return Transform.translate(
                                    offset: Offset(0, 20 * (1 - value)),
                                    child: Opacity(
                                      opacity: value,
                                      child: child,
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: AppConstants.padM),
                                  child: _ServiceSelectionCard(
                                    service: service,
                                    isSelected: isSelected,
                                    onTap: () => _toggleServiceSelection(service),
                                  ),
                                ),
                              );
                            },
                            childCount: state.availableServices.length,
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Floating footer
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: _buildEnhancedFooter(theme),
                  ),
                ],
              );
            }
            return _buildLoadingState();
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

  Widget _buildGradientBackground(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.03),
            theme.scaffoldBackgroundColor,
          ],
          stops: const [0.0, 0.3],
        ),
      ),
    );
  }

  Widget _buildHeroHeader(ThemeData theme) {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppConstants.padL,
          kToolbarHeight + 60,
          AppConstants.padL,
          AppConstants.padL,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.salonName,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: AppConstants.padXS),
            Text(
              'client.booking.select_services_header'.tr(),
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
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

  Widget _buildEnhancedFooter(ThemeData theme) {
    final double totalPrice =
    _selectedServices.fold(0.0, (sum, service) => sum + service.price);
    final int totalDuration = _selectedServices.fold(
        0, (sum, service) => sum + service.durationMinutes);
    final hasSelection = _selectedServices.isNotEmpty;

    return AnimatedContainer(
      duration: AppConstants.durationMedium,
      curve: Curves.easeOutCubic,
      margin: hasSelection
          ? const EdgeInsets.all(AppConstants.padL)
          : EdgeInsets.zero,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: hasSelection
            ? BorderRadius.circular(AppConstants.radiusValL)
            : const BorderRadius.only(
          topLeft: Radius.circular(AppConstants.radiusValL),
          topRight: Radius.circular(AppConstants.radiusValL),
        ),
        boxShadow: theme.brightness == Brightness.light
            ? AppColors.lightShadowLg
            : AppColors.darkShadowLg,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.padL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Selection counter badge
              if (hasSelection)
                Container(
                  margin: const EdgeInsets.only(bottom: AppConstants.padM),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.padM,
                    vertical: AppConstants.padXS,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        CupertinoIcons.checkmark_circle_fill,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: AppConstants.padXS),
                      Text(
                        'client.booking.services_selected'.tr(args: ['${_selectedServices.length}']),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'client.booking.total_price_label'.tr(),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          AppFormatters.formatCurrency(totalPrice),
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        if (totalDuration > 0) ...[
                          const SizedBox(height: 2),
                          Text(
                            'client.booking.approx_duration'
                                .tr(args: ['$totalDuration']),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                        ]
                      ],
                    ),
                  ),
                  const SizedBox(width: AppConstants.padM),
                  Expanded(
                    flex: 3,
                    child: AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: hasSelection
                              ? 1.0 + (_pulseController.value * 0.02)
                              : 1.0,
                          child: child,
                        );
                      },
                      child: PrimaryGradientButton(
                        text: 'client.booking.next_time_btn'.tr(),
                        onPressed:
                        hasSelection ? _proceedToTimeSelection : null,
                        iconData: CupertinoIcons.arrow_right,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceSelectionCard extends StatefulWidget {
  final ServiceModel service;
  final bool isSelected;
  final VoidCallback onTap;

  const _ServiceSelectionCard({
    required this.service,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_ServiceSelectionCard> createState() => _ServiceSelectionCardState();
}

class _ServiceSelectionCardState extends State<_ServiceSelectionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: AppConstants.durationFast,
      value: widget.isSelected ? 1.0 : 0.0,
    );
  }

  @override
  void didUpdateWidget(_ServiceSelectionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected != oldWidget.isSelected) {
      if (widget.isSelected) {
        _scaleController.forward();
      } else {
        _scaleController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedBuilder(
      animation: _scaleController,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + (_scaleController.value * 0.02),
          child: child,
        );
      },
      child: CustomCard(
        onTap: widget.onTap,
        color: widget.isSelected
            ? colorScheme.primary.withValues(alpha: 0.08)
            : theme.cardColor,
        padding: EdgeInsets.zero,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: widget.isSelected
                    ? colorScheme.primary
                    : Colors.transparent,
                width: 4.0,
              ),
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(AppConstants.radiusValL),
              bottomLeft: Radius.circular(AppConstants.radiusValL),
            ),
          ),
          padding: const EdgeInsets.all(AppConstants.padM),
          child: Row(
            children: [
              AnimatedScale(
                scale: widget.isSelected ? 1.0 : 0.9,
                duration: AppConstants.durationFast,
                child: Icon(
                  widget.isSelected
                      ? CupertinoIcons.check_mark_circled_solid
                      : CupertinoIcons.circle,
                  color: widget.isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurface.withValues(alpha: 0.3),
                  size: 28,
                ),
              ),
              const SizedBox(width: AppConstants.padL),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.service.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppConstants.padXXS),
                    Text(
                      '${widget.service.durationMinutes} min • ${AppFormatters.formatCurrency(widget.service.price)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (widget.service.description.isNotEmpty) ...[
                      const SizedBox(height: AppConstants.padXXS),
                      Text(
                        widget.service.description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}