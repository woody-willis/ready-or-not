import 'dart:io';

import 'package:app_links/app_links.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ready_or_not/main.dart';
import 'package:ready_or_not/models/user.dart';
import 'package:ready_or_not/repository/gamemodes/classic.dart';
import 'package:ready_or_not/ui/home/pages/bloc/login_bloc.dart';
import 'package:ready_or_not/ui/home/widgets/apple_sign_in_widget/apple_sign_in_widget.dart';
import 'package:ready_or_not/ui/home/widgets/google_sign_in_widget/google_sign_in_widget.dart';
import 'package:ready_or_not/ui/home/widgets/home_header/home_header.dart';
import 'package:ready_or_not/ui/home/widgets/quick_action_button.dart';
import 'package:ready_or_not/ui/lobby/pages/bloc/lobby_bloc.dart';
import 'package:ready_or_not/ui/lobby/pages/gamemodes/classic/bloc/classic_bloc.dart';
import 'package:ready_or_not/ui/lobby/pages/lobby_page.dart';

class HomeLayout extends StatefulWidget {
  const HomeLayout({Key? key}) : super(key: key);

  @override
  _HomeLayoutState createState() => _HomeLayoutState();
}

class _HomeLayoutState extends State<HomeLayout> {
  _HomeLayoutState();

  late final LoginBloc loginBloc;
  late final LobbyBloc lobbyBloc;

