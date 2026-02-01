import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pendeza/app/config/theme/app_constants.dart';
import 'package:pendeza/app/config/theme/app_colors.dart';
import 'package:pendeza/app/services/service_locator.dart';
import 'package:pendeza/app/services/analytics_service.dart';
import 'package:pendeza/app/services/firestore_service.dart';
import 'package:pendeza/features/0_auth/presentation/bloc/auth_bloc.dart';
import 'package:pendeza/features/0_auth/presentation/bloc/auth_state.dart';
import '../../../../../app/utils/client_invite_util.dart';
import '../bloc/client_management_bloc.dart';
import '../bloc/client_management_event.dart';
import '../bloc/client_management_state.dart';
import '../widgets/client_list_item.dart';
import '../widgets/client_search_bar.dart';

class ClientsListScreen extends StatelessWidget {
  const ClientsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<ClientManagementBloc>()..add(const LoadClients()),
      child: const _ClientsListView(),
    );
  }
}

class _ClientsListView extends StatelessWidget {
  const _ClientsListView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            const ClientSearchBar(),
            Expanded(
              child: BlocBuilder<ClientManagementBloc, ClientManagementState>(
                builder: (context, state) {
                  if (state is ClientManagementLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is ClientManagementLoaded) {
                    if (state.clients.isEmpty) {
                      return const Center(child: Text('No clients found. Invite your first one!'));
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.all(AppConstants.padM),
                      itemCount: state.clients.length,
                      itemBuilder: (context, index) {
                        return ClientListItem(
                          clientStats: state.clients[index],
                          onTap: () {
                            // Navigate to details (existing logic)
                          },
                        );
                      },
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _handleInvite(context),
        label: const Text('Invite Client'),
        icon: const Icon(CupertinoIcons.person_add),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Future<void> _handleInvite(BuildContext context) async {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      // 1. Fetch salon data (needed for the salon name in the message)
      final salon = await sl<FirestoreService>().getSalonForOwner(
        ownerId: authState.user.uid,
      );

      if (salon != null) {
        // 2. Use our utility to open the Native Share Sheet
        if (context.mounted) {
          await ClientInviteUtil.inviteClient(
            salon: salon,
            analytics: sl<AnalyticsService>(),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not find your salon details.')),
          );
        }
      }
    }
  }
}