import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ready_or_not/models/lobby.dart';
import 'package:ready_or_not/repository/lobby/lobby.dart';

part 'lobby_event.dart';
part 'lobby_state.dart';

class LobbyBloc extends Bloc<LobbyEvent, LobbyState> {
  LobbyBloc({
    required this.lobbyRepository,
  }) : super(const LobbyState()) {
    on<OpenJoinLobby>(_mapOpenJoinLobbyToState);
    on<OpenCreateLobby>(_mapOpenCreateLobbyToState);
    on<LeaveLobby>(_mapLeaveLobbyToState);

    on<CreateLobby>(_mapCreateLobbyToState);
    on<JoinLobby>(_mapJoinLobbyToState);
    on<RefreshLobby>(_mapRefreshLobbyToState);

    on<UpdatePlayArea>(_mapUpdatePlayAreaToState);
    on<UpdateSetting>(_mapUpdateSettingToState);
    on<RemovePlayer>(_mapRemovePlayerToState);
    on<UpdateReady>(_mapUpdateReadyToState);

    on<StartGame>(_mapStartGameToState);
  }

  final LobbyRepository lobbyRepository;

  void _mapOpenJoinLobbyToState(
      OpenJoinLobby event, Emitter<LobbyState> emit) async {
    emit(
      state.copyWith(
        status: LobbyStatus.joining,
        error: () => null,
      ),
    );
  }

  void _mapOpenCreateLobbyToState(
      OpenCreateLobby event, Emitter<LobbyState> emit) async {
    emit(
      state.copyWith(
        status: LobbyStatus.creating,
        error: () => null,
      ),
    );
  }

  void _mapLeaveLobbyToState(
      LeaveLobby event, Emitter<LobbyState> emit) async {
    emit(
      state.copyWith(
        status: LobbyStatus.loading,
      ),
    );

    await lobbyRepository.leaveLobby();

    emit(
      state.copyWith(
        status: LobbyStatus.joining,
        lobby: Lobby.empty,
        players: [],
        error: () => null,
      ),
    );
  }

  void _mapCreateLobbyToState(
      CreateLobby event, Emitter<LobbyState> emit) async {
    emit(
      state.copyWith(
        status: LobbyStatus.loading,
      ),
    );

    await lobbyRepository.createLobby(event.gameMode);
    lobbyRepository.currentLobbyStream.listen((lobby) {
      add(RefreshLobby(lobby: lobby));
    });
    lobbyRepository.playersStream.listen((players) {
      add(RefreshLobby(lobby: lobbyRepository.currentLobby));
    });

    emit(
      state.copyWith(
        status: LobbyStatus.waiting,
        lobby: lobbyRepository.currentLobby,
        players: lobbyRepository.currentPlayers,
        error: () => null,
      ),
    );
  }

  void _mapJoinLobbyToState(
      JoinLobby event, Emitter<LobbyState> emit) async {
    emit(
      state.copyWith(
        status: LobbyStatus.loading,
        error: () => null,
      ),
    );

    final success = await lobbyRepository.joinLobby(event.gameCode);

    if (success) {
      lobbyRepository.currentLobbyStream.listen((lobby) {
        this.add(RefreshLobby(lobby: lobby));
      });
      lobbyRepository.playersStream.listen((players) {
        this.add(RefreshLobby(lobby: lobbyRepository.currentLobby));
      });

      emit(
        state.copyWith(
          status: LobbyStatus.waiting,
          lobby: lobbyRepository.currentLobby,
          players: lobbyRepository.currentPlayers,
          error: () => null,
        ),
      );
    } else {
      emit(
        state.copyWith(
          status: LobbyStatus.joining,
          error: () => 'Invalid game code',
        ),
      );
    }
  }

  void _mapRefreshLobbyToState(
      RefreshLobby event, Emitter<LobbyState> emit) async {
    emit(
      state.copyWith(
        lobby: lobbyRepository.currentLobby,
        players: lobbyRepository.currentPlayers,
        error: () => null,
      ),
    );
  }

  void _mapUpdatePlayAreaToState(
      UpdatePlayArea event, Emitter<LobbyState> emit) async {
    await lobbyRepository.updatePlayArea(event.lng, event.lat, event.radius);

    emit(
      state.copyWith(
        lobby: lobbyRepository.currentLobby,
        players: lobbyRepository.currentPlayers,
      ),
    );
  }

  void _mapUpdateSettingToState(
      UpdateSetting event, Emitter<LobbyState> emit) async {
    await lobbyRepository.updateSetting(event.key, event.value);

    emit(
      state.copyWith(
        lobby: lobbyRepository.currentLobby,
        players: lobbyRepository.currentPlayers,
      ),
    );
  }

  void _mapRemovePlayerToState(
      RemovePlayer event, Emitter<LobbyState> emit) async {
    await lobbyRepository.removePlayer(event.uid);

    emit(
      state.copyWith(
        lobby: lobbyRepository.currentLobby,
        players: lobbyRepository.currentPlayers,
      ),
    );
  }

  void _mapUpdateReadyToState(
      UpdateReady event, Emitter<LobbyState> emit) async {
    await lobbyRepository.updateReady(event.ready);

    emit(
      state.copyWith(
        lobby: lobbyRepository.currentLobby,
        players: lobbyRepository.currentPlayers,
      ),
    );
  }

  void _mapStartGameToState(
      StartGame event, Emitter<LobbyState> emit) async {
    await lobbyRepository.startGame();

    emit(
      state.copyWith(
        status: LobbyStatus.playing,
        lobby: lobbyRepository.currentLobby,
        players: lobbyRepository.currentPlayers,
        error: () => null,
      ),
    );
  }
}