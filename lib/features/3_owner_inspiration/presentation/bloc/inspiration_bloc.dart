// lib/features/3_owner_inspiration/presentation/bloc/inspiration_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pendeza/app/utils/logger.dart';
// Updated import path to match your project structure

import '../../domain/repository/inspiration_repository.dart';
import 'inspiration_event.dart';
import 'inspiration_state.dart';

class InspirationBloc extends Bloc<InspirationEvent, InspirationState> {
  final InspirationRepository _repository;

  InspirationBloc(this._repository) : super(const InspirationInitial()) {
    on<LoadInspiration>(_onLoad);
    on<RefreshInspiration>(_onRefresh);
    on<SwitchTab>(_onSwitchTab);
  }

  Future<void> _onLoad(LoadInspiration event, Emitter<InspirationState> emit) async {
    emit(const InspirationLoading());
    await _fetchData(emit);
  }

  Future<void> _onRefresh(RefreshInspiration event, Emitter<InspirationState> emit) async {
    await _fetchData(emit);
  }

  void _onSwitchTab(SwitchTab event, Emitter<InspirationState> emit) {
    if (state is InspirationLoaded) {
      final current = state as InspirationLoaded;
      emit(current.copyWith(selectedTab: event.tab));
    }
  }

  Future<void> _fetchData(Emitter<InspirationState> emit) async {
    try {
      log.i('InspirationBloc: Fetching content...');
      final articles = await _repository.getArticles();
      final lookbook = await _repository.getLookbook();

      emit(InspirationLoaded(
        articles: articles,
        lookbook: lookbook,
        selectedTab: InspirationTab.trends,
      ));
    } catch (e, s) {
      log.e('InspirationBloc: Failed to load', error: e, stackTrace: s);
      emit(InspirationError('Failed to load inspiration: ${e.toString()}'));
    }
  }
}