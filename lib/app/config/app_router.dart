import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:pendeza/features/5_admin_panel/presentation/screens/admin_dashboard_screen.dart';

import 'package:pendeza/screens/main_screen.dart';
import 'package:pendeza/screens/splash_screen.dart';

import '../../features/0_auth/presentation/bloc/auth_bloc.dart';
import '../../features/0_auth/presentation/bloc/auth_state.dart';
import '../../features/0_auth/presentation/screens/forgot_password.dart';
import '../../features/0_auth/presentation/screens/login_screen.dart';
import '../../features/0_auth/presentation/screens/otp_screen.dart';
import '../../features/0_auth/presentation/screens/phone_auth_screen.dart';
import '../../features/0_auth/presentation/screens/signup_screen.dart';
import '../../features/1_onboarding/presentation/screens/client_profile_setup_screen.dart';
import '../../features/1_onboarding/presentation/screens/business_type_selection_screen.dart';
import '../../features/1_onboarding/presentation/screens/role_selection_screen.dart';
import '../../features/2_client_appointments/presentation/screens/appointments_screen.dart';

import '../../features/2_client_dashboard/presentation/screens/client_dashboard_screen.dart';
// IMPORT ADDED FOR CATEGORY LIST
import '../../features/2_client_dashboard/presentation/screens/category_list_screen.dart';

import '../../features/2_client_discovery/presentation/screens/discovery_screen.dart';
import '../../features/2_client_discovery/presentation/screens/salon_detail_screen.dart';
import '../../features/2_client_discovery/presentation/screens/salon_gallery_screen.dart';
// UPDATED: Import new ClientProfileScreen instead of old ProfileScreen
import '../../features/2_client_profile/presentation/screens/profile_screen.dart';
// NEW: Import EditProfileScreen
import '../../features/2_client_profile/presentation/screens/edit_profile_screen.dart';
// Add Favorites Screen Import
import '../../features/2_client_favorites/presentation/screens/favorites_screen.dart';
// Add Notifications Screen Import
import '../../features/2_client_notifications/presentation/screens/notifications_screen.dart';

import '../../features/3_owner_management/calendar/presentation/screens/calendar_screen.dart';
import '../../features/3_owner_management/clients/presentation/screens/client_detail_screen.dart';
import '../../features/3_owner_management/clients/presentation/screens/client_list_screen.dart';
import '../../features/3_owner_management/dashboard/presentation/screens/owner_dashboard_screen.dart';
import '../../features/3_owner_management/services/presentation/screens/service_list_screen.dart';
import '../../features/3_owner_profile_screen/owner_profile_screen.dart';
import '../../features/3_owner_management/salon_profile/presentation/screens/salon_profile_screen.dart';
import '../../features/3_reviews/data/models/review_model.dart';
import '../../features/4_payments/presentation/screens/payment_screen.dart';
import '../../features/5_admin_panel/presentation/screens/admin_manage_notification_screen.dart';
import '../../features/5_admin_panel/presentation/screens/admin_manage_salon_screen.dart';
import '../../features/5_admin_panel/presentation/screens/admin_manage_user_screen.dart';
import '../../features/5_admin_panel/presentation/screens/admin_manage_inspiration_screen.dart';
import '../../features/5_admin_panel/presentation/screens/admin_manage_promotion_screen.dart';
import '../../features/5_admin_panel/presentation/widgets/admin_shell_route.dart';
import '../../features/wallet/presentation/screens/transaction_history_screen.dart';
import '../../features/wallet/presentation/screens/wallet_screen.dart';
import '../../screens/debug/salon_import_debug_screen.dart';
import '../../shared/models/salon_model.dart';
import '../services/service_locator.dart';

import '../../features/2_client_booking/presentation/screens/service_selection_screen.dart';
import '../../features/2_client_booking/presentation/screens/timeslot_selection_screen.dart';
import '../../features/2_client_booking/presentation/screens/booking_confirmation_screen.dart';

import 'package:pendeza/features/2_client_booking/domain/repositories/booking_repository.dart';

