import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
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

    _playersStreamSubscription = playersStream.listen((players) {
      currentPlayers = players;
    });
  }

  Future<void> stopGame() async {
    await _currentLobbyStreamSubscription?.cancel();
    currentGame = ClassicGame.empty;
  }

  Future<void> registerTag() async {
    if (currentGame == ClassicGame.empty) return;
    if (!isSeeker()) return;
    
    // TODO
  }
}