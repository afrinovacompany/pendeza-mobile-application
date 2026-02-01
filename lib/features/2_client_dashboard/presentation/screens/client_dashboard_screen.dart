import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/config/theme/app_constants.dart';
import '../../../../app/config/theme/adaptive_theme.dart';
import '../../../../app/config/app_router.dart';
import '../../../../app/services/service_locator.dart';
import '../../../../app/services/local_storage_service.dart';
import '../../../../shared/models/category_data.dart';
import '../../../../shared/models/salon_model.dart';
import '../../../../shared/models/promotion_model.dart';
import '../../../../shared/widgets/salon_card.dart';
import '../../../../shared/widgets/loading_indicator.dart';

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
          create: (context) => sl<AppointmentsBloc>()..add(FetchAppointmentsRequested()),
        ),
        BlocProvider(
          create: (context) => sl<PromotionsBloc>()..add(LoadDashboardPromotions()),
        ),
      ],
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _handleRefresh,
            color: theme.colorScheme.primary,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // ════════════════════════════════════════════════════════
                // 1. CLEAN HEADER (No Overlay - Handles Guest Mode Inside)
                // ════════════════════════════════════════════════════════
                const SliverToBoxAdapter(
                  child: DashboardHeader(),
                ),

                // Spacing after header
                const SliverToBoxAdapter(child: SizedBox(height: AppConstants.padM)),

                // ════════════════════════════════════════════════════════
                // 🔥 2. WALLET BALANCE CARD
                // ════════════════════════════════════════════════════════
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppConstants.padL),
                    child: WalletBalanceCard(),
                  ),
                ),

                // Spacing after wallet card
                const SliverToBoxAdapter(child: SizedBox(height: AppConstants.padL)),

                // ════════════════════════════════════════════════════════
                // 3. UPCOMING APPOINTMENT (Priority Visibility)
                // ════════════════════════════════════════════════════════
                SliverToBoxAdapter(
                  child: _buildUpcomingAppointment(context, theme),
                ),

                // ════════════════════════════════════════════════════════
                // 4. QUICK ACTIONS BAR
                // ════════════════════════════════════════════════════════
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppConstants.padL,
                    ),
                    child: QuickActionsBar(
                      onActionTap: (action) {
                        if (action == 'favorites') context.go(AppRoutes.clientFavorites);
                        if (action == 'near_me') context.go(AppRoutes.clientDiscover);
                        if (action == 'offers') {
                          // Could scroll to promotions section
                        }
                      },
                    ),
                  ),
                ),

                // ════════════════════════════════════════════════════════
                // 5. PROMOTIONS CAROUSEL (Hero Section)
                // ════════════════════════════════════════════════════════
                SliverToBoxAdapter(
                  child: _buildPromotionsSection(context, theme),
                ),

                // Spacing before categories
                const SliverToBoxAdapter(child: SizedBox(height: AppConstants.padXL)),

                // ════════════════════════════════════════════════════════
                // 6. CATEGORIES GRID WITH SECTION HEADER
                // ════════════════════════════════════════════════════════
                SliverToBoxAdapter(
                  child: _buildCategoriesSection(context, theme),
                ),

                // Large spacing before salons
                const SliverToBoxAdapter(child: SizedBox(height: 32)),

                // ════════════════════════════════════════════════════════
                // 7. RECOMMENDED SALONS WITH SECTION HEADER
                // ════════════════════════════════════════════════════════
                SliverToBoxAdapter(
                  child: _buildSectionHeader(
                    context,
                    theme,
                    // Key: "client.dashboard.recommended"
                    title: 'client.dashboard.recommended'.tr(),
                    // Key: "client.dashboard.see_all"
                    actionLabel: 'client.dashboard.see_all'.tr(),
                    onActionTap: () => context.go(AppRoutes.clientDiscover),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: AppConstants.padM)),

                // ════════════════════════════════════════════════════════
                // 8. SALONS HORIZONTAL LIST
                // ════════════════════════════════════════════════════════
                SliverToBoxAdapter(
                  child: _buildSalonsCarousel(context),
                ),

                // Bottom padding for navigation bar
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SECTION BUILDERS - Clean, Organized, Reusable
  // ══════════════════════════════════════════════════════════════════════════

  /// Upcoming appointment with better visual hierarchy
  Widget _buildUpcomingAppointment(BuildContext context, ThemeData theme) {
    return BlocBuilder<AppointmentsBloc, AppointmentsState>(
      builder: (context, state) {
        if (state is AppointmentsLoaded && state.upcomingAppointments.isNotEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section label
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppConstants.padL),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 20,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Key: "client.dashboard.up_next"
                    Text(
                      'client.dashboard.up_next'.tr(),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppConstants.padM),

              // Appointment card
              UpcomingAppointmentWidget(
                appointmentWithDetails: state.upcomingAppointments.first,
                onTap: () => context.go(AppRoutes.clientBookings),
              ),

              const SizedBox(height: AppConstants.padXL),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  /// Promotions section with elegant presentation
  Widget _buildPromotionsSection(BuildContext context, ThemeData theme) {
    return BlocBuilder<PromotionsBloc, PromotionsState>(
      builder: (context, state) {
        if (state is PromotionsLoading) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppConstants.padL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Shimmer for section title
                Container(
                  width: 150,
                  height: 24,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: AppConstants.padM),
                // Shimmer for carousel
                const ShimmerPlaceholder.rectangular(
                  height: 200,
                  width: double.infinity,
                ),
              ],
            ),
          );
        }

        if (state is PromotionsLoaded && state.promotions.isNotEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section header with badge
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppConstants.padL),
                child: Row(
                  children: [
                    Icon(
                      Icons.local_offer_rounded,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    // Key: "client.dashboard.special_offers"
                    Text(
                      'client.dashboard.special_offers'.tr(),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${state.promotions.length}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppConstants.padM),

              // Carousel
              PromotionCarousel(
                promotions: state.promotions,
                onPromotionTap: _handlePromotionTap,
                height: 200,
              ),
            ],
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  /// Categories section with modern layout
  Widget _buildCategoriesSection(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppConstants.padL),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.category_rounded,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Key: "client.dashboard.browse_categories"
                  Text(
                    'client.dashboard.browse_categories'.tr(),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: AppConstants.padL),

        // Categories grid
        CategoryGridWidget(
          categories: CategoriesData.allCategories,
          onCategorySelected: _handleCategorySelected,
          showAll: false,
        ),

        // "View All" button with enhanced styling
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppConstants.padL,
            AppConstants.padM,
            AppConstants.padL,
            0,
          ),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                context.push(AppRoutes.clientCategories);
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: theme.colorScheme.outline.withOpacity(0.3),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              icon: Icon(
                Icons.grid_view_rounded,
                size: 18,
                color: theme.colorScheme.onSurface,
              ),
              // Key: "client.dashboard.view_all_categories"
              label: Text(
                'client.dashboard.view_all_categories'.tr(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Reusable section header component
  Widget _buildSectionHeader(
      BuildContext context,
      ThemeData theme, {
        required String title,
        String? actionLabel,
        VoidCallback? onActionTap,
        IconData? icon,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.padL),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
              ],
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (actionLabel != null && onActionTap != null)
            TextButton(
              onPressed: onActionTap,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(actionLabel),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                  ),
                ],
              ),
            ),
        ],
      ),
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

          return SizedBox(
            height: 290,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.padL,
              ),
              itemCount: state.allSalons.length,
              separatorBuilder: (context, index) => const SizedBox(
                width: AppConstants.padM,
              ),
              itemBuilder: (context, index) {
                final salon = state.allSalons[index];
                return SalonCard(
                  salon: salon,
                  width: 250,
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
    return SizedBox(
      height: 290,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.padL),
        itemCount: 3,
        separatorBuilder: (context, index) => const SizedBox(
          width: AppConstants.padM,
        ),
        itemBuilder: (context, index) {
          return const ShimmerPlaceholder.rectangular(
            width: 250,
            height: 290,
          );
        },
      ),
    );
  }

  /// Empty state when no salons available
  Widget _buildEmptySalonsState(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 200,
      margin: const EdgeInsets.symmetric(horizontal: AppConstants.padL),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.store_outlined,
              size: 48,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 12),
            // Key: "client.dashboard.no_salons_title"
            Text(
              'client.dashboard.no_salons_title'.tr(),
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 8),
            // Key: "client.dashboard.no_salons_msg"
            Text(
              'client.dashboard.no_salons_msg'.tr(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.4),
              ),
            ),
          ],
        ),
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
        if (promotion.actionValue != null && promotion.actionValue!.isNotEmpty) {
          context.go(AppRoutes.clientDiscover, extra: promotion.actionValue);
        } else {
          context.go(AppRoutes.clientDiscover);
        }
        break;

      case PromotionAction.openSalon:
        if (promotion.actionValue != null && promotion.actionValue!.isNotEmpty) {
          context.push(
            AppRoutes.salonDetail.replaceFirst(':salonId', promotion.actionValue!),
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
    context.push(
      AppRoutes.salonDetail.replaceFirst(':salonId', salon.id),
      extra: salon,
    );
  }

  Future<void> _handleRefresh() async {
    context.read<DiscoveryBloc>().add(const RefreshSalons());
    context.read<PromotionsBloc>().add(RefreshPromotions());
  }
}