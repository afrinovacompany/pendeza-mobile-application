import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pendeza/app/config/theme/app_constants.dart';
import 'package:pendeza/app/services/service_locator.dart';
import 'package:pendeza/shared/models/salon_model.dart';
import 'package:pendeza/features/2_client_discovery/presentation/widgets/salon_overview_tab.dart';

// REVIEWS
import 'package:pendeza/features/3_reviews/presentation/bloc/reviews_bloc.dart';
import 'package:pendeza/features/3_reviews/presentation/bloc/reviews_event.dart';
import 'package:pendeza/features/3_reviews/presentation/widgets/reviews_section.dart';

// BOOKING
import 'package:pendeza/features/2_client_booking/domain/repositories/booking_repository.dart';
import 'package:pendeza/features/2_client_booking/presentation/bloc/booking_bloc.dart';
import 'package:pendeza/features/2_client_booking/presentation/bloc/booking_event.dart';
import 'package:pendeza/shared/models/service_model.dart';
import 'package:pendeza/app/config/app_router.dart';
import 'package:pendeza/app/utils/formatters.dart';
import '../widgets/salon_hero_appbar.dart';
import '../../../../app/utils/navigation_guard.dart';

// PROMOTIONS (Future Integration)
// import 'package:pendeza/features/2_client_dashboard/presentation/bloc/promotion_bloc.dart';

/// The main orchestrator for the Salon Details.
/// Keeps the screen logic separate from the UI components.
class SalonDetailScreen extends StatefulWidget {
  final SalonModel salon;

  const SalonDetailScreen({super.key, required this.salon});

  @override
  State<SalonDetailScreen> createState() => _SalonDetailScreenState();
}

class _SalonDetailScreenState extends State<SalonDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _scrollController.addListener(() {
      if (mounted) {
        setState(() {
          _scrollOffset =
          _scrollController.hasClients ? _scrollController.offset : 0.0;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MultiBlocProvider(
      providers: [
        // Reviews Bloc - Necessary for the reviews tab and rating aggregation
        BlocProvider(
          create: (_) => sl<ReviewsBloc>()
            ..add(LoadReviews(salonId: widget.salon.id)),
        ),
        // Future: Add PromotionsBloc here when we implement the logic
      ],
      child: Scaffold(
        body: NestedScrollView(
          controller: _scrollController,
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              // 1. Clean extracted Hero AppBar
              SalonHeroAppBar(
                salon: widget.salon,
                scrollOffset: _scrollOffset,
              ),

              // 2. Sticky Tab Bar
              SliverPersistentHeader(
                pinned: true,
                delegate: _StickyTabBarDelegate(
                  TabBar(
                    controller: _tabController,
                    indicatorColor: theme.colorScheme.primary,
                    labelColor: theme.colorScheme.primary,
                    unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                    labelStyle: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    tabs: [
                      Tab(text: 'Overview'.tr()),
                      Tab(text: 'Services'.tr()),
                      Tab(text: 'Reviews'.tr()), // Note: Reviews key might clash with common.review if not careful, sticking to string if no specific key
                    ],
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            controller: _tabController,
            children: [
              // TAB 1: OVERVIEW (Extracted & Redesigned)
              SalonOverviewTab(salon: widget.salon),

              // TAB 2: SERVICES (Inline for now - will be extracted next batch)
              _ServicesTabPlaceholder(salon: widget.salon),

              // TAB 3: REVIEWS (Existing widget)
              SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: AppConstants.padL),
                child: Column(
                  children: [
                    ReviewsSection(salon: widget.salon),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Floating Booking Button
        bottomNavigationBar: _BookingBottomBar(salon: widget.salon),
      ),
    );
  }
}

class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _StickyTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final theme = Theme.of(context);
    return Container(
      color: theme.scaffoldBackgroundColor,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_StickyTabBarDelegate oldDelegate) {
    return false;
  }
}

// Temporary placeholder for Services Tab (will be extracted in next batch)
class _ServicesTabPlaceholder extends StatefulWidget {
  final SalonModel salon;
  const _ServicesTabPlaceholder({required this.salon});

  @override
  State<_ServicesTabPlaceholder> createState() => _ServicesTabPlaceholderState();
}

class _ServicesTabPlaceholderState extends State<_ServicesTabPlaceholder> {
  List<ServiceModel> _services = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchServices();
  }

  Future<void> _fetchServices() async {
    try {
      final services = await sl<BookingRepository>().getServicesForSalon(widget.salon.id);
      if (mounted) setState(() { _services = services; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_services.isEmpty) return Center(child: Text("client.salon_details.no_services".tr()));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _services.length,
      itemBuilder: (ctx, i) => ListTile(
        title: Text(_services[i].name),
        trailing: Text(AppFormatters.formatCurrency(_services[i].price)),
        subtitle: Text('client.booking.approx_duration'.tr(args: ['${_services[i].durationMinutes}'])),
      ),
    );
  }
}

// Temporary Booking Bar (will be extracted)
class _BookingBottomBar extends StatelessWidget {
  final SalonModel salon;
  const _BookingBottomBar({required this.salon});

  void _startBooking(BuildContext context) {
    // Prevent double navigation on rapid button taps
    if (!NavigationDebouncer.shouldNavigate('book_now_${salon.id}')) return;

    context.read<BookingBloc>().add(StartBooking(salon));
    context.push(
      AppRoutes.serviceSelection.replaceFirst(':salonId', salon.id),
      extra: {'salonName': salon.salonName},
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: () => _startBooking(context),
          // Key: "client.appointments.book_now" -> "Book Now"
          child: Text("client.appointments.book_now".tr()),
        ),
      ),
    );
  }
}