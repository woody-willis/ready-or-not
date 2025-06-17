part of 'lobby_bloc.dart';

enum LobbyStatus { joining, creating, loading, waiting, playing }

extension LobbyStatusX on LobbyStatus {
  bool get isJoining => this == LobbyStatus.joining;
  bool get isCreating => this == LobbyStatus.creating;
  bool get isLoading => this == LobbyStatus.loading;
  bool get isWaiting => this == LobbyStatus.waiting;
  bool get isPlaying => this == LobbyStatus.playing;
}

class LobbyState extends Equatable {
  const LobbyState({
    this.status = LobbyStatus.joining,
    this.lobby,
    this.players,
    this.error,
  });

  final LobbyStatus status;
  final Lobby? lobby;
  final List<LobbyPlayer>? players;
  final String? error;

  @override
  List<Object?> get props => [status, lobby, players, error];

  LobbyState copyWith({
    LobbyStatus? status,
    Lobby? lobby,
    List<LobbyPlayer>? players,
    String? error,
  }) {
    return LobbyState(
      status: status ?? this.status,
      lobby: lobby ?? this.lobby,
      players: players ?? this.players,
      error: error ?? this.error,
    );
  }
}