import '../../shared/models/service_model.dart';
import 'package:pendeza/features/3_owner_management/services/presentation/screens/add_edit_service_screen.dart';
import 'package:pendeza/features/3_owner_management/services/presentation/bloc/services_bloc.dart';
import 'package:pendeza/features/3_owner_inspiration/presentation/screens/inspiration_screen.dart';

import 'package:pendeza/features/3_reviews/presentation/screens/write_review_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';
  static const String phoneAuth = '/phone-auth';
  static const String otp = '/otp';
  static const String roleSelection = '/role-selection';
  static const String clientSetup = '/client-setup';
  static const String ownerSetup = '/owner-setup';


  // Client Routes
  static const String clientHome = '/client/home';
  static const String clientDiscover = '/client/discover';
  static const String clientBookings = '/client/bookings';
  static const String clientProfile = '/client/profile';
  static const String clientFavorites = '/client/favorites';
  // NEW: Edit Profile Route
  static const String editProfile = '/client/edit-profile';

  // Notifications Route
  static const String clientNotifications = '/client/notifications';

  // NEW: Categories Route
  static const String clientCategories = '/client/categories';

  // Wallet Routes (ADDED)
  static const String clientWallet = '/client/wallet';
  static const String walletHistory = '/client/wallet/history';

  // Booking Flow Routes
  static const String salonDetail = '/salon/:salonId';
  static const String salonGallery = '/salon/:salonId/gallery';
  static const String serviceSelection = '/salon/:salonId/services';
  static const String timeslotSelection = '/salon/:salonId/schedule';
  static const String bookingConfirmation = '/salon/:salonId/confirm';

  // Payment Route
  static const String paymentSelection = '/payment';

  // Review Route
  static const String writeReview = '/salon/:salonId/review';

  // Owner Routes
  static const String ownerHome = '/owner/home';
  static const String ownerSchedule = '/owner/schedule';
  static const String ownerClients = '/owner/clients';
  static const String clientDetails = '/owner/clients/:clientId';
  static const String ownerServices = '/owner/services';
  static const String addEditService = 'add-edit-service';
  static const String ownerInspiration = '/owner/inspiration';
  static const String ownerAnalytics = '/owner/analytics';
  static const String ownerProfile = '/owner/profile';
  static const String ownerSalonProfile = '/owner/salon-profile';

  // Admin Routes
  static const String adminHome = '/admin/home';
  static const String adminManageUsers = '/admin/users';
  static const String adminManageSalons = '/admin/salons';
  static const String adminManageInspiration = '/admin/inspiration';
  static const String adminManagePromotions = '/admin/promotions';
  static const String adminManageNotifications = '/admin/notifications';
// In AppRoutes class

}

class AppRouter {
  static final AuthBloc _authBloc = sl<AuthBloc>();

  static final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
  static final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

