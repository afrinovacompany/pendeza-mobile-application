import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pendeza/app/config/theme/app_constants.dart';

import '../bloc/client_management_bloc_new.dart';
import '../bloc/client_management_event_new.dart';


class ClientSearchBar extends StatefulWidget {
  const ClientSearchBar({super.key});

  @override
  State<ClientSearchBar> createState() => _ClientSearchBarState();
}

class _ClientSearchBarState extends State<ClientSearchBar> {
  final _controller = TextEditingController();
  bool _isActive = false;

  void _onSearchChanged(String query) {
    // Debounce search
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_controller.text == query && mounted) {
        context.read<ClientManagementBloc>().add(SearchClients(query));
      }
    });
  }

  void _clearSearch() {
    _controller.clear();
    setState(() => _isActive = false);
    context.read<ClientManagementBloc>().add(const SearchClients(''));
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.all(AppConstants.padL),
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.padM),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: _isActive
            ? Border.all(color: theme.colorScheme.primary, width: 2)
            : null,
      ),
      child: Row(
        children: [
          Icon(
            CupertinoIcons.search,
            color: _isActive
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface.withOpacity(0.5),
            size: 20,
          ),
          const SizedBox(width: AppConstants.padS),
          Expanded(
            child: TextField(
              controller: _controller,
              onChanged: (value) {
                setState(() => _isActive = value.isNotEmpty);
                _onSearchChanged(value);
              },
              decoration: InputDecoration(
                hintText: 'Search by name or phone...',
                hintStyle: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: AppConstants.padM,
                ),
              ),
            ),
          ),
          if (_isActive)
            GestureDetector(
              onTap: _clearSearch,
              child: Icon(
                CupertinoIcons.xmark_circle_fill,
                color: theme.colorScheme.onSurface.withOpacity(0.3),
                size: 20,
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
