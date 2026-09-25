import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pendeza/app/utils/formatters.dart';
import 'package:pendeza/features/0_auth/presentation/bloc/auth_bloc.dart';
import 'package:pendeza/features/0_auth/presentation/bloc/auth_state.dart';
import 'package:pendeza/features/2_client_booking/presentation/bloc/booking_bloc.dart';
import 'package:pendeza/features/2_client_booking/presentation/bloc/booking_event.dart';
import 'package:pendeza/features/2_client_booking/presentation/bloc/booking_state.dart';
import 'package:pendeza/shared/widgets/client_ui.dart';
import 'package:pendeza/app/config/app_config.dart';
import 'package:pendeza/app/config/app_router.dart';
import '../../../../shared/widgets/custom_snackbar.dart';
import '../../../0_auth/presentation/dialog/auth_prompt_dialog.dart';
import '../../../4_payments/presentation/screens/payment_screen.dart';
import '../../../../app/utils/navigation_guard.dart';
import '../widgets/appoitment_summary_card.dart';
import '../widgets/booking_service_tile.dart';
import '../widgets/booking_step_header.dart';
import '../widgets/booking_summary_footer.dart';
import '../widgets/booking_total_row.dart';

class BookingConfirmationScreen extends StatefulWidget {
  const BookingConfirmationScreen({super.key});

  @override
  State<BookingConfirmationScreen> createState() =>
      _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState extends State<BookingConfirmationScreen>
    with NavigationGuard {
  /// Compute appointmentDateTime from BLoC state's selectedDate + selectedTimeSlot
  DateTime? _getAppointmentDateTime(BookingInProgress state) {
    if (state.selectedDate == null || state.selectedTimeSlot == null) return null;
    try {
      DateTime parsedTime;
      try {
        parsedTime = DateFormat('HH:mm').parse(state.selectedTimeSlot!);
      } catch (_) {
        parsedTime = DateFormat.jm().parse(state.selectedTimeSlot!);
      }
      return DateTime(
        state.selectedDate!.year,
        state.selectedDate!.month,
        state.selectedDate!.day,
        parsedTime.hour,
        parsedTime.minute,
      );
    } catch (_) {
      return null;
    }
  }

  void _handleConfirmBooking(BuildContext context) {
    final authState = context.read<AuthBloc>().state;

    if (authState is GuestMode) {
      AuthPromptDialog.show(
        context,
        featureName: 'booking',
        customMessage: 'client.booking.guest_prompt'.tr(),
        icon: Icons.calendar_month_rounded,
        returnRoute: GoRouterState.of(context).uri.path,
      );
      return;
    }

    context.read<BookingBloc>().add(ConfirmBooking());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ClientTheme.background(context),
      body: SafeArea(
        bottom: false,
        child: BlocConsumer<BookingBloc, BookingState>(
          listener: (context, state) {
            if (state is BookingPaymentRequired) {
              // TEMPORARILY DISABLED - Payments turned off for App Store submission
              // BookingBloc now emits BookingSuccess instead; this path is kept for re-enable.
              if (!AppConfig.paymentsEnabled) return;

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
            final bookingState = state is BookingInProgress ? state : null;
            final header = BookingStepHeader(
              step: 3,
              title: 'client.booking.confirm_title'.tr(),
              subtitle: bookingState?.salon.salonName ?? '',
            );

            // Success / payment hand-off / unknown states: nothing to show
            // while the listener navigates away.
            if (state is! BookingInProgress && state is! BookingFailure ||
                state is BookingFailure && state.isGuestAttempt) {
              return Column(
                children: [
                  header,
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          Text(
                            'common.loading_details'.tr(),
                            style: ClientTheme.caption(context),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }

            if (state is BookingFailure) {
              return Column(
                children: [
                  header,
                  Expanded(
                    child: ClientEmptyState(
                      icon: CupertinoIcons.exclamationmark_circle,
                      title: 'common.oops'.tr(),
                      message: state.error,
                      color: const Color(0xFFEF4444),
                    ),
                  ),
                ],
              );
            }

            final isLoading = bookingState != null &&
                bookingState.status == BookingStatus.processing;
            final services = bookingState?.selectedServices ?? [];
            final salonName = bookingState?.salon.salonName ?? '';
            final appointmentDateTime = bookingState != null
                ? _getAppointmentDateTime(bookingState)
                : null;
            final totalPrice = bookingState?.totalPrice ?? 0.0;
            final totalDuration = bookingState?.totalDurationMinutes ?? 0;

            return Column(
              children: [
                header,
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      ClientTheme.gutter,
                      18,
                      ClientTheme.gutter,
                      24,
                    ),
                    children: [
                      _FadeSlideIn(
                        child: AppointmentSummaryCard(
                          salonName: salonName,
                          appointmentDateTime: appointmentDateTime,
                        ),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        'client.booking.summary_title'.tr(),
                        style: ClientTheme.title(context),
                      ),
                      const SizedBox(height: 12),
                      _FadeSlideIn(
                        delay: 120,
                        child: ClientCard(
                          radius: 24,
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (var i = 0; i < services.length; i++) ...[
                                if (i > 0)
                                  Divider(
                                    height: 1,
                                    color: ClientTheme.border(context),
                                  ),
                                BookingServiceTile(service: services[i]),
                              ],
                              Divider(
                                height: 16,
                                color: ClientTheme.border(context),
                              ),
                              BookingTotalRow(
                                title: 'common.duration'.tr(),
                                value:
                                    '$totalDuration ${'common.min'.tr()}',
                              ),
                              BookingTotalRow(
                                title: 'common.total'.tr(),
                                value: AppFormatters.formatCurrency(totalPrice),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                BookingSummaryFooter(
                  totalPrice: totalPrice,
                  totalDurationMinutes: totalDuration,
                  buttonText: 'client.booking.confirm_btn'.tr(),
                  buttonIcon: CupertinoIcons.checkmark_circle_fill,
                  isButtonLoading: isLoading,
                  onButtonPressed:
                      isLoading ? null : () => _handleConfirmBooking(context),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Fades and slides its child up a little on first build.
class _FadeSlideIn extends StatelessWidget {
  final Widget child;
  final int delay;

  const _FadeSlideIn({required this.child, this.delay = 0});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 450 + delay),
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) => Opacity(
        opacity: value.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, 18 * (1 - value)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}
