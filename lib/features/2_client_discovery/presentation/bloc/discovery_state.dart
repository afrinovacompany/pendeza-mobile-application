import 'package:equatable/equatable.dart';
import 'package:pendeza/shared/models/salon_model.dart';

abstract class DiscoveryState extends Equatable {
  const DiscoveryState();

  @override
  List<Object> get props => [];
}

class DiscoveryInitial extends DiscoveryState {}

class DiscoveryLoading extends DiscoveryState {}

class DiscoveryLoaded extends DiscoveryState {
  final List<SalonModel> salons;

  const DiscoveryLoaded(this.salons);

  @override
  List<Object> get props => [salons];
}

class DiscoveryError extends DiscoveryState {
  final String message;

  const DiscoveryError(this.message);

  @override
  List<Object> get props => [message];
}
