import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pendeza/app/config/theme/app_colors.dart';
import 'package:pendeza/app/config/theme/app_constants.dart';
import 'package:pendeza/features/5_admin_panel/presentation/bloc/admin_bloc.dart';
import 'package:pendeza/features/5_admin_panel/presentation/bloc/admin_event.dart';
import 'package:pendeza/features/5_admin_panel/presentation/bloc/admin_state.dart';
import 'package:pendeza/shared/models/salon_model.dart';
import 'package:pendeza/shared/widgets/profile_avatar.dart';

class AdminManageSalonsScreen extends StatefulWidget {
  const AdminManageSalonsScreen({super.key});

  @override
  State<AdminManageSalonsScreen> createState() =>
      _AdminManageSalonsScreenState();
}

class _AdminManageSalonsScreenState extends State<AdminManageSalonsScreen> {
  String _filterStatus = 'all'; // all, pending, approved, rejected
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Salons'),
        backgroundColor:
            isDark ? AppColors.darkSurfaceVariant : theme.colorScheme.surface,
        elevation: 1,
      ),
      backgroundColor: isDark
          ? AppColors.darkBackground
          : theme.scaffoldBackgroundColor.withAlpha(245),
      body: BlocBuilder<AdminBloc, AdminState>(
        builder: (context, state) {
          if (state is AdminLoading || state is AdminInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is AdminError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                  const SizedBox(height: AppConstants.padM),
                  Text(state.message),
                  const SizedBox(height: AppConstants.padM),
                  ElevatedButton(
                    onPressed: () => context.read<AdminBloc>().add(LoadAdminData()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          if (state is AdminLoaded) {
            return _buildBody(context, state);
          }
          return const Center(child: Text('Unknown state.'));
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, AdminLoaded state) {
    final theme = Theme.of(context);

    // Filter salons
    var salons = state.salons;
    if (_filterStatus != 'all') {
      salons = salons
          .where((s) => s.verificationStatus == _filterStatus)
          .toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      salons = salons
          .where((s) =>
              s.salonName.toLowerCase().contains(q) ||
              s.address.toLowerCase().contains(q))
          .toList();
    }

    // Count by status
    final pendingCount =
        state.salons.where((s) => s.isPending).length;
    final approvedCount =
        state.salons.where((s) => s.isApproved).length;
    final rejectedCount =
        state.salons.where((s) => s.isRejected).length;

    return Column(
      children: [
        // Stats row
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppConstants.padM,
            AppConstants.padM,
            AppConstants.padM,
            AppConstants.padS,
          ),
          child: Row(
            children: [
              _buildStatChip(
                context,
                label: 'All',
                count: state.salons.length,
                color: theme.colorScheme.primary,
                isSelected: _filterStatus == 'all',
                onTap: () => setState(() => _filterStatus = 'all'),
              ),
              const SizedBox(width: AppConstants.padS),
              _buildStatChip(
                context,
                label: 'Pending',
                count: pendingCount,
                color: Colors.orange,
                isSelected: _filterStatus == 'pending',
                onTap: () => setState(() => _filterStatus = 'pending'),
              ),
              const SizedBox(width: AppConstants.padS),
              _buildStatChip(
                context,
                label: 'Approved',
                count: approvedCount,
                color: Colors.green,
                isSelected: _filterStatus == 'approved',
                onTap: () => setState(() => _filterStatus = 'approved'),
              ),
              const SizedBox(width: AppConstants.padS),
              _buildStatChip(
                context,
                label: 'Rejected',
                count: rejectedCount,
                color: Colors.red,
                isSelected: _filterStatus == 'rejected',
                onTap: () => setState(() => _filterStatus = 'rejected'),
              ),
            ],
          ),
        ),

        // Search bar
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.padM,
            vertical: AppConstants.padS,
          ),
          child: TextField(
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(
              hintText: 'Search salons...',
              prefixIcon: const Icon(CupertinoIcons.search, size: 20),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppConstants.padM,
                vertical: AppConstants.padS,
              ),
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(AppConstants.radiusValM),
                borderSide: BorderSide(color: theme.dividerColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(AppConstants.radiusValM),
                borderSide: BorderSide(color: theme.dividerColor),
              ),
            ),
          ),
        ),

        // Salon list
        Expanded(
          child: salons.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        CupertinoIcons.building_2_fill,
                        size: 48,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: AppConstants.padM),
                      Text(
                        'No salons found',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color:
                              theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.padM,
                    vertical: AppConstants.padS,
                  ),
                  itemCount: salons.length,
                  itemBuilder: (context, index) {
                    return _SalonCard(
                      salon: salons[index],
                      users: state.users,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildStatChip(
    BuildContext context, {
    required String label,
    required int count,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(
            vertical: AppConstants.padS,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.15)
                : theme.colorScheme.surface,
            borderRadius:
                BorderRadius.circular(AppConstants.radiusValM),
            border: Border.all(
              color: isSelected ? color : theme.dividerColor,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                '$count',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isSelected ? color : null,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isSelected
                      ? color
                      : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// SALON CARD
// ═════════════════════════════════════════════════════════════════════════════

class _SalonCard extends StatefulWidget {
  final SalonModel salon;
  final List<dynamic> users;

  const _SalonCard({
    required this.salon,
    required this.users,
  });

  @override
  State<_SalonCard> createState() => _SalonCardState();
}

class _SalonCardState extends State<_SalonCard> {
  String? _ownerName;
  String? _ownerEmail;
  String? _ownerAvatar;
  bool _ownerLoaded = false;

  @override
  void initState() {
    super.initState();
    _resolveOwner();
  }

  void _resolveOwner() {
    // First try to find from pre-loaded admin users
    try {
      final match = widget.users.firstWhere(
        (u) => u.uid == widget.salon.ownerId,
      );
      setState(() {
        _ownerName = match.fullName;
        _ownerEmail = match.email;
        _ownerAvatar = match.profilePictureUrl;
        _ownerLoaded = true;
      });
    } catch (_) {
      // User not in pre-loaded list - fetch from Firestore
      _fetchOwner();
    }
  }

  Future<void> _fetchOwner() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.salon.ownerId)
          .get();
      if (doc.exists && mounted) {
        final data = doc.data()!;
        setState(() {
          _ownerName = data['fullName'] as String? ?? 'Unknown';
          _ownerEmail = data['email'] as String? ?? '';
          _ownerAvatar = data['profilePictureUrl'] as String?;
          _ownerLoaded = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _ownerName = 'Unknown Owner';
          _ownerLoaded = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final salon = widget.salon;

    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.padS),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusValM),
        side: BorderSide(color: theme.dividerColor),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppConstants.radiusValM),
        onTap: () => _showSalonDetails(context, salon),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.padM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: Salon name + avatar + status badge
              Row(
                children: [
                  ProfileAvatar(
                    imageUrl: salon.primaryImage,
                    fullName: salon.salonName,
                    radius: 22,
                  ),
                  const SizedBox(width: AppConstants.padM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          salon.salonName,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          salon.address,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppConstants.padS),
                  _buildStatusBadge(context, salon),
                ],
              ),
              const SizedBox(height: AppConstants.padM),

              // Row 2: Owner info
              Container(
                padding: const EdgeInsets.all(AppConstants.padS),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.4),
                  borderRadius:
                      BorderRadius.circular(AppConstants.radiusValS),
                ),
                child: Row(
                  children: [
                    Icon(
                      CupertinoIcons.person_fill,
                      size: 14,
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: AppConstants.padXS),
                    Text(
                      'Owner: ',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.5),
                      ),
                    ),
                    if (_ownerLoaded) ...[
                      if (_ownerAvatar != null)
                        Padding(
                          padding: const EdgeInsets.only(
                              right: AppConstants.padXS),
                          child: ProfileAvatar(
                            imageUrl: _ownerAvatar,
                            fullName: _ownerName,
                            radius: 10,
                          ),
                        ),
                      Expanded(
                        child: Text(
                          _ownerName ?? 'Unknown',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (_ownerEmail != null &&
                          _ownerEmail!.isNotEmpty)
                        Text(
                          _ownerEmail!,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.5),
                            fontSize: 10,
                          ),
                        ),
                    ] else
                      const SizedBox(
                        width: 12,
                        height: 12,
                        child:
                            CircularProgressIndicator(strokeWidth: 1.5),
                      ),
                  ],
                ),
              ),

              // Row 3: Categories + business types
              if (salon.serviceCategories.isNotEmpty) ...[
                const SizedBox(height: AppConstants.padS),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: salon.serviceCategories
                      .take(4)
                      .map((cat) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer
                                  .withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(
                                  AppConstants.radiusValCircular),
                            ),
                            child: Text(
                              cat,
                              style:
                                  theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontSize: 10,
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ],

              // Row 4: Rejection reason if rejected
              if (salon.isRejected &&
                  salon.rejectionReason != null) ...[
                const SizedBox(height: AppConstants.padS),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppConstants.padS),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.08),
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusValS),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline,
                          size: 14, color: Colors.red),
                      const SizedBox(width: AppConstants.padXS),
                      Expanded(
                        child: Text(
                          salon.rejectionReason!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.red[700],
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Row 5: Action buttons for pending salons
              if (salon.isPending) ...[
                const SizedBox(height: AppConstants.padM),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _showRejectDialog(context, salon),
                        icon: const Icon(Icons.close_rounded, size: 16),
                        label: const Text('Reject'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(
                              vertical: AppConstants.padS),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppConstants.padM),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            _confirmApprove(context, salon),
                        icon: const Icon(Icons.check_rounded, size: 16),
                        label: const Text('Approve'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              vertical: AppConstants.padS),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, SalonModel salon) {
    Color color;
    String text;
    IconData icon;

    if (salon.isApproved) {
      color = Colors.green;
      text = 'Approved';
      icon = Icons.check_circle_rounded;
    } else if (salon.isPending) {
      color = Colors.orange;
      text = 'Pending';
      icon = Icons.hourglass_empty_rounded;
    } else {
      color = Colors.red;
      text = 'Rejected';
      icon = Icons.cancel_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius:
            BorderRadius.circular(AppConstants.radiusValCircular),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmApprove(BuildContext context, SalonModel salon) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Approve Salon'),
        content: Text(
          'Are you sure you want to approve "${salon.salonName}"?\n\n'
          'This salon will become visible to all clients.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              context.read<AdminBloc>().add(ApproveSalon(salon.id));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${salon.salonName} approved'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext context, SalonModel salon) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Reject Salon'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Rejecting "${salon.salonName}".'),
            const SizedBox(height: AppConstants.padM),
            TextField(
              controller: reasonController,
              maxLines: 3,
              maxLength: 250,
              decoration: const InputDecoration(
                hintText: 'Reason for rejection...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) return;
              Navigator.pop(dialogCtx);
              context.read<AdminBloc>().add(
                    RejectSalon(
                      salonId: salon.id,
                      reason: reason,
                    ),
                  );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${salon.salonName} rejected'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  void _showSalonDetails(BuildContext context, SalonModel salon) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.radiusValL),
        ),
      ),
      builder: (sheetCtx) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(AppConstants.padL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.padL),

              // Salon header
              Row(
                children: [
                  ProfileAvatar(
                    imageUrl: salon.primaryImage,
                    fullName: salon.salonName,
                    radius: 30,
                  ),
                  const SizedBox(width: AppConstants.padM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          salon.salonName,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        _buildStatusBadge(context, salon),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.padL),

              // Details
              _detailRow(theme, CupertinoIcons.location_solid,
                  'Address', salon.address),
              if (salon.fullLocation != null)
                _detailRow(theme, CupertinoIcons.map,
                    'Location', salon.fullLocation!),
              if (salon.phoneNumber != null)
                _detailRow(theme, CupertinoIcons.phone_fill,
                    'Phone', salon.phoneNumber!),
              if (salon.description != null &&
                  salon.description!.isNotEmpty)
                _detailRow(theme, CupertinoIcons.doc_text,
                    'Description', salon.description!),
              if (salon.hasBusinessHours)
                _detailRow(theme, CupertinoIcons.clock_fill,
                    'Hours', '${salon.openingTime} - ${salon.closingTime}'),
              _detailRow(
                theme,
                CupertinoIcons.tag,
                'Categories',
                salon.serviceCategories.join(', '),
              ),
              if (salon.businessTypeNames.isNotEmpty)
                _detailRow(
                  theme,
                  CupertinoIcons.building_2_fill,
                  'Business Type',
                  salon.businessTypeNames.join(', '),
                ),
              _detailRow(
                theme,
                CupertinoIcons.photo,
                'Images',
                '${salon.imageCount} photo(s)',
              ),

              // Owner section
              const SizedBox(height: AppConstants.padM),
              const Divider(),
              const SizedBox(height: AppConstants.padS),
              Text(
                'Owner',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppConstants.padS),
              Row(
                children: [
                  if (_ownerAvatar != null)
                    ProfileAvatar(
                      imageUrl: _ownerAvatar,
                      fullName: _ownerName,
                      radius: 18,
                    ),
                  if (_ownerAvatar != null)
                    const SizedBox(width: AppConstants.padS),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _ownerName ?? 'Loading...',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (_ownerEmail != null)
                          Text(
                            _ownerEmail!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.6),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),

              // Action buttons
              const SizedBox(height: AppConstants.padL),
              if (salon.isPending || salon.isRejected)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetCtx);
                      _confirmApprove(context, salon);
                    },
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Approve Salon'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(AppConstants.padM),
                    ),
                  ),
                ),
              if (salon.isApproved || salon.isPending) ...[
                const SizedBox(height: AppConstants.padS),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetCtx);
                      _showRejectDialog(context, salon);
                    },
                    icon: const Icon(Icons.close_rounded),
                    label: Text(salon.isApproved
                        ? 'Revoke Approval'
                        : 'Reject Salon'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.all(AppConstants.padM),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: AppConstants.padL),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(
      ThemeData theme, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.padS),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
          const SizedBox(width: AppConstants.padS),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
