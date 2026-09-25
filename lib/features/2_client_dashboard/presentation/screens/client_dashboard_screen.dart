import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/config/app_config.dart';
import '../../../../app/config/theme/app_constants.dart';
import '../../../../app/config/app_router.dart';
import '../../../../app/services/service_locator.dart';
import '../../../../app/services/local_storage_service.dart';
import '../../../../shared/models/category_data.dart';
import '../../../../shared/models/salon_model.dart';
import '../../../../shared/models/promotion_model.dart';
import '../../../../shared/widgets/salon_card.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../../shared/widgets/client_ui.dart';

// BLoC Imports
import '../../../2_client_discovery/presentation/bloc/discovery_bloc.dart';
import '../../../2_client_discovery/presentation/bloc/discovery_event.dart';
import '../../../2_client_discovery/presentation/bloc/discovery_state.dart';
import '../../../2_client_appointments/presentation/bloc/appointments_bloc.dart';
import '../../../2_client_appointments/presentation/bloc/appoitment_events.dart';
import '../../../2_client_appointments/presentation/bloc/appoitments_state.dart';

// Auth & Tracking Imports
import '../../../0_auth/presentation/bloc/auth_bloc.dart';
import '../../../0_auth/presentation/bloc/auth_state.dart';
import '../../../../app/services/guest_session_tracker.dart';

import '../bloc/promotion_bloc.dart';
import '../bloc/promotion_event.dart';
import '../bloc/promotion_state.dart';
import '../widgets/promotion_carousel.dart';
import '../widgets/quick_action_bar.dart';
import '../widgets/upcoming_appointment_widget.dart';
import '../widgets/category_grid_widget.dart';
import '../widgets/dashboard_header.dart';
import '../../../wallet/presentation/widgets/wallet_balance_card.dart';

// 🆕 Video Shorts imports
import '../../../video_shorts/presentation/bloc/video_shorts_bloc.dart';
import '../../../video_shorts/presentation/bloc/video_shorts_event.dart';
import '../../../video_shorts/presentation/widgets/video_story_widget.dart';

class ClientDashboardScreen extends StatefulWidget {
  const ClientDashboardScreen({super.key});

  @override
  State<ClientDashboardScreen> createState() => _ClientDashboardScreenState();
}

class _ClientDashboardScreenState extends State<ClientDashboardScreen> {
  late final GuestSessionTracker _sessionTracker;
  bool _isGuest = false;

