import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'loading_indicator.dart';


/// A reusable widget to display a user's profile picture or initials.
///
/// It handles multiple states:
/// 1. Displays a network image using `CachedNetworkImage` for performance.
/// 2. Shows a `ShimmerPlaceholder` while the image is loading.
/// 3. Shows a fallback with the user's initials if the image URL is null or fails to load.
class ProfileAvatar extends StatelessWidget {
  /// The URL of the profile image to display.
  final String? imageUrl;

  /// The radius of the avatar circle. Defaults to 24.0.
  final double radius;

  /// The full name of the user, used to generate initials for the fallback.
  final String? fullName;

  /// The font size for the initials. It scales with the radius.
  final double? fontSize;

  const ProfileAvatar({
    super.key,
    this.imageUrl,
    this.radius = 24.0,
    this.fullName,
    this.fontSize,
  });

  /// Generates initials from a full name.
  /// Example: "John Doe" -> "JD"
  String _getInitials() {
    if (fullName == null || fullName!.trim().isEmpty) {
      return '?';
    }
    final names = fullName!.trim().split(' ');
    if (names.length > 1) {
      return names[0][0].toUpperCase() + names.last[0].toUpperCase();
    } else if (names.isNotEmpty) {
      return names[0][0].toUpperCase();
    }
    return '?';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initials = _getInitials();

    // The main widget is a CircleAvatar for a circular shape.
    return CircleAvatar(
      radius: radius,
      backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
      // The child of the CircleAvatar is a ClipOval to ensure
      // all children (image, fallback) are perfectly circular.
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: imageUrl ?? '', // Use empty string to trigger errorBuilder if null
          fit: BoxFit.cover,
          width: radius * 2,
          height: radius * 2,
          // Placeholder to show while the image is loading from the network.
          placeholder: (context, url) => ShimmerPlaceholder.circle(size: radius * 2),
          // Widget to show if the imageUrl is null or fails to load.
          errorWidget: (context, url, error) => Center(
            child: Text(
              initials,
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: fontSize ?? radius * 0.8, // Font size scales with avatar size
              ),
            ),
          ),
        ),
      ),
    );
  }
}
