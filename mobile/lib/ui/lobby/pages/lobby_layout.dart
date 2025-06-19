import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:ready_or_not/models/lobby.dart';
import 'package:ready_or_not/repository/gamemodes/classic.dart';
import 'package:ready_or_not/ui/lobby/pages/bloc/lobby_bloc.dart';
import 'package:ready_or_not/ui/lobby/pages/settings_page.dart';
import 'package:ready_or_not/ui/lobby/widgets/gamemode_widget/gamemode_widget.dart';
import 'package:ready_or_not/utils/map_circle_draw.dart';

class LobbyLayout extends StatefulWidget {
  const LobbyLayout({Key? key}) : super(key: key);

  @override
  _LobbyLayoutState createState() => _LobbyLayoutState();
}

class _LobbyLayoutState extends State<LobbyLayout> {
  List<GameModeWidget> gameModes = [
    GameModeWidget(
      name: 'Classic',
      code: 'classic',
      imageAssetPath: 'assets/gamemodes/classic.jpg',
    ),
    GameModeWidget(
      name: 'Shrink',
      code: 'shrink',
      imageAssetPath: 'assets/gamemodes/shrink.jpg',
    ),
    GameModeWidget(
      name: 'Infection',
      code: 'infection',
      imageAssetPath: 'assets/gamemodes/infection.jpg',
    ),
    GameModeWidget(
      name: 'Fog of War',
      code: 'fog_of_war',
      imageAssetPath: 'assets/gamemodes/fog_of_war.jpg',
    ),
  ];

  final TextEditingController lobbyCodeController = TextEditingController();
  late final MapboxMap mapboxMap;
  late final MapCircleDrawer mapCircleDrawer;
  CircleAnnotationManager? circleAnnotationManager;
  double areaRadius = 500;
  bool showPlayArea = true;
  bool showLobbyCode = false;

  late final LobbyBloc lobbyBloc;
  bool isHost = false;
  bool isReady = false;
  bool allPlayersReady = false;
  bool loadingStartGame = false;

  late final StreamSubscription lobbySubscription;
  late final StreamSubscription playersSubscription;

  @override
  void initState() {
    super.initState();

    lobbyBloc = context.read<LobbyBloc>();
    isHost = lobbyBloc.lobbyRepository.isHost();
    isReady = isHost;
    if (!isHost) showLobbyCode = true;

    lobbySubscription = lobbyBloc.lobbyRepository.currentLobbyStream.listen(lobbyUpdateListener);
    playersSubscription = lobbyBloc.lobbyRepository.playersStream.listen(lobbyPlayersUpdateListener);
  }

  Future<void> lobbyUpdateListener(Lobby lobby) async {
    if (!mounted) return;
    if (lobby == Lobby.empty) {
      lobbyBloc.add(LeaveLobby());
      lobbyBloc.add(OpenCreateLobby());
      Navigator.pop(context);
      lobbySubscription.cancel();
      return;
    }

    setState(() {
      isHost = lobbyBloc.lobbyRepository.isMe(lobby.hostUid);
    });

    if (lobbyBloc.state.lobby != null) {
      if (lobbyBloc.state.lobby!.status == 'starting') {
        switch (lobbyBloc.state.lobby!.gameMode) {
          case 'classic':
            await ClassicGameRepository.instance.startGame(lobbyBloc.state.lobby!.id);
            break;
          default:
            throw Exception('Unknown game mode');
        }

        if (!isHost) {
          lobbyBloc.add(StartGame());
        }
      }

      if (lobbyBloc.state.lobby!.playArea != null) {
        mapCircleDrawer.center = Point(coordinates: Position(
          lobbyBloc.state.lobby!.playArea!.lng,
          lobbyBloc.state.lobby!.playArea!.lat,
        ));
        mapCircleDrawer.radiusInMeters = lobbyBloc.state.lobby!.playArea!.radius;

        await mapCircleDrawer.removeCircle();
        await mapCircleDrawer.drawCircle();

        if (!mounted) return;
        await mapboxMap.flyTo(
          CameraOptions(
            center: mapCircleDrawer.center,
            zoom: widthToZoomLevel(mapCircleDrawer.radiusInMeters * 5, lobbyBloc.state.lobby!.playArea!.lat),
          ),
          MapAnimationOptions(
            duration: 1000,
          ),
        );
      }
    }
  }

