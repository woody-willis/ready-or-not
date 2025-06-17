part of 'classic_bloc.dart';

class ClassicEvent extends Equatable {
  const ClassicEvent();

  @override
  List<Object?> get props => [];
}

class RefreshGame extends ClassicEvent {
  const RefreshGame();
}

class RegisterTag extends ClassicEvent {
  const RegisterTag();
}