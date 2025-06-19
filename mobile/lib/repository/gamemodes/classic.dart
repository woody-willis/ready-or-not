import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ready_or_not/models/classic_game.dart';
import 'package:ready_or_not/repository/authentication/authentication.dart';

class ClassicGameRepository {
  ClassicGameRepository._privateConstructor({
    FirebaseFirestore? firestore,
    AuthenticationRepository? authenticationRepository,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _authenticationRepository = authenticationRepository ?? AuthenticationRepository.instance;

  static final ClassicGameRepository instance = ClassicGameRepository._privateConstructor();

  final FirebaseFirestore _firestore;
  final AuthenticationRepository _authenticationRepository;

  ClassicGame currentGame = ClassicGame.empty;
  List<ClassicPlayer> currentPlayers = [];

  Stream<ClassicGame> get currentGameStream => _firestore.collection('games').doc(currentGame.id).snapshots().map((snapshot) {
    if (snapshot.exists) {
      return ClassicGame.fromJson(snapshot.id, snapshot.data()!);
    } else {
      return ClassicGame.empty;
    }
  });
  StreamSubscription? _currentLobbyStreamSubscription;

  Stream<List<ClassicPlayer>> get playersStream => _firestore.collection('games').doc(currentGame.id).collection('players').snapshots().map((snapshot) {
    currentPlayers = snapshot.docs.map((doc) => ClassicPlayer.fromJson(doc.id, doc.data())).toList();
    return currentPlayers;
  });
  StreamSubscription? _playersStreamSubscription;

  bool isHost() {
    return currentGame.hostUid == _authenticationRepository.currentUser.id;
  }
  bool isMe(String uid) {
    return uid == _authenticationRepository.currentUser.id;
  }
  bool isSeeker() {
    return currentGame.seekerUids?.contains(_authenticationRepository.currentUser.id) ?? false;
  }
  bool isHider() {
    return currentGame.hiderUids?.contains(_authenticationRepository.currentUser.id) ?? false;
  }
  bool isCaught() {
    return currentGame.caughtHiderUids?.contains(_authenticationRepository.currentUser.id) ?? false;
  }
  
  Future<void> startGame(String id) async {
    if (currentGame.id.isNotEmpty) {
      await _currentLobbyStreamSubscription?.cancel();
      currentGame = ClassicGame.empty;
    }

    final gameRef = _firestore.collection('games').doc(id);
    final gameSnapshot = await gameRef.get();
    if (!gameSnapshot.exists) return;

    currentGame = ClassicGame.fromJson(gameSnapshot.id, gameSnapshot.data()!);

    _currentLobbyStreamSubscription = currentGameStream.listen((game) {
      currentGame = game;
    });

    final playersRef = gameRef.collection('players');
    final playersSnapshot = await playersRef.get();
    currentPlayers = playersSnapshot.docs.map((doc) => ClassicPlayer.fromJson(doc.id, doc.data())).toList();

    currentPlayers = await _firestore.collection('games').doc(currentGame.id).collection('players').get().then((snapshot) {
      return snapshot.docs.map((doc) => ClassicPlayer.fromJson(doc.id, doc.data())).toList();
    });
    _playersStreamSubscription?.cancel();
    _playersStreamSubscription = playersStream.listen((players) {
      currentPlayers = players;
    });
  }

  Future<void> stopGame() async {
    await _currentLobbyStreamSubscription?.cancel();
    currentGame = ClassicGame.empty;

    await _playersStreamSubscription?.cancel();
    currentPlayers = [];
  }

  Future<void> registerTag() async {
    if (currentGame == ClassicGame.empty) return;
    if (!isSeeker()) return;
    
    Position location = await Geolocator.getCurrentPosition();

    List<ClassicPlayer> nearestHiders = currentPlayers.where((player) {
      return player.location != null && currentGame.hiderUids!.contains(player.uid) && !currentGame.caughtHiderUids!.contains(player.uid);
    }).toList();
    
    nearestHiders.sort((a, b) {
      final distanceA = Geolocator.distanceBetween(
        location.latitude, location.longitude,
        a.location!.lat.toDouble(), a.location!.lng.toDouble(),
      );
      final distanceB = Geolocator.distanceBetween(
        location.latitude, location.longitude,
        b.location!.lat.toDouble(), b.location!.lng.toDouble(),
      );
      return distanceA.compareTo(distanceB);
    });

    if (nearestHiders.isEmpty) return;
    
    ClassicPlayer nearestHider = nearestHiders.first;
    double distanceMeters = Geolocator.distanceBetween(
      location.latitude, location.longitude,
      nearestHider.location!.lat.toDouble(), nearestHider.location!.lng.toDouble(),
    );

    final catchDistance = (currentGame.settings!['catch_distance'] as num?) ?? 10;
    final accuracy = nearestHider.location!.accuracy;
    if (distanceMeters > catchDistance + accuracy) {
      return; // Too far to tag
    }

    final gameRef = _firestore.collection('games').doc(currentGame.id);

    // Update player status
    await gameRef.collection('players').doc(nearestHider.id).update({
      'status': 'caught',
    });

    final ClassicPlayer me = currentPlayers.firstWhere((player) => player.uid == _authenticationRepository.currentUser.id);

    // Add caught hider to the seeker's list
    await gameRef.collection('players').doc(me.id).update({
      'caughtHiders': FieldValue.arrayUnion([nearestHider.uid]),
    });

    // Update game state
    await gameRef.update({
      'caughtHiders': FieldValue.arrayUnion([nearestHider.uid]),
    });
  }

  Future<bool> areHidersNearby() async {
    if (currentGame == ClassicGame.empty || !isSeeker()) return false;

    // Get current location from firebase
    final ClassicPlayer me = currentPlayers.firstWhere((player) => player.uid == _authenticationRepository.currentUser.id);
    if (me.location == null) return false;

    final seekerProximityDistance = (currentGame.settings!['seeker_proximity_distance'] as num?) ?? 100;

    // Check if any hiders are nearby
    for (var hider in currentPlayers.where((player) => player.uid != me.uid && currentGame.hiderUids!.contains(player.uid))) {
      if (hider.location == null) continue;
      if (hider.status == 'caught') continue;

      double distance = Geolocator.distanceBetween(
        me.location!.lat.toDouble(), me.location!.lng.toDouble(),
        hider.location!.lat.toDouble(), hider.location!.lng.toDouble(),
      );

      if (distance <= seekerProximityDistance) {
        return true;
      }
    }

    return false;
  }

  ClassicPlayer getPlayerByUid(String uid) {
    return currentPlayers.firstWhere((player) => player.uid == uid, orElse: () => ClassicPlayer.empty);
  }
}