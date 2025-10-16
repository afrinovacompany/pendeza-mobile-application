import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';


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
import '../../features/1_onboarding/presentation/screens/owner_profile_setup_screen.dart';
import '../../features/1_onboarding/presentation/screens/role_selection_screen.dart';
import '../../features/2_client_appointments/presentation/screens/appointments_screen.dart';
import '../../features/2_client_booking/presentation/screens/salon_detail_screen.dart';
import '../../features/2_client_dashboard/presentation/screens/client_dashboard_screen.dart';
import '../../features/2_client_discovery/presentation/screens/discovery_screen.dart';
import '../../features/2_client_profile/presentation/screens/profile_screen.dart';
import '../../features/3_owner_dashboard/presentation/screens/owner_dashboard_screen.dart';
import '../../features/3_owner_management/calendar/presentation/screens/calendar_screen.dart';
import '../../features/3_owner_management/clients/presentation/screens/client_list_screen.dart';
import '../../features/3_owner_management/services/presentation/screens/service_list_screen.dart';
import '../../features/3_owner_management/staff/bloc/staff_bloc.dart';
import '../../features/3_owner_management/staff/bloc/staff_event.dart';
import '../../features/3_owner_management/staff/presentation/screens/staff_list_screen.dart';
import '../../shared/models/salon_model.dart';
import '../services/service_locator.dart';

// --- NEW BOOKING SCREEN IMPORTS ---
import '../../features/2_client_booking/presentation/screens/service_selection_screen.dart';
import '../../features/2_client_booking/presentation/screens/timeslot_selection_screen.dart';
import '../../features/2_client_booking/presentation/screens/booking_confirmation_screen.dart';
// ------------------------------------
// Import StaffModel
import '../../shared/models/service_model.dart'; // Import ServiceModel



import 'package:pendeza/features/3_owner_management/services/presentation/screens/add_edit_service_screen.dart';
import '../../shared/widgets/custom_page_transition.dart';


import 'package:pendeza/features/3_owner_management/services/presentation/bloc/services_bloc.dart';
import 'package:pendeza/features/3_owner_management/services/presentation/bloc/services_event.dart';


import 'package:pendeza/features/3_owner_management/staff/presentation/screens/add_edit_staff_screen.dart';
import 'package:pendeza/shared/models/staff_model.dart';






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
  static const String clientHome = '/client/home';
  static const String clientDiscover = '/client/discover';
  static const String clientBookings = '/client/bookings';
  static const String clientProfile = '/client/profile';
  static const String salonDetail = '/salon/detail';
  static const String serviceSelection = '/salon/services';
  static const String timeslotSelection = '/salon/timeslot';
  static const String bookingConfirmation = '/salon/confirm';
  static const String ownerHome = '/owner/home';
  static const String ownerSchedule = '/owner/schedule';
  static const String ownerClients = '/owner/clients';
  static const String ownerServices = '/owner/services';
  static const String addEditService = 'add-edit-service';
  // --- NEW STAFF ROUTES ---
  static const String ownerStaff = '/owner/staff';
  static const String addEditStaff = 'add-edit-staff';
}

class AppRouter {
  static final AuthBloc _authBloc = sl<AuthBloc>();

