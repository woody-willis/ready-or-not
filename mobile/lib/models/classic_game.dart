import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class ClassicGame extends Equatable {
  final String id;
  final String hostUid;
  final ClassicGameStatus status;
  final Timestamp? hideEndTime;
  final Timestamp? gameEndTime;
  final List<String>? seekerUids;
  final List<String>? hiderUids;
  final List<String>? caughtHiderUids;
  final Map? settings;
  final ClassicPlayerRole? winners;

  const ClassicGame({
    required this.id,
    required this.hostUid,
    required this.status,
    required this.hideEndTime,
    required this.gameEndTime,
    this.seekerUids,
    this.hiderUids,
    this.caughtHiderUids,
    this.settings,
    this.winners,
  });
  
  @override
  List<Object?> get props => [id, hostUid, status, hideEndTime, gameEndTime, seekerUids, hiderUids, caughtHiderUids, settings, winners];

  static const empty = ClassicGame(
    id: '',
    hostUid: '',
    status: ClassicGameStatus.waiting,
    hideEndTime: null,
    gameEndTime: null,
    seekerUids: null,
    hiderUids: null,
    caughtHiderUids: null,
    settings: null,
    winners: null,
  );

  factory ClassicGame.fromJson(String id, Map<String, dynamic> json) {
    return ClassicGame(
      id: id,
      hostUid: json['hostUid'] as String,
      status: ClassicGameStatus.fromString(json['status'] as String),
      hideEndTime: json['hideEndTime'] != null ? (json['hideEndTime'] as Timestamp) : null,
      gameEndTime: json['gameEndTime'] != null ? (json['gameEndTime'] as Timestamp) : null,
      seekerUids: (json['seekers'] as List<dynamic>?)?.map((e) => e as String).toList(),
      hiderUids: (json['hiders'] as List<dynamic>?)?.map((e) => e as String).toList(),
      caughtHiderUids: (json['caughtHiders'] as List<dynamic>?)?.map((e) => e as String).toList(),
      settings: json['settings'] as Map<String, dynamic>?,
      winners: json['winner'] != null
          ? ClassicPlayerRole.fromString(json['winner'] as String)
          : null,
    );
  }
}

enum ClassicGameStatus {
  waiting,
  starting,
  inProgress,
  finished;

  static ClassicGameStatus fromString(String status) {
    switch (status) {
      case 'waiting':
        return ClassicGameStatus.waiting;
      case 'starting':
        return ClassicGameStatus.starting;
      case 'in_progress':
        return ClassicGameStatus.inProgress;
      case 'finished':
        return ClassicGameStatus.finished;
      default:
        throw ArgumentError('Unknown game status: $status');
    }
  }
}

class ClassicPlayer extends Equatable {
  final String id;
  final String uid;
  final String name;
  final Timestamp? lastHeartbeat;
  final bool ready;
  final ClassicPlayerLocation? location;
  final ClassicPlayerRole? role;
  final String? status;

  const ClassicPlayer({
    required this.id,
    required this.uid,
    required this.name,
    required this.lastHeartbeat,
    required this.ready,
    this.location,
    this.role,
    this.status,
  });

  @override
  List<Object?> get props => [id, uid, name, lastHeartbeat, ready, location, role, status];

  static const empty = ClassicPlayer(
    id: '',
    uid: '',
    name: '',
    lastHeartbeat: null,
    ready: false,
    location: null,
    role: null,
    status: null,
  );

  factory ClassicPlayer.fromJson(String id, Map<String, dynamic> json) {
    return ClassicPlayer(
      id: id,
      uid: json['uid'] as String,
      name: json['name'] as String,
      lastHeartbeat: json['lastHeartbeat'] as Timestamp?,
      ready: json['ready'] as bool,
      location: json['location'] != null
          ? ClassicPlayerLocation.fromJson(json['location'] as Map<String, dynamic>)
          : null,
      role: json['role'] != null
          ? ClassicPlayerRole.fromString(json['role'] as String)
          : null,
      status: json['status'] as String?,
    );
  }
}

class ClassicPlayerLocation extends Equatable {
  final num lng;
  final num lat;
  final num accuracy;
  final num speed;
  final num heading;

  const ClassicPlayerLocation({
    required this.lng,
    required this.lat,
    required this.accuracy,
    required this.speed,
    required this.heading,
  });

  @override
  List<Object?> get props => [lng, lat, accuracy, speed, heading];

  static const empty = ClassicPlayerLocation(
    lng: 0,
    lat: 0,
    accuracy: 0,
    speed: 0,
    heading: 0,
  );

  factory ClassicPlayerLocation.fromJson(Map<String, dynamic> json) {
    return ClassicPlayerLocation(
      lng: (json['lng'] as num).toDouble(),
      lat: (json['lat'] as num).toDouble(),
      accuracy: (json['accuracy'] as num).toDouble(),
      speed: (json['speed'] as num).toDouble(),
      heading: (json['heading'] as num).toDouble(),
    );
  }
}

enum ClassicPlayerRole {
  seeker,
  hider;

  static ClassicPlayerRole? fromString(String? role) {
    if (role == null) return null;
    switch (role) {
      case 'seeker':
        return ClassicPlayerRole.seeker;
      case 'hider':
        return ClassicPlayerRole.hider;
      default:
        return null; // Handle unexpected role values
    }
  }
}