  @override
  void initState() {
    super.initState();
    context.read<DiscoveryBloc>().add(const LoadSalons());

    _sessionTracker = sl<GuestSessionTracker>();
    final authState = context.read<AuthBloc>().state;
    _isGuest = authState is GuestMode;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create:
              (context) =>
                  sl<AppointmentsBloc>()..add(FetchAppointmentsRequested()),
        ),
        BlocProvider(
          create:
              (context) => sl<PromotionsBloc>()..add(LoadDashboardPromotions()),
        ),
        // 🆕 Add VideoShortsBloc
        BlocProvider(
          create:
              (context) => sl<VideoShortsBloc>()..add(const LoadVideoShorts()),
        ),
      ],
      child: Builder(
        builder: (context) {
          return Scaffold(
            backgroundColor: ClientTheme.background(context),
            body: SafeArea(
              bottom: false,
              child: RefreshIndicator(
                onRefresh: () => _handleRefresh(context),
                color: theme.colorScheme.primary,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    // 1. HERO HEADER (greeting, notifications, search)
                    const SliverToBoxAdapter(child: DashboardHeader()),
                    const SliverToBoxAdapter(child: SizedBox(height: 20)),

                    // 2. VIDEO STORIES
                    const SliverToBoxAdapter(child: VideoStoryWidget()),
                    const SliverToBoxAdapter(child: SizedBox(height: 8)),

                    // TEMPORARILY DISABLED - Payments turned off for App Store submission
                    if (AppConfig.paymentsEnabled) ...[
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: ClientTheme.gutter,
                          ),
                          child: WalletBalanceCard(),
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 24)),
                    ],

                    // 3. UP NEXT
                    SliverToBoxAdapter(
                      child: _buildUpcomingAppointment(context, theme),
                    ),

                    // 4. QUICK ACTIONS
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12, bottom: 28),
                        child: QuickActionsBar(
                          onActionTap: (action) {
                            if (action == 'favorites') {
                              context.go(AppRoutes.clientFavorites);
                            }
                            if (action == 'near_me') {
                              context.go(AppRoutes.clientDiscover);
                            }
                            if (action == 'offers') {
                              // Could scroll to promotions section
                            }
                          },
                        ),
                      ),
                    ),

                    // 5. PROMOTIONS
                    SliverToBoxAdapter(
                      child: _buildPromotionsSection(context, theme),
                    ),

                    // 6. CATEGORIES
                    SliverToBoxAdapter(
                      child: _buildCategoriesSection(context, theme),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 32)),

                    // 7. RECOMMENDED SALONS
                    SliverToBoxAdapter(
                      child: _buildSectionHeader(
                        context,
                        theme,
                        title: 'client.dashboard.recommended'.tr(),
                        actionLabel: 'client.dashboard.see_all'.tr(),
                        onActionTap: () => context.go(AppRoutes.clientDiscover),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 14)),
                    SliverToBoxAdapter(child: _buildSalonsCarousel(context)),

                    // Bottom padding for navigation bar
                    const SliverToBoxAdapter(child: SizedBox(height: 110)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SECTION BUILDERS - Clean, Organized, Reusable
  // ══════════════════════════════════════════════════════════════════════════

  /// Upcoming appointment with better visual hierarchy
  /// Shows both pending-payment and confirmed upcoming appointments
  Widget _buildUpcomingAppointment(BuildContext context, ThemeData theme) {
    return BlocBuilder<AppointmentsBloc, AppointmentsState>(
      builder: (context, state) {
        if (state is AppointmentsLoaded) {
          // Combine pending payment + confirmed upcoming, sorted by start time
          // TEMPORARILY DISABLED - Payments turned off for App Store submission
          final allUpcoming = [
            if (AppConfig.paymentsEnabled) ...state.pendingPaymentAppointments,
            ...state.upcomingAppointments,
          ];
          // Sort by nearest first
          allUpcoming.sort(
            (a, b) =>
                a.appointment.startTime.compareTo(b.appointment.startTime),
          );

          if (allUpcoming.isEmpty) return const SizedBox.shrink();

          final nearest = allUpcoming.first;
          final isPending = nearest.appointment.isPendingPayment;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClientSectionHeader(
                title: 'client.dashboard.up_next'.tr(),
                trailing: (AppConfig.paymentsEnabled && isPending)
                    ? ClientPill(
                        label: 'Pending Payment',
                        color: theme.colorScheme.error,
                      )
                    : null,
              ),
              const SizedBox(height: 14),
              UpcomingAppointmentWidget(
                appointmentWithDetails: nearest,
                onTap: () => context.go(AppRoutes.clientBookings),
              ),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildPromotionsSection(BuildContext context, ThemeData theme) {
    return BlocBuilder<PromotionsBloc, PromotionsState>(
      builder: (context, state) {
        if (state is PromotionsLoading) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(
              ClientTheme.gutter,
              0,
              ClientTheme.gutter,
              28,
            ),
            child: ShimmerPlaceholder.rectangular(
              height: 210,
              borderRadius: BorderRadius.circular(28),
            ),
          );
        }

        if (state is PromotionsLoaded && state.promotions.isNotEmpty) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClientSectionHeader(
                  title: 'client.dashboard.special_offers'.tr(),
                ),
                const SizedBox(height: 10),
                PromotionCarousel(
                  promotions: state.promotions,
                  onPromotionTap: _handlePromotionTap,
                ),
              ],
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildCategoriesSection(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          context,
          theme,
          title: 'client.dashboard.browse_categories'.tr(),
          actionLabel: 'client.dashboard.see_all'.tr(),
          onActionTap: () => context.push(AppRoutes.clientCategories),
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: ClientTheme.gutter),
          child: CategoryGridWidget(
            categories: CategoriesData.allCategories,
            onCategorySelected: _handleCategorySelected,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    ThemeData theme, {
    required String title,
    String? actionLabel,
    VoidCallback? onActionTap,
  }) {
    return ClientSectionHeader(
      title: title,
      actionLabel: actionLabel,
      onAction: onActionTap,
    );
  }

  /// Salons carousel with loading states
  Widget _buildSalonsCarousel(BuildContext context) {
    return BlocBuilder<DiscoveryBloc, DiscoveryState>(
      builder: (context, state) {
        if (state is DiscoveryLoading) {
          return _buildLoadingCarousel();
        }

        if (state is DiscoveryLoaded) {
          if (state.allSalons.isEmpty) {
            return _buildEmptySalonsState(context);
          }

          // Responsive card width based on screen size
          final screenWidth = MediaQuery.of(context).size.width;
          final cardWidth = (screenWidth * 0.68).clamp(230.0, 300.0);

          return SizedBox(
            height: 300,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              padding: const EdgeInsets.symmetric(
                horizontal: ClientTheme.gutter,
              ),
              itemCount: state.allSalons.length,
              separatorBuilder:
                  (context, index) => const SizedBox(width: AppConstants.padM),
              itemBuilder: (context, index) {
                final salon = state.allSalons[index];
                return SalonCard(
                  salon: salon,
                  width: cardWidth,
                  onTap: () => _handleSalonTap(salon),
                );
              },
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  /// Loading shimmer for salons carousel
  Widget _buildLoadingCarousel() {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth * 0.68).clamp(230.0, 300.0);

    return SizedBox(
      height: 300,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: ClientTheme.gutter),
        itemCount: 3,
        separatorBuilder:
            (context, index) => const SizedBox(width: AppConstants.padM),
        itemBuilder: (context, index) {
          return ShimmerPlaceholder.rectangular(
            width: cardWidth,
            height: 300,
            borderRadius: BorderRadius.circular(26),
          );
        },
      ),
    );
  }

  /// Empty state when no salons available
  Widget _buildEmptySalonsState(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: ClientTheme.gutter),
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        color: ClientTheme.inset(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: ClientTheme.border(context)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClientIconTile(
            icon: CupertinoIcons.building_2_fill,
            color: Theme.of(context).colorScheme.primary,
            size: 56,
          ),
          const SizedBox(height: 14),
          Text(
            'client.dashboard.no_salons_title'.tr(),
            textAlign: TextAlign.center,
            style: ClientTheme.heading(context),
          ),
          const SizedBox(height: 4),
          Text(
            'client.dashboard.no_salons_msg'.tr(),
            textAlign: TextAlign.center,
            style: ClientTheme.caption(context),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // EVENT HANDLERS - Smart Navigation & Tracking
  // ══════════════════════════════════════════════════════════════════════════

  void _handlePromotionTap(PromotionModel promotion) {
    if (_isGuest) {
      _sessionTracker.trackFeatureInteraction('promotion_tapped');
    }

    switch (promotion.action) {
      case PromotionAction.openDiscover:
        context.go(AppRoutes.clientDiscover);
        break;

      case PromotionAction.openCategory:
        if (promotion.actionValue != null &&
            promotion.actionValue!.isNotEmpty) {
          context.go(AppRoutes.clientDiscover, extra: promotion.actionValue);
        } else {
          context.go(AppRoutes.clientDiscover);
        }
        break;

      case PromotionAction.openSalon:
        if (promotion.actionValue != null &&
            promotion.actionValue!.isNotEmpty) {
          context.push(
            AppRoutes.salonDetail.replaceFirst(
              ':salonId',
              promotion.actionValue!,
            ),
          );
        }
        break;

      case PromotionAction.openUrl:
        // TODO: Implement url_launcher if needed
        break;

      case PromotionAction.none:
        break;
    }
  }

  void _handleCategorySelected(String categoryId) {
    if (_isGuest) {
      _sessionTracker.trackFeatureInteraction('category_selected');
    }
    context.go(AppRoutes.clientDiscover, extra: categoryId);
  }

  void _handleSalonTap(SalonModel salon) {
    if (_isGuest) {
      _sessionTracker.trackSalonView(salon.id);
      sl<LocalStorageService>().addToBrowsingHistory(salon.id);
    }
    context.push(AppRoutes.salonDetail.replaceFirst(':salonId', salon.id));
  }

  Future<void> _handleRefresh(BuildContext context) async {
    context.read<DiscoveryBloc>().add(const RefreshSalons());
    context.read<PromotionsBloc>().add(RefreshPromotions());
    context.read<VideoShortsBloc>().add(const RefreshVideoShorts());
    context.read<AppointmentsBloc>().add(FetchAppointmentsRequested());
  }
}
