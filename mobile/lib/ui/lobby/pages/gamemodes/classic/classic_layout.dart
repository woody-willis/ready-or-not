import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:ready_or_not/models/lobby.dart';
import 'package:ready_or_not/ui/lobby/pages/bloc/lobby_bloc.dart';
import 'package:ready_or_not/ui/lobby/pages/gamemodes/classic/bloc/classic_bloc.dart';
import 'package:ready_or_not/ui/lobby/pages/gamemodes/classic/widgets/role_widget.dart';
import 'package:ready_or_not/utils/map_circle_draw.dart';
import 'package:vibration/vibration.dart';

class ClassicLayout extends StatefulWidget {
  const ClassicLayout({Key? key}) : super(key: key);

  @override
  State<ClassicLayout> createState() => _ClassicLayoutState();
}

class _ClassicLayoutState extends State<ClassicLayout> with SingleTickerProviderStateMixin {
  late final MapboxMap mapboxMapController;
  late final MapCircleDrawer mapCircleDrawer;
  CircleAnnotationManager? circleAnnotationManager;
  late final LobbyBloc lobbyBloc;
  late final ClassicBloc classicBloc;

  late final Timer updateTimer;

  bool seekersReleased = false;

  late final StreamSubscription lobbySubscription;
  late final StreamSubscription playersSubscription;

  late AnimationController _roleWidgetAnimationController;
  late Animation<double> _scaleAnimation;

  bool shownRole = false;

  @override
  void initState() {
    super.initState();
    
    lobbyBloc = context.read<LobbyBloc>();
    lobbyBloc.add(RefreshLobby(lobby: lobbyBloc.state.lobby!));
    classicBloc = context.read<ClassicBloc>();
    classicBloc.add(RefreshGame());

    updateTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      final DateTime now = DateTime.now();
      final DateTime? seekersReleaseTime = classicBloc.state.game.hideEndTime?.toDate();
      if (seekersReleaseTime == null) return;

      if (!seekersReleased && now.isAfter(seekersReleaseTime)) {
        seekersReleased = true;
        
        if (await Vibration.hasVibrator()) {
          await Vibration.vibrate();
        }
      }

      setState(() {
        // Update the UI every second
      });
    });

    lobbySubscription = lobbyBloc.lobbyRepository.currentLobbyStream.listen(lobbyUpdateListener);
    playersSubscription = lobbyBloc.lobbyRepository.playersStream.listen(lobbyPlayersUpdateListener);

    _roleWidgetAnimationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _roleWidgetAnimationController,
      curve: Curves.easeInOut,
    );

    if (classicBloc.classicRepository.isSeeker() || classicBloc.classicRepository.isHider()) {
      _startRoleAnimationSequence();
    }
  }

  Future<void> lobbyUpdateListener(Lobby lobby) async {
    if (!mounted) {
      lobbySubscription.cancel();
      updateTimer.cancel();
      return;
    }

    classicBloc.add(RefreshGame());

    if (classicBloc.classicRepository.isSeeker() || classicBloc.classicRepository.isHider()) {
      _startRoleAnimationSequence();
    }
  }

  Future<void> lobbyPlayersUpdateListener(List<LobbyPlayer> players) async {
    if (!mounted) {
      playersSubscription.cancel();
      return;
    }

    await circleAnnotationManager?.deleteAll();
    for (LobbyPlayer player in players) {
      if (!mounted) return;
      if (player.location == null) continue;
      
      await circleAnnotationManager?.create(
        CircleAnnotationOptions(
          geometry: Point(coordinates: Position(
            player.location!.lng,
            player.location!.lat,
          )),
          circleRadius: 5,
          circleColor: Theme.of(context).colorScheme.tertiary.value,
        ),
      );
    }

    setState(() {});
  }

  Future<void> _startRoleAnimationSequence() async {
    if (shownRole) return;
    shownRole = true;

    try {
      await _roleWidgetAnimationController.forward();
      await Future.delayed(Duration(seconds: 5));
      await _roleWidgetAnimationController.reverse();
    } catch (e) {
      // Handle the error if needed
    }
  }

  @override
  void dispose() {
    _roleWidgetAnimationController.dispose();
    updateTimer.cancel();
    lobbySubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        MapWidget(
          styleUri: MapboxStyles.MAPBOX_STREETS,
          onMapCreated: (MapboxMap mapboxMap) async {
            mapboxMapController = mapboxMap;

            await mapboxMapController.setCamera(
              CameraOptions(
                center: Point(
                  coordinates: Position(
                    lobbyBloc.state.lobby!.playArea!.lng,
                    lobbyBloc.state.lobby!.playArea!.lat,
                  ),
                ),
                zoom: widthToZoomLevel(
                  lobbyBloc.state.lobby!.playArea!.radius.toDouble() * 3,
                  lobbyBloc.state.lobby!.playArea!.lat,
                ),
              )
            );

            circleAnnotationManager = await mapboxMap.annotations.createCircleAnnotationManager();

            mapCircleDrawer = MapCircleDrawer(
              mapboxMap: mapboxMapController,
              circleColor: Colors.transparent,
              strokeColor: Theme.of(context).colorScheme.primary,
              center: Point(
                coordinates: Position(
                  lobbyBloc.state.lobby!.playArea!.lng,
                  lobbyBloc.state.lobby!.playArea!.lat,
                ),
              ),
              radiusInMeters: lobbyBloc.state.lobby!.playArea!.radius.toDouble(),
            );

            await mapCircleDrawer.removeCircle();
            await mapCircleDrawer.drawCircle();
          },
        ),
        Align(
          alignment: Alignment.topCenter,
          child: Container(
            height: 80,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  !seekersReleased ? 'Seekers released in' : 'Game ends in',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
                Text(
                  prettyTimeToTimestamp((!seekersReleased ? classicBloc.state.game.hideEndTime : classicBloc.state.game.gameEndTime) ?? Timestamp.now()),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
        classicBloc.classicRepository.isSeeker() && seekersReleased ? Positioned(
          bottom: 24,
          left: 16,
          right: 16,
          child: TextButton(
            onPressed: () {
              classicBloc.add(RegisterTag());
            },
            style: TextButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Tag',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ) : const SizedBox(),

        ScaleTransition(
          scale: _scaleAnimation,
          child: Align(
            alignment: Alignment.center,
            child: RoleWidget(
              role: classicBloc.classicRepository.isSeeker() ? 'Seeker' : (classicBloc.classicRepository.isHider() ? 'Hider' : '...'),
            ),
          ),
        )
      ],
    );
  }

  String prettyTimeToTimestamp(Timestamp timestamp) {
    final DateTime dateTime = timestamp.toDate();
    final DateTime now = DateTime.now();
    final Duration difference = dateTime.difference(now);

    if (difference.isNegative) {
      return '00:00';
    }

    final int hours = difference.inHours;
    final int minutes = difference.inMinutes.remainder(60);
    final int seconds = difference.inSeconds.remainder(60);

    String formattedTime = '';

    if (hours > 0) {
      formattedTime += '${hours.toString().padLeft(2, '0')}:';
    }
    formattedTime += '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return formattedTime;
  }
}