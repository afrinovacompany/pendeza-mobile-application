import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pendeza/app/config/app_router.dart';
import 'package:pendeza/app/config/theme/app_constants.dart';
import 'package:pendeza/features/0_auth/presentation/bloc/auth_bloc.dart';
import 'package:pendeza/features/0_auth/presentation/bloc/auth_state.dart';
import 'package:pendeza/features/2_client_favorites/presentation/bloc/favorites_bloc.dart';
import 'package:pendeza/features/2_client_favorites/presentation/bloc/favorites_event.dart';
import 'package:pendeza/features/2_client_favorites/presentation/bloc/favorites_state.dart';
import 'package:pendeza/shared/widgets/loading_indicator.dart';
import 'package:pendeza/shared/widgets/salon_card.dart';

/// Favorites Screen - Shows all user's favorited salons
///
/// Features:
/// - Grid layout of favorite salons
/// - Pull to refresh
/// - Empty state for no favorites
/// - Guest user prompt to sign in
/// - Working favorite buttons on each card
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  void _loadFavorites() {
    final authState = context.read<AuthBloc>().state;

    if (authState is Authenticated) {
      context.read<FavoritesBloc>().add(
        LoadFavorites(
          userId: authState.user.uid,
          isGuest: false,
        ),
      );
    } else if (authState is GuestMode) {
      context.read<FavoritesBloc>().add(
        LoadFavorites(
          userId: authState.guestUser.uid,
          isGuest: true,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        // Key: "client.profile.menu.favorites" -> "My Favorites"
        title: Text('client.profile.menu.favorites'.tr()),
        centerTitle: true,
        actions: [
          // Clear all button (only show when there are favorites)
          BlocBuilder<FavoritesBloc, FavoritesState>(
            builder: (context, state) {
              if (state is FavoritesLoaded && state.hasFavorites) {
                return IconButton(
                  icon: const Icon(CupertinoIcons.trash),
                  onPressed: () => _showClearAllDialog(context),
                  tooltip: 'client.favorites.clear_all_action'.tr(), // "Clear all favorites" (tooltip not strictly in JSON, reusing action label or generic)
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocConsumer<FavoritesBloc, FavoritesState>(
        listener: (context, state) {
          if (state is FavoritesError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: theme.colorScheme.error,
              ),
            );
          }

          if (state is FavoritesMigrated) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is FavoritesLoading) {
            return _buildLoadingState();
          }

          if (state is FavoritesEmpty) {
            return _buildEmptyState(context, state.message);
          }

          if (state is FavoritesLoaded) {
            return _buildLoadedState(context, state);
          }

          if (state is FavoritesError) {
            return _buildErrorState(context, state.message);
          }

          // Initial state
          return const SizedBox.shrink();
        },
      ),
    );
  }

  //============================================================================
  // LOADING STATE
  //============================================================================

  Widget _buildLoadingState() {
    return GridView.builder(
      padding: const EdgeInsets.all(AppConstants.padL),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: AppConstants.padM,
        mainAxisSpacing: AppConstants.padM,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return const ShimmerPlaceholder.rectangular(height: 250);
      },
    );
  }

  //============================================================================
  // EMPTY STATE
  //============================================================================

  Widget _buildEmptyState(BuildContext context, String message) {
    final authState = context.read<AuthBloc>().state;
    final isGuest = authState is GuestMode;

    return RefreshIndicator(
      onRefresh: () async => _loadFavorites(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height - 100,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.padXXL),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.heart,
                    size: 80,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: AppConstants.padL),
                  Text(
                    'client.favorites.empty_title'.tr(),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppConstants.padM),
                  Text(
                    isGuest
                        ? 'client.booking.guest_prompt'.tr()
                        : 'client.favorites.empty_msg'.tr(),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: AppConstants.padXL),
                  if (isGuest)
                    ElevatedButton.icon(
                      onPressed: () => context.push(AppRoutes.login),
                      icon: const Icon(CupertinoIcons.person),
                      // Key: "auth.login.button" -> "SIGN IN"
                      label: Text('auth.login.button'.tr()),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: () => context.go(AppRoutes.clientDiscover),
                      icon: const Icon(CupertinoIcons.search),
                      label: Text('client.favorites.explore_salons'.tr()),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  //============================================================================
  // LOADED STATE
  //============================================================================

  Widget _buildLoadedState(BuildContext context, FavoritesLoaded state) {
    return RefreshIndicator(
      onRefresh: () async => _loadFavorites(),
      child: GridView.builder(
        padding: const EdgeInsets.all(AppConstants.padL),
        physics: const AlwaysScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: AppConstants.padM,
          mainAxisSpacing: AppConstants.padM,
        ),
        itemCount: state.favoriteSalons.length,
        itemBuilder: (context, index) {
          final salon = state.favoriteSalons[index];
          return SalonCard(
            salon: salon,
            onTap: () {
              context.push(
                AppRoutes.salonDetail.replaceFirst(':salonId', salon.id),
              );
            },
          );
        },
      ),
    );
  }

  //============================================================================
  // ERROR STATE
  //============================================================================

  Widget _buildErrorState(BuildContext context, String message) {
    return RefreshIndicator(
      onRefresh: () async => _loadFavorites(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height - 100,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.padXXL),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.exclamationmark_triangle,
                    size: 80,
                    color: Colors.orange[300],
                  ),
                  const SizedBox(height: AppConstants.padL),
                  Text(
                    // Key: "common.oops"
                    'common.oops'.tr(),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppConstants.padM),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: AppConstants.padXL),
                  ElevatedButton.icon(
                    onPressed: () => _loadFavorites(),
                    icon: const Icon(CupertinoIcons.refresh),
                    label: Text('common.retry'.tr()),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  //============================================================================
  // HELPER METHODS
  //============================================================================

  void _showClearAllDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        // Key: "client.favorites.clear_dialog_title"
        title: Text('client.favorites.clear_dialog_title'.tr()),
        // Key: "client.favorites.clear_dialog_content"
        content: Text('client.favorites.clear_dialog_content'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            // Key: "common.cancel"
            child: Text('common.cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              final authState = context.read<AuthBloc>().state;

              if (authState is Authenticated) {
                context.read<FavoritesBloc>().add(
                  ClearAllFavorites(
                    userId: authState.user.uid,
                    isGuest: false,
                  ),
                );
              } else if (authState is GuestMode) {
                context.read<FavoritesBloc>().add(
                  ClearAllFavorites(
                    userId: authState.guestUser.uid,
                    isGuest: true,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            // Key: "client.favorites.clear_all_action"
            child: Text('client.favorites.clear_all_action'.tr()),
          ),
        ],
      ),
    );
  }
}