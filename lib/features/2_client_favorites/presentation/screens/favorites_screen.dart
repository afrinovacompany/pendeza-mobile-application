import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pendeza/app/config/app_router.dart';
import 'package:pendeza/features/0_auth/presentation/bloc/auth_bloc.dart';
import 'package:pendeza/features/0_auth/presentation/bloc/auth_state.dart';
import 'package:pendeza/features/2_client_favorites/presentation/bloc/favorites_bloc.dart';
import 'package:pendeza/features/2_client_favorites/presentation/bloc/favorites_event.dart';
import 'package:pendeza/features/2_client_favorites/presentation/bloc/favorites_state.dart';
import 'package:pendeza/shared/widgets/client_ui.dart';
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
  static const _gridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2,
    childAspectRatio: 0.75,
    crossAxisSpacing: 14,
    mainAxisSpacing: 14,
  );

  static const _gridPadding = EdgeInsets.fromLTRB(
    ClientTheme.gutter,
    18,
    ClientTheme.gutter,
    24,
  );

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
      backgroundColor: ClientTheme.background(context),
      body: SafeArea(
        bottom: false,
        child: BlocConsumer<FavoritesBloc, FavoritesState>(
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
            final hasFavorites = state is FavoritesLoaded && state.hasFavorites;

            return Column(
              children: [
                ClientPageHeader(
                  title: 'client.profile.menu.favorites'.tr(),
                  subtitle: hasFavorites
                      ? 'client.favorites.saved_count'
                          .tr(args: ['${state.favoriteSalons.length}'])
                      : null,
                  actions: [
                    // Clear all button (only show when there are favorites)
                    if (hasFavorites)
                      GlassCircleButton(
                        icon: CupertinoIcons.trash,
                        size: 42,
                        tooltip: 'client.favorites.clear_all_action'.tr(),
                        onTap: () => _showClearAllDialog(context),
                      ),
                  ],
                ),
                Expanded(child: _buildBody(context, state)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, FavoritesState state) {
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
  }

  //============================================================================
  // LOADING STATE
  //============================================================================

  Widget _buildLoadingState() {
    return GridView.builder(
      padding: _gridPadding,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: _gridDelegate,
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
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: constraints.maxHeight,
            child: ClientEmptyState(
              icon: CupertinoIcons.heart_fill,
              title: 'client.favorites.empty_title'.tr(),
              message: isGuest
                  ? 'client.booking.guest_prompt'.tr()
                  : 'client.favorites.empty_msg'.tr(),
              actionLabel: isGuest
                  ? 'auth.login.button'.tr()
                  : 'client.favorites.explore_salons'.tr(),
              onAction: () => isGuest
                  ? context.push(AppRoutes.login)
                  : context.go(AppRoutes.clientDiscover),
              color: const Color(0xFFEF4444),
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
        padding: _gridPadding,
        physics: const AlwaysScrollableScrollPhysics(),
        gridDelegate: _gridDelegate,
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
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: constraints.maxHeight,
            child: ClientEmptyState(
              icon: CupertinoIcons.exclamationmark_triangle_fill,
              title: 'common.oops'.tr(),
              message: message,
              actionLabel: 'common.retry'.tr(),
              onAction: _loadFavorites,
              color: const Color(0xFFF5A623),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('client.favorites.clear_dialog_title'.tr()),
        content: Text('client.favorites.clear_dialog_content'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
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
              foregroundColor: const Color(0xFFEF4444),
            ),
            child: Text('client.favorites.clear_all_action'.tr()),
          ),
        ],
      ),
    );
  }
}
