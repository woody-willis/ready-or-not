part of 'classic_bloc.dart';

class ClassicState extends Equatable {
  const ClassicState({
    this.game = ClassicGame.empty,
  });

  final ClassicGame game;
  
  @override
  List<Object> get props => [game];

  ClassicState copyWith({
    ClassicGame? game,
  }) {
    return ClassicState(
      game: game ?? this.game,
    );
  }
}
