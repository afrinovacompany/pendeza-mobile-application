import 'package:get_it/get_it.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
import 'auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestore_service.dart';

final sl = GetIt.instance;

Future<void> initializeDependencies() async {
  // CORE SERVICES
  sl.registerLazySingleton<AuthService>(() => AuthService());
  sl.registerLazySingleton<FirestoreService>(() => FirestoreService());

  // EXTERNAL PACKAGES
  sl.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  sl.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);

  // REPOSITORIES
  sl.registerLazySingleton<AuthRepository>(
        () => AuthRepositoryImpl(
      authService: sl(),
      firestoreService: sl(),
    ),
  );

  sl.registerLazySingleton<BookingRepository>(
        () => BookingRepositoryImpl(sl<FirestoreService>()),
  );

  sl.registerLazySingleton<AppointmentsRepository>(
        () => AppointmentsRepositoryImpl(sl<FirestoreService>()),
  );

  sl.registerLazySingleton<ServicesRepository>(
        () => ServicesRepositoryImpl(sl<FirestoreService>()),
  );

  // BLOCS / CUBITS
  sl.registerSingleton<AuthBloc>(
    AuthBloc(authRepository: sl()),
  );

  sl.registerFactory<BookingBloc>(() => BookingBloc());

  sl.registerFactory<AppointmentsBloc>(() => AppointmentsBloc(
    appointmentsRepository: sl(),
    authBloc: sl(),
  ));

  sl.registerFactory<ServicesBloc>(() => ServicesBloc(
    servicesRepository: sl(),
    authBloc: sl(),
  ));

  sl.registerFactory<DiscoveryBloc>(() => DiscoveryBloc(sl()));
}
