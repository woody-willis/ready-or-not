import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:ready_or_not/ui/home/pages/bloc/login_bloc.dart';
import 'package:ready_or_not/ui/home/pages/home_layout.dart';
import 'package:ready_or_not/ui/home/pages/login_layout.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 0,
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: BlocBuilder<LoginBloc, LoginState>(
        builder: (context, state) {
          switch (state.status) {
            case LoginStatus.initial:
            case LoginStatus.error:
              return const LoginLayout();
            case LoginStatus.success:
              return const HomeLayout();
            case LoginStatus.loading:
              return Center(
                child: LoadingAnimationWidget.threeRotatingDots(
                  color: Theme.of(context).colorScheme.primary,
                  size: 50,
                ),
              );
          }
        },
      ),
    );
  }
}