  Future<void> lobbyPlayersUpdateListener(List<LobbyPlayer> players) async {
    if (!mounted) return;
    if (!lobbyBloc.lobbyRepository.isPlayerInLobby()) {
      lobbyBloc.add(LeaveLobby());
      lobbyBloc.add(OpenJoinLobby());
      Navigator.pop(context);
      playersSubscription.cancel();
      return;
    }

    isHost = lobbyBloc.lobbyRepository.isHost();

    isReady = players.firstWhere(
      (player) => lobbyBloc.lobbyRepository.isMe(player.uid),
      orElse: () => LobbyPlayer.empty,
    ).ready;
    allPlayersReady = players.every((player) => player.ready);
    
    if (lobbyBloc.state.players != null) {
      setState(() {});
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
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: Text(
              'Lobby',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.onPrimary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: gameModes.firstWhere(
              (gameMode) => gameMode.code == lobbyBloc.state.lobby!.gameMode,
              orElse: () => gameModes.first,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: () {
                    lobbyBloc.add(LeaveLobby());

                    Navigator.pop(context);
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: Icon(
                    Symbols.arrow_back_rounded,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                  label: Text(
                    'Leave',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                showLobbyCode ? InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => BlocProvider.value(
                          value: lobbyBloc,
                          child: const LobbyJoinCodeExpandedScreen(),
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.onSecondary.withAlpha(40),
                          spreadRadius: 1,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Symbols.qr_code_rounded,
                          color: Theme.of(context).colorScheme.onSecondary,
                        ),
                        const SizedBox(width: 8),
                        Text.rich(
                          textAlign: TextAlign.center,
                          TextSpan(
                            text: 'Lobby Code: ',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Theme.of(context).colorScheme.onSecondary,
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                            ),
                            children: [
                              TextSpan(
                                text: lobbyBloc.state.lobby!.gameCode,
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Theme.of(context).colorScheme.onSecondary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ): Padding(
                  padding: const EdgeInsets.fromLTRB(0, 8, 50, 8),
                  child: LoadingAnimationWidget.threeRotatingDots(
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Play Area',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      showPlayArea = !showPlayArea;
                    });
                  },
                  icon: Icon(
                    showPlayArea ? Symbols.keyboard_double_arrow_down_rounded : Symbols.keyboard_double_arrow_up_rounded,
                    color: Theme.of(context).colorScheme.primary,
                    size: 32,
                  ),
                ),
              ],
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: showPlayArea ? 250 : 0,
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: double.infinity,
                  height: 250,
                  child: MapWidget(
                    styleUri: MapboxStyles.MAPBOX_STREETS,
                    onMapCreated: (controller) async {
                      mapboxMap = controller;

                      mapCircleDrawer = MapCircleDrawer(
                        mapboxMap: mapboxMap,
                        center: Point(coordinates: Position(0.0, 0.0)),
                        radiusInMeters: 0,
                        circleColor: Theme.of(context).colorScheme.primary.withAlpha(50),
                        strokeColor: Theme.of(context).colorScheme.primary,
                      );

                      circleAnnotationManager = await mapboxMap.annotations.createCircleAnnotationManager();

                      if (isHost) {
                        geolocator.Geolocator.getCurrentPosition()
                          .then((position) async {
                            if (!mounted) return;

                            mapCircleDrawer.center = Point(coordinates: Position(
                              position.longitude,
                              position.latitude,
                            ));
                            mapCircleDrawer.radiusInMeters = areaRadius;

                            await mapCircleDrawer.removeCircle();
                            await mapCircleDrawer.drawCircle();

                            if (!mounted) return;
                            await mapboxMap.flyTo(
                              CameraOptions(
                                center: Point(coordinates: Position(
                                  position.longitude,
                                  position.latitude,
                                )),
                                zoom: widthToZoomLevel(areaRadius * 5, position.latitude),
                              ),
                              MapAnimationOptions(
                                duration: 1000,
                              ),
                            );

                            lobbyBloc.add(UpdatePlayArea(
                              lng: mapCircleDrawer.center.coordinates.lng,
                              lat: mapCircleDrawer.center.coordinates.lat,
                              radius: areaRadius,
                            ));

                            setState(() {
                              showLobbyCode = true;
                            });
                          });
                      } else {
                        mapCircleDrawer.center = Point(coordinates: Position(
                          lobbyBloc.state.lobby!.playArea!.lng,
                          lobbyBloc.state.lobby!.playArea!.lat,
                        ));
                        mapCircleDrawer.radiusInMeters = lobbyBloc.state.lobby!.playArea!.radius;
                        
                        if (!mounted) return;
                        await mapboxMap.flyTo(
                          CameraOptions(
                            center: Point(coordinates: Position(
                              lobbyBloc.state.lobby!.playArea?.lng ?? 0,
                              lobbyBloc.state.lobby!.playArea?.lat ?? 0,
                            )),
                            zoom: 12,
                          ),
                          MapAnimationOptions(
                            duration: 1000,
                          ),
                        );
                      }
                      
                      final locationSettings = await mapboxMap.location.getSettings();
                      locationSettings.enabled = true;
                      locationSettings.puckBearingEnabled = false;
                      locationSettings.showAccuracyRing = false;
                    },
                    onTapListener: (tapContext) async {
                      if (!isHost) return;
            
                      await mapCircleDrawer.removeCircle();
            
                      mapCircleDrawer.center = tapContext.point;
                      mapCircleDrawer.radiusInMeters = areaRadius;
            
                      await mapCircleDrawer.drawCircle();
            
                      lobbyBloc.add(UpdatePlayArea(
                        lng: tapContext.point.coordinates.lng,
                        lat: tapContext.point.coordinates.lat,
                        radius: areaRadius,
                      ));
                    },
                  ),
                ),
              ),
            ),
          ),
          if (isHost && showPlayArea)
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 24),
                  child: Text(
                    '${areaRadius.toInt()*2} m',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: Slider(
                    value: areaRadius*2,
                    min: 100,
                    max: 10000,
                    divisions: 99,
                    label: '${areaRadius.toInt()*2} m',
                    onChanged: (value) {
                      setState(() {
                        areaRadius = value/2;
                        mapCircleDrawer.radiusInMeters = value/2;
                      });
                    },
                    onChangeEnd: (value) async {
                      await mapCircleDrawer.removeCircle();
                      await mapCircleDrawer.drawCircle();
                  
                      lobbyBloc.add(UpdatePlayArea(
                        lng: mapCircleDrawer.center.coordinates.lng,
                        lat: mapCircleDrawer.center.coordinates.lat,
                        radius: value/2,
                      ));
                    },
                  ),
                ),
              ],
            ),
          SizedBox(
            width: double.infinity,
            child: Text(
              'Players',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: lobbyBloc.state.players?.length ?? 0,
              itemBuilder: (context, index) {
                final player = lobbyBloc.state.players![index];
                return ListTile(
                  title: Row(
                    children: [
                      Text(
                        player.name
                      ),
                      const SizedBox(width: 12),
                      if (player.uid == lobbyBloc.state.lobby?.hostUid)
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'HOST',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      if (lobbyBloc.lobbyRepository.isMe(player.uid))
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.tertiary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'YOU',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onTertiary,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      if (player.ready)
                        Container(
                          padding: const EdgeInsets.only(left: 16),
                          child: Icon(
                            Symbols.check_rounded,
                            color: Theme.of(context).colorScheme.tertiary,
                            fill: 1,
                            size: 24,
                          ),
                        ),
                    ],
                  ),
                  trailing: isHost && !lobbyBloc.lobbyRepository.isMe(player.uid) ? IconButton(
                    onPressed: () {
                      lobbyBloc.add(RemovePlayer(
                        uid: player.uid,
                      ));
                    },
                    icon: Icon(
                      Symbols.person_remove_rounded,
                      color: Theme.of(context).colorScheme.primary,
                      fill: 1,
                      size: 28,
                    ),
                  ) : null,
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: SizedBox(
              width: double.infinity,
              height: 44,
              child: Row(
                children: [
                  isHost ? Expanded(
                    child: SizedBox(
                      height: double.infinity,
                      child: TextButton(
                        onPressed: () {
                          if (loadingStartGame) return;
                          if (!allPlayersReady || (lobbyBloc.state.players?.length ?? 0) <= 1) return;

                          loadingStartGame = true;
                          lobbyBloc.add(StartGame());
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: allPlayersReady && (lobbyBloc.state.players?.length ?? 0) > 1 ? Theme.of(context).colorScheme.primary : Colors.grey,
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          allPlayersReady && (lobbyBloc.state.players?.length ?? 0) > 1
                            ? 'Start Game'
                            : 'Waiting for players${!allPlayersReady ? ' to be ready' : ''}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ) : Expanded(
                    child: SizedBox(
                      height: double.infinity,
                      child: TextButton(
                        onPressed: () {
                          lobbyBloc.add(UpdateReady(
                            ready: !isReady,
                          ));
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: !isReady ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Symbols.check_rounded,
                              color: Theme.of(context).colorScheme.onPrimary,
                              fill: 1,
                              size: 20,
                            ),
                            const SizedBox(width: 16),
                            Text(
                              'Ready',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ) : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            LoadingAnimationWidget.threeArchedCircle(
                              color: Theme.of(context).colorScheme.onPrimary,
                              size: 20,
                            ),
                            const SizedBox(width: 16),
                            Text(
                              'Waiting for host',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  isHost ? Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: SizedBox(
                      height: double.infinity,
                      child: IconButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            PageRouteBuilder(
                              pageBuilder: (context, animation, secondaryAnimation) => BlocProvider.value(
                                value: lobbyBloc,
                                child: LobbySettingsPage(
                                  gameMode: lobbyBloc.state.lobby!.gameMode,
                                ),
                              ),
                              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                const begin = Offset(1.0, 0.0);
                                const end = Offset.zero;
                                const curve = Curves.ease;

                                final tween = Tween(begin: begin, end: end);
                                final curvedAnimation = CurvedAnimation(parent: animation, curve: curve);

                                return SlideTransition(
                                  position: tween.animate(curvedAnimation),
                                  child: child,
                                );
                              },
                            ),
                          );
                        },
                        style: IconButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: Icon(
                          Symbols.settings_rounded,
                          color: Theme.of(context).colorScheme.onPrimary,
                          fill: 1,
                          size: 24,
                        ),
                      ),
                    ),
                  ) : const SizedBox(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}



class LobbyJoinCodeExpandedScreen extends StatelessWidget {
  const LobbyJoinCodeExpandedScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String lobbyCode = context.read<LobbyBloc>().state.lobby?.gameCode ?? '';

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 0,
        backgroundColor: Theme.of(context).colorScheme.secondary,
      ),
      body: Container(
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondary,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 8, right: 8, bottom: 32),
                child: QrImageView(
                  data: 'https://woodywillis.co.uk/redirect.html?readyornot://join-lobby?code=$lobbyCode',
                  version: 6,
                  size: MediaQuery.of(context).size.width * 0.75,
                  errorCorrectionLevel: QrErrorCorrectLevel.Q,
                ),
              ),
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  lobbyCode,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: TextButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: Icon(
                  Symbols.arrow_back_rounded,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
                label: Text(
                  'Go back',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}