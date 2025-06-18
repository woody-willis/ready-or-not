import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ready_or_not/main.dart';
import 'package:ready_or_not/models/lobby.dart';
import 'package:ready_or_not/models/user.dart';
import 'package:ready_or_not/repository/authentication/authentication.dart';

class LobbyRepository {
  LobbyRepository._privateConstructor({
    FirebaseFirestore? firestore,
    AuthenticationRepository? authenticationRepository,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _authenticationRepository = authenticationRepository ?? AuthenticationRepository.instance;

  static final LobbyRepository instance = LobbyRepository._privateConstructor();

  final FirebaseFirestore _firestore;
  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;
  final AuthenticationRepository _authenticationRepository;

  Lobby currentLobby = Lobby.empty;
  List<LobbyPlayer> currentPlayers = [];

  Stream<Lobby> get currentLobbyStream => _firestore.collection('games').doc(currentLobby.id).snapshots().map((snapshot) {
    if (snapshot.exists) {
      return Lobby.fromJson(snapshot.id, snapshot.data()!);
    } else {
      return Lobby.empty;
    }
  });
  StreamSubscription? _currentLobbyStreamSubscription;

  Stream<List<LobbyPlayer>> get playersStream => _firestore.collection('games').doc(currentLobby.id).collection('players').snapshots().map((snapshot) {
    currentPlayers = snapshot.docs.map((doc) => LobbyPlayer.fromJson(doc.id, doc.data())).toList();
    return currentPlayers;
  });
  StreamSubscription? _playersStreamSubscription;

  final LocationSettings locationSettings = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 2,
  );
  StreamSubscription<Position>? locationStream; 

  bool isHost() {
    return currentLobby.hostUid == _authenticationRepository.currentUser.id;
  }
  bool isMe(String uid) {
    return uid == _authenticationRepository.currentUser.id;
  }
  bool isPlayerInLobby() {
    return currentPlayers.any((player) => player.uid == _authenticationRepository.currentUser.id);
  }
  bool isGuest() {
    return _authenticationRepository.currentUser.type == UserType.guest;
  }

  Future<void> createLobby(String gameMode) async {
    await _remoteConfig.fetchAndActivate();

    final hostUid = _authenticationRepository.currentUser.id;
    final gameCode = await getUniqueGameCode();

    // Default settings for gamemode
    final defaultSettingsInfo = jsonDecode(_remoteConfig.getValue("gamemode_${gameMode}_defaultSettings").asString());
    Map<String, dynamic> defaultSettings = {};

    for (Map<String, dynamic> section in defaultSettingsInfo) {
      for (Map setting in section['settings']) {
        defaultSettings[setting['key']] = setting['default'];
      }
    }

    final docRef = await _firestore.collection('games').add({
      'gameCode': gameCode,
      'gameMode': gameMode,
      'hostUid': hostUid,
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'waiting',
      'playArea': {
        'center': {
          'lat': 0,
          'lng': 0,
        },
        'radius': 0,
      },
      'settings': defaultSettings,
    });

    await _firestore.collection('games').doc(docRef.id).collection('players').add({
      'uid': hostUid,
      'name': Constants.prefs!.getString('displayName') ?? _authenticationRepository.currentUser.name,
      'lastHeartbeat': FieldValue.serverTimestamp(),
      'ready': true,
    });

    currentLobby = Lobby.fromJson(docRef.id, await _firestore.collection('games').doc(docRef.id).get().then((doc) => doc.data()!));
    
    _currentLobbyStreamSubscription?.cancel();
    _currentLobbyStreamSubscription = currentLobbyStream.listen((lobby) {
      currentLobby = lobby;
    });

    currentPlayers = await _firestore.collection('games').doc(currentLobby.id).collection('players').get().then((snapshot) {
      return snapshot.docs.map((doc) => LobbyPlayer.fromJson(doc.id, doc.data())).toList();
    });
    _playersStreamSubscription?.cancel();
    _playersStreamSubscription = playersStream.listen((players) {
      currentPlayers = players;
    });

    locationStream = Geolocator.getPositionStream(locationSettings: locationSettings).listen((Position? position) async {
      if (position == null) return;
      if (position.isMocked) return;
      if (currentLobby == Lobby.empty) {
        locationStream?.cancel();
        return;
      }

      await updateLocation(position.longitude, position.latitude, position.accuracy, position.speed, position.heading);
    });

    Position currentPosition = await Geolocator.getCurrentPosition();
    await updateLocation(currentPosition.longitude, currentPosition.latitude, currentPosition.accuracy, currentPosition.speed, currentPosition.heading);
  }

  Future<String> getUniqueGameCode() async {
    int gameCode = Random().nextInt(89999) + 10000;

    while (true) {
      final gameCodeSnapshot = await _firestore.collection('games').where('gameCode', isEqualTo: gameCode).get();

      if (gameCodeSnapshot.docs.isEmpty) {
        break;
      }

      gameCode = Random().nextInt(89999) + 10000;
    }

    return gameCode.toString();
  }


  Future<bool> joinLobby(String gameCode) async {
    await _remoteConfig.fetchAndActivate();
    
    final querySnapshot = await _firestore.collection('games').where('gameCode', isEqualTo: gameCode).where('status', isEqualTo: 'waiting').get();
    if (querySnapshot.docs.isEmpty) {
      return false;
    }
    
    // Check if the user is already in the lobby, if so delete the old player document
    final existingPlayerSnapshot = await _firestore.collection('games').doc(querySnapshot.docs[0].id).collection('players').where('uid', isEqualTo: _authenticationRepository.currentUser.id).get();
    if (existingPlayerSnapshot.docs.isNotEmpty) {
      for (var doc in existingPlayerSnapshot.docs) {
        await doc.reference.delete();
      }
    }

    await _firestore.collection('games').doc(querySnapshot.docs[0].id).collection('players').add({
      'uid': _authenticationRepository.currentUser.id,
      'name': Constants.prefs!.getString('displayName') ?? _authenticationRepository.currentUser.name,
      'lastHeartbeat': FieldValue.serverTimestamp(),
      'ready': false,
    });

    currentLobby = Lobby.fromJson(querySnapshot.docs[0].id, querySnapshot.docs.first.data());

    _currentLobbyStreamSubscription?.cancel();
    _currentLobbyStreamSubscription = currentLobbyStream.listen((lobby) {
      currentLobby = lobby;
    });

    currentPlayers = await _firestore.collection('games').doc(currentLobby.id).collection('players').get().then((snapshot) {
      return snapshot.docs.map((doc) => LobbyPlayer.fromJson(doc.id, doc.data())).toList();
    });
    _playersStreamSubscription?.cancel();
    _playersStreamSubscription = playersStream.listen((players) {
      currentPlayers = players;
    });

    locationStream = Geolocator.getPositionStream(locationSettings: locationSettings).listen((Position? position) async {
      if (position == null) return;
      if (position.isMocked) return;
      if (currentLobby == Lobby.empty) {
        locationStream?.cancel();
        return;
      }

      await updateLocation(position.longitude, position.latitude, position.accuracy, position.speed, position.heading);
    });

    Position currentPosition = await Geolocator.getCurrentPosition();
    await updateLocation(currentPosition.longitude, currentPosition.latitude, currentPosition.accuracy, currentPosition.speed, currentPosition.heading);
    
    return true;
  }

  Future<void> leaveLobby() async {
    try {
      final lobbyId = currentLobby.id;
      final uid = _authenticationRepository.currentUser.id;

      await _firestore.collection('games').doc(lobbyId).collection('players').where('uid', isEqualTo: uid).get().then((snapshot) {
        for (var doc in snapshot.docs) {
          doc.reference.delete();
        }
      });

      final bool isHost = currentLobby.hostUid == uid;
      if (isHost) {
        final playersRef = _firestore.collection('games').doc(lobbyId).collection('players');
        final playersSnapshot = await playersRef.get();
        if (playersSnapshot.docs.isNotEmpty) {
          final newHostDoc = playersSnapshot.docs[0]; // Select the first player as the new host
          await _firestore.collection('games').doc(lobbyId).update({'hostUid': newHostDoc['uid']});
        } else {
          await _firestore.collection('games').doc(lobbyId).delete();
        }
      }
    } catch (e) {
      print('Error leaving lobby: $e');
    }

    currentLobby = Lobby.empty;
    currentPlayers = [];
    locationStream = null;
    _currentLobbyStreamSubscription?.cancel();
    _playersStreamSubscription?.cancel();
    locationStream?.cancel();
  }

  Future<void> updatePlayArea(num lng, num lat, double radius) async {
    final lobbyId = currentLobby.id;

    await _firestore.collection('games').doc(lobbyId).update({
      'playArea': {
        'center': {
          'lng': lng,
          'lat': lat,
        },
        'radius': radius,
      },
    });
  }

  Future<void> updateSetting(String key, dynamic value) async {
    if (!isHost()) {
      throw Exception('Only the host can update settings');
    }
    
    final lobbyId = currentLobby.id;
    final docSnapshot = await _firestore.collection('games').doc(lobbyId).get();

    if (docSnapshot.exists) {
      final data = docSnapshot.data();
      if (data != null && data.containsKey('settings')) {
        await _firestore.collection('games').doc(lobbyId).update({
          'settings': {
            ...data['settings'],
            key: value,
          },
        });
      } else {
        await _firestore.collection('games').doc(lobbyId).update({
          'settings': {
            key: value,
          },
        });
      }
    }
  }

  Future<dynamic> getSetting(String key) async {
    final lobbyId = currentLobby.id;
    final docSnapshot = await _firestore.collection('games').doc(lobbyId).get();

    if (docSnapshot.exists) {
      final data = docSnapshot.data();
      if (data != null && data.containsKey('settings')) {
        return data['settings'][key];
      }
    }

    return null;
  }

  Future<void> removePlayer(String uid) async {
    final lobbyId = currentLobby.id;

    await _firestore.collection('games').doc(lobbyId).collection('players').where('uid', isEqualTo: uid).get().then((snapshot) {
      for (var doc in snapshot.docs) {
        doc.reference.delete();
      }
    });
  }

  Future<void> updateReady(bool ready) async {
    final lobbyId = currentLobby.id;
    final uid = _authenticationRepository.currentUser.id;

    await _firestore.collection('games').doc(lobbyId).collection('players').where('uid', isEqualTo: uid).get().then((snapshot) {
      for (var doc in snapshot.docs) {
        doc.reference.update({
          'ready': ready,
        });
      }
    });
  }

  Future<void> startGame() async {
    if (!isHost()) return;

    final lobbyId = currentLobby.id;

    await _firestore.collection('games').doc(lobbyId).update({
      'status': 'starting',
    });
  }

  Future<void> updateLocation(num lng, num lat, num accuracy, num speed, num heading) async {
    final lobbyId = currentLobby.id;
    final uid = _authenticationRepository.currentUser.id;

    await _firestore.collection('games').doc(lobbyId).collection('players').where('uid', isEqualTo: uid).get().then((snapshot) {
      for (var doc in snapshot.docs) {
        doc.reference.update({
          'lastLocationPing': FieldValue.serverTimestamp(),
          'location': {
            'lng': lng,
            'lat': lat,
            'accuracy': accuracy,
            'speed': speed,
            'heading': heading,
          },
        });
      }
    });
  }
}