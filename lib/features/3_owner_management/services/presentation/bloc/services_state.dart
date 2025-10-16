import 'package:equatable/equatable.dart';
import 'package:pendeza/shared/models/service_model.dart';

abstract class ServicesState extends Equatable {
  const ServicesState();

  @override
  List<Object> get props => [];
}

class ServicesInitial extends ServicesState {}

class ServicesLoading extends ServicesState {}

// Renamed for clarity
class ServicesLoadSuccess extends ServicesState {
  final List<ServiceModel> services;

  const ServicesLoadSuccess(this.services);

  @override
  List<Object> get props => [services];
}

class ServicesError extends ServicesState {
  final String message;

  const ServicesError(this.message);

  @override
  List<Object> get props => [message];
}

// --- NEW STATES TO HANDLE ADD/UPDATE/DELETE OPERATIONS ---

// State for when an operation like add, update, or delete is in progress
class ServiceOperationInProgress extends ServicesState {}

// State to signal that an operation was successful
class ServiceOperationSuccess extends ServicesState {}
