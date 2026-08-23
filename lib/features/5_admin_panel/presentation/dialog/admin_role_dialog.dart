// lib/features/5_admin_panel/presentation/dialog/admin_role_dialog.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pendeza/app/config/theme/app_colors.dart';
import 'package:pendeza/app/config/theme/app_constants.dart';
import 'package:pendeza/app/config/theme/app_text_styles.dart';
import 'package:pendeza/features/0_auth/data/models/user_model.dart';
import 'package:pendeza/features/5_admin_panel/presentation/bloc/admin_bloc.dart';
import 'package:pendeza/features/5_admin_panel/presentation/bloc/admin_event.dart';

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

class _AdminRoleDialogState extends State<AdminRoleDialog>
    with SingleTickerProviderStateMixin {
  late String _selectedRole;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  final List<_RoleOption> _roles = [
    _RoleOption(
      role: 'admin',
      title: 'Administrator',
      description: 'Full access to all features and settings',
      icon: CupertinoIcons.shield_lefthalf_fill,
      color: AppColors.error,
    ),
    _RoleOption(
      role: 'owner',
      title: 'Salon Owner',
      description: 'Manage salon services and bookings',
      icon: CupertinoIcons.building_2_fill,
      color: AppColors.accent2,
    ),
    _RoleOption(
      role: 'client',
      title: 'Client',
      description: 'Book appointments and view services',
      icon: CupertinoIcons.person_fill,
      color: AppColors.success,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.user.role ?? 'client';
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 480),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurfaceVariant : Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        CupertinoIcons.person_crop_circle_badge_checkmark,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Edit User Role',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.user.fullName,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(CupertinoIcons.xmark, color: Colors.white),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Role',
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Choose the appropriate role for this user',
                      style: AppTextStyles.caption.copyWith(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.6)
                            : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ..._roles.map((role) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildRoleOption(role, theme, isDark),
                    )),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _selectedRole != widget.user.role
                            ? () {
                          widget.adminBloc.add(UpdateUserRole(
                            userId: widget.user.uid,
                            newRole: _selectedRole,
                          ));
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Icon(CupertinoIcons.checkmark_circle_fill, color: Colors.white),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Role updated successfully',
                                    style: AppTextStyles.bodySmall.copyWith(color: Colors.white),
                                  ),
                                ],
                              ),
                              backgroundColor: AppColors.success,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                          disabledBackgroundColor: isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : AppColors.border,
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(CupertinoIcons.checkmark_alt, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'Save Changes',
                                style: AppTextStyles.button.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleOption(_RoleOption roleOption, ThemeData theme, bool isDark) {
    final isSelected = _selectedRole == roleOption.role;

    return InkWell(
      onTap: () => setState(() => _selectedRole = roleOption.role),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: AppConstants.durationFast,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? roleOption.color.withValues(alpha: 0.1)
              : (isDark ? Colors.white.withValues(alpha: 0.03) : AppColors.background),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? roleOption.color
                : (isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.border),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: roleOption.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(roleOption.icon, color: roleOption.color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    roleOption.title,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    roleOption.description,
                    style: AppTextStyles.caption.copyWith(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.6)
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: AppConstants.durationFast,
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? roleOption.color : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? roleOption.color
                      : (isDark ? Colors.white.withValues(alpha: 0.3) : AppColors.border),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(CupertinoIcons.checkmark, size: 14, color: Colors.white)
                  : null,
            ),
          ],
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
  final Color color;

  _RoleOption({
    required this.role,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}