  static final router = GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    refreshListenable: GoRouterRefreshStream(_authBloc.stream),
    redirect: (BuildContext context, GoRouterState state) {
      final authState = _authBloc.state;
      final currentLocation = state.matchedLocation;
      final unauthenticatedRoutes = [
        AppRoutes.splash,
        AppRoutes.login,
        AppRoutes.signup,
        AppRoutes.forgotPassword,
        AppRoutes.phoneAuth,
        AppRoutes.otp,
      ];
      final onboardingRoutes = [
        AppRoutes.roleSelection,
        AppRoutes.clientSetup,
        AppRoutes.ownerSetup
      ];
      final isGoingToAuthRoute = unauthenticatedRoutes.contains(currentLocation);
      final isGoingToOnboardingRoute =
      onboardingRoutes.contains(currentLocation);
      if (currentLocation == AppRoutes.splash && authState is AuthInitial) {
        return null;
      }
      if (authState is Unauthenticated) {
        return isGoingToAuthRoute ? null : AppRoutes.login;
      }
      if (authState is RoleSelectionRequired) {
        return currentLocation == AppRoutes.roleSelection
            ? null
            : AppRoutes.roleSelection;
      }
      if (authState is ClientProfileSetupRequired) {
        return currentLocation == AppRoutes.clientSetup
            ? null
            : AppRoutes.clientSetup;
      }
      if (authState is OwnerProfileSetupRequired) {
        return currentLocation == AppRoutes.ownerSetup
            ? null
            : AppRoutes.ownerSetup;
      }
      if (authState is Authenticated) {
        if (isGoingToAuthRoute || isGoingToOnboardingRoute) {
          return authState.user.role == 'owner'
              ? AppRoutes.ownerHome
              : AppRoutes.clientHome;
        }
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        pageBuilder: (context, state) => CustomPageTransition(
          child: BlocProvider.value(
            value: _authBloc,
            child: const SplashScreen(),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (context, state) =>
            CustomPageTransition(child: const LoginScreen()),
      ),
      GoRoute(
        path: AppRoutes.salonDetail,
        pageBuilder: (context, state) {
          final salon = state.extra as SalonModel?;
          return CustomPageTransition(
            child: SalonDetailScreen(salon: salon),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.signup,
        pageBuilder: (context, state) =>
            CustomPageTransition(child: const SignUpScreen()),
      ),
      GoRoute(
        path: AppRoutes.phoneAuth,
        pageBuilder: (context, state) =>
            CustomPageTransition(child: const PhoneAuthScreen()),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        pageBuilder: (context, state) =>
            CustomPageTransition(child: const ForgotPasswordScreen()),
      ),
      GoRoute(
        path: AppRoutes.otp,
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return CustomPageTransition(
            child: OtpScreen(
              verificationId: extra['verificationId'] ?? 'error_no_id',
              phoneNumber: extra['phoneNumber'] ?? 'error_no_phone',
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.roleSelection,
        pageBuilder: (context, state) => CustomPageTransition(
          child: BlocProvider.value(
              value: _authBloc, child: const RoleSelectionScreen()),
        ),
      ),
      GoRoute(
        path: AppRoutes.clientSetup,
        pageBuilder: (context, state) => CustomPageTransition(
          child: BlocProvider.value(
              value: _authBloc, child: const ClientProfileSetupScreen()),
        ),
      ),
      GoRoute(
        path: AppRoutes.ownerSetup,
        pageBuilder: (context, state) => CustomPageTransition(
          child: BlocProvider.value(
              value: _authBloc, child: const OwnerOnboardingScreen()),
        ),
      ),
      GoRoute(
        path: AppRoutes.serviceSelection,
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return CustomPageTransition(
            child: ServiceSelectionScreen(
              salonName: extra['salonName'] as String? ?? 'Salon',
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.timeslotSelection,
        pageBuilder: (context, state) {
          return CustomPageTransition(
            child: TimeslotSelectionScreen(),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.bookingConfirmation,
        pageBuilder: (context, state) {
          final details = state.extra as BookingDetailsArguments;
          return CustomPageTransition(
            child: BookingConfirmationScreen(
              bookingDetails: details,
            ),
          );
        },
      ),
      ShellRoute(
        pageBuilder: (context, state, child) {
          final authState = _authBloc.state;
          String userRole = 'client';
          if (authState is Authenticated) {
            userRole = authState.user.role ?? 'client';
          }
          return CustomPageTransition(
            child: MultiBlocProvider(
              providers: [
                BlocProvider(
                  create: (context) =>
                  sl<ServicesBloc>()..add(FetchServicesRequested()),
                ),
                BlocProvider(
                  create: (context) =>
                  sl<StaffBloc>()..add(FetchStaffRequested()),
                ),
              ],
              child: MainScreen(userRole: userRole, child: child),
            ),
          );
        },
        routes: [
          GoRoute(
              path: AppRoutes.clientHome,
              pageBuilder: (context, state) =>
                  CustomPageTransition(child: const ClientDashboardScreen())),
          GoRoute(
              path: AppRoutes.clientDiscover,
              pageBuilder: (context, state) =>
                  CustomPageTransition(child: const DiscoveryScreen())),
          GoRoute(
              path: AppRoutes.clientBookings,
              pageBuilder: (context, state) =>
                  CustomPageTransition(child: const AppointmentsScreen())),
          GoRoute(
              path: AppRoutes.clientProfile,
              pageBuilder: (context, state) =>
                  CustomPageTransition(child: const ProfileScreen())),
          GoRoute(
              path: AppRoutes.ownerHome,
              pageBuilder: (context, state) =>
                  CustomPageTransition(child: const OwnerDashboardScreen())),
          GoRoute(
              path: AppRoutes.ownerSchedule,
              pageBuilder: (context, state) =>
                  CustomPageTransition(child: const CalendarScreen())),
          GoRoute(
            path: AppRoutes.ownerServices,
            pageBuilder: (context, state) =>
                CustomPageTransition(child: const ServiceListScreen()),
            routes: [
              GoRoute(
                path: AppRoutes.addEditService,
                pageBuilder: (context, state) {
                  final service = state.extra as ServiceModel?;
                  return CustomPageTransition(
                    child: AddEditServiceScreen(service: service),
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.ownerStaff,
            pageBuilder: (context, state) =>
                CustomPageTransition(child: const StaffListScreen()),
            routes: [
              GoRoute(
                path: AppRoutes.addEditStaff,
                pageBuilder: (context, state) {
                  final staff = state.extra as StaffModel?;
                  return CustomPageTransition(
                    child: AddEditStaffScreen(staff: staff),
                  );
                },
              )
            ],
          ),
          GoRoute(
              path: AppRoutes.ownerClients,
              pageBuilder: (context, state) =>
                  CustomPageTransition(child: const ClientListScreen())),
        ],
      ),
    ],
  );
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    stream.asBroadcastStream().listen((_) => notifyListeners());
  }
}





