import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pendeza/app/config/theme/app_constants.dart';
import 'package:pendeza/shared/models/salon_model.dart';
import 'package:pendeza/shared/utils/placeholder_images.dart';
import 'package:pendeza/app/config/app_config.dart';

// Import Auth and Favorites Blocs
import 'package:pendeza/features/0_auth/presentation/bloc/auth_bloc.dart';
import 'package:pendeza/features/0_auth/presentation/bloc/auth_state.dart';
import 'package:pendeza/features/2_client_favorites/presentation/bloc/favorites_bloc.dart';
import 'package:pendeza/features/2_client_favorites/presentation/bloc/favorites_state.dart';
import 'package:pendeza/features/2_client_favorites/presentation/bloc/favorites_event.dart';

class SalonHeroAppBar extends StatelessWidget {
  final SalonModel salon;
  final double scrollOffset;

  const SalonHeroAppBar({
    super.key,
    required this.salon,
    required this.scrollOffset,
  });

  void _shareSalon(BuildContext context) {
    // Ensure we have a valid ID for the link
    final String deepLink = AppConfig.getSalonDeepLink(salon.id);
    final String shareMessage =
        'Check out ${salon.salonName} on Pendeza! Book your appointment now.\n\n$deepLink';

    // Using the standard static Share method to avoid object creation issues
    Share.share(
      shareMessage,
      subject: 'Book ${salon.salonName} on Pendeza',
    );
  }

  // Logic to toggle favorite status
  void _toggleFavorite(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    String userId;
    bool isGuest;

    if (authState is Authenticated) {
      userId = authState.user.uid;
      isGuest = false;
    } else if (authState is GuestMode) {
      userId = authState.guestUser.uid;
      isGuest = true;
    } else {
      // Prompt login if neither authenticated nor guest (edge case)
      return;
    }

    // Trigger the event in FavoritesBloc
    context.read<FavoritesBloc>().add(
      ToggleFavorite(
        userId: userId,
        salonId: salon.id,
        isGuest: isGuest,
      ),
    );
  }

  // Safe check for business hours
  bool _isSalonOpen() {
    if (salon.openingTime == null || salon.closingTime == null) return false;

    try {
      final now = DateTime.now();

      // Parse "HH:mm" strings safely
      final openParts = salon.openingTime!.split(':');
      final closeParts = salon.closingTime!.split(':');

      if (openParts.length != 2 || closeParts.length != 2) return false;

      final openTime = DateTime(
          now.year, now.month, now.day,
          int.parse(openParts[0]), int.parse(openParts[1])
      );

      final closeTime = DateTime(
          now.year, now.month, now.day,
          int.parse(closeParts[0]), int.parse(closeParts[1])
      );

      return now.isAfter(openTime) && now.isBefore(closeTime);
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Calculate opacity for the background/title
    final double opacity = (scrollOffset / 150).clamp(0.0, 1.0);

    // Dynamic text color based on scroll
    final Color iconColor = opacity > 0.6
        ? (isDark ? Colors.white : Colors.black)
        : Colors.white;

    // Check if image exists and is not empty to prevent "String?" errors
    // We assume primaryImage might be nullable (String?) in your model
    final String? imageUrl = salon.primaryImage;
    final bool hasImage = imageUrl != null && imageUrl.isNotEmpty;

    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      stretch: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      elevation: opacity > 0.8 ? 2 : 0,
      leading: _buildGlassButton(
        context,
        icon: CupertinoIcons.back,
        onTap: () => context.pop(),
        opacity: opacity,
        iconColor: iconColor,
      ),
      actions: [
        // Share Button
        _buildGlassButton(
          context,
          icon: CupertinoIcons.share_up,
          onTap: () => _shareSalon(context),
          opacity: opacity,
          iconColor: iconColor,
        ),
        const SizedBox(width: 8),

        // Favorite Button (Connected to Bloc)
        BlocBuilder<FavoritesBloc, FavoritesState>(
          builder: (context, state) {
            bool isFavorited = false;

            if (state is FavoritesLoaded) {
              isFavorited = state.isFavorited(salon.id);
            } else if (state is FavoriteToggled && state.salonId == salon.id) {
              isFavorited = state.isFavorited;
            }

            return _buildGlassButton(
              context,
              icon: isFavorited ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
              iconColor: isFavorited ? Colors.red : iconColor,
              onTap: () => _toggleFavorite(context),
              opacity: opacity,
            );
          },
        ),
        const SizedBox(width: AppConstants.padM),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.blurBackground,
        ],
        title: Opacity(
          opacity: opacity,
          child: Text(
            salon.salonName,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        centerTitle: true,
        background: Stack(
          fit: StackFit.expand,
          children: [
            // 1. HERO IMAGE (with fallback to placeholder)
            Hero(
              tag: 'salon_image_${salon.id}',
              child: CachedNetworkImage(
                imageUrl: hasImage
                    ? imageUrl ?? ''
                    : PlaceholderImages.forSalon(salon.id),
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: theme.colorScheme.surfaceContainerHighest,
                ),
                errorWidget: (context, url, error) => CachedNetworkImage(
                  imageUrl: PlaceholderImages.forSalon(salon.id),
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) => Container(
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: const Icon(Icons.broken_image, size: 40),
                  ),
                ),
              ),
            ),

            // 2. GRADIENT OVERLAY
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.4),
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                  stops: const [0.0, 0.3, 0.6, 1.0],
                ),
              ),
            ),

            // 3. STATUS BADGE (Open/Closed)
            Positioned(
              bottom: 16,
              left: 16,
              child: _buildStatusBadge(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    // Check if hours are set
    if (salon.openingTime == null || salon.closingTime == null) {
      return const SizedBox.shrink();
    }

    final isOpen = _isSalonOpen();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isOpen ? Colors.green : Colors.red,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOpen ? Icons.check_circle : Icons.access_time_filled,
            color: Colors.white,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            isOpen ? 'Open Now' : 'Closed',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassButton(
      BuildContext context, {
        required IconData icon,
        required VoidCallback onTap,
        double opacity = 0.0,
        Color? iconColor,
      }) {
    // If scrolled (opacity > 0.8), use standard transparent/flat look
    // If expanded (opacity < 0.8), use glassmorphism
    final isScrolled = opacity > 0.8;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: isScrolled
            ? Colors.transparent
            : Colors.black.withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Icon(
              icon,
              size: 22,
              color: iconColor ?? Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}