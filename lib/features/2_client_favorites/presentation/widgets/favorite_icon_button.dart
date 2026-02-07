import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pendeza/app/services/service_locator.dart';
import 'package:pendeza/features/0_auth/presentation/bloc/auth_bloc.dart';
import 'package:pendeza/features/0_auth/presentation/bloc/auth_state.dart';
import 'package:pendeza/features/2_client_favorites/presentation/bloc/favorites_bloc.dart';
import 'package:pendeza/features/2_client_favorites/presentation/bloc/favorites_event.dart';
import 'package:pendeza/features/2_client_favorites/presentation/bloc/favorites_state.dart';
// Add this import to access the repository interface
import 'package:pendeza/features/2_client_favorites/domain/repositories/favorites_repository.dart';

/// A reusable favorite icon button that handles guest and authenticated users.
class FavoriteIconButton extends StatefulWidget {
  final String salonId;
  final double size;
  final Color? backgroundColor;
  final Color? iconColor;
  final Color? favoriteColor;
  final bool showBackground;
  final VoidCallback? onToggled; // Callback after toggle completes

  const FavoriteIconButton({
    super.key,
    required this.salonId,
    this.size = 20,
    this.backgroundColor,
    this.iconColor,
    this.favoriteColor,
    this.showBackground = true,
    this.onToggled,
  });

  @override
  State<FavoriteIconButton> createState() => _FavoriteIconButtonState();
}

class _FavoriteIconButtonState extends State<FavoriteIconButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isFavorited = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // Setup animation for heart pop effect
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    // Check initial favorite status
    _checkFavoriteStatus();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Check if this salon is already favorited
  Future<void> _checkFavoriteStatus() async {
    if (!mounted) return;

    final authState = context.read<AuthBloc>().state;
    String? userId;
    bool isGuest = false;

    if (authState is Authenticated) {
      userId = authState.user.uid;
      isGuest = false;
    } else if (authState is GuestMode) {
      userId = authState.guestUser.uid;
      isGuest = true;
    }

    if (userId == null) return;

    try {
      // FIX: Get the repository directly from SL, not from the Bloc's private field
      final favRepo = sl<FavoritesRepository>();

      final isFav = await favRepo.isFavorited(
        userId: userId,
        salonId: widget.salonId,
        isGuest: isGuest,
      );

      if (mounted) {
        setState(() {
          _isFavorited = isFav;
        });
      }
    } catch (e) {
      // Fail silently - not critical
      // print('Error checking favorite status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocListener<FavoritesBloc, FavoritesState>(
      listener: (context, state) {
        if (state is FavoriteToggled && state.salonId == widget.salonId) {
          // Update local state
          setState(() {
            _isFavorited = state.isFavorited;
            _isLoading = false;
          });

          // Animate if favorited
          if (state.isFavorited) {
            _animationController.forward().then((_) {
              _animationController.reverse();
            });
          }

          // Show snackbar
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );

          // Trigger callback
          widget.onToggled?.call();
        } else if (state is FavoriteToggling &&
            state.salonId == widget.salonId) {
          setState(() {
            _isLoading = true;
          });
        }
      },
      child: GestureDetector(
        onTap: _isLoading ? null : _handleToggle,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: widget.showBackground
                    ? BoxDecoration(
                  color: widget.backgroundColor ??
                      Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                )
                    : null,
                child: _isLoading
                    ? SizedBox(
                  width: widget.size,
                  height: widget.size,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.colorScheme.primary,
                    ),
                  ),
                )
                    : Icon(
                  _isFavorited
                      ? CupertinoIcons.heart_fill
                      : CupertinoIcons.heart,
                  size: widget.size,
                  color: _isFavorited
                      ? (widget.favoriteColor ?? Colors.red)
                      : (widget.iconColor ??
                      theme.colorScheme.onSurface),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Handle favorite toggle
  void _handleToggle() {
    final authState = context.read<AuthBloc>().state;
    String? userId;
    bool isGuest = false;

    if (authState is Authenticated) {
      userId = authState.user.uid;
      isGuest = false;
    } else if (authState is GuestMode) {
      userId = authState.guestUser.uid;
      isGuest = true;
    }

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to add favorites'),
        ),
      );
      return;
    }

    // Dispatch toggle event
    context.read<FavoritesBloc>().add(
      ToggleFavorite(
        userId: userId,
        salonId: widget.salonId,
        isGuest: isGuest,
      ),
    );
  }
}