  static final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    refreshListenable: GoRouterRefreshStream(_authBloc.stream),
    redirect: (BuildContext context, GoRouterState state) {
      final authState = _authBloc.state;
      final currentLocation = state.matchedLocation;
      final loggingIn = currentLocation == AppRoutes.login ||
          currentLocation == AppRoutes.signup ||
          currentLocation == AppRoutes.forgotPassword ||
          currentLocation == AppRoutes.phoneAuth ||
          currentLocation == AppRoutes.otp;
      final onboarding = currentLocation == AppRoutes.roleSelection ||
          currentLocation == AppRoutes.clientSetup ||
          currentLocation == AppRoutes.ownerSetup;
      final splashing = currentLocation == AppRoutes.splash;

      final bool isAdminArea = currentLocation.startsWith('/admin');
      final bool isClientArea = currentLocation.startsWith('/client');
      final bool isSalonArea = currentLocation.startsWith('/salon');

      final isAuthenticated = authState is Authenticated;
      final needsRole = authState is RoleSelectionRequired;
      final needsClientSetup = authState is ClientProfileSetupRequired;
      final needsOwnerSetup = authState is OwnerProfileSetupRequired;
      final isUnauthenticated = authState is Unauthenticated;
      final isGuestMode = authState is GuestMode;
      final needsAuth = authState is AuthenticationRequired;

      if (splashing && (authState is AuthInitial || authState is AuthLoading)) {
        return null;
      }

      // Handle guest mode
      if (isGuestMode) {
        if (splashing) return AppRoutes.clientHome;
        if (loggingIn || onboarding) return null;
        if (isClientArea || isSalonArea || currentLocation == AppRoutes.splash) {
          return null;
        }
        return AppRoutes.clientHome;
      }

      if (needsAuth) {
        return loggingIn ? null : AppRoutes.login;
      }

      if (isUnauthenticated) {
        return loggingIn || splashing ? null : AppRoutes.login;
      }
      if (needsRole) {
        return splashing || currentLocation == AppRoutes.roleSelection
            ? null
            : AppRoutes.roleSelection;
      }
      if (needsClientSetup) {
        return splashing || currentLocation == AppRoutes.clientSetup
            ? null
            : AppRoutes.clientSetup;
      }
      if (needsOwnerSetup) {
        return splashing || currentLocation == AppRoutes.ownerSetup
            ? null
            : AppRoutes.ownerSetup;
      }
      if (isAuthenticated) {
        final userRole = authState.user.role;

        // ADMIN REDIRECT LOGIC
        if (authState.user.isAdmin) {
          if (loggingIn || onboarding || splashing) {
            return AppRoutes.adminHome;
          }
          // Only redirect admin if they try to leave admin area
          if (!isAdminArea) {
            return AppRoutes.adminHome;
          }
          return null; // Admin already in admin area, allow navigation
        }

        // BLOCK NON-ADMINS FROM ADMIN AREA
        if (isAdminArea) {
          // Non-admin trying to access admin? Redirect them home
          return userRole == 'owner'
              ? AppRoutes.ownerHome
              : AppRoutes.clientHome;
        }

        // INITIAL REDIRECT AFTER LOGIN/ONBOARDING/SPLASH
        if (loggingIn || onboarding || splashing) {
          return userRole == 'owner'
              ? AppRoutes.ownerHome
              : AppRoutes.clientHome;
        }

        // ✅ CRITICAL: Allow authenticated users to navigate freely in their areas
        // No redirect needed for:
        // - Clients in /client/* routes (including /client/wallet)
        // - Owners in /owner/* routes
        // - Anyone in /salon/* routes (booking flow)
        return null;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        pageBuilder: (context, state) =>
            _buildPage(context, state, const SplashScreen()),
      ),
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (context, state) =>
            _buildPage(context, state, const LoginScreen()),
      ),
      GoRoute(
        path: AppRoutes.signup,
        pageBuilder: (context, state) =>
            _buildPage(context, state, const SignUpScreen()),
      ),
      GoRoute(
        path: AppRoutes.phoneAuth,
        pageBuilder: (context, state) =>
            _buildPage(context, state, const PhoneAuthScreen()),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        pageBuilder: (context, state) =>
            _buildPage(context, state, const ForgotPasswordScreen()),
      ),

