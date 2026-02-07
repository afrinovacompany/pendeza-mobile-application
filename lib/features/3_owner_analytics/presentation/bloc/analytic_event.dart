// lib/features/3_owner_management/presentation/bloc/analytics_event.dart
import 'package:equatable/equatable.dart';

abstract class AnalyticsEvent extends Equatable {
  const AnalyticsEvent();

  @override
  List<Object> get props => [];
}

class LoadAnalyticsData extends AnalyticsEvent {
  const LoadAnalyticsData();
}

class RefreshAnalyticsData extends AnalyticsEvent {
  const RefreshAnalyticsData();
}