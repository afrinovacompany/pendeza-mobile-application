import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pendeza/app/config/theme/app_constants.dart';
import 'package:pendeza/app/config/theme/app_colors.dart';
import 'package:pendeza/app/services/service_locator.dart';
import 'package:pendeza/app/utils/logger.dart';
import 'package:pendeza/shared/widgets/loading_indicator.dart';
import 'package:pendeza/shared/widgets/empty_state_widget.dart';
import 'package:pendeza/shared/widgets/profile_avatar.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pendeza/app/utils/formatters.dart';
import '../bloc/client_details_bloc.dart';
import '../bloc/client_details_event.dart';
import '../bloc/client_details_state.dart';
import '../widgets/client_appointment_history.dart';
import '../widgets/favorite_services_widget.dart';
import '../../domain/models/client_stats.dart';
import '../../../../0_auth/data/models/user_model.dart';

class ClientDetailsScreen extends StatelessWidget {
  final String clientId;

  const ClientDetailsScreen({
    super.key,
    required this.clientId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<ClientDetailsBloc>()..add(LoadClientDetails(clientId)),
      child: const _ClientDetailsView(),
    );
  }
}

class _ClientDetailsView extends StatelessWidget {
  const _ClientDetailsView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ClientDetailsBloc, ClientDetailsState>(
      builder: (context, state) {
        if (state is ClientDetailsLoading || state is ClientDetailsInitial) {
          return _buildLoadingState(context);
        }

        if (state is ClientDetailsError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Client Details')),
            body: EmptyStateWidget.error(
              message: state.message,
              onActionPressed: () => Navigator.pop(context),
            ),
          );
        }

        if (state is ClientDetailsLoaded) {
          return Scaffold(
            body: RefreshIndicator(
              onRefresh: () async {
                context.read<ClientDetailsBloc>().add(const RefreshClientDetails());
                await context
                    .read<ClientDetailsBloc>()
                    .stream
                    .firstWhere((s) => s is! ClientDetailsLoading);
              },
              child: CustomScrollView(
                slivers: [
                  _buildSliverAppBar(context, state),
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ClientQuickActions(
                          phoneNumber: state.clientUser.phoneNumber,
                          email: state.clientUser.email,
                        ),
                        const SizedBox(height: AppConstants.padL),
                        _ClientStatsCards(clientStats: state.clientStats),
                        const SizedBox(height: AppConstants.padL),
                        if (state.clientStats.favoriteServices.isNotEmpty) ...[
                          FavoriteServicesWidget(clientStats: state.clientStats),
                          const SizedBox(height: AppConstants.padL),
                        ],
                        ClientAppointmentHistory(
                          appointments: state.appointments,
                          clientStats: state.clientStats,
                        ),
                        const SizedBox(height: AppConstants.padXL * 2),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildSliverAppBar(BuildContext context, ClientDetailsLoaded state) {
    final theme = Theme.of(context);

    return SliverAppBar(
      expandedHeight: 300,
      floating: false,
      pinned: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      flexibleSpace: FlexibleSpaceBar(
        background: _ClientProfileHeader(
          clientStats: state.clientStats,
          clientUser: state.clientUser,
        ),
      ),
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.3),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: const Icon(CupertinoIcons.back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Client Details'),
        backgroundColor: theme.scaffoldBackgroundColor,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppConstants.padL),
        children: [
          const ShimmerPlaceholder(height: 200, width: double.infinity),
          const SizedBox(height: AppConstants.padL),
          const ShimmerPlaceholder(height: 80, width: double.infinity),
          const SizedBox(height: AppConstants.padL),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: AppConstants.padM,
            mainAxisSpacing: AppConstants.padM,
            childAspectRatio: 1.5,
            children: List.generate(
              4,
                  (index) => const ShimmerPlaceholder(
                height: double.infinity,
                width: double.infinity,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClientProfileHeader extends StatelessWidget {
  final ClientStats clientStats;
  final UserModel clientUser;

  const _ClientProfileHeader({
    required this.clientStats,
    required this.clientUser,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.secondary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: AppConstants.padXL),
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ProfileAvatar(
                    fullName: clientUser.fullName,
                    imageUrl: clientUser.profilePictureUrl,
                    radius: 50,
                  ),
                ),
                if (clientStats.isRegularClient)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.amber, Colors.orange],
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amber.withValues(alpha: 0.5),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Icon(
                        CupertinoIcons.star_fill,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppConstants.padM),
            Text(
              clientUser.fullName,
              style: theme.textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    CupertinoIcons.calendar,
                    size: 14,
                    color: Colors.white.withValues(alpha: 0.95),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Since ${DateFormat.yMMM().format(clientStats.firstVisit)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.95),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppConstants.padL),
          ],
        ),
      ),
    );
  }
}

class _ClientQuickActions extends StatelessWidget {
  final String? phoneNumber;
  final String? email;

  const _ClientQuickActions({
    this.phoneNumber,
    this.email,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppConstants.padL,
        vertical: AppConstants.padM,
      ),
      padding: const EdgeInsets.all(AppConstants.padL),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.surface,
            theme.colorScheme.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButton(
            context: context,
            icon: CupertinoIcons.phone_fill,
            label: 'Call',
            color: AppColors.success,
            onTap: phoneNumber != null ? () => _makePhoneCall(phoneNumber!) : null,
          ),
          _buildActionButton(
            context: context,
            icon: CupertinoIcons.chat_bubble_fill,
            label: 'SMS',
            color: AppColors.info,
            onTap: phoneNumber != null ? () => _sendSMS(phoneNumber!) : null,
          ),
          _buildActionButton(
            context: context,
            icon: CupertinoIcons.mail_solid,
            label: 'Email',
            color: AppColors.accent,
            onTap: email != null ? () => _sendEmail(email!) : null,
          ),
          _buildActionButton(
            context: context,
            icon: CupertinoIcons.calendar_badge_plus,
            label: 'Book',
            color: theme.colorScheme.primary,
            onTap: () {
              log.i('Book appointment for client');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final isDisabled = onTap == null;

    return Opacity(
      opacity: isDisabled ? 0.4 : 1.0,
      child: InkWell(
        onTap: isDisabled
            ? null
            : () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withValues(alpha: 0.15),
                      color.withValues(alpha: 0.08),
                    ],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: color.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri url = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  Future<void> _sendSMS(String phoneNumber) async {
    final Uri url = Uri.parse('sms:$phoneNumber');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  Future<void> _sendEmail(String email) async {
    final Uri url = Uri.parse('mailto:$email');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }
}

class _ClientStatsCards extends StatelessWidget {
  final ClientStats clientStats;

  const _ClientStatsCards({required this.clientStats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.padL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary.withValues(alpha: 0.15),
                      theme.colorScheme.secondary.withValues(alpha: 0.15),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  CupertinoIcons.chart_bar_fill,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Client Overview',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.padM),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: AppConstants.padM,
            mainAxisSpacing: AppConstants.padM,
            childAspectRatio: 1.4,
            children: [
              _buildStatCard(
                context: context,
                title: 'Total Spent',
                value: AppFormatters.formatCurrency(clientStats.totalSpent),
                icon: CupertinoIcons.money_dollar_circle_fill,
                color: AppColors.success,
                gradient: AppColors.successGradient,
              ),
              _buildStatCard(
                context: context,
                title: 'Total Visits',
                value: '${clientStats.completedAppointments}',
                icon: CupertinoIcons.calendar_circle_fill,
                color: AppColors.info,
                gradient: LinearGradient(
                  colors: [AppColors.info, AppColors.infoLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              _buildStatCard(
                context: context,
                title: 'Avg. Spend',
                value: AppFormatters.formatCurrency(
                  clientStats.completedAppointments > 0
                      ? clientStats.totalSpent / clientStats.completedAppointments
                      : 0,
                ),
                icon: CupertinoIcons.arrow_up_circle_fill,
                color: AppColors.accent,
                gradient: AppColors.accentGradient,
              ),
              _buildStatCard(
                context: context,
                title: 'Last Visit',
                value: _formatLastVisit(clientStats.lastVisit),
                icon: CupertinoIcons.time,
                color: theme.colorScheme.primary,
                gradient: AppColors.primaryGradient,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required LinearGradient gradient,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppConstants.padL),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 22,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                title,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatLastVisit(DateTime lastVisit) {
    final now = DateTime.now();
    final difference = now.difference(lastVisit);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '${weeks}w ago';
    } else {
      return DateFormat.MMMd().format(lastVisit);
    }
  }
}