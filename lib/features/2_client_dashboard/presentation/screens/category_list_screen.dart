import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/config/app_router.dart';
import '../../../../app/config/theme/app_constants.dart';
import '../../../../shared/models/category_data.dart';
import '../../../../app/services/service_locator.dart';
import '../../../../app/services/guest_session_tracker.dart';
import '../../../0_auth/presentation/bloc/auth_bloc.dart';
import '../../../0_auth/presentation/bloc/auth_state.dart';

import '../widgets/category_grid_widget.dart';

class CategoryListScreen extends StatelessWidget {
  const CategoryListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Key: "client.dashboard.categories_title"
        title: Text('client.dashboard.categories_title'.tr()),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: AppConstants.padL),
        child: CategoryGridWidget(
          categories: CategoriesData.allCategories,
          showAll: true, // 🔥 This tells the widget to render EVERYTHING
          onCategorySelected: (categoryId) {
            // Track interaction
            final authState = context.read<AuthBloc>().state;
            if (authState is GuestMode) {
              sl<GuestSessionTracker>().trackFeatureInteraction('category_selected_from_list');
            }

            // Navigate to discovery with the filter
            context.go(AppRoutes.clientDiscover, extra: categoryId);
          },
        ),
      ),
    );
  }
}