import 'package:equatable/equatable.dart';
import 'package:pendeza/shared/models/service_model.dart';

abstract class ServicesEvent extends Equatable {
  const ServicesEvent();

  @override
  List<Object> get props => [];
}

class FetchServicesRequested extends ServicesEvent {}

class AddServiceRequested extends ServicesEvent {
  final ServiceModel service;
  const AddServiceRequested(this.service);
  @override
  List<Object> get props => [service];
}

class UpdateServiceRequested extends ServicesEvent {
  final ServiceModel service;
  const UpdateServiceRequested(this.service);
  @override
  List<Object> get props => [service];
}

class DeleteServiceRequested extends ServicesEvent {
  final String serviceId;
  const DeleteServiceRequested(this.serviceId);
  @override
  List<Object> get props => [serviceId];
}
