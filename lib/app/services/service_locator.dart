import 'package:get_it/get_it.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:pendeza/app/services/promotion_service.dart';
import 'package:pendeza/app/services/payment_service.dart';

// Repositories & Services
import 'package:pendeza/features/2_client_booking/domain/repositories/booking_repository.dart';
import 'package:pendeza/features/2_client_booking/presentation/bloc/booking_bloc.dart';
import 'package:pendeza/features/2_client_discovery/presentation/bloc/discovery_bloc.dart';
import 'package:pendeza/features/3_owner_management/services/domain/repositories/services_repository.dart';
import 'package:pendeza/features/3_owner_management/services/domain/repositories/services_repository_impl.dart';
import 'package:pendeza/features/3_owner_management/services/presentation/bloc/services_bloc.dart';

import '../../features/0_auth/data/repositories/auth_repository_impl.dart';
import '../../features/0_auth/domain/repositories/auth_repository.dart';
import '../../features/0_auth/presentation/bloc/auth_bloc.dart';
import '../../features/2_client_appointments/domain/repositories/appoitments_repository.dart';
import '../../features/2_client_appointments/domain/repositories/appoitments_repository_impl.dart';
import '../../features/2_client_appointments/presentation/bloc/appointments_bloc.dart';
import '../../features/2_client_booking/domain/repositories/booking_repository_impl.dart';

import '../../features/2_client_dashboard/presentation/bloc/promotion_bloc.dart';
import '../../features/2_client_favorites/domain/repositories/favorites_repository_impl.dart';
import '../../features/2_client_favorites/presentation/bloc/favorites_bloc.dart';
import '../../features/2_client_profile/domain/repositories/profile_repository.dart';
import '../../features/2_client_profile/domain/repositories/profile_repository_impl.dart';
import '../../features/2_client_profile/presentation/bloc/profile_bloc.dart';
import '../../features/3_owner_inspiration/domain/repository/inspiration_repository.dart';
import '../../features/3_owner_inspiration/domain/repository/inspiration_repository_impl.dart';
import '../../features/3_owner_inspiration/presentation/bloc/inspiration_bloc.dart';
import '../../features/3_owner_management/clients/domain/repositories/client_management_repository.dart';
import '../../features/3_owner_management/clients/domain/repositories/client_management_repository_impl.dart';
import '../../features/3_owner_management/clients/presentation/bloc/client_details_bloc.dart';
import '../../features/3_owner_management/clients/presentation/bloc/client_management_bloc.dart';
import '../../features/3_owner_management/dashboard/domain/repositories/owner_dashboard_repository.dart';
import '../../features/3_owner_management/dashboard/domain/repositories/owner_dashboard_repository_impl.dart';
import '../../features/3_owner_management/dashboard/presentation/bloc/owner_dashboard_bloc.dart';

// Salon Profile imports
import '../../features/3_owner_management/promotions/domain/repositories/owner_promotions_repository_impl.dart';
import '../../features/3_owner_management/salon_profile/domain/repositories/salon_profile_repository.dart';
import '../../features/3_owner_management/salon_profile/domain/repositories/salon_profile_repository_impl.dart';
import '../../features/3_owner_management/salon_profile/presentation/bloc/salon_profile_bloc.dart';

// --- OWNER PROMOTIONS IMPORTS ---
import '../../features/3_owner_management/promotions/domain/repositories/owner_promotions_repository.dart';
import '../../features/3_owner_management/promotions/presentation/bloc/owner_promotions_bloc.dart';

// --- ADMIN IMPORTS ---
import '../../features/5_admin_panel/data/repositories/admin_repository.dart';
import '../../features/5_admin_panel/data/repositories/admin_repository_impl.dart';
import '../../features/5_admin_panel/presentation/bloc/admin_bloc.dart';

// --- FAVORITES IMPORTS ---
import 'package:pendeza/features/2_client_favorites/domain/repositories/favorites_repository.dart';

// --- REVIEWS IMPORTS ---
import 'package:pendeza/features/3_reviews/domain/repositories/reviews_repository.dart';
import 'package:pendeza/features/3_reviews/data/repositories/reviews_repository_impl.dart';
import 'package:pendeza/features/3_reviews/presentation/bloc/reviews_bloc.dart';

// --- NOTIFICATIONS IMPORTS ---
import 'package:pendeza/features/2_client_notifications/domain/repositories/notification_repository.dart';
import 'package:pendeza/features/2_client_notifications/presentation/bloc/notification_bloc.dart';

// --- VIDEO SHORTS IMPORTS ---
import 'package:pendeza/features/video_shorts/domain/video_shorts_repository.dart';
import 'package:pendeza/features/video_shorts/data/video_shorts_repository_impl.dart';
import 'package:pendeza/features/video_shorts/presentation/bloc/video_shorts_bloc.dart';

