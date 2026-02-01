import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pendeza/app/config/theme/app_constants.dart';
import 'package:pendeza/app/utils/formatters.dart';
import 'package:pendeza/app/widgets/adaptive/adaptive_app_bar.dart';
import 'package:pendeza/features/0_auth/presentation/bloc/auth_bloc.dart';
import 'package:pendeza/features/0_auth/presentation/bloc/auth_state.dart';
import 'package:pendeza/features/2_client_booking/presentation/bloc/booking_bloc.dart';
import 'package:pendeza/features/2_client_booking/presentation/bloc/booking_event.dart';
import 'package:pendeza/features/2_client_booking/presentation/bloc/booking_state.dart';
import 'package:pendeza/shared/models/service_model.dart';
import 'package:pendeza/shared/widgets/custom_card.dart';
import 'package:pendeza/shared/widgets/primary_gradient_button.dart';
import 'package:pendeza/app/config/app_router.dart';
import 'package:pendeza/app/config/theme/app_colors.dart';
import '../../../../shared/widgets/custom_snackbar.dart';
import '../../../0_auth/presentation/dialog/auth_prompt_dialog.dart';
import '../../../4_payments/presentation/screens/payment_screen.dart';
import '../../../../app/utils/navigation_guard.dart';

class BookingDetailsArguments {
  final String salonName;
  final List<ServiceModel> services;
  final DateTime appointmentDateTime;

  const BookingDetailsArguments({
    required this.salonName,
    required this.services,
    required this.appointmentDateTime,
  });

  double get totalPrice =>
      services.fold(0.0, (sum, service) => sum + service.price);
  int get totalDuration =>
      services.fold(0, (sum, service) => sum + service.durationMinutes);
}

class BookingConfirmationScreen extends StatefulWidget {
  final BookingDetailsArguments bookingDetails;

  const BookingConfirmationScreen({
    super.key,
    required this.bookingDetails,
  });

