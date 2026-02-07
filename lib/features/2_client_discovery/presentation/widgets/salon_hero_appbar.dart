import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pendeza/app/config/theme/app_constants.dart';
import 'package:pendeza/app/utils/business_hours_utils.dart';
import 'package:pendeza/shared/models/salon_model.dart';
import 'package:pendeza/app/config/app_router.dart';
import 'package:pendeza/app/config/app_config.dart';

class SalonHeroAppBar extends StatelessWidget {
  final SalonModel salon;
  final double scrollOffset;

  const SalonHeroAppBar({
    super.key,
    required this.salon,
    required this.scrollOffset,
  });

  void _shareSalon(BuildContext context) {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final opacity = (scrollOffset / 250).clamp(0.0, 1.0);

    return SliverAppBar(
      expandedHeight: 320,
      pinned: true,
      stretch: true,
      backgroundColor: theme.colorScheme.surface.withValues(alpha: opacity),
      elevation: opacity > 0.8 ? 1 : 0,
      leading: _buildGlassButton(
        context,
        icon: CupertinoIcons.back,
        onTap: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go(AppRoutes.clientDiscover);
          }
        },
      ),
      actions: [
        _buildGlassButton(
          context,
          icon: CupertinoIcons.share_up,
          onTap: () => _shareSalon(context),
        ),
        const SizedBox(width: 8),
        _buildGlassButton(
          context,
          icon: CupertinoIcons.heart,
          onTap: () {}, // TODO: Implement favorite
        ),
        const SizedBox(width: AppConstants.padM),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Hero Image with parallax effect
            Hero(
              tag: 'salon_${salon.id}',
              child: Transform.scale(
                scale: 1 + (scrollOffset / 1000).clamp(0.0, 0.3),
                child: salon.primaryImage != null
                    ? CachedNetworkImage(
                  imageUrl: salon.primaryImage!,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: theme.colorScheme.surfaceContainerHighest,
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: const Icon(CupertinoIcons.building_2_fill, size: 80),
                  ),
                )
                    : Container(
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: const Icon(CupertinoIcons.building_2_fill, size: 80),
                ),
              ),
            ),

            // Enhanced gradient overlay
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.2),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.4),
                    Colors.black.withValues(alpha: 0.9),
                  ],
                  stops: const [0.0, 0.3, 0.6, 1.0],
                ),
              ),
            ),

            // Salon info with fade animation
            Positioned(
              bottom: AppConstants.padL,
              left: AppConstants.padL,
              right: AppConstants.padL,
              child: Opacity(
                opacity: (1 - (scrollOffset / 200)).clamp(0.0, 1.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      salon.salonName,
                      style: theme.textTheme.headlineLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 28,
                        shadows: [
                          Shadow(
                            offset: const Offset(0, 2),
                            blurRadius: 8,
                            color: Colors.black.withValues(alpha: 0.8),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(
                            CupertinoIcons.location_solid,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            salon.address,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.95),
                              fontWeight: FontWeight.w500,
                              shadows: [
                                Shadow(
                                  offset: const Offset(0, 1),
                                  blurRadius: 4,
                                  color: Colors.black.withValues(alpha: 0.6),
                                ),
                              ],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Status Badge (only show if hours are set)
                    Row(
                      children: [
                        if (salon.hasBusinessHours) _buildStatusBadge(context),
                        if (!salon.isBookable) ...[
                          if (salon.hasBusinessHours) const SizedBox(width: 8),
                          _buildPendingBadge(context),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    final status = BusinessHoursUtils.getStatus(
      openingTime: salon.openingTime,
      closingTime: salon.closingTime,
    );
    final statusColor = BusinessHoursUtils.getStatusColor(status);
    final statusText = BusinessHoursUtils.getStatusText(
      openingTime: salon.openingTime,
      closingTime: salon.closingTime,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Pulsing dot for open status
          _PulsingDot(color: statusColor, isAnimated: status == SalonStatus.open),
          const SizedBox(width: 6),
          Text(
            statusText,
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              shadows: [
                Shadow(
                  offset: const Offset(0, 1),
                  blurRadius: 2,
                  color: Colors.black.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingBadge(BuildContext context) {
    const badgeColor = Color(0xFFF97316); // Orange
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: badgeColor.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(CupertinoIcons.clock, size: 12, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            'Pending Approval',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              shadows: [
                Shadow(
                  offset: const Offset(0, 1),
                  blurRadius: 2,
                  color: Colors.black.withValues(alpha: 0.5),
                ),
              ],
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
      }) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 20),
        onPressed: onTap,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      ),
    );
  }
}

/// A pulsing dot indicator for status display.
class _PulsingDot extends StatefulWidget {
  final Color color;
  final bool isAnimated;

  const _PulsingDot({
    required this.color,
    this.isAnimated = true,
  });

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.isAnimated) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(_PulsingDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isAnimated && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.isAnimated && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isAnimated) {
      return Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
        ),
      );
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: _animation.value * 0.6),
                blurRadius: 4 * _animation.value,
                spreadRadius: 2 * _animation.value,
              ),
            ],
          ),
        );
      },
    );
  }
}