import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:ready_or_not/models/classic_game.dart';
import 'package:ready_or_not/repository/gamemodes/classic.dart';

part 'classic_event.dart';
part 'classic_state.dart';

class ClassicBloc extends Bloc<ClassicEvent, ClassicState> {
  ClassicBloc({
    required this.classicRepository
  }) : super(const ClassicState()) {
    on<RefreshGame>(_mapRefreshGameToState);
    on<RegisterTag>(_mapRegisterTagToState);
  }

  final ClassicGameRepository classicRepository;

  void _mapRefreshGameToState(
      RefreshGame event, Emitter<ClassicState> emit) async {
        
    emit(
      state.copyWith(
        game: classicRepository.currentGame,
      ),
    );
  }

  void _mapRegisterTagToState(
      RegisterTag event, Emitter<ClassicState> emit) async {
    await classicRepository.registerTag();

    emit(
      state.copyWith(
        game: classicRepository.currentGame,
      ),
    );
  }
}