import 'auth_service.dart';
import 'firestore_service.dart';
import 'local_storage_service.dart';
import 'guest_data_migration_service.dart';
import 'guest_session_tracker.dart';
import 'guest_prompt_service.dart';
import 'notification_service.dart';
import 'analytics_service.dart';

// WALLET IMPORTS
import 'package:pendeza/app/services/wallet_service.dart';
import 'package:pendeza/features/wallet/domain/repositories/wallet_repository.dart';
import 'package:pendeza/features/wallet/presentation/bloc/wallet_bloc.dart';

final sl = GetIt.instance;

/// ============================================================================
/// SERVICE LOCATOR - FIXED VERSION
/// ============================================================================
///
/// IMPORTANT REGISTRATION RULES:
///
/// 1. registerLazySingleton → Creates ONE instance for the entire app lifetime
///    - Use for: AuthBloc, WalletBloc, ProfileBloc (global state that persists)
///    - In app.dart, use: BlocProvider.value(value: sl<MyBloc>())
///    - NEVER create local BlocProviders for singletons in child widgets!
///
/// 2. registerFactory → Creates a NEW instance every time sl<T>() is called
///    - Use for: Screen-specific BLoCs that should be fresh each time
///    - In app.dart, use: BlocProvider(create: (_) => sl<MyBloc>())
///
/// 🔥 KEY FIX: ProfileBloc changed from registerFactory to registerLazySingleton
/// because it needs to persist across navigations (same as WalletBloc)
/// ============================================================================

