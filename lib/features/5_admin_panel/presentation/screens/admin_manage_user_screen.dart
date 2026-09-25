import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pendeza/features/0_auth/data/models/user_model.dart';
import 'package:pendeza/features/5_admin_panel/presentation/bloc/admin_bloc.dart';
import 'package:pendeza/features/5_admin_panel/presentation/bloc/admin_event.dart';
import 'package:pendeza/features/5_admin_panel/presentation/bloc/admin_state.dart';
import 'package:pendeza/features/5_admin_panel/presentation/widgets/admin_ui.dart';
import 'package:pendeza/features/5_admin_panel/presentation/widgets/admin_user_list_item.dart';

class AdminManageUsersScreen extends StatefulWidget {
  const AdminManageUsersScreen({super.key});

  @override
  State<AdminManageUsersScreen> createState() =>
      _AdminManageUsersScreenState();
}

class _AdminManageUsersScreenState extends State<AdminManageUsersScreen> {
  String _role = 'all'; // all, client, owner, admin
  String _query = '';

  List<UserModel> _filter(List<UserModel> users) {
    var result = users;
    if (_role != 'all') {
      result = result.where((u) => u.role == _role).toList();
    }
    final q = _query.trim().toLowerCase();
    if (q.isNotEmpty) {
      result = result
          .where((u) =>
              u.fullName.toLowerCase().contains(q) ||
              u.email.toLowerCase().contains(q) ||
              (u.phoneNumber ?? '').toLowerCase().contains(q))
          .toList();
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminBloc, AdminState>(
      builder: (context, state) {
        final loaded = state is AdminLoaded ? state : null;
        final users = loaded?.users ?? const <UserModel>[];

        int count(String role) => users.where((u) => u.role == role).length;

        return AdminPage(
          title: 'Users',
          subtitle: loaded == null ? null : '${users.length} accounts',
          icon: CupertinoIcons.group_solid,
          toolbar: loaded == null
              ? null
              : AdminSearchField(
                  hint: 'Search by name, email or phone',
                  onChanged: (v) => setState(() => _query = v),
                ),
          filters: loaded == null
              ? null
              : AdminFilterBar(
                      chips: [
                        AdminFilterChip(
                          label: 'All',
                          count: users.length,
                          selected: _role == 'all',
                          onTap: () => setState(() => _role = 'all'),
                        ),
                        AdminFilterChip(
                          label: 'Clients',
                          count: count('client'),
                          tone: AdminTone.success,
                          selected: _role == 'client',
                          onTap: () => setState(() => _role = 'client'),
                        ),
                        AdminFilterChip(
                          label: 'Owners',
                          count: count('owner'),
                          tone: AdminTone.info,
                          selected: _role == 'owner',
                          onTap: () => setState(() => _role = 'owner'),
                        ),
                        AdminFilterChip(
                          label: 'Admins',
                          count: count('admin'),
                          tone: AdminTone.danger,
                          selected: _role == 'admin',
                          onTap: () => setState(() => _role = 'admin'),
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
      return const AdminLoadingState();
    }
    if (state is AdminError) {
      return AdminErrorState(
        message: state.message,
        onRetry: () => context.read<AdminBloc>().add(LoadAdminData()),
      );
    }
    if (state is! AdminLoaded) return const SizedBox.shrink();

    final users = _filter(state.users);
    if (users.isEmpty) {
      final filtering = _query.isNotEmpty || _role != 'all';
      return AdminEmptyState(
        icon: CupertinoIcons.person_crop_circle_badge_xmark,
        title: filtering ? 'No matching users' : 'No users yet',
        message: filtering
            ? 'Try a different search or clear the filters.'
            : 'Accounts will appear here as people sign up.',
      );
    }

    final gutter = AdminTheme.gutter(MediaQuery.sizeOf(context).width);
    return GridView.builder(
      padding: EdgeInsets.fromLTRB(gutter, 8, gutter, 32),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 560,
        mainAxisExtent: 78,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: users.length,
      itemBuilder: (context, index) => AdminUserListItem(user: users[index]),
    );
  }
}
