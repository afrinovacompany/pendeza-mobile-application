// lib/features/5_admin_panel/presentation/dialog/admin_role_dialog.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pendeza/app/config/theme/app_constants.dart';
import 'package:pendeza/features/0_auth/data/models/user_model.dart';
import 'package:pendeza/features/5_admin_panel/presentation/bloc/admin_bloc.dart';
import 'package:pendeza/features/5_admin_panel/presentation/bloc/admin_event.dart';
import 'package:pendeza/features/5_admin_panel/presentation/widgets/admin_ui.dart';
import 'package:pendeza/shared/widgets/custom_snackbar.dart';
import 'package:pendeza/shared/widgets/profile_avatar.dart';

class AdminRoleDialog extends StatefulWidget {
  final UserModel user;
  final AdminBloc adminBloc;

  const AdminRoleDialog({
    super.key,
    required this.user,
    required this.adminBloc,
  });

  @override
  State<AdminRoleDialog> createState() => _AdminRoleDialogState();
}

class _AdminRoleDialogState extends State<AdminRoleDialog> {
  late String _selectedRole;

  static const List<_RoleOption> _roles = [
    _RoleOption(
      role: 'admin',
      title: 'Administrator',
      description: 'Full access to all features and settings',
      icon: CupertinoIcons.shield_lefthalf_fill,
      tone: AdminTone.danger,
    ),
    _RoleOption(
      role: 'owner',
      title: 'Salon Owner',
      description: 'Manage salon services and bookings',
      icon: CupertinoIcons.building_2_fill,
      tone: AdminTone.info,
    ),
    _RoleOption(
      role: 'client',
      title: 'Client',
      description: 'Book appointments and view services',
      icon: CupertinoIcons.person_fill,
      tone: AdminTone.success,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.user.role ?? 'client';
  }

  bool get _changed => _selectedRole != widget.user.role;

  void _save() {
    widget.adminBloc.add(UpdateUserRole(
      userId: widget.user.uid,
      newRole: _selectedRole,
    ));
    CustomSnackBar.show(
      context,
      message: 'Role updated successfully',
      type: SnackBarType.success,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;

    return Dialog(
      backgroundColor: AdminTheme.card(context),
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ProfileAvatar(
                    imageUrl: user.profilePictureUrl,
                    fullName: user.fullName,
                    radius: 26,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.fullName.isEmpty ? 'Unnamed user' : user.fullName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AdminTheme.heading(context)
                              .copyWith(fontSize: 18),
                        ),
                        const SizedBox(height: 4),
                        AdminPill(
                          label: 'Currently ${adminRoleLabel(user.role)}',
                          tone: adminRoleTone(user.role),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(CupertinoIcons.xmark, size: 18),
                    style: IconButton.styleFrom(
                      backgroundColor: AdminTheme.inset(context),
                      foregroundColor: AdminTheme.textSecondary(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Text('Change role', style: AdminTheme.heading(context)),
              const SizedBox(height: 2),
              Text(
                'Choose what this person can do in Pendeza.',
                style: AdminTheme.caption(context),
              ),
              const SizedBox(height: 16),
              for (final option in _roles)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _RoleTile(
                    option: option,
                    selected: _selectedRole == option.role,
                    onTap: () => setState(() => _selectedRole = option.role),
                  ),
                ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: AdminTheme.textButton(context,
                          tone: AdminTone.neutral),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: _changed ? _save : null,
                      style: AdminTheme.filledButton(context),
                      icon: const Icon(CupertinoIcons.checkmark_alt, size: 18),
                      label: const Text('Save changes'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleTile extends StatelessWidget {
  final _RoleOption option;
  final bool selected;
  final VoidCallback onTap;

  const _RoleTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final base = AdminTheme.toneBase(context, option.tone);

    return Material(
      color: selected
          ? AdminTheme.toneTint(context, option.tone, alpha: 0.10)
          : AdminTheme.card(context),
      shape: RoundedRectangleBorder(
        borderRadius: AppConstants.radiusM,
        side: BorderSide(
          color: selected ? base : AdminTheme.border(context),
          width: selected ? 1.6 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: AppConstants.radiusM,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              AdminIconTile(icon: option.icon, tone: option.tone, size: 42),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.title,
                      style: AdminTheme.body(context)
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(option.description,
                        style: AdminTheme.caption(context)),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              AnimatedContainer(
                duration: AppConstants.durationFast,
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? base : Colors.transparent,
                  border: Border.all(
                    color: selected ? base : AdminTheme.border(context),
                    width: 1.6,
                  ),
                ),
                child: selected
                    ? const Icon(CupertinoIcons.checkmark,
                        size: 12, color: Colors.white)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleOption {
  final String role;
  final String title;
  final String description;
  final IconData icon;
  final AdminTone tone;

  const _RoleOption({
    required this.role,
    required this.title,
    required this.description,
    required this.icon,
    required this.tone,
  });
}
