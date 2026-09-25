import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pendeza/app/config/theme/app_constants.dart';
import 'package:pendeza/app/services/service_locator.dart';
import 'package:pendeza/features/2_client_booking/domain/repositories/booking_repository.dart';
import 'package:pendeza/shared/models/salon_model.dart';
import 'package:pendeza/shared/models/service_model.dart';
import 'package:pendeza/features/2_client_discovery/presentation/widgets/salon_overview_tab.dart';

// REVIEWS
import 'package:pendeza/features/3_reviews/presentation/bloc/reviews_bloc.dart';
import 'package:pendeza/features/3_reviews/presentation/bloc/reviews_event.dart';
import 'package:pendeza/features/3_reviews/presentation/widgets/reviews_section.dart';

// BOOKING
import 'package:pendeza/features/2_client_booking/presentation/bloc/booking_bloc.dart';
import 'package:pendeza/features/2_client_booking/presentation/bloc/booking_event.dart';
import 'package:pendeza/app/config/app_router.dart';
import 'package:pendeza/shared/widgets/client_ui.dart';
import '../widgets/salon_hero_appbar.dart';
import '../widgets/salon_services_tab.dart';
import '../widgets/enhanced_booking_bottom_bar.dart';

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

  List<ServiceModel> _services = [];
  bool _servicesLoading = true;
  String? _servicesError;

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
    _loadServices();
  }

  Future<void> _loadServices() async {
    setState(() {
      _servicesLoading = true;
      _servicesError = null;
    });
    try {
      final services =
          await sl<BookingRepository>().getServicesForSalon(widget.salon.id);
      if (!mounted) return;
      setState(() {
        _services = services.where((s) => s.isActive).toList();
        _servicesLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _servicesLoading = false;
        _servicesError = e.toString();
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onServiceTap(dynamic service) {
    // Navigate to service selection with the service pre-selected
    context.read<BookingBloc>().add(StartBooking(widget.salon));
    context.push(
      AppRoutes.serviceSelection.replaceFirst(':salonId', widget.salon.id),
      extra: {'salonName': widget.salon.salonName, 'preselectedService': service},
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // Reviews Bloc - Necessary for the reviews tab and rating aggregation
        BlocProvider(
          create: (_) => sl<ReviewsBloc>()
            ..add(LoadReviews(salonId: widget.salon.id)),
        ),
      ],
      child: Scaffold(
        backgroundColor: ClientTheme.background(context),
        body: NestedScrollView(
          controller: _scrollController,
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              // 1. Clean extracted Hero AppBar with status badge
              SalonHeroAppBar(
                salon: widget.salon,
                scrollOffset: _scrollOffset,
              ),

              // 2. Sticky segmented tab bar
              SliverPersistentHeader(
                pinned: true,
                delegate: _StickyTabBarDelegate(
                  background: ClientTheme.background(context),
                  child: ClientSegmentedTabs(
                    controller: _tabController,
                    labels: [
                      'client.salon_details.tab_overview'.tr(),
                      'client.salon_details.tab_services'.tr(),
                      'client.salon_details.tab_reviews'.tr(),
                    ],
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            controller: _tabController,
            children: [
              // TAB 1: OVERVIEW
              SalonOverviewTab(salon: widget.salon),

              // TAB 2: SERVICES (Enhanced with featured carousel and categories)
              SalonServicesTab(
                salon: widget.salon,
                services: _services,
                isLoading: _servicesLoading,
                error: _servicesError,
                onRetry: _loadServices,
                onServiceTap: _onServiceTap,
              ),

              // TAB 3: REVIEWS
              SingleChildScrollView(
                padding: const EdgeInsets.only(top: AppConstants.padS),
                child: Column(
                  children: [
                    ReviewsSection(salon: widget.salon),
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Enhanced Booking Bottom Bar
        bottomNavigationBar: EnhancedBookingBottomBar(
          salon: widget.salon,
          services: _services,
          servicesLoading: _servicesLoading,
        ),
      ),
    );
  }
}

class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final Color background;

  _StickyTabBarDelegate({required this.child, required this.background});

  static const double _height = 68;

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: background,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(
        horizontal: ClientTheme.gutter,
        vertical: 8,
      ),
      child: child,
    );
  }

  @override
  bool shouldRebuild(_StickyTabBarDelegate oldDelegate) =>
      oldDelegate.background != background || oldDelegate.child != child;
}
