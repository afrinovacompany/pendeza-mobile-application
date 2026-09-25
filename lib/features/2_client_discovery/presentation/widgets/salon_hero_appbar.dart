import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pendeza/app/config/theme/app_text_styles.dart';
import 'package:pendeza/app/utils/business_hours_utils.dart';
import 'package:pendeza/shared/models/salon_model.dart';
import 'package:pendeza/shared/utils/placeholder_images.dart';
import 'package:pendeza/app/config/app_config.dart';
import 'package:pendeza/shared/widgets/client_ui.dart';

// Import Auth, Favorites and Reviews Blocs
import 'package:pendeza/features/0_auth/presentation/bloc/auth_bloc.dart';
import 'package:pendeza/features/0_auth/presentation/bloc/auth_state.dart';
import 'package:pendeza/features/2_client_favorites/presentation/bloc/favorites_bloc.dart';
import 'package:pendeza/features/2_client_favorites/presentation/bloc/favorites_state.dart';
import 'package:pendeza/features/2_client_favorites/presentation/bloc/favorites_event.dart';
import 'package:pendeza/features/3_reviews/presentation/bloc/reviews_bloc.dart';
import 'package:pendeza/features/3_reviews/presentation/bloc/reviews_state.dart';

/// Full-bleed photo header for the salon page: name, place, rating and
/// open/closed status over the image, with the content sheet curving up
/// underneath.
class SalonHeroAppBar extends StatelessWidget {
  final SalonModel salon;
  final double scrollOffset;

  static const double expandedHeight = 340;

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

    SharePlus.instance.share(
      ShareParams(
        text: shareMessage,
        subject: 'Book ${salon.salonName} on Pendeza',
      ),
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // 0 while the photo is showing, 1 once the bar has collapsed.
    final double collapsed =
        ((scrollOffset - (expandedHeight - 160)) / 90).clamp(0.0, 1.0);
    final bool isCollapsed = collapsed > 0.6;
    final Color iconColor = isCollapsed ? cs.onSurface : Colors.white;

    final String? imageUrl = salon.primaryImage;
    final bool hasImage = imageUrl != null && imageUrl.isNotEmpty;

    return SliverAppBar(
      expandedHeight: expandedHeight,
      pinned: true,
      stretch: true,
      backgroundColor: ClientTheme.background(context),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      leadingWidth: 60,
      leading: _GlassButton(
        icon: CupertinoIcons.back,
        onTap: () => context.pop(),
        collapsed: isCollapsed,
        iconColor: iconColor,
      ),
      actions: [
        _GlassButton(
          icon: CupertinoIcons.share_up,
          onTap: () => _shareSalon(context),
          collapsed: isCollapsed,
          iconColor: iconColor,
        ),
        // Favorite Button (Connected to Bloc)
        BlocBuilder<FavoritesBloc, FavoritesState>(
          builder: (context, state) {
            bool isFavorited = false;

            if (state is FavoritesLoaded) {
              isFavorited = state.isFavorited(salon.id);
            } else if (state is FavoriteToggled && state.salonId == salon.id) {
              isFavorited = state.isFavorited;
            }

            return _GlassButton(
              icon: isFavorited ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
              iconColor: isFavorited ? const Color(0xFFFF6B6B) : iconColor,
              onTap: () => _toggleFavorite(context),
              collapsed: isCollapsed,
            );
          },
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.blurBackground,
        ],
        title: Opacity(
          opacity: collapsed,
          child: Text(
            salon.salonName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              color: cs.onSurface,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ),
        centerTitle: true,
        titlePadding: const EdgeInsets.only(bottom: 14, left: 64, right: 110),
        background: Stack(
          fit: StackFit.expand,
          children: [
            // 1. HERO IMAGE (with fallback to placeholder)
            Hero(
              tag: 'salon_image_${salon.id}',
              child: CachedNetworkImage(
                imageUrl: hasImage
                    ? imageUrl
                    : PlaceholderImages.forSalon(salon.id),
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: cs.surfaceContainerHighest,
                ),
                errorWidget: (context, url, error) => CachedNetworkImage(
                  imageUrl: PlaceholderImages.forSalon(salon.id),
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) => Container(
                    color: cs.surfaceContainerHighest,
                    child: const Icon(CupertinoIcons.photo, size: 40),
                  ),
                ),
              ),
            ),

            // 2. SCRIM
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.45),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.30),
                    Colors.black.withValues(alpha: 0.82),
                  ],
                  stops: const [0.0, 0.28, 0.55, 1.0],
                ),
              ),
            ),

            // 3. IDENTITY (name, place, rating, status)
            Positioned(
              left: 20,
              right: 20,
              bottom: 44,
              child: Opacity(
                opacity: (1 - collapsed * 1.6).clamp(0.0, 1.0),
                child: _Identity(salon: salon),
              ),
            ),

            // 4. Content sheet curving up over the photo.
            Positioned(
              left: 0,
              right: 0,
              bottom: -1,
              height: 28,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: ClientTheme.background(context),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(30)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Identity extends StatelessWidget {
  final SalonModel salon;
  const _Identity({required this.salon});

  @override
  Widget build(BuildContext context) {
    final status = BusinessHoursUtils.getStatus(
      openingTime: salon.openingTime,
      closingTime: salon.closingTime,
    );
    final hasStatus = status != SalonStatus.unknown;
    final statusColor = BusinessHoursUtils.getStatusColor(status);

    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.15,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (hasStatus)
                _StatusChip(
                  color: statusColor,
                  label: BusinessHoursUtils.getStatusText(
                    openingTime: salon.openingTime,
                    closingTime: salon.closingTime,
                  ),
                ),
              BlocBuilder<ReviewsBloc, ReviewsState>(
                builder: (context, state) {
                  if (state is! ReviewsLoaded || state.totalReviews == 0) {
                    return const SizedBox.shrink();
                  }
                  return ClientPill(
                    label:
                        '${state.averageRating.toStringAsFixed(1)} (${state.totalReviews})',
                    color: const Color(0xFFF5A623),
                    icon: CupertinoIcons.star_fill,
                    onDark: true,
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Flexible(
                child: Text(
                  salon.salonName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 27,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                    letterSpacing: -0.4,
                    color: Colors.white,
                  ),
                ),
              ),
              if (salon.isApproved) ...[
                const SizedBox(width: 8),
                const Icon(
                  CupertinoIcons.checkmark_seal_fill,
                  size: 20,
                  color: Color(0xFF8FE3C9),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                CupertinoIcons.location_solid,
                size: 13,
                color: Colors.white.withValues(alpha: 0.85),
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  salon.district ?? salon.address,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 13.5,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final Color color;
  final String label;
  const _StatusChip({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 6),
              ],
            ),
          ),
          const SizedBox(width: 7),
          Text(
            label,
            style: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// Round icon button: translucent over the photo, card-coloured once the
/// bar has collapsed.
class _GlassButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool collapsed;
  final Color? iconColor;

  const _GlassButton({
    required this.icon,
    required this.onTap,
    required this.collapsed,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Material(
          color: collapsed
              ? Colors.transparent
              : Colors.black.withValues(alpha: 0.30),
          shape: CircleBorder(
            side: BorderSide(
              color: collapsed
                  ? Colors.transparent
                  : Colors.white.withValues(alpha: 0.25),
            ),
          ),
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: 40,
              height: 40,
              child: Icon(icon, size: 21, color: iconColor ?? cs.onSurface),
            ),
          ),
        ),
      ),
    );
  }
}
