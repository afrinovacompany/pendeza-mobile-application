import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pendeza/app/config/theme/app_constants.dart';
import 'package:pendeza/shared/models/salon_model.dart';
import 'package:pendeza/features/2_client_discovery/presentation/widgets/salon_description_widget.dart';
import 'package:pendeza/features/2_client_discovery/presentation/widgets/saloon_gallery_widget.dart';
import 'package:pendeza/app/services/service_locator.dart';
import '../../../3_reviews/data/repositories/reviews_repository_impl.dart';

class SalonOverviewTab extends StatelessWidget {
  final SalonModel salon;

  const SalonOverviewTab({super.key, required this.salon});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: AppConstants.padL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. PROMOTIONS SECTION (Placeholder)
          _buildPromotionsSection(context),

          // 2. DESCRIPTION
          SalonDescriptionSection(salon: salon),

          const SizedBox(height: AppConstants.padXXL),

          // 3. ENHANCED QUICK INFO CARD
          _SalonRatingAggregator(
            salonId: salon.id,
            builder: (context, averageRating, totalReviews) {
              return _EnhancedQuickInfoCard(
                salon: salon,
                averageRating: averageRating,
                totalReviews: totalReviews,
              );
            },
          ),

          const SizedBox(height: AppConstants.padXXL),

          // 4. GALLERY PREVIEW
          if (salon.allImages.isNotEmpty)
            SalonGalleryPreview(salon: salon),

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildPromotionsSection(BuildContext context) {
    return const SizedBox.shrink();
  }
}

// ============================================================================
// ENHANCED QUICK INFO CARD - Modern iOS-Inspired Design
// ============================================================================

class _EnhancedQuickInfoCard extends StatelessWidget {
  final SalonModel salon;
  final double averageRating;
  final int totalReviews;

  const _EnhancedQuickInfoCard({
    required this.salon,
    required this.averageRating,
    required this.totalReviews,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.padL),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.surfaceContainerHighest,
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            // Top Section: Rating & Location
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary.withValues(alpha: 0.05),
                    theme.colorScheme.secondary.withValues(alpha: 0.03),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  // Rating Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.tertiary,
                          theme.colorScheme.tertiary.withValues(alpha: 0.85),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.tertiary.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          CupertinoIcons.star_fill,
                          size: 18,
                          color: theme.colorScheme.onTertiary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          averageRating.toStringAsFixed(1),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: theme.colorScheme.onTertiary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '($totalReviews)',
                          style: TextStyle(
                            color: theme.colorScheme.onTertiary.withValues(alpha: 0.9),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Location Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          CupertinoIcons.location_solid,
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          salon.district ?? salon.region ?? 'Tanzania',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Action Buttons Grid
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  if (salon.phoneNumber != null)
                    _buildModernActionButton(
                      context: context,
                      label: 'Call',
                      icon: CupertinoIcons.phone_fill,
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.primary.withValues(alpha: 0.8),
                        ],
                      ),
                      onTap: () => _makePhoneCall(salon.phoneNumber!),
                    ),
                  if (salon.whatsappNumber != null)
                    _buildModernActionButton(
                      context: context,
                      label: 'Chat',
                      icon: CupertinoIcons.chat_bubble_2_fill,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF25D366), Color(0xFF20BA5A)],
                      ),
                      onTap: () => _openWhatsApp(salon.whatsappNumber!),
                    ),
                  if (_hasMapQuery(salon))
                    _buildModernActionButton(
                      context: context,
                      label: 'Map',
                      icon: CupertinoIcons.map_fill,
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.primary.withValues(alpha: 0.8),
                        ],
                      ),
                      onTap: () => _openMap(salon),
                    ),
                  _buildModernActionButton(
                    context: context,
                    label: 'Hours',
                    icon: CupertinoIcons.clock_fill,
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.tertiary,
                        theme.colorScheme.tertiary.withValues(alpha: 0.8),
                      ],
                    ),
                    onTap: () => _showHoursDialog(context, salon),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernActionButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openWhatsApp(String phoneNumber) async {
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'\D'), '');
    final uri = Uri.parse('https://wa.me/$cleanNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  bool _hasMapQuery(SalonModel salon) {
    return salon.address.trim().isNotEmpty ||
        (salon.district?.trim().isNotEmpty ?? false) ||
        (salon.region?.trim().isNotEmpty ?? false);
  }

  Future<void> _openMap(SalonModel salon) async {
    final query = [
      salon.salonName,
      if (salon.address.trim().isNotEmpty) salon.address.trim(),
      if (salon.district?.trim().isNotEmpty ?? false) salon.district!.trim(),
      if (salon.region?.trim().isNotEmpty ?? false) salon.region!.trim(),
    ].join(', ');
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showHoursDialog(BuildContext context, SalonModel salon) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.surface,
                theme.colorScheme.surfaceContainerHighest,
              ],
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary.withValues(alpha: 0.15),
                      theme.colorScheme.secondary.withValues(alpha: 0.08),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  CupertinoIcons.clock_fill,
                  size: 32,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Business Hours',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              if (salon.hasBusinessHours) ...[
                _buildTimeRow(context, 'Opens at', salon.openingTime!),
                const SizedBox(height: 12),
                Divider(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
                const SizedBox(height: 12),
                _buildTimeRow(context, 'Closes at', salon.closingTime!),
              ] else
                Text(
                  'Business hours not set yet',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Got it'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeRow(BuildContext context, String label, String time) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            time,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }
}

// Helper to get ratings
typedef RatingBuilder = Widget Function(BuildContext context, double avg, int count);

class _SalonRatingAggregator extends StatefulWidget {
  final String salonId;
  final RatingBuilder builder;
  const _SalonRatingAggregator({required this.salonId, required this.builder});

  @override
  State<_SalonRatingAggregator> createState() => __SalonRatingAggregatorState();
}

class __SalonRatingAggregatorState extends State<_SalonRatingAggregator> {
  double _averageRating = 0.0;
  int _totalReviews = 0;

  @override
  void initState() {
    super.initState();
    _fetchRatings();
  }

  Future<void> _fetchRatings() async {
    try {
      final reviewsRepo = sl<ReviewsRepository>();
      final avg = await reviewsRepo.getAverageRating(salonId: widget.salonId);
      final count = await reviewsRepo.getReviewCount(salonId: widget.salonId);
      if (mounted) setState(() { _averageRating = avg; _totalReviews = count; });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _averageRating, _totalReviews);
}