import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pendeza/features/2_client_booking/presentation/bloc/booking_bloc.dart';
import 'package:pendeza/features/2_client_booking/presentation/bloc/booking_event.dart';
import 'package:pendeza/features/2_client_booking/presentation/bloc/booking_state.dart';
import '../../../../app/config/app_router.dart';
import '../../../../app/utils/navigation_guard.dart';
import '../../../../shared/models/service_model.dart';
import '../../../../shared/widgets/client_ui.dart';
import '../../../../shared/widgets/custom_snackbar.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../widgets/booking_step_header.dart';
import '../widgets/booking_summary_footer.dart';
import '../widgets/service_list_tile.dart';

class ServiceSelectionScreen extends StatefulWidget {
  final String salonName;

  /// Service tapped on the salon page; starts out selected.
  final ServiceModel? preselectedService;

  const ServiceSelectionScreen({
    super.key,
    required this.salonName,
    this.preselectedService,
  });

  @override
  State<ServiceSelectionScreen> createState() => _ServiceSelectionScreenState();
}

class _ServiceSelectionScreenState extends State<ServiceSelectionScreen>
    with NavigationGuard {
  final Set<ServiceModel> _selectedServices = {};

  @override
  void initState() {
    super.initState();
    final currentState = context.read<BookingBloc>().state;
    if (currentState is BookingInProgress) {
      _selectedServices.addAll(currentState.selectedServices);
    }
    if (_selectedServices.isEmpty && widget.preselectedService != null) {
      _selectedServices.add(widget.preselectedService!);
    }
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
      context
          .read<BookingBloc>()
          .add(ServicesSelected(_selectedServices.toList()));

      final currentState = context.read<BookingBloc>().state;
      if (currentState is BookingInProgress) {
        final salonId = currentState.salon.id;
        context
            .push(AppRoutes.timeslotSelection.replaceFirst(':salonId', salonId));
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
    return Scaffold(
      backgroundColor: ClientTheme.background(context),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BookingStepHeader(
              step: 1,
              title: 'client.booking.choose_services'.tr(),
              subtitle: widget.salonName,
            ),
            Expanded(
              child: BlocBuilder<BookingBloc, BookingState>(
                builder: (context, state) {
                  if (state is BookingInProgress) {
                    if (state.status == BookingStatus.loadingServices) {
                      return const _LoadingList();
                    }
                    final showsServices =
                        state.status == BookingStatus.selectingServices ||
                            state.status == BookingStatus.selectingTime ||
                            state.status == BookingStatus.reviewing;
                    if (showsServices && state.availableServices.isEmpty) {
                      return ClientEmptyState(
                        icon: CupertinoIcons.scissors,
                        title: 'client.booking.empty_services'.tr(),
                      );
                    }
                    if (showsServices) {
                      return _buildServiceList(state);
                    }
                    return const _LoadingList();
                  }
                  if (state is BookingFailure) {
                    return ClientEmptyState(
                      icon: CupertinoIcons.exclamationmark_circle,
                      title: 'common.oops'.tr(),
                      message: state.error,
                      actionLabel: 'common.retry'.tr(),
                      onAction: () {
                        context.read<BookingBloc>().add(FetchServicesForSalon());
                      },
                      color: const Color(0xFFEF4444),
                    );
                  }
                  return const _LoadingList();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceList(BookingInProgress state) {
    final services = state.availableServices;
    final totalPrice = _selectedServices.fold(
        0.0, (sum, service) => sum + service.effectivePrice);
    final totalDuration = _selectedServices.fold(
        0, (sum, service) => sum + service.durationMinutes);
    final hasSelection = _selectedServices.isNotEmpty;

    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(
              ClientTheme.gutter,
              18,
              ClientTheme.gutter,
              24,
            ),
            physics: const BouncingScrollPhysics(),
            itemCount: services.length + 1,
            separatorBuilder: (context, index) => SizedBox(
              height: index == 0 ? 14 : 12,
            ),
            itemBuilder: (context, index) {
              if (index == 0) {
                return Text(
                  'client.booking.select_services_header'.tr(),
                  style: ClientTheme.body(context).copyWith(
                    color: ClientTheme.textSecondary(context),
                  ),
                );
              }
              final service = services[index - 1];
              return TweenAnimationBuilder<double>(
                duration: Duration(milliseconds: 150 + (index * 40)),
                tween: Tween(begin: 0.0, end: 1.0),
                builder: (context, value, child) => Transform.translate(
                  offset: Offset(0, 16 * (1 - value)),
                  child: Opacity(opacity: value, child: child),
                ),
                child: ServiceSelectionCard(
                  service: service,
                  isSelected: _selectedServices.contains(service),
                  onTap: () => _toggleServiceSelection(service),
                ),
              );
            },
          ),
        ),
        BookingSummaryFooter(
          totalPrice: totalPrice,
          totalDurationMinutes: totalDuration,
          label: hasSelection
              ? 'client.booking.services_selected'
                  .tr(args: ['${_selectedServices.length}'])
              : 'client.booking.total_price_label'.tr(),
          caption: hasSelection
              ? 'client.booking.approx_duration'.tr(args: ['$totalDuration'])
              : null,
          buttonText: 'client.booking.next_time_btn'.tr(),
          buttonIcon: CupertinoIcons.arrow_right,
          onButtonPressed: hasSelection ? _proceedToTimeSelection : null,
        ),
      ],
    );
  }
}

class _LoadingList extends StatelessWidget {
  const _LoadingList();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        ClientTheme.gutter,
        18,
        ClientTheme.gutter,
        24,
      ),
      itemCount: 5,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) =>
          const ShimmerPlaceholder(width: double.infinity, height: 92),
    );
  }
}
