import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:pendeza/app/config/platform_config.dart';
import 'package:pendeza/app/config/theme/app_theme.dart';
import 'package:pendeza/app/config/app_router.dart';
import 'package:pendeza/app/bloc/theme_cubit.dart';
import 'package:pendeza/app/services/service_locator.dart';
import 'package:pendeza/features/0_auth/presentation/bloc/auth_bloc.dart';
import 'package:pendeza/features/2_client_booking/presentation/bloc/booking_bloc.dart';
import 'package:pendeza/features/2_client_discovery/presentation/bloc/discovery_bloc.dart';
import 'package:pendeza/features/2_client_favorites/presentation/bloc/favorites_bloc.dart';
import 'package:provider/provider.dart';

// Services & Repositories
import 'package:pendeza/app/services/wallet_service.dart';
import 'package:pendeza/app/services/payment_service.dart';
import 'package:pendeza/features/wallet/domain/repositories/wallet_repository.dart';

// 🔥 WALLET & PROFILE BLOC IMPORTS
import 'package:pendeza/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:pendeza/features/2_client_profile/presentation/bloc/profile_bloc.dart';

// 🔔 NOTIFICATION BLOC IMPORT
import 'package:pendeza/features/2_client_notifications/presentation/bloc/notification_bloc.dart';

import 'features/2_client_appointments/presentation/bloc/appointments_bloc.dart';

/// ============================================================================
/// APP.DART - FIXED VERSION
/// ============================================================================
///
/// IMPORTANT: All BLoCs that need to persist across the app lifecycle should
/// be provided here using BlocProvider.value() for singletons.
///
/// KEY RULES:
/// 1. Singletons (registered with registerLazySingleton) → Use BlocProvider.value()
/// 2. Factories (registered with registerFactory) → Use BlocProvider(create: ...)
///
/// The WalletBloc and ProfileBloc are SINGLETONS, so we use .value() here.
/// This means NEVER create local BlocProviders for these in child widgets!
/// ============================================================================

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // ====================================================================
        // STEP 1: Provide Services & Repositories FIRST
        // ====================================================================
        Provider<WalletService>.value(value: sl<WalletService>()),
        Provider<PaymentService>.value(value: sl<PaymentService>()),
        Provider<WalletRepository>.value(value: sl<WalletRepository>()),

        // ====================================================================
        // STEP 2: Provide BLoCs
        // ====================================================================

        // Theme Cubit - not a singleton, create fresh
        BlocProvider<ThemeCubit>(create: (context) => ThemeCubit()),

        // AuthBloc - SINGLETON (registered with registerLazySingleton)
        // Use .value() to avoid closing it when widgets dispose
        BlocProvider<AuthBloc>.value(value: sl<AuthBloc>()),

        // BookingBloc - FACTORY (registered with registerFactory)
        // Create new instance each time
        BlocProvider<BookingBloc>(create: (context) => sl<BookingBloc>()),

        // DiscoveryBloc - FACTORY
        BlocProvider<DiscoveryBloc>(create: (context) => sl<DiscoveryBloc>()),

        // FavoritesBloc - FACTORY
        BlocProvider<FavoritesBloc>(create: (context) => sl<FavoritesBloc>()),

        // AppointmentsBloc - FACTORY
        BlocProvider<AppointmentsBloc>(create: (context) => sl<AppointmentsBloc>()),

        // ================================================================
        // 🔥 ProfileBloc - SINGLETON (changed from FACTORY in service_locator)
        // Must use .value() to keep it alive across navigations
        // ================================================================
        BlocProvider<ProfileBloc>.value(value: sl<ProfileBloc>()),

        // ================================================================
        // 🔥 WalletBloc - SINGLETON
        // Must use .value() to keep it alive across navigations
        // ================================================================
        BlocProvider<WalletBloc>.value(value: sl<WalletBloc>()),

        // ================================================================
        // 🔔 NotificationBloc - SINGLETON
        // Tracks unread count and real-time notifications across the app
        // ================================================================
        BlocProvider<NotificationBloc>.value(value: sl<NotificationBloc>()),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return PlatformProvider(
            settings: PlatformSettingsData(
              iosUsesMaterialWidgets: true,
              iosUseZeroPaddingForAppbarPlatformIcon: true,
            ),
            builder: (context) => PlatformTheme(
              themeMode: themeMode,
              materialLightTheme: AppTheme.lightTheme,
              materialDarkTheme: AppTheme.darkTheme,
              cupertinoLightTheme: AppTheme.cupertinoLightTheme,
              cupertinoDarkTheme: AppTheme.cupertinoDarkTheme,
              builder: (context) => PlatformApp.router(
                title: 'Pendeza App',
                debugShowCheckedModeBanner: false,
                routerConfig: AppRouter.router,
                localizationsDelegates: [
                  ...context.localizationDelegates,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                  FlutterQuillLocalizations.delegate,
                ],
                supportedLocales: context.supportedLocales,
                locale: context.locale,
              ),
            ),
          );
        },
      ),
    );
  }
}