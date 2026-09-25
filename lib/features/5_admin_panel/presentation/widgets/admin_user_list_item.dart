import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pendeza/features/0_auth/data/models/user_model.dart';
import 'package:pendeza/features/5_admin_panel/presentation/bloc/admin_bloc.dart';
import 'package:pendeza/features/5_admin_panel/presentation/widgets/admin_ui.dart';
import 'package:pendeza/shared/widgets/profile_avatar.dart';

import '../dialog/admin_role_dialog.dart';

class AdminUserListItem extends StatelessWidget {
  final UserModel user;
  const AdminUserListItem({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final contact = user.email.isNotEmpty
        ? user.email
        : (user.phoneNumber ?? 'No contact details');

    return AdminCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      onTap: () {
        showDialog(
          context: context,
          builder: (dialogContext) => AdminRoleDialog(
            user: user,
            // Pass the AdminBloc from the current context
            adminBloc: context.read<AdminBloc>(),
          ),
        );
      },
      child: Row(
        children: [
          ProfileAvatar(
            imageUrl: user.profilePictureUrl,
            fullName: user.fullName,
            radius: 22,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName.isEmpty ? 'Unnamed user' : user.fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AdminTheme.body(context)
                      .copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  contact,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AdminTheme.caption(context),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          AdminPill(
            label: adminRoleLabel(user.role),
            tone: adminRoleTone(user.role),
          ),
          const SizedBox(width: 6),
          Icon(
            CupertinoIcons.chevron_forward,
            size: 14,
            color: AdminTheme.textSecondary(context),
          ),
        ],
      ),
    );
  }
}
