import 'package:app_links/app_links.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:ready_or_not/repository/authentication/authentication.dart';
import 'package:ready_or_not/repository/lobby/lobby.dart';
import 'package:ready_or_not/ui/home/pages/bloc/login_bloc.dart';
import 'package:ready_or_not/ui/home/pages/home_page.dart';
import 'package:ready_or_not/ui/lobby/pages/bloc/lobby_bloc.dart';
import 'package:ready_or_not/utils/app_bloc_observer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Constants {
  static SharedPreferences? prefs;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");
  MapboxOptions.setAccessToken(dotenv.env['MAPBOX_ACCESS_TOKEN']!);

  Constants.prefs = await SharedPreferences.getInstance();

  await Firebase.initializeApp();

  // FirebaseFirestore.instance.useFirestoreEmulator('10.0.2.2', 8080);

  final remoteConfig = FirebaseRemoteConfig.instance;
  await remoteConfig.setConfigSettings(RemoteConfigSettings(
    fetchTimeout: const Duration(seconds: 10),
    minimumFetchInterval: const Duration(hours: 12),
    // minimumFetchInterval: const Duration(minutes: 5),
  ));
  remoteConfig.onConfigUpdated.listen((event) async {
    await remoteConfig.activate();
  });
  await remoteConfig.setDefaults(const {
    // TODO
  });

  FirebaseMessaging.instance.onTokenRefresh.listen((String? token) {
    if (token != null) {
      Constants.prefs?.setString('fcm_token', token);
    } else {
      Constants.prefs?.remove('fcm_token');
    }
  }).onError((error) {
    print('Failed to get FCM token: $error');
  });

  Bloc.observer = AppBlocObserver();

  final appLinks = AppLinks();

  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFFFF6B6B)).copyWith(
          surface: Color(0xFFFAFAFA),
          onSurface: Color(0xFF333333),

          primary: Color(0xFFFF6B6B),
          onPrimary: Color(0xFFFAFAFA),

          secondary: Color(0xFFFFC757),
          onSecondary: Color(0xFF333333),

          tertiary: Color(0xFF1AA29B),
          onTertiary: Color(0xFFFAFAFA),
        ),
        textTheme: GoogleFonts.interTightTextTheme(),
        useMaterial3: true,
      ),
      home: MultiBlocProvider(
        providers: [
          BlocProvider<LoginBloc>(
            create: (context) => LoginBloc(authenticationRepository: AuthenticationRepository.instance),
          ),
          BlocProvider<LobbyBloc>(
            create: (context) => LobbyBloc(lobbyRepository: LobbyRepository.instance),
          ),
        ],
        child: HomePage(),
      ),
    );
  }
}