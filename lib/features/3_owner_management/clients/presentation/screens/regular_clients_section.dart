import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:pendeza/app/config/theme/app_constants.dart';
import 'package:pendeza/shared/widgets/profile_avatar.dart';
import '../../domain/models/regular_client.dart';
import '../widgets/client_quick_view_bottom_sheet.dart';


/// Horizontal scroll of top regular clients
/// Instagram story vibes - big circle avatars with names below
class RegularClientsSection extends StatelessWidget {
  final List<RegularClient> clients;

  const RegularClientsSection({
    super.key,
    required this.clients,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppConstants.padL),
          child: Row(
            children: [
              Icon(
                CupertinoIcons.star_fill,
                color: theme.colorScheme.secondary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'owner.clients.regulars_title'.tr(),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppConstants.padM),
        SizedBox(
          height: 110,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: AppConstants.padM),
            scrollDirection: Axis.horizontal,
            itemCount: clients.length,
            itemBuilder: (context, index) {
              return _RegularClientItem(
                client: clients[index],
                showBadge: index < 3, // Gold, silver, bronze for top 3
              );
            },
          ),
        ),
      ],
    );
  }
}

class _RegularClientItem extends StatelessWidget {
  final RegularClient client;
  final bool showBadge;

  const _RegularClientItem({
    required this.client,
    required this.showBadge,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: GestureDetector(
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => ClientQuickViewBottomSheet(client: client),
          );
        },
        child: SizedBox(
          width: 75,
          child: Column(
            children: [
              // Avatar with gradient border
              Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.secondary,
                        ],
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.colorScheme.surface,
                      ),
                      child: ProfileAvatar(
                        fullName: client.name,
                        imageUrl: client.photoUrl,
                        radius: 28,
                      ),
                    ),
                  ),
                  
                  // Visit count badge
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary,
                            theme.colorScheme.secondary,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: theme.colorScheme.surface,
                          width: 2,
                        ),
                      ),
                      child: Text(
                        '${client.visitCount}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              
              // Name
              Text(
                client.name.split(' ').first, // First name only
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              
              // Last visit
              Text(
                client.lastVisitFormatted,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  fontSize: 10,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