  @override
  State<BookingConfirmationScreen> createState() =>
      _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState extends State<BookingConfirmationScreen>
    with SingleTickerProviderStateMixin, NavigationGuard {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _handleConfirmBooking(BuildContext context) {
    final authState = context.read<AuthBloc>().state;

    if (authState is GuestMode) {
      AuthPromptDialog.show(
        context,
        featureName: 'booking',
        customMessage: 'client.booking.guest_prompt'.tr(),
        icon: Icons.calendar_month_rounded,
      );
      return;
    }

    context.read<BookingBloc>().add(ConfirmBooking());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AdaptiveAppBar(
        title: 'client.booking.confirm_title'.tr(),
        elevation: 0,
      ),
      body: BlocConsumer<BookingBloc, BookingState>(
        listener: (context, state) {
          if (state is BookingPaymentRequired) {
            // Prevent double navigation if state emits multiple times
            guardedNavigate(() {
              final authState = context.read<AuthBloc>().state;
              String name = "Client";
              String email = "client@example.com";

              if (authState is Authenticated) {
                name = authState.user.fullName;
                email = authState.user.email;
              }

              context.push(
                AppRoutes.paymentSelection,
                extra: PaymentArguments(
                  appointmentId: state.appointmentId,
                  amount: state.amount,
                  customerName: name,
                  customerEmail: email,
                  salonOwnerId: state.salon.ownerId,
                ),
              );
            });
          } else if (state is BookingSuccess) {
            guardedNavigate(() {
              CustomSnackBar.show(
                context,
                message: 'client.booking.success_msg'.tr(),
                type: SnackBarType.success,
              );
              context.read<BookingBloc>().add(ResetBooking());
              context.go(AppRoutes.clientBookings);
            });
          } else if (state is BookingFailure) {
            if (state.isGuestAttempt) return;

            CustomSnackBar.show(
              context,
              message: state.error,
              type: SnackBarType.error,
            );
          } else if (state is! BookingInProgress &&
              state is! BookingSuccess &&
              state is! BookingFailure &&
              state is! BookingInitial &&
              state is! BookingPaymentRequired) {
            guardedNavigate(() {
              CustomSnackBar.show(
                context,
                message: 'client.booking.interrupted_msg'.tr(),
                type: SnackBarType.warning,
              );
              context.read<BookingBloc>().add(ResetBooking());
              context.go(AppRoutes.clientDiscover);
            });
          }
        },
        builder: (context, state) {
          final isLoading = state is BookingInProgress &&
              state.status == BookingStatus.processing;

          if (state is! BookingInProgress &&
              state is! BookingSuccess &&
              state is! BookingFailure &&
              state is! BookingPaymentRequired) {
            return Center(
              child: isLoading
                  ? const CircularProgressIndicator()
                  : Text('common.loading_details'.tr()),
            );
          }

          if (state is BookingFailure && !state.isGuestAttempt) {
            return Center(child: Text(state.error));
          }

          return Stack(
            children: [
              // Gradient background
              _buildGradientBackground(theme),
              // Content
              Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(
                        AppConstants.padL,
                        AppConstants.padL,
                        AppConstants.padL,
                        140,
                      ),
                      children: [
                        _buildSuccessIndicator(theme),
                        const SizedBox(height: AppConstants.padXL),
                        _buildAppointmentSummaryCard(context, theme),
                        const SizedBox(height: AppConstants.padXL),
                        _buildSectionTitle(
                            context, 'client.booking.summary_title'.tr()),
                        const SizedBox(height: AppConstants.padM),
                        ...widget.bookingDetails.services.map(
                              (service) => TweenAnimationBuilder<double>(
                            duration: Duration(
                                milliseconds:
                                300 + (widget.bookingDetails.services.indexOf(service) * 100)),
                            tween: Tween(begin: 0.0, end: 1.0),
                            builder: (context, value, child) {
                              return Transform.translate(
                                offset: Offset(0, 10 * (1 - value)),
                                child: Opacity(
                                  opacity: value,
                                  child: child,
                                ),
                              );
                            },
                            child: _buildServiceTile(context, service, theme),
                          ),
                        ),
                        const Divider(height: AppConstants.padXL),
                        _buildTotalRow(
                          context,
                          'common.duration'.tr(),
                          'client.booking.est_duration'.tr(
                              args: ['${widget.bookingDetails.totalDuration}']),
                          theme,
                        ),
                      ],
                    ),
                  ),
                  _buildEnhancedFooter(
                      context, theme, widget.bookingDetails.totalPrice, isLoading),
                ],
              ),
            ],
          );
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
            theme.colorScheme.primary.withOpacity(0.05),
            theme.scaffoldBackgroundColor,
          ],
          stops: const [0.0, 0.3],
        ),
      ),
    );
  }

  Widget _buildSuccessIndicator(ThemeData theme) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: Container(
        padding: const EdgeInsets.all(AppConstants.padL),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary.withOpacity(0.2),
              theme.colorScheme.primary.withOpacity(0.05),
            ],
          ),
        ),
        child: Icon(
          CupertinoIcons.check_mark_circled_solid,
          size: 64,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
        letterSpacing: -0.3,
      ),
    );
  }

  Widget _buildAppointmentSummaryCard(BuildContext context, ThemeData theme) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 500),
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
      child: CustomCard(
        padding: const EdgeInsets.all(AppConstants.padL),
        color: theme.colorScheme.primary.withOpacity(0.08),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppConstants.padS),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(AppConstants.radiusValM),
                  ),
                  child: Icon(
                    CupertinoIcons.building_2_fill,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppConstants.padM),
                Expanded(
                  child: Text(
                    widget.bookingDetails.salonName,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.padL),
            _buildDetailRow(
              context,
              theme,
              icon: CupertinoIcons.calendar_today,
              value: DateFormat.yMMMMEEEEd()
                  .format(widget.bookingDetails.appointmentDateTime),
            ),
            const SizedBox(height: AppConstants.padM),
            _buildDetailRow(
              context,
              theme,
              icon: CupertinoIcons.time,
              value: DateFormat.jm()
                  .format(widget.bookingDetails.appointmentDateTime),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, ThemeData theme,
      {required IconData icon, required String value}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppConstants.padXS),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppConstants.radiusValS),
          ),
          child: Icon(icon, size: 18, color: theme.colorScheme.primary),
        ),
        const SizedBox(width: AppConstants.padM),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface.withOpacity(0.9),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildServiceTile(
      BuildContext context, ServiceModel service, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppConstants.padS),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: AppConstants.padM),
                Expanded(
                  child: Text(
                    service.name,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppConstants.padM),
          Text(
            AppFormatters.formatCurrency(service.price),
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(
      BuildContext context, String title, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppConstants.padS),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedFooter(BuildContext context, ThemeData theme,
      double totalPrice, bool isLoading) {
    return AnimatedContainer(
      duration: AppConstants.durationMedium,
      margin: const EdgeInsets.all(AppConstants.padL),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(AppConstants.radiusValL),
        boxShadow: theme.brightness == Brightness.light
            ? AppColors.lightShadowLg
            : AppColors.darkShadowLg,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.padL),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'common.total_label'.tr(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppFormatters.formatCurrency(totalPrice),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
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
                      scale: isLoading
                          ? 1.0
                          : 1.0 + (_pulseController.value * 0.02),
                      child: child,
                    );
                  },
                  child: PrimaryGradientButton(
                    text: 'client.booking.confirm_btn'.tr(),
                    isLoading: isLoading,
                    onPressed:
                    isLoading ? null : () => _handleConfirmBooking(context),
                    iconData: CupertinoIcons.check_mark_circled_solid,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}