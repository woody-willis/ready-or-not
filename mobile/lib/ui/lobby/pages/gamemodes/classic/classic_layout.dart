import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:ready_or_not/models/classic_game.dart';
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

class _ClassicLayoutState extends State<ClassicLayout> with TickerProviderStateMixin {
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

  AnimationController? _pulseAnimationController;

  bool shownRole = false;
  bool showNearbyHidersIndicator = false;

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
      if (!seekersReleased) continue;

      ClassicPlayer gamePlayer = classicBloc.classicRepository.getPlayerByUid(player.uid);
      
      if (classicBloc.classicRepository.isMe(player.uid)) {
        await circleAnnotationManager?.create(
          CircleAnnotationOptions(
            geometry: Point(coordinates: Position(
              player.location!.lng,
              player.location!.lat,
            )),
            circleRadius: 5,
            circleColor: Theme.of(context).colorScheme.secondary.value,
          ),
        );
      } else if (classicBloc.classicRepository.isSeeker() && gamePlayer.role == ClassicPlayerRole.seeker) {
        await circleAnnotationManager?.create(
          CircleAnnotationOptions(
            geometry: Point(coordinates: Position(
              player.location!.lng,
              player.location!.lat,
            )),
            circleRadius: 5,
            circleColor: Theme.of(context).colorScheme.primary.value,
          ),
        );
      } else if (classicBloc.classicRepository.isHider() && gamePlayer.role == ClassicPlayerRole.hider && gamePlayer.status != 'caught') {
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
    }

    if (classicBloc.classicRepository.isSeeker()) {
      bool nearbyHidersFound = await classicBloc.classicRepository.areHidersNearby();
      if (nearbyHidersFound && seekersReleased) {
        _startPulseAnimation();
        showNearbyHidersIndicator = true;
      } else {
        _stopPulseAnimation();
        showNearbyHidersIndicator = false;
      }
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

  void _startPulseAnimation() {
    _pulseAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    final Animation<double> pulseAnimation = Tween<double>(begin: 0.0, end: 20.0).animate(
      CurvedAnimation(
        parent: _pulseAnimationController!,
        curve: Curves.easeInOut,
      ),
    );

    pulseAnimation.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _pulseAnimationController!.reverse();
      } else if (status == AnimationStatus.dismissed) {
        Future.delayed(const Duration(milliseconds: 2500), () {
          if (mounted) {
            _pulseAnimationController!.reset();
            _pulseAnimationController!.forward();
          }
        });
      }
    });

    _pulseAnimationController!.forward();
  }

  void _stopPulseAnimation() {
    if (_pulseAnimationController == null) return;

    if (_pulseAnimationController!.isAnimating) {
      _pulseAnimationController!.stop();
    }
    _pulseAnimationController!.dispose();
  }

  @override
  void dispose() {
    try {
      mapboxMapController.dispose();
    } catch (e) {
      // Do nothing
    }

    _stopPulseAnimation();

    _roleWidgetAnimationController.dispose();
    updateTimer.cancel();
    lobbySubscription.cancel();
    playersSubscription.cancel();
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

            mapboxMapController.scaleBar.updateSettings(
              ScaleBarSettings(
                enabled: false,
              ),
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

        IgnorePointer(
          ignoring: true,
          child: _pulseAnimationController != null ? AnimatedBuilder(
            animation: _pulseAnimationController!,
            builder: (context, child) {
              return Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withOpacity(_pulseAnimationController!.value * 0.25),
                    width: 2 + _pulseAnimationController!.value * 12,
                  ),
                ),
              );
            },
          ) : const SizedBox(),
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
                  !seekersReleased ? (classicBloc.classicRepository.isSeeker() ? 'You will be released in' : 'Seekers released in') : 'Game ends in',
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

        showNearbyHidersIndicator ? Positioned(
          top: 20,
          right: 20,
          child: GestureDetector(
            onTap: () {
              if (Platform.isAndroid) {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Nearby Hiders'),
                    content: Text('There are hiders nearby. Find and tag them!'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text('OK'),
                      ),
                    ],
                  ),
                );
              } else if (Platform.isIOS) {
                showCupertinoDialog(
                  context: context,
                  builder: (context) => CupertinoAlertDialog(
                    title: Text('Nearby Hiders'),
                    content: Text('There are hiders nearby. Find and tag them!'),
                    actions: [
                      CupertinoDialogAction(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text('OK'),
                      ),
                    ],
                  ),
                );
              }
            },
            child: Icon(
              Symbols.mystery_rounded,
              color: Theme.of(context).colorScheme.primary,
              size: 48,
              fill: 1,
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
        ),
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