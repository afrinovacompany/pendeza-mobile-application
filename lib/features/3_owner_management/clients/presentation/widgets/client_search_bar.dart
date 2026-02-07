import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pendeza/app/config/theme/app_constants.dart';
import '../bloc/client_management_bloc.dart';
import '../bloc/client_management_event.dart';

class ClientSearchBar extends StatefulWidget {
  const ClientSearchBar({super.key});

  @override
  State<ClientSearchBar> createState() => _ClientSearchBarState();
}

class _ClientSearchBarState extends State<ClientSearchBar> {
  final _searchController = TextEditingController();
  bool _isSearching = false;

  void _onSearchChanged(String query) {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_searchController.text == query) {
        context.read<ClientManagementBloc>().add(SearchClients(query));
      }
    });
  }

  void _clearSearch() {
    _searchController.clear();
    context.read<ClientManagementBloc>().add(const SearchClients(''));
    setState(() => _isSearching = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(AppConstants.padM),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.surface,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (value) {
            setState(() => _isSearching = value.isNotEmpty);
            _onSearchChanged(value);
          },
          decoration: InputDecoration(
            hintText: 'Search by name or phone...',
            hintStyle: TextStyle(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            prefixIcon: Container(
              padding: const EdgeInsets.all(12),
              child: Icon(
                CupertinoIcons.search,
                color: theme.colorScheme.primary,
              ),
            ),
            suffixIcon: _isSearching
                ? IconButton(
              icon: Icon(
                CupertinoIcons.clear_circled_solid,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              onPressed: _clearSearch,
            )
                : null,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppConstants.padM,
              vertical: AppConstants.padM,
            ),
          ),
        ),
      ),
    );
  }
}