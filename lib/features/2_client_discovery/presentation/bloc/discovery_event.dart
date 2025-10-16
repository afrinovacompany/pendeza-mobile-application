import 'package:equatable/equatable.dart';

abstract class DiscoveryEvent extends Equatable {
  const DiscoveryEvent();

  @override
  List<Object> get props => [];
}

/// Fired to fetch the initial list of salons for the discovery screen.
class FetchSalons extends DiscoveryEvent {}
