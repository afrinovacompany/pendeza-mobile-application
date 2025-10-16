import 'package:equatable/equatable.dart';
import 'package:pendeza/shared/models/staff_model.dart';

abstract class StaffState extends Equatable {
  const StaffState();

  @override
  List<Object> get props => [];
}

class StaffInitial extends StaffState {}

class StaffLoading extends StaffState {}

class StaffLoadSuccess extends StaffState {
  final List<StaffModel> staff;

  const StaffLoadSuccess(this.staff);

  @override
  List<Object> get props => [staff];
}

class StaffError extends StaffState {
  final String message;

  const StaffError(this.message);

  @override
  List<Object> get props => [message];
}

class StaffOperationInProgress extends StaffState {}

class StaffOperationSuccess extends StaffState {}