      GoRoute(
        path: AppRoutes.otp,
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          final verificationId = extra['verificationId'] as String? ?? '';
          final phoneNumber = extra['phoneNumber'] as String? ?? '';

          if (verificationId.isEmpty) {
            return _buildPage(context, state, const PhoneAuthScreen());
          }

          return _buildPage(
            context,
            state,
            OtpScreen(
              verificationId: verificationId,
              phoneNumber: phoneNumber,
            ),
          );
        },
      ),

      GoRoute(
        path: AppRoutes.roleSelection,
        pageBuilder: (context, state) =>
            _buildPage(context, state, const RoleSelectionScreen()),
      ),
      GoRoute(
        path: AppRoutes.clientSetup,
        pageBuilder: (context, state) =>
            _buildPage(context, state, const ClientProfileSetupScreen()),
      ),
      GoRoute(
        path: AppRoutes.ownerSetup,
        pageBuilder: (context, state) =>
            _buildPage(context, state, const BusinessTypeSelectionScreen()),
      ),

      // BOOKING FLOW ROUTES
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.salonDetail,
        pageBuilder: (context, state) {
          final salonId = state.pathParameters['salonId'] ?? '';
          final salonExtra = state.extra as SalonModel?;

          return _buildPage(
            context,
            state,
            SalonDeepLinkResolver(
              salonId: salonId,
              initialSalon: salonExtra,
            ),
          );
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.salonGallery,
        pageBuilder: (context, state) {
          final salon = state.extra as SalonModel?;
          if (salon == null) {
            return _buildPage(
              context,
              state,
              const Scaffold(body: Center(child: Text('Error: Salon not found'))),
            );
          }
          return _buildPage(
              context,
              state,
              SalonGalleryScreen(salon: salon)
          );
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.writeReview,
        name: 'write-review',
        pageBuilder: (context, state) {
          final extra = state.extra;
          SalonModel? salon;
          ReviewModel? review;

          if (extra is SalonModel) {
            salon = extra;
          } else if (extra is Map<String, dynamic>) {
            salon = extra['salon'] as SalonModel?;
            review = extra['review'] as ReviewModel?;
          }

          if (salon == null) {
            return _buildPage(
              context,
              state,
              const Scaffold(body: Center(child: Text('Error: Salon data missing'))),
            );
          }

          return _buildPage(
            context,
            state,
            WriteReviewScreen(
              salon: salon,
              existingReview: review,
            ),
          );
        },
      ),

      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.serviceSelection,
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return _buildPage(
              context,
              state,
              ServiceSelectionScreen(
                salonName: extra['salonName'] ?? 'Salon',
              ));
        },
      ),

      GoRoute(
        path: '/owner/import-debug',
        name: 'import-debug',
        builder: (context, state) => const SalonImportDebugScreen(),
      ),

      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.timeslotSelection,
        pageBuilder: (context, state) {
          return _buildPage(context, state, const TimeslotSelectionScreen());
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.bookingConfirmation,
        pageBuilder: (context, state) {
          final details = state.extra as BookingDetailsArguments?;
          if (details == null) {
            return _buildPage(
                context,
                state,
                Scaffold(
                    appBar: AppBar(),
                    body: const Center(
                        child: Text("Error: Booking details missing"))));
          }
          return _buildPage(
              context,
              state,
              BookingConfirmationScreen(
                bookingDetails: details,
              ));
        },
      ),

      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.paymentSelection,
        pageBuilder: (context, state) {
          final args = state.extra as PaymentArguments?;
          if (args == null) {
            return _buildPage(context, state, const Scaffold(body: Center(child: Text("Error: Missing payment info"))));
          }
          return _buildPage(
            context,
            state,
            PaymentMethodSelectionScreen(args: args),
          );
        },
      ),

      // NEW: Edit Profile Route (uses root navigator for full-screen navigation)
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.editProfile,
        pageBuilder: (context, state) =>
            _buildPage(context, state, const EditProfileScreen()),
      ),

      // ADMIN SHELL ROUTE (Wallet routes REMOVED from here)
      ShellRoute(
        pageBuilder: (context, state, child) => _buildPage(
          context,
          state,
          AdminShellRoute(child: child),
        ),
        routes: [
          GoRoute(
            path: AppRoutes.adminHome,
            name: AppRoutes.adminHome,
            pageBuilder: (context, state) =>
                _buildPage(context, state, const AdminDashboardScreen()),
          ),
          GoRoute(
            path: AppRoutes.adminManageUsers,
            name: AppRoutes.adminManageUsers,
            pageBuilder: (context, state) =>
                _buildPage(context, state, const AdminManageUsersScreen()),
          ),
          GoRoute(
            path: AppRoutes.adminManageSalons,
            name: AppRoutes.adminManageSalons,
            pageBuilder: (context, state) =>
                _buildPage(context, state, const AdminManageSalonsScreen()),
          ),
          GoRoute(
            path: AppRoutes.adminManageInspiration,
            name: AppRoutes.adminManageInspiration,
            pageBuilder: (context, state) =>
                _buildPage(context, state, const AdminManageInspirationScreen()),
          ),
          GoRoute(
            path: AppRoutes.adminManagePromotions,
            name: AppRoutes.adminManagePromotions,
            pageBuilder: (context, state) =>
                _buildPage(context, state, const AdminManagePromotionsScreen()),
          ),
          // ✅ CORRECT - Fixed code
          GoRoute(
            path: AppRoutes.adminManageNotifications,  // Use the constant: '/admin/notifications'
            name: AppRoutes.adminManageNotifications,
            pageBuilder: (context, state) =>
                _buildPage(context, state, const AdminManageNotificationsScreen()),
          ),
        ],
      ),

      // CLIENT/OWNER SHELL ROUTE (Wallet routes MOVED here)
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        pageBuilder: (context, state, child) {
          final authState = _authBloc.state;
          String userRole = 'client';
          if (authState is Authenticated) {
            userRole = authState.user.role ?? 'client';
          } else if (authState is GuestMode) {
            userRole = 'client';
          }
          return MaterialPage(
            child: MainScreen(userRole: userRole, child: child),
          );
        },
        routes: [
          // Client Tabs
          GoRoute(
            path: AppRoutes.clientHome,
            pageBuilder: (context, state) =>
                _buildPage(context, state, const ClientDashboardScreen()),
          ),
          GoRoute(
            path: AppRoutes.clientDiscover,
            pageBuilder: (context, state) {
              final categoryId = state.extra as String?;
              return _buildPage(
                  context,
                  state,
                  DiscoveryScreen(initialCategoryId: categoryId)
              );
            },
          ),
          GoRoute(
            path: AppRoutes.clientBookings,
            pageBuilder: (context, state) =>
                _buildPage(context, state, const AppointmentsScreen()),
          ),
          // UPDATED: Use new ClientProfileScreen instead of old ProfileScreen
          GoRoute(
            path: AppRoutes.clientProfile,
            pageBuilder: (context, state) =>
                _buildPage(context, state, const ClientProfileScreen()),
          ),
          GoRoute(
            path: AppRoutes.clientFavorites,
            pageBuilder: (context, state) =>
                _buildPage(context, state, const FavoritesScreen()),
          ),
          GoRoute(
            path: AppRoutes.clientNotifications,
            pageBuilder: (context, state) =>
                _buildPage(context, state, const NotificationsScreen()),
          ),

          // NEW: Category List Route (Added as a top-level pushing over the shell or inside based on preference,
          // but typically "See All" screens cover the tab bar or exist within the stack.
          // Here we place it inside the client shell routes so it feels part of the flow,
          // or use parentNavigatorKey: _rootNavigatorKey if you want it full screen.
          // Based on typical "See All" behavior, I will add it here within the client shell context,
          // but typically secondary screens in GoRouter ShellRoutes need to be siblings or children.
          // I will make it a sibling of the tabs to ensure proper navigation stack).
          GoRoute(
            path: AppRoutes.clientCategories,
            pageBuilder: (context, state) =>
                _buildPage(context, state, const CategoryListScreen()),
          ),

          // ✅ WALLET ROUTES MOVED HERE (from admin shell to client shell)
          GoRoute(
            path: AppRoutes.clientWallet,
            name: 'wallet',
            pageBuilder: (context, state) =>
                _buildPage(context, state, const WalletScreen()),
          ),
          GoRoute(
            path: AppRoutes.walletHistory,
            name: 'wallet-history',
            pageBuilder: (context, state) =>
                _buildPage(context, state, const TransactionHistoryScreen()),
          ),

          // Owner Tabs
          GoRoute(
            path: AppRoutes.ownerHome,
            pageBuilder: (context, state) =>
                _buildPage(context, state, const OwnerDashboardScreen()),
          ),
          GoRoute(
            path: AppRoutes.ownerSchedule,
            pageBuilder: (context, state) =>
                _buildPage(context, state, const CalendarScreen()),
          ),
          GoRoute(
            path: AppRoutes.ownerInspiration,
            pageBuilder: (context, state) =>
                _buildPage(context, state, const InspirationScreen()),
          ),
          GoRoute(
            path: AppRoutes.ownerAnalytics,
            pageBuilder: (context, state) => _buildPage(
                context,
                state,
                const Scaffold(
                    body: Center(child: Text('Analytics Screen')))),
          ),
          ShellRoute(
            pageBuilder: (context, state, child) {
              return MaterialPage(
                child: BlocProvider(
                  create: (context) => sl<ServicesBloc>(),
                  child: child,
                ),
              );
            },
            routes: [
              GoRoute(
                path: AppRoutes.ownerServices,
                pageBuilder: (context, state) {
                  return _buildPage(context, state, const ServiceListScreen());
                },
                routes: [
                  GoRoute(
                    path: AppRoutes.addEditService,
                    pageBuilder: (context, state) {
                      final service = state.extra as ServiceModel?;
                      return _buildPage(context, state,
                          AddEditServiceScreen(service: service));
                    },
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.ownerClients,
            pageBuilder: (context, state) =>
                _buildPage(context, state, const ClientsListScreen()),
          ),
          GoRoute(
            path: AppRoutes.clientDetails,
            pageBuilder: (context, state) {
              final clientId = state.pathParameters['clientId'];
              if (clientId == null) {
                return _buildPage(
                    context,
                    state,
                    Scaffold(
                      appBar: AppBar(title: const Text('Error')),
                      body: const Center(child: Text('Client ID not found')),
                    ));
              }
              return _buildPage(
                  context, state, ClientDetailsScreen(clientId: clientId));
            },
          ),
          GoRoute(
            path: AppRoutes.ownerProfile,
            pageBuilder: (context, state) =>
                _buildPage(context, state, const OwnerProfileScreen()),
          ),



          GoRoute(
            path: AppRoutes.ownerSalonProfile,
            pageBuilder: (context, state) =>
                _buildPage(context, state, const SalonProfileScreen()),
          ),
        ],
      ),
    ],
    errorPageBuilder: (context, state) => _buildPage(
      context,
      state,
      Scaffold(
        appBar: AppBar(title: const Text('Page Not Found')),
        body: Center(child: Text('Error: ${state.error}')),
      ),
    ),
  );

  static Page<dynamic> _buildPage(
      BuildContext context, GoRouterState state, Widget child) {
    return MaterialPage(child: child, key: state.pageKey);
  }
}

