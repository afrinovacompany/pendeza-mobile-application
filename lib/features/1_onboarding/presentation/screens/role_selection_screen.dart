import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../0_auth/presentation/bloc/auth_bloc.dart';
import '../../../0_auth/presentation/bloc/auth_event.dart';
import '../../../0_auth/presentation/bloc/auth_state.dart';
import '../../../0_auth/presentation/widgets/auth_chrome.dart';
import '../widgets/role_card.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        return AuthScaffold(
          isLoading: isLoading,
          loadingMessage: 'common.loading'.tr(),
          body: AuthPageBody(
            expandToFill: true,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AuthHeader(
                  title: 'auth.role.title'.tr(),
                  subtitle: 'auth.role.subtitle'.tr(),
                ),
                const SizedBox(height: AuthChrome.headerGap),

                RoleCard(
                  icon: CupertinoIcons.person_2_fill,
                  title: 'auth.role.client_title'.tr(),
                  subtitle: 'auth.role.client_desc'.tr(),
                  onTap: isLoading
                      ? null
                      : () {
                          context
                              .read<AuthBloc>()
                              .add(const UpdateUserRoleRequested('client'));
                        },
                ),
                const SizedBox(height: AuthChrome.fieldGap),

                RoleCard(
                  icon: CupertinoIcons.building_2_fill,
                  title: 'auth.role.owner_title'.tr(),
                  subtitle: 'auth.role.owner_desc'.tr(),
                  onTap: isLoading
                      ? null
                      : () {
                          context
                              .read<AuthBloc>()
                              .add(const UpdateUserRoleRequested('owner'));
                        },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
