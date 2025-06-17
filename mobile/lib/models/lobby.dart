import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class Lobby extends Equatable {
  final String id;
  final String gameCode;
  final String gameMode;
  final String hostUid;
  final DateTime? createdAt;
  final String status;
  final PlayArea? playArea;
  final Map? settings;

  const Lobby({
    required this.id,
    required this.gameCode,
    required this.gameMode,
    required this.hostUid,
    required this.createdAt,
    required this.status,
    this.playArea,
    this.settings,
  });
  
  @override
  List<Object?> get props => [id, gameCode, gameMode, hostUid, createdAt, status, playArea, settings];

  static const empty = Lobby(
    id: '',
    gameCode: '',
    gameMode: '',
    hostUid: '',
    createdAt: null,
    status: '',
    playArea: null,
    settings: null,
  );

  factory Lobby.fromJson(String id, Map<String, dynamic> json) {
    return Lobby(
      id: id,
      gameCode: json['gameCode'] as String,
      gameMode: json['gameMode'] as String,
      hostUid: json['hostUid'] as String,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      status: json['status'] as String,
      playArea: json['playArea'] != null
          ? PlayArea(
              lat: (json['playArea']['center']['lat'] as num).toDouble(),
              lng: (json['playArea']['center']['lng'] as num).toDouble(),
              radius: (json['playArea']['radius'] as num).toDouble(),
            )
          : null,
      settings: json['settings'] as Map<String, dynamic>?,
    );
  }
}

class PlayArea extends Equatable {
  final num lat;
  final num lng;
  final double radius;

  const PlayArea({
    required this.lat,
    required this.lng,
    required this.radius,
  });

  @override
  List<Object?> get props => [lat, lng, radius];
}

class LobbyPlayer extends Equatable {
  final String id;
  final String uid;
  final String name;
  final Timestamp? lastHeartbeat;
  final bool ready;
  final LobbyPlayerLocation? location;

  const LobbyPlayer({
    required this.id,
    required this.uid,
    required this.name,
    required this.lastHeartbeat,
    required this.ready,
    this.location,
  });

  @override
  List<Object?> get props => [id, uid, name, lastHeartbeat, ready, location];

  static const empty = LobbyPlayer(
    id: '',
    uid: '',
    name: '',
    lastHeartbeat: null,
    ready: false,
    location: null,
  );

  factory LobbyPlayer.fromJson(String id, Map<String, dynamic> json) {
    return LobbyPlayer(
      id: id,
      uid: json['uid'] as String,
      name: json['name'] as String,
      lastHeartbeat: json['lastHeartbeat'] as Timestamp?,
      ready: json['ready'] as bool,
      location: json['location'] != null
          ? LobbyPlayerLocation.fromJson(json['location'] as Map<String, dynamic>)
          : null,
    );
  }
}

class LobbyPlayerLocation extends Equatable {
  final num lng;
  final num lat;
  final num accuracy;
  final num speed;
  final num heading;

  const LobbyPlayerLocation({
    required this.lng,
    required this.lat,
    required this.accuracy,
    required this.speed,
    required this.heading,
  });

  @override
  List<Object?> get props => [lng, lat, accuracy, speed, heading];

  static const empty = LobbyPlayerLocation(
    lng: 0,
    lat: 0,
    accuracy: 0,
    speed: 0,
    heading: 0,
  );

  factory LobbyPlayerLocation.fromJson(Map<String, dynamic> json) {
    return LobbyPlayerLocation(
      lng: (json['lng'] as num).toDouble(),
      lat: (json['lat'] as num).toDouble(),
      accuracy: (json['accuracy'] as num).toDouble(),
      speed: (json['speed'] as num).toDouble(),
      heading: (json['heading'] as num).toDouble(),
    );
  }
}