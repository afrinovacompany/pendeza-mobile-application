import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pendeza/features/5_admin_panel/presentation/bloc/admin_bloc.dart';
import 'package:pendeza/features/5_admin_panel/presentation/bloc/admin_event.dart';
import 'package:pendeza/features/5_admin_panel/presentation/bloc/admin_state.dart';
import 'package:pendeza/features/5_admin_panel/presentation/widgets/admin_ui.dart';
import 'package:pendeza/shared/models/salon_model.dart';
import 'package:pendeza/shared/widgets/custom_snackbar.dart';
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
  bool _appliedRouteFilter = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The dashboard can deep-link straight to the pending queue.
    if (!_appliedRouteFilter) {
      _appliedRouteFilter = true;
      final extra = GoRouterState.of(context).extra;
      if (extra is String &&
          const {'pending', 'approved', 'rejected'}.contains(extra)) {
        _filterStatus = extra;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminBloc, AdminState>(
      builder: (context, state) {
        final loaded = state is AdminLoaded ? state : null;
        final salons = loaded?.salons ?? const <SalonModel>[];

        return AdminPage(
          title: 'Salons',
          subtitle: loaded == null
              ? null
              : '${salons.length} registered · '
                  '${salons.where((s) => s.isPending).length} pending',
          icon: CupertinoIcons.building_2_fill,
          toolbar: loaded == null
              ? null
              : AdminSearchField(
                  hint: 'Search by salon name or address',
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
          filters: loaded == null
              ? null
              : AdminFilterBar(
                      chips: [
                        AdminFilterChip(
                          label: 'All',
                          count: salons.length,
                          selected: _filterStatus == 'all',
                          onTap: () => setState(() => _filterStatus = 'all'),
                        ),
                        AdminFilterChip(
                          label: 'Pending',
                          count: salons.where((s) => s.isPending).length,
                          tone: AdminTone.warning,
                          selected: _filterStatus == 'pending',
                          onTap: () =>
                              setState(() => _filterStatus = 'pending'),
                        ),
                        AdminFilterChip(
                          label: 'Approved',
                          count: salons.where((s) => s.isApproved).length,
                          tone: AdminTone.success,
                          selected: _filterStatus == 'approved',
                          onTap: () =>
                              setState(() => _filterStatus = 'approved'),
                        ),
                        AdminFilterChip(
                          label: 'Rejected',
                          count: salons.where((s) => s.isRejected).length,
                          tone: AdminTone.danger,
                          selected: _filterStatus == 'rejected',
                          onTap: () =>
                              setState(() => _filterStatus = 'rejected'),
                        ),
                      ],
                    ),
          child: _buildBody(context, state),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, AdminState state) {
    if (state is AdminLoading || state is AdminInitial) {
      return const AdminLoadingState(itemHeight: 150);
    }
    if (state is AdminError) {
      return AdminErrorState(
        message: state.message,
        onRetry: () => context.read<AdminBloc>().add(LoadAdminData()),
      );
    }
    if (state is! AdminLoaded) return const SizedBox.shrink();

    var salons = state.salons;
    if (_filterStatus != 'all') {
      salons =
          salons.where((s) => s.verificationStatus == _filterStatus).toList();
    }
    final q = _searchQuery.trim().toLowerCase();
    if (q.isNotEmpty) {
      salons = salons
          .where((s) =>
              s.salonName.toLowerCase().contains(q) ||
              s.address.toLowerCase().contains(q))
          .toList();
    }

    if (salons.isEmpty) {
      final filtering = q.isNotEmpty || _filterStatus != 'all';
      return AdminEmptyState(
        icon: CupertinoIcons.building_2_fill,
        title: filtering ? 'No matching salons' : 'No salons yet',
        message: filtering
            ? 'Try a different search or switch the status filter.'
            : 'Salons appear here once owners register them.',
      );
    }

    final width = MediaQuery.sizeOf(context).width;
    final gutter = AdminTheme.gutter(width);
    final columns = width >= AdminTheme.wideBreakpoint ? 2 : 1;
    final rowCount = (salons.length / columns).ceil();

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(gutter, 8, gutter, 32),
      itemCount: rowCount,
      itemBuilder: (context, row) {
        final children = <Widget>[];
        for (var c = 0; c < columns; c++) {
          final index = row * columns + c;
          if (c > 0) children.add(const SizedBox(width: 12));
          children.add(
            Expanded(
              child: index < salons.length
                  ? _SalonCard(
                      key: ValueKey(salons[index].id),
                      salon: salons[index],
                      users: state.users,
                    )
                  : const SizedBox.shrink(),
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        );
      },
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// SALON CARD
// ═════════════════════════════════════════════════════════════════════════════

AdminTone _statusTone(SalonModel salon) {
  if (salon.isApproved) return AdminTone.success;
  if (salon.isPending) return AdminTone.warning;
  return AdminTone.danger;
}

class _StatusPill extends StatelessWidget {
  final SalonModel salon;
  const _StatusPill({required this.salon});

  @override
  Widget build(BuildContext context) {
    final IconData icon;
    final String text;
    if (salon.isApproved) {
      icon = CupertinoIcons.checkmark_seal_fill;
      text = 'Approved';
    } else if (salon.isPending) {
      icon = CupertinoIcons.hourglass;
      text = 'Pending';
    } else {
      icon = CupertinoIcons.xmark_circle_fill;
      text = 'Rejected';
    }
    return AdminPill(label: text, tone: _statusTone(salon), icon: icon);
  }
}

class _SalonCard extends StatefulWidget {
  final SalonModel salon;
  final List<dynamic> users;

  const _SalonCard({
    super.key,
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
      _ownerName = match.fullName;
      _ownerEmail = match.email;
      _ownerAvatar = match.profilePictureUrl;
      _ownerLoaded = true;
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
    final salon = widget.salon;
    final tone = _statusTone(salon);

    return AdminCard(
      onTap: () => _showSalonDetails(context, salon),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Salon identity + status
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProfileAvatar(
                imageUrl: salon.primaryImage,
                fullName: salon.salonName,
                radius: 24,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      salon.salonName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AdminTheme.body(context)
                          .copyWith(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          CupertinoIcons.location_solid,
                          size: 12,
                          color: AdminTheme.textSecondary(context),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            salon.address,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AdminTheme.caption(context),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _StatusPill(salon: salon),
            ],
          ),
          const SizedBox(height: 14),

          // Owner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AdminTheme.inset(context),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                if (!_ownerLoaded)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else ...[
                  ProfileAvatar(
                    imageUrl: _ownerAvatar,
                    fullName: _ownerName,
                    radius: 12,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('OWNER', style: AdminTheme.label(context)),
                        Text(
                          _ownerName ?? 'Unknown',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AdminTheme.body(context)
                              .copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  if (_ownerEmail != null && _ownerEmail!.isNotEmpty)
                    Flexible(
                      child: Text(
                        _ownerEmail!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AdminTheme.caption(context),
                      ),
                    ),
                ],
              ],
            ),
          ),

          // Categories
          if (salon.serviceCategories.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final cat in salon.serviceCategories.take(4))
                  AdminPill(label: cat, tone: AdminTone.primary),
                if (salon.serviceCategories.length > 4)
                  AdminPill(
                    label: '+${salon.serviceCategories.length - 4}',
                    tone: AdminTone.neutral,
                  ),
              ],
            ),
          ],

          // Rejection reason
          if (salon.isRejected && salon.rejectionReason != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AdminTheme.toneTint(context, tone, alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    CupertinoIcons.info_circle_fill,
                    size: 15,
                    color: AdminTheme.toneInk(context, tone),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      salon.rejectionReason!,
                      style: AdminTheme.caption(context).copyWith(
                        color: AdminTheme.toneInk(context, tone),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Actions for pending salons
          if (salon.isPending) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showRejectDialog(context, salon),
                    icon: const Icon(CupertinoIcons.xmark, size: 15),
                    label: const Text('Reject'),
                    style: AdminTheme.outlinedButton(context,
                        tone: AdminTone.danger),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _confirmApprove(context, salon),
                    icon: const Icon(CupertinoIcons.checkmark_alt, size: 16),
                    label: const Text('Approve'),
                    style: AdminTheme.filledButton(context,
                        tone: AdminTone.success),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmApprove(BuildContext context, SalonModel salon) async {
    final confirmed = await showAdminConfirmDialog(
      context,
      title: 'Approve salon?',
      message: '"${salon.salonName}" will become visible to all clients.',
      confirmLabel: 'Approve',
      tone: AdminTone.success,
      icon: CupertinoIcons.checkmark_seal_fill,
    );
    if (!confirmed || !context.mounted) return;

    context.read<AdminBloc>().add(ApproveSalon(salon.id));
    CustomSnackBar.show(
      context,
      message: '${salon.salonName} approved',
      type: SnackBarType.success,
    );
  }

  Future<void> _showRejectDialog(BuildContext context, SalonModel salon) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => _RejectReasonDialog(salon: salon),
    );
    if (reason == null || !context.mounted) return;

    context.read<AdminBloc>().add(
          RejectSalon(salonId: salon.id, reason: reason),
        );
    CustomSnackBar.show(
      context,
      message: '${salon.salonName} rejected',
      type: SnackBarType.error,
    );
  }

  void _showSalonDetails(BuildContext context, SalonModel salon) {
    showAdminSheet<void>(
      context,
      builder: (sheetCtx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ProfileAvatar(
                        imageUrl: salon.primaryImage,
                        fullName: salon.salonName,
                        radius: 30,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              salon.salonName,
                              style: AdminTheme.title(sheetCtx)
                                  .copyWith(fontSize: 20),
                            ),
                            const SizedBox(height: 6),
                            _StatusPill(salon: salon),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  AdminInfoRow(
                    icon: CupertinoIcons.location_solid,
                    label: 'Address',
                    value: salon.address,
                  ),
                  if (salon.fullLocation != null)
                    AdminInfoRow(
                      icon: CupertinoIcons.map,
                      label: 'Location',
                      value: salon.fullLocation!,
                    ),
                  if (salon.phoneNumber != null)
                    AdminInfoRow(
                      icon: CupertinoIcons.phone_fill,
                      label: 'Phone',
                      value: salon.phoneNumber!,
                    ),
                  if (salon.description != null &&
                      salon.description!.isNotEmpty)
                    AdminInfoRow(
                      icon: CupertinoIcons.doc_text,
                      label: 'Description',
                      value: salon.description!,
                    ),
                  if (salon.hasBusinessHours)
                    AdminInfoRow(
                      icon: CupertinoIcons.clock_fill,
                      label: 'Hours',
                      value: '${salon.openingTime} - ${salon.closingTime}',
                    ),
                  AdminInfoRow(
                    icon: CupertinoIcons.tag,
                    label: 'Categories',
                    value: salon.serviceCategories.isEmpty
                        ? 'None'
                        : salon.serviceCategories.join(', '),
                  ),
                  if (salon.businessTypeNames.isNotEmpty)
                    AdminInfoRow(
                      icon: CupertinoIcons.building_2_fill,
                      label: 'Business type',
                      value: salon.businessTypeNames.join(', '),
                    ),
                  AdminInfoRow(
                    icon: CupertinoIcons.photo,
                    label: 'Images',
                    value: '${salon.imageCount} photo(s)',
                  ),
                  const SizedBox(height: 4),
                  AdminCard(
                    color: AdminTheme.inset(sheetCtx),
                    borderColor: Colors.transparent,
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        ProfileAvatar(
                          imageUrl: _ownerAvatar,
                          fullName: _ownerName,
                          radius: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('OWNER', style: AdminTheme.label(sheetCtx)),
                              Text(
                                _ownerName ?? 'Loading…',
                                style: AdminTheme.body(sheetCtx)
                                    .copyWith(fontWeight: FontWeight.w700),
                              ),
                              if (_ownerEmail != null &&
                                  _ownerEmail!.isNotEmpty)
                                Text(
                                  _ownerEmail!,
                                  style: AdminTheme.caption(sheetCtx),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (salon.isPending || salon.isRejected || salon.isApproved)
            Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                8,
                24,
                16 + MediaQuery.paddingOf(sheetCtx).bottom,
              ),
              child: Row(
                children: [
                  if (salon.isApproved || salon.isPending)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(sheetCtx);
                          _showRejectDialog(context, salon);
                        },
                        style: AdminTheme.outlinedButton(sheetCtx,
                            tone: AdminTone.danger),
                        child: Text(
                          salon.isApproved ? 'Revoke approval' : 'Reject',
                        ),
                      ),
                    ),
                  if ((salon.isApproved || salon.isPending) &&
                      (salon.isPending || salon.isRejected))
                    const SizedBox(width: 12),
                  if (salon.isPending || salon.isRejected)
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          Navigator.pop(sheetCtx);
                          _confirmApprove(context, salon);
                        },
                        style: AdminTheme.filledButton(sheetCtx,
                            tone: AdminTone.success),
                        child: const Text('Approve salon'),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// REJECT DIALOG
// ═════════════════════════════════════════════════════════════════════════════

/// Collects a rejection reason. Pops with the trimmed reason, or null.
class _RejectReasonDialog extends StatefulWidget {
  final SalonModel salon;
  const _RejectReasonDialog({required this.salon});

  @override
  State<_RejectReasonDialog> createState() => _RejectReasonDialogState();
}

class _RejectReasonDialogState extends State<_RejectReasonDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdminDialogFrame(
      icon: CupertinoIcons.xmark_octagon_fill,
      tone: AdminTone.danger,
      title: 'Reject salon',
      message:
          'Tell "${widget.salon.salonName}" why it was rejected so the owner can fix it.',
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: AdminTheme.textButton(context, tone: AdminTone.neutral),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _controller.text.trim().isEmpty
              ? null
              : () => Navigator.pop(context, _controller.text.trim()),
          style: AdminTheme.filledButton(context, tone: AdminTone.danger),
          child: const Text('Reject'),
        ),
      ],
      child: TextField(
        controller: _controller,
        maxLines: 3,
        maxLength: 250,
        autofocus: true,
        style: AdminTheme.body(context),
        onChanged: (_) => setState(() {}),
        decoration: const InputDecoration(hintText: 'Reason for rejection…'),
      ),
    );
  }
}
