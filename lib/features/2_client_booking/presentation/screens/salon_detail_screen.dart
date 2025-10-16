import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pendeza/features/2_client_booking/presentation/bloc/booking_bloc.dart';
import 'package:pendeza/features/2_client_booking/presentation/bloc/booking_event.dart';
import 'package:pendeza/shared/models/salon_model.dart';
import 'package:pendeza/shared/models/service_model.dart';
import '../../../../app/config/theme/app_constants.dart';
import '../../../../app/utils/formatters.dart';
import '../../../../shared/widgets/primary_gradient_button.dart';
import '../../../../app/config/app_router.dart';


// MOCK DATA for services - in a real app, this would come from a BLoC/repository
List<ServiceModel> _getMockServices() {
  return const [
    ServiceModel(
        id: 's1',
        salonId: 'sal1',
        name: 'Gel Manicure',
        price: 25000,
        durationMinutes: 45,
        category: 'Nail Care'),
    ServiceModel(
        id: 's2',
        salonId: 'sal1',
        name: 'Classic Pedicure',
        price: 20000,
        durationMinutes: 40,
        category: 'Nail Care'),
    ServiceModel(
        id: 's3',
        salonId: 'sal1',
        name: 'Swedish Massage (1hr)',
        price: 40000,
        durationMinutes: 60,
        category: 'Massage Therapy'),
    ServiceModel(
        id: 's4',
        salonId: 'sal1',
        name: 'Men\'s Haircut',
        price: 15000,
        durationMinutes: 30,
        category: 'Hair Services'),
    ServiceModel(
        id: 's5',
        salonId: 'sal1',
        name: 'Hair Braiding',
        price: 30000,
        durationMinutes: 90,
        category: 'Hair Services'),
  ];
}

class SalonDetailScreen extends StatefulWidget {
  final SalonModel? salon;

  const SalonDetailScreen({super.key, this.salon});

  @override
  State<SalonDetailScreen> createState() => _SalonDetailScreenState();
}

class _SalonDetailScreenState extends State<SalonDetailScreen> {
  bool _isLoading = true;
  late SalonModel _salonData;
  late List<ServiceModel> _services;
  late Map<String, List<ServiceModel>> _categorizedServices;

  @override
  void initState() {
    super.initState();
    _salonData = widget.salon ?? _getMockSalon();
    _services = _getMockServices(); // Fetch services
    _categorizedServices = _groupServicesByCategory(_services);

    // Simulate network delay
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  Map<String, List<ServiceModel>> _groupServicesByCategory(
      List<ServiceModel> services) {
    final map = <String, List<ServiceModel>>{};
    for (var service in services) {
      (map[service.category] ??= []).add(service);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading ? _buildSkeletonLoader() : _buildContentLoaded(context),
    );
  }

  Widget _buildContentLoaded(BuildContext context) {
    final theme = Theme.of(context);
    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 250.0,
              pinned: true,
              stretch: true,
              backgroundColor: theme.colorScheme.primary,
              iconTheme: const IconThemeData(color: Colors.white),
              flexibleSpace: FlexibleSpaceBar(
                title: Text(_salonData.salonName,
                    style:
                    theme.textTheme.titleLarge?.copyWith(color: Colors.white)),
                centerTitle: false,
                background: Container(
                  decoration: const BoxDecoration(
                    color: Colors.grey,
                  ),
                  child: const Center(
                      child: Icon(Icons.image, size: 80, color: Colors.white54)),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(
                    bottom: 120), // Space for the floating button
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(AppConstants.padL),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow(context,
                              icon: Icons.location_on_outlined,
                              text: _salonData.address),
                          const SizedBox(height: AppConstants.padS),
                          _buildInfoRow(context,
                              icon: Icons.access_time_rounded,
                              text: 'Open Today until 8:00 PM'),
                          const SizedBox(height: AppConstants.padS),
                          _buildInfoRow(context,
                              icon: Icons.star_rounded,
                              text: '4.8 (125 Reviews)'),
                        ],
                      ),
                    ),

                    // NEW: Display services by category
                    ..._categorizedServices.entries.map((entry) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppConstants.padL,
                                vertical: AppConstants.padM),
                            child: Text(entry.key,
                                style: theme.textTheme.headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.bold)),
                          ),
                          ...entry.value.map((service) =>
                              _buildServiceItem(context, service: service)),
                          const SizedBox(height: AppConstants.padM),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
        // Floating "Book Now" Button
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            padding: const EdgeInsets.all(AppConstants.padL),
            color: theme.scaffoldBackgroundColor.withAlpha(230),
            child: PrimaryGradientButton(
              text: 'BOOK APPOINTMENT',
              onPressed: () {
                context.read<BookingBloc>().add(StartBooking(_salonData));
                context.push(
                  AppRoutes.serviceSelection,
                  extra: {'salonName': _salonData.salonName},
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSkeletonLoader() {
    // ... skeleton loader remains the same
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildInfoRow(BuildContext context,
      {required IconData icon, required String text}) {
    // ... info row remains the same
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
        const SizedBox(width: AppConstants.padM),
        Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyLarge)),
      ],
    );
  }

  Widget _buildServiceItem(BuildContext context,
      {required ServiceModel service}) {
    return ListTile(
      title: Text(service.name),
      subtitle: Text('${service.durationMinutes} min'),
      trailing: Text(
        AppFormatters.formatCurrency(service.price),
        style: Theme.of(context)
            .textTheme
            .bodyMedium
            ?.copyWith(fontWeight: FontWeight.bold),
      ),
      onTap: () {
        // Tapping a single service could be a shortcut to the booking flow
        context.read<BookingBloc>().add(StartBooking(_salonData));
        context.read<BookingBloc>().add(SelectServices([service]));
        // --- FIX IS HERE: Navigate to the correct next step ---
        context.push(AppRoutes.timeslotSelection);
      },
    );
  }

  SalonModel _getMockSalon() {
    return SalonModel(
      id: 'mock_id',
      ownerId: 'mock_owner',
      salonName: 'Glamour Touch Salon',
      address: '123 Mbezi Beach, Dar es Salaam',
      serviceCategories: ['Nails', 'Hair', 'Spa'],
      createdAt: DateTime.now(),
    );
  }
}

