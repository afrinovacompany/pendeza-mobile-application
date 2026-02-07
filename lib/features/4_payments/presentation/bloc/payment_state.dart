import 'package:equatable/equatable.dart';

abstract class PaymentState extends Equatable {
  const PaymentState();
  @override
  List<Object?> get props => [];
}

class PaymentInitial extends PaymentState {}

class PaymentLoading extends PaymentState {}

class PaymentInitiated extends PaymentState {
  final String message;
  const PaymentInitiated(this.message);
  @override
  List<Object?> get props => [message];
}

// New state for successful payment
class PaymentSuccess extends PaymentState {
  final String appointmentId;
  const PaymentSuccess(this.appointmentId);
  @override
  List<Object?> get props => [appointmentId];
}

class PaymentError extends PaymentState {
  final String message;
  const PaymentError(this.message);
  @override
  List<Object?> get props => [message];
}