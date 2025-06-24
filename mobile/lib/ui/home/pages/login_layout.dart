import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_player/video_player.dart';
import 'package:ready_or_not/ui/home/pages/bloc/login_bloc.dart';
import 'package:ready_or_not/ui/home/widgets/apple_sign_in_widget/apple_sign_in_widget.dart';
import 'package:ready_or_not/ui/home/widgets/google_sign_in_widget/google_sign_in_widget.dart';
import 'package:ready_or_not/ui/home/widgets/guest_sign_in_widget/guest_sign_in_widget.dart';
import 'package:ready_or_not/ui/home/widgets/login_header/login_header.dart';

class LoginLayout extends StatefulWidget {
  const LoginLayout({Key? key}) : super(key: key);

  @override
  _LoginLayoutState createState() => _LoginLayoutState();
}

class _LoginLayoutState extends State<LoginLayout> {
  late VideoPlayerController _controller;

  late final LoginBloc loginBloc;

  @override
  void initState() {
    super.initState();

    loginBloc = context.read<LoginBloc>();
    loginBloc.add(CheckLoggedIn());

    _controller =
        VideoPlayerController.asset('assets/home/login_background.mp4')
          ..initialize().then((_) {
            _controller.play();
            _controller.setLooping(true);
            // Ensure the first frame is shown after the video is initialized
            setState(() {});
          });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.primary,
      child: Stack(
        children: [
          SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _controller.value.size.width,
                height: _controller.value.size.height,
                child: VideoPlayer(_controller),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.primary.withAlpha(20),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.01, 1.0],
              ),
            ),
          ),
          Column(
            children: [
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const LoginHeader(),
                    const SizedBox(height: 40.0),
                    GuestSignInWidget(
                      onTap: () async {
                        loginBloc.add(LogInGuest());
                      },
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
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: 28, left: 16, right: 16),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'By signing in, you agree to our ',
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontWeight: FontWeight.w400,
                              ),
                        ),
                        TextSpan(
                          text: 'Terms of Service',
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        TextSpan(
                          text: '.',
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontWeight: FontWeight.w400,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
