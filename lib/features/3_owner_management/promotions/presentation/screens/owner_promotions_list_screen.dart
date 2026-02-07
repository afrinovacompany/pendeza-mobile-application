
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pendeza/app/config/theme/app_colors.dart';
import 'package:pendeza/app/config/theme/app_constants.dart';
import 'package:pendeza/app/services/service_locator.dart';
import 'package:pendeza/app/services/firestore_service.dart'; // 🔥 ADD THIS
import 'package:pendeza/features/0_auth/presentation/bloc/auth_bloc.dart';
import 'package:pendeza/features/0_auth/presentation/bloc/auth_state.dart';
import 'package:pendeza/shared/widgets/empty_state_widget.dart';
import 'package:pendeza/shared/widgets/loading_indicator.dart';
import 'package:pendeza/app/utils/logger.dart'; // 🔥 ADD THIS
import '../bloc/owner_promotions_bloc.dart';
import '../bloc/owner_promotions_event.dart';
import '../bloc/owner_promotions_state.dart';
import '../widgets/promotion_card.dart';
import 'create_promotion_screen.dart';

class OwnerPromotionsListScreen extends StatelessWidget {
  const OwnerPromotionsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<OwnerPromotionsBloc>(),
      child: const _PromotionsListView(),
    );
  }
}

class _PromotionsListView extends StatefulWidget {
  const _PromotionsListView();

  @override
  State<_PromotionsListView> createState() => _PromotionsListViewState();
}

class _PromotionsListViewState extends State<_PromotionsListView> {
  String? _cachedSalonId; // 🔥 CACHE SALON ID
  bool _isLoadingSalonId = false;

  @override
  void initState() {
    super.initState();
    _loadPromotions();
  }

  // 🔥 FIXED: Actually fetch and dispatch the event
  Future<void> _loadPromotions() async {
    if (_isLoadingSalonId) return;

    setState(() => _isLoadingSalonId = true);

    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is! Authenticated) {
        throw Exception('User not authenticated');
      }

      log.i('Fetching salon for owner: ${authState.user.uid}');

      final salon = await sl<FirestoreService>().getSalonForOwner(
        ownerId: authState.user.uid,
      );

      if (salon == null) {
        throw Exception('No salon found for this owner');
      }

      log.i('Found salon: ${salon.id} - ${salon.salonName}');

      setState(() {
        _cachedSalonId = salon.id;
        _isLoadingSalonId = false;
      });

      if (mounted) {
        // 🔥 DISPATCH THE EVENT WITH THE CORRECT SALON ID
        context.read<OwnerPromotionsBloc>().add(LoadOwnerPromotions(salon.id));
      }
    } catch (e, stackTrace) {
      log.e('Failed to load promotions', error: e, stackTrace: stackTrace);
      setState(() => _isLoadingSalonId = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load salon data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Promotions'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: BlocConsumer<OwnerPromotionsBloc, OwnerPromotionsState>(
        listener: (context, state) {
          if (state is OwnerPromotionsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },
        builder: (context, state) {
          // 🔥 SHOW LOADING WHILE FETCHING SALON ID
          if (_isLoadingSalonId || _cachedSalonId == null) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading salon information...'),
                ],
              ),
            );
          }

          if (state is OwnerPromotionsLoading) {
            return _buildLoadingList();
          }

          if (state is OwnerPromotionsLoaded) {
            if (state.promotions.isEmpty) {
              return EmptyStateWidget(
                title: 'No Promotions Yet',
                message: 'Create a promotion to boost your salon visibility!',
                iconData: Icons.local_offer_outlined,
                actionText: 'Create Promotion',
                onActionPressed: () => _navigateToCreate(context),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(AppConstants.padM),
              itemCount: state.promotions.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppConstants.padM),
              itemBuilder: (context, index) {
                return PromotionCard(
                  promotion: state.promotions[index],
                  onTap: () {
                    // TODO: Navigate to details/edit
                  },
                  onToggleStatus: (isActive) {
                    context.read<OwnerPromotionsBloc>().add(
                      ToggleSalonPromotionStatus(
                        salonId: _cachedSalonId!, // 🔥 USE CACHED ID
                        promotionId: state.promotions[index].id,
                        isActive: isActive,
                      ),
                    );
                  },
                  onDelete: () {
                    _showDeleteConfirmation(context, state.promotions[index]);
                  },
                );
              },
            );
          }

          // Initial state or error with retry
          return Center(
            child: ElevatedButton(
              onPressed: _loadPromotions,
              child: const Text('Load Promotions'),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToCreate(context),
        label: const Text('New Promo'),
        icon: const Icon(Icons.add),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _navigateToCreate(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<OwnerPromotionsBloc>(),
          child: CreatePromotionScreen(salonId: _cachedSalonId), // 🔥 PASS SALON ID
        ),
      ),
    );
  }

  // 🔥 NEW: Delete confirmation dialog
  void _showDeleteConfirmation(BuildContext context, promotion) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Promotion'),
        content: Text('Are you sure you want to delete "${promotion.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<OwnerPromotionsBloc>().add(
                DeleteSalonPromotion(
                  salonId: _cachedSalonId!,
                  promotionId: promotion.id,
                  imageUrl: promotion.imageUrl,
                ),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingList() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.padM),
      itemCount: 3,
      itemBuilder: (_, __) => const Padding(
        padding: EdgeInsets.only(bottom: AppConstants.padM),
        child: ShimmerPlaceholder.rectangular(height: 160),
      ),
    );
  }
}