import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pendeza/features/2_client_dashboard/presentation/bloc/promotion_event.dart';
import 'package:pendeza/features/2_client_dashboard/presentation/bloc/promotion_state.dart';

import '../../../../app/services/promotion_service.dart';


class PromotionsBloc extends Bloc<PromotionsEvent, PromotionsState> {
  final PromotionsService _promotionsService;

  PromotionsBloc(this._promotionsService) : super(PromotionsInitial()) {
    on<LoadDashboardPromotions>(_onLoadDashboardPromotions);
    on<RefreshPromotions>(_onRefreshPromotions);
  }

  Future<void> _onLoadDashboardPromotions(
      LoadDashboardPromotions event,
      Emitter<PromotionsState> emit,
      ) async {
    emit(PromotionsLoading());
    await _fetchPromotions(emit);
  }

  Future<void> _onRefreshPromotions(
      RefreshPromotions event,
      Emitter<PromotionsState> emit,
      ) async {
    // We don't emit Loading on refresh to keep the UI stable
    await _fetchPromotions(emit);
  }

  Future<void> _fetchPromotions(Emitter<PromotionsState> emit) async {
    try {
      final promotions = await _promotionsService.getDashboardPromotions();

      if (promotions.isEmpty) {
        emit(PromotionsEmpty());
      } else {
        emit(PromotionsLoaded(promotions));
      }
    } catch (e) {
      emit(PromotionsError("Failed to load promotions"));
    }
  }
}