Future<void> initializeDependencies() async {
  // ============================================================================
  // LOCAL STORAGE & TRACKING
  // ============================================================================
  final localStorage = await LocalStorageService.init();
  sl.registerSingleton<LocalStorageService>(localStorage);

  final sessionTracker = await GuestSessionTracker.init();
  sl.registerSingleton<GuestSessionTracker>(sessionTracker);

  if (sessionTracker.isNewSession) {
    await sessionTracker.startSession();
  }

  sl.registerLazySingleton<GuestPromptService>(
        () => GuestPromptService(sl<GuestSessionTracker>()),
  );

  // ============================================================================
  // CORE SERVICES
  // ============================================================================
  sl.registerLazySingleton<AuthService>(() => AuthService());
  sl.registerLazySingleton<FirestoreService>(() => FirestoreService());
  sl.registerLazySingleton<NotificationService>(() => NotificationService());
  sl.registerLazySingleton<PromotionsService>(() => PromotionsService());
  sl.registerLazySingleton<PaymentService>(() => PaymentService());
  sl.registerLazySingleton<AnalyticsService>(() => AnalyticsService());

  // WALLET SERVICE
  sl.registerLazySingleton<WalletService>(() => WalletService());

  sl.registerLazySingleton<GuestDataMigrationService>(
        () => GuestDataMigrationService(
      localStorage: sl<LocalStorageService>(),
      firestore: sl<FirestoreService>(),
      favoritesRepository: sl<FavoritesRepository>(),
    ),
  );

  // ============================================================================
  // EXTERNAL PACKAGES
  // ============================================================================
  sl.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  sl.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);
  sl.registerLazySingleton<FirebaseStorage>(() => FirebaseStorage.instance);

  // ============================================================================
  // REPOSITORIES
  // ============================================================================

  // Auth & Core Repos
  sl.registerLazySingleton<AuthRepository>(
        () => AuthRepositoryImpl(authService: sl(), firestoreService: sl()),
  );

  sl.registerLazySingleton<FavoritesRepository>(
        () => FavoritesRepositoryImpl(
      firestoreService: sl<FirestoreService>(),
      localStorageService: sl<LocalStorageService>(),
    ),
  );

  // WALLET REPOSITORY
  sl.registerLazySingleton<WalletRepository>(
        () => WalletRepositoryImpl(sl<WalletService>()),
  );

  // Client Repos
  sl.registerLazySingleton<BookingRepository>(
        () => BookingRepositoryImpl(sl<FirestoreService>()),
  );
  sl.registerLazySingleton<AppointmentsRepository>(
        () => AppointmentsRepositoryImpl(sl<FirestoreService>()),
  );

  // Owner Repos
  sl.registerLazySingleton<ServicesRepository>(
        () => ServicesRepositoryImpl(sl<FirestoreService>()),
  );
  sl.registerLazySingleton<OwnerDashboardRepository>(
        () => OwnerDashboardRepositoryImpl(sl<FirestoreService>()),
  );
  sl.registerLazySingleton<ClientManagementRepository>(
        () => ClientManagementRepositoryImpl(sl<FirestoreService>()),
  );
  sl.registerLazySingleton<SalonProfileRepository>(
        () => SalonProfileRepositoryImpl(
      sl<FirestoreService>(),
      firestore: sl<FirebaseFirestore>(),
      storage: sl<FirebaseStorage>(),
      authBloc: sl<AuthBloc>(),
    ),
  );
  sl.registerLazySingleton<OwnerPromotionsRepository>(
        () => OwnerPromotionsRepositoryImpl(),
  );

  // Admin & Other Repos
  sl.registerLazySingleton<AdminRepository>(
        () => AdminRepositoryImpl(sl<FirestoreService>()),
  );
  sl.registerLazySingleton<InspirationRepository>(
        () => InspirationRepositoryImpl(),
  );
  sl.registerLazySingleton<ReviewsRepository>(
        () => ReviewsRepositoryImpl(firestoreService: sl<FirestoreService>()),
  );
  sl.registerLazySingleton<ProfileRepository>(
        () => ProfileRepositoryImpl(),
  );

  // Notification Repository
  sl.registerLazySingleton<NotificationRepository>(
        () => NotificationRepository(),
  );

  // ════════════════════════════════════════════════════════════════════════
  // 🆕 VIDEO SHORTS REPOSITORY
  // ════════════════════════════════════════════════════════════════════════
  sl.registerLazySingleton<VideoShortsRepository>(
        () => VideoShortsRepositoryImpl(
      firestore: sl<FirebaseFirestore>(),
    ),
  );

  // ============================================================================
  // BLOCS / CUBITS
  // ============================================================================

  // ================================================================
  // 🔥 SINGLETON BLOCS - These persist for the entire app lifetime
  // ================================================================

  // AuthBloc - SINGLETON (global auth state)
  sl.registerLazySingleton<AuthBloc>(
        () => AuthBloc(authRepository: sl()),
  );

  // WalletBloc - SINGLETON (global wallet state)
  // Used across multiple screens (profile, wallet, booking confirmation)
  sl.registerLazySingleton<WalletBloc>(
        () => WalletBloc(
      walletRepository: sl<WalletRepository>(),
      paymentService: sl<PaymentService>(),
    ),
  );

  // 🔥 ProfileBloc - SINGLETON (changed from Factory!)
  // Needs to persist across navigations to avoid "closed bloc" errors
  sl.registerLazySingleton<ProfileBloc>(
        () => ProfileBloc(
      profileRepository: sl<ProfileRepository>(),
      authBloc: sl<AuthBloc>(),
    ),
  );

  // NotificationBloc - SINGLETON (global notification state)
  // Tracks unread count and real-time notifications across the app
  sl.registerLazySingleton<NotificationBloc>(
        () => NotificationBloc(
      repository: sl<NotificationRepository>(),
      authBloc: sl<AuthBloc>(),
    ),
  );

  // ================================================================
  // FACTORY BLOCS - Fresh instance created each time
  // ================================================================

  // Client Blocs
  sl.registerFactory<PromotionsBloc>(
        () => PromotionsBloc(sl<PromotionsService>()),
  );
  sl.registerFactory<FavoritesBloc>(
        () => FavoritesBloc(
      favoritesRepository: sl<FavoritesRepository>(),
      authBloc: sl<AuthBloc>(),
    ),
  );
  sl.registerFactory<BookingBloc>(() => BookingBloc(authBloc: sl<AuthBloc>()));
  sl.registerFactory<AppointmentsBloc>(
        () => AppointmentsBloc(appointmentsRepository: sl(), authBloc: sl()),
  );
  sl.registerFactory<DiscoveryBloc>(() => DiscoveryBloc(sl()));

  // Owner Blocs
  sl.registerFactory<ServicesBloc>(
        () => ServicesBloc(servicesRepository: sl(), authBloc: sl()),
  );
  sl.registerFactory<OwnerDashboardBloc>(
        () => OwnerDashboardBloc(
        repository: sl<OwnerDashboardRepository>(), authBloc: sl<AuthBloc>()),
  );
  sl.registerFactory<ClientManagementBloc>(
        () => ClientManagementBloc(
        repository: sl(), firestoreService: sl(), authBloc: sl()),
  );
  sl.registerFactory<ClientDetailsBloc>(
        () => ClientDetailsBloc(
        repository: sl(), firestoreService: sl(), authBloc: sl()),
  );
  sl.registerFactory<SalonProfileBloc>(
        () => SalonProfileBloc(
        repository: sl(), authBloc: sl(), firestoreService: sl()),
  );
  sl.registerFactory<OwnerPromotionsBloc>(
        () => OwnerPromotionsBloc(repository: sl<OwnerPromotionsRepository>()),
  );

  // Admin & Shared Blocs
  sl.registerFactory<AdminBloc>(
        () => AdminBloc(adminRepository: sl(), inspirationRepository: sl()),
  );
  sl.registerFactory<InspirationBloc>(
        () => InspirationBloc(sl<InspirationRepository>()),
  );
  sl.registerFactory<ReviewsBloc>(
        () => ReviewsBloc(reviewsRepository: sl<ReviewsRepository>()),
  );

  // ════════════════════════════════════════════════════════════════════════
  // 🆕 VIDEO SHORTS BLOC
  // ════════════════════════════════════════════════════════════════════════
  sl.registerFactory<VideoShortsBloc>(
        () => VideoShortsBloc(
      repository: sl<VideoShortsRepository>(),
    ),
  );
}