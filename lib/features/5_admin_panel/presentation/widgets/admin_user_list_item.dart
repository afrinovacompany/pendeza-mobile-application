import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pendeza/features/0_auth/data/models/user_model.dart';
import 'package:pendeza/shared/widgets/profile_avatar.dart';

import '../dialog/admin_role_dialog.dart';

class AdminUserListItem extends StatelessWidget {
  final UserModel user;
  const AdminUserListItem({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: ProfileAvatar(
        imageUrl: user.profilePictureUrl,
        fullName: user.fullName,
        radius: 20,
      ),
      title: Text(user.fullName),
      subtitle: Text(user.email.isEmpty ? user.phoneNumber ?? 'No Contact' : user.email),
      trailing: Chip(
        label: Text(user.role ?? 'N/A'),
        backgroundColor: _getRoleColor(user.role).withOpacity(0.1),
        labelStyle: TextStyle(color: _getRoleColor(user.role)),
      ),
      onTap: () {
        // Show dialog to change role
        showDialog(
          context: context,
          builder: (dialogContext) => AdminRoleDialog(
            user: user,
            // Pass the AdminBloc from the current context
            adminBloc: context.read(),
          ),
        );
      },
    );
  }

  Color _getRoleColor(String? role) {
    switch (role) {
      case 'admin':
        return Colors.red;
      case 'owner':
        return Colors.blue;
      case 'client':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}