class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription =
        stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

class SalonDeepLinkResolver extends StatefulWidget {
  final String salonId;
  final SalonModel? initialSalon;

  const SalonDeepLinkResolver({
    super.key,
    required this.salonId,
    this.initialSalon,
  });

  @override
  State<SalonDeepLinkResolver> createState() => _SalonDeepLinkResolverState();
}

class _SalonDeepLinkResolverState extends State<SalonDeepLinkResolver> {
  SalonModel? _salon;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialSalon != null) {
      _salon = widget.initialSalon;
      _isLoading = false;
    } else {
      _fetchSalon();
    }
  }

  Future<void> _fetchSalon() async {
    try {
      final salons = await sl<BookingRepository>().getSalons();
      final foundSalon = salons.firstWhere(
            (s) => s.id == widget.salonId,
        orElse: () => throw Exception('Salon not found'),
      );

      if (mounted) {
        setState(() {
          _salon = foundSalon;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_hasError || _salon == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Could not load salon details.'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go(AppRoutes.clientDiscover),
                child: const Text('Go to Discovery'),
              ),
            ],
          ),
        ),
      );
    }

    return PopScope(
      canPop: Navigator.canPop(context),
      onPopInvoked: (didPop) {
        if (didPop) return;
        context.go(AppRoutes.clientDiscover);
      },
      child: SalonDetailScreen(salon: _salon!),
    );
  }
}