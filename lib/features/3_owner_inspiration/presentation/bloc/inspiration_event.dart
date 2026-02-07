// lib/features/3_owner_inspiration/presentation/bloc/inspiration_event.dart
import 'package:equatable/equatable.dart';

abstract class InspirationEvent extends Equatable {
  const InspirationEvent();
  @override
  List<Object> get props => [];
}

class LoadInspiration extends InspirationEvent {
  const LoadInspiration();
}

class RefreshInspiration extends InspirationEvent {
  const RefreshInspiration();
}

class SwitchTab extends InspirationEvent {
  final InspirationTab tab;
  const SwitchTab(this.tab);
  @override
  List<Object> get props => [tab];
}

enum InspirationTab { trends, lookbook }