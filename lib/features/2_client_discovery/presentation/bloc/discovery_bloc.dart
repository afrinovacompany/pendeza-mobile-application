import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pendeza/features/2_client_booking/domain/repositories/booking_repository.dart';
import 'discovery_event.dart';
import 'discovery_state.dart';

class DiscoveryBloc extends Bloc<DiscoveryEvent, DiscoveryState> {
  final BookingRepository _bookingRepository;

  DiscoveryBloc(this._bookingRepository) : super(DiscoveryInitial()) {
    on<FetchSalons>(_onFetchSalons);
  }

  Future<void> _onFetchSalons(
      FetchSalons event, Emitter<DiscoveryState> emit) async {
    emit(DiscoveryLoading());
    try {
      final salons = await _bookingRepository.getSalons();
      emit(DiscoveryLoaded(salons));
    } catch (e) {
      emit(DiscoveryError('Failed to fetch salons: ${e.toString()}'));
    }
  }
}
