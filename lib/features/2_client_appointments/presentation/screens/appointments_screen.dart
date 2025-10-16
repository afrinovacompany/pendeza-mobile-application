import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pendeza/app/config/theme/app_constants.dart';
import 'package:pendeza/app/services/service_locator.dart';
import 'package:pendeza/features/2_client_appointments/domain/models/appointment_with_details.dart';
import 'package:pendeza/features/2_client_appointments/presentation/bloc/appointments_bloc.dart';
import 'package:pendeza/features/2_client_appointments/presentation/widgets/appointment_card.dart';
import 'package:pendeza/shared/widgets/empty_state_widget.dart';
import 'package:pendeza/shared/widgets/loading_indicator.dart';

import '../bloc/appoitment_events.dart';
import '../bloc/appoitments_state.dart';

class AppointmentsScreen extends StatelessWidget {
  const AppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
      sl<AppointmentsBloc>()..add(FetchAppointmentsRequested()),
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('My Appointments'),
            bottom: TabBar(
              indicatorColor: Theme.of(context).colorScheme.primary,
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor:
              Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              tabs: const [
                Tab(text: 'Upcoming'),
                Tab(text: 'Past'),
              ],
            ),
          ),
          body: const TabBarView(
            children: [
              _AppointmentsListView(isUpcoming: true),
              _AppointmentsListView(isUpcoming: false),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppointmentsListView extends StatelessWidget {
  final bool isUpcoming;
  const _AppointmentsListView({required this.isUpcoming});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppointmentsBloc, AppointmentsState>(
      builder: (context, state) {
        if (state is AppointmentsLoading || state is AppointmentsInitial) {
          return _buildLoadingState();
        }
        if (state is AppointmentsError) {
          return EmptyStateWidget.error(
            message: state.message,
            onActionPressed: () {
              context.read<AppointmentsBloc>().add(FetchAppointmentsRequested());
            },
          );
        }
        if (state is AppointmentsLoaded) {
          final appointments = isUpcoming
              ? state.upcomingAppointments
              : state.pastAppointments;

          if (appointments.isEmpty) {
            return EmptyStateWidget.notFound(
              message: isUpcoming
                  ? 'You have no upcoming appointments.\nTime to book a new one!'
                  : 'You have no past appointments.',
            );
          }

          return _buildLoadedList(context, appointments);
        }
        return const Center(child: Text('An unknown error occurred.'));
      },
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.padL),
      itemCount: 3,
      itemBuilder: (context, index) {
        return const Padding(
          padding: EdgeInsets.only(bottom: AppConstants.padM),
          child: ShimmerPlaceholder(width: double.infinity, height: 150),
        );
      },
    );
  }

  Widget _buildLoadedList(
      BuildContext context, List<AppointmentWithDetails> appointments) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<AppointmentsBloc>().add(FetchAppointmentsRequested());
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(AppConstants.padL),
        itemCount: appointments.length,
        itemBuilder: (context, index) {
          final appointmentDetails = appointments[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: AppConstants.padM),
            child: AppointmentCard(details: appointmentDetails),
          );
        },
      ),
    );
  }
}