  @override
  void initState() {
    super.initState();

    loginBloc = context.read<LoginBloc>();
    loginBloc.add(CheckLoggedIn());

    lobbyBloc = context.read<LobbyBloc>();

    requestPermissions();

    final appLinks = AppLinks();
    final sub = appLinks.uriLinkStream.listen((uri) {
      final action = uri.authority;
      final queryParams = uri.queryParameters;

      switch (action) {
        case 'join-lobby':
          final code = queryParams['code'];

          if (code == null || code.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Invalid game code.'),
                duration: const Duration(seconds: 2),
                action: SnackBarAction(
                  label: 'OK',
                  onPressed: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  },
                ),
              ),
            );
            return;
          }

          Navigator.of(context).push(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  MultiBlocProvider(
                providers: [
                  BlocProvider.value(value: lobbyBloc),
                  BlocProvider(
                    create: (context) => ClassicBloc(
                      classicRepository: ClassicGameRepository.instance,
                    ),
                  ),
                ],
                child: LobbyPage(),
              ),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                const begin = Offset(1.0, 0.0);
                const end = Offset.zero;
                const curve = Curves.ease;

                final tween = Tween(begin: begin, end: end);
                final curvedAnimation =
                    CurvedAnimation(parent: animation, curve: curve);

                return SlideTransition(
                  position: tween.animate(curvedAnimation),
                  child: child,
                );
              },
            ),
          );

          lobbyBloc.add(JoinLobby(gameCode: code));

          break;
      }
    });
  }

  Future<void> requestPermissions() async {
    final locationPerm = await Permission.location.status;
    final notificationPerm = await Permission.notification.status;

    if (locationPerm.isDenied || notificationPerm.isDenied) {
      final grantedLocation = await requestLocationPermission();
      final grantedNotification = await requestNotificationPermission();

      if (grantedLocation && grantedNotification) {
        print('All permissions granted.');
      } else {
        print('Some permissions were not granted.');
      }
    } else {
      print('All permissions already granted.');
    }

    final fcmToken = await FirebaseMessaging.instance.getToken();
    if (fcmToken != null) {
      Constants.prefs?.setString('fcm_token', fcmToken);
    }
  }

  Future<bool> requestLocationPermission() async {
    final locationPerm = await Permission.location.request();

    if (locationPerm.isGranted) {
      return true;
    } else if (locationPerm.isDenied) {
      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Location Permission Required'),
            content: const Text(
                'This app requires location permission to function properly.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );

      return await requestLocationPermission();
    } else if (locationPerm.isPermanentlyDenied) {
      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Location Permission Required'),
            content: const Text(
                'Please enable location permission in the app settings.'),
            actions: [
              TextButton(
                onPressed: () {
                  openAppSettings();
                },
                child: const Text('Open Settings'),
              ),
            ],
          );
        },
      );

      return false;
    }

    return false;
  }

  Future<bool> requestNotificationPermission() async {
    // For apple platforms, ensure the APNS token is available before making any FCM plugin API calls
    if (Platform.isIOS) {
      final apnsToken = await FirebaseMessaging.instance.getAPNSToken();
      if (apnsToken != null) {
        print('APNS Token: $apnsToken');
      } else {
        print('Failed to get APNS token.');
      }
    }

    final notificationPerm = await Permission.notification.request();

    if (notificationPerm.isGranted) {
      return true;
    } else if (notificationPerm.isDenied) {
      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Notification Permission Required'),
            content: const Text(
                'This app requires notification permission to function properly.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );

      return await requestNotificationPermission();
    } else if (notificationPerm.isPermanentlyDenied) {
      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Notification Permission Required'),
            content: const Text(
                'Please enable notification permission in the app settings.'),
            actions: [
              TextButton(
                onPressed: () {
                  openAppSettings();
                },
                child: const Text('Open Settings'),
              ),
            ],
          );
        },
      );

      return false;
    }

    await FirebaseMessaging.instance.requestPermission(provisional: true);

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const HomeHeader(),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.only(left: 48, right: 48, top: 48),
          child: TextFormField(
            initialValue: Constants.prefs!.getString('displayName') ??
                loginBloc.state.user.name,
            onChanged: (value) {
              Constants.prefs!.setString('displayName', value);
            },
            onTapOutside: (event) {
              FocusScope.of(context).unfocus();
            },
            decoration: InputDecoration(
              labelText: 'Choose your display name...',
              labelStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w400,
                  ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.onSurface,
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 48, right: 48),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: () {
                    lobbyBloc.add(OpenJoinLobby());

                    Navigator.of(context).push(
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            MultiBlocProvider(
                          providers: [
                            BlocProvider.value(value: lobbyBloc),
                            BlocProvider(
                              create: (context) => ClassicBloc(
                                classicRepository:
                                    ClassicGameRepository.instance,
                              ),
                            ),
                          ],
                          child: LobbyPage(),
                        ),
                        transitionsBuilder:
                            (context, animation, secondaryAnimation, child) {
                          const begin = Offset(1.0, 0.0);
                          const end = Offset.zero;
                          const curve = Curves.ease;

                          final tween = Tween(begin: begin, end: end);
                          final curvedAnimation =
                              CurvedAnimation(parent: animation, curve: curve);

                          return SlideTransition(
                            position: tween.animate(curvedAnimation),
                            child: child,
                          );
                        },
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: Icon(
                    Symbols.group_rounded,
                    color: Theme.of(context).colorScheme.onPrimary,
                    fill: 1,
                  ),
                  label: Text(
                    'Join Game',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontWeight: FontWeight.w400,
                        ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              BlocBuilder<LoginBloc, LoginState>(builder: (context, state) {
                bool disabled = state.user.type == UserType.guest;

                return Expanded(
                  child: TextButton.icon(
                    onPressed: () {
                      if (disabled) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Please sign in to create a room.'),
                            duration: const Duration(seconds: 2),
                            action: SnackBarAction(
                              label: 'OK',
                              onPressed: () {
                                ScaffoldMessenger.of(context)
                                    .hideCurrentSnackBar();
                              },
                            ),
                          ),
                        );

                        return;
                      }

                      lobbyBloc.add(OpenCreateLobby());

                      Navigator.of(context).push(
                        PageRouteBuilder(
                          pageBuilder:
                              (context, animation, secondaryAnimation) =>
                                  MultiBlocProvider(
                            providers: [
                              BlocProvider.value(value: lobbyBloc),
                              BlocProvider(
                                create: (context) => ClassicBloc(
                                  classicRepository:
                                      ClassicGameRepository.instance,
                                ),
                              ),
                            ],
                            child: LobbyPage(),
                          ),
                          transitionsBuilder:
                              (context, animation, secondaryAnimation, child) {
                            const begin = Offset(1.0, 0.0);
                            const end = Offset.zero;
                            const curve = Curves.ease;

                            final tween = Tween(begin: begin, end: end);
                            final curvedAnimation = CurvedAnimation(
                                parent: animation, curve: curve);

                            return SlideTransition(
                              position: tween.animate(curvedAnimation),
                              child: child,
                            );
                          },
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: disabled
                          ? Colors.grey
                          : Theme.of(context).colorScheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: Icon(
                      Symbols.create_rounded,
                      color: Theme.of(context).colorScheme.onPrimary,
                      fill: 1,
                    ),
                    label: Text(
                      'Create Game',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontWeight: FontWeight.w400,
                          ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 48),
        Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                QuickActionButton(
                  icon: Symbols.person_rounded,
                  label: 'My Profile',
                  onPressed: () {
                    
                  },
                  disabled: loginBloc.state.user.type == UserType.guest,
                ),
                QuickActionButton(
                  icon: Symbols.settings_rounded,
                  label: 'Settings',
                  onPressed: () {
                    
                  },
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                QuickActionButton(
                  icon: Symbols.history_rounded,
                  label: 'Game History',
                  onPressed: () {
                    
                  },
                  disabled: loginBloc.state.user.type == UserType.guest,
                ),
                QuickActionButton(
                  icon: Symbols.location_on_rounded,
                  label: 'Events',
                  onPressed: () {
                    
                  },
                  disabled: loginBloc.state.user.type == UserType.guest,
                ),
              ],
            ),
          ],
        ),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: BlocBuilder<LoginBloc, LoginState>(
            bloc: context.read<LoginBloc>(),
            builder: (context, state) {
              if (state.user.type == UserType.guest) {
                return Column(
                  children: [
                    const SizedBox(height: 32),
                    Padding(
                      padding: const EdgeInsets.only(left: 32, right: 32),
                      child: Text(
                        'You are currently playing as a guest.\nSign in to use all features.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    GoogleSignInWidget(
                      onTap: () async {
                        loginBloc.add(LogInGoogle());
                      },
                    ),
                    AppleSignInWidget(
                      onTap: () async {
                        loginBloc.add(LogInApple());
                      },
                    ),
                  ],
                );
              } else {
                return const SizedBox();
              }
            },
          ),
        ),
      ],
    );
  }
}
