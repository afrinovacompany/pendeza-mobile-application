import 'package:equatable/equatable.dart';
import 'package:pendeza/shared/models/staff_model.dart';

abstract class StaffEvent extends Equatable {
  const StaffEvent();

  @override
  List<Object> get props => [];
}

class FetchStaffRequested extends StaffEvent {}

class AddStaffRequested extends StaffEvent {
  final StaffModel staff;
  const AddStaffRequested(this.staff);
  @override
  List<Object> get props => [staff];
}

class UpdateStaffRequested extends StaffEvent {
  final StaffModel staff;
  const UpdateStaffRequested(this.staff);
  @override
  List<Object> get props => [staff];
}

class DeleteStaffRequested extends StaffEvent {
  final String staffId;
  const DeleteStaffRequested(this.staffId);
  @override
  List<Object> get props => [staffId];
}
