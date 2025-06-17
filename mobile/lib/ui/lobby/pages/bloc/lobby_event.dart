part of 'lobby_bloc.dart';

class LobbyEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class OpenJoinLobby extends LobbyEvent {
  @override
  List<Object?> get props => [];
}

class OpenCreateLobby extends LobbyEvent {
  @override
  List<Object?> get props => [];
}

class JoinLobby extends LobbyEvent {
  JoinLobby({required this.gameCode});

  final String gameCode;

  @override
  List<Object?> get props => [gameCode];
}

class CreateLobby extends LobbyEvent {
  CreateLobby({required this.gameMode});

  final String gameMode;

  @override
  List<Object?> get props => [gameMode];
}

class RefreshLobby extends LobbyEvent {
  RefreshLobby({required this.lobby});

  final Lobby lobby;

  @override
  List<Object?> get props => [lobby];
}

class LeaveLobby extends LobbyEvent {
  @override
  List<Object?> get props => [];
}

class UpdatePlayArea extends LobbyEvent {
  UpdatePlayArea({
    required this.lng,
    required this.lat,
    required this.radius,
  });

  final num lng;
  final num lat;
  final double radius;

  @override
  List<Object?> get props => [lng, lat, radius];
}

class UpdateSetting extends LobbyEvent {
  UpdateSetting({
    required this.key,
    required this.value,
  });

  final String key;
  final dynamic value;

  @override
  List<Object?> get props => [key, value];
}

class RemovePlayer extends LobbyEvent {
  RemovePlayer({
    required this.uid,
  });

  final String uid;

  @override
  List<Object?> get props => [uid];
}

class UpdateReady extends LobbyEvent {
  UpdateReady({
    required this.ready,
  });

  final bool ready;

  @override
  List<Object?> get props => [ready];
}

class StartGame extends LobbyEvent {
  StartGame();

  @override
  List<Object?> get props => [];
}