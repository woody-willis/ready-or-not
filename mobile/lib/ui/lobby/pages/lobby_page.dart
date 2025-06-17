import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:ready_or_not/ui/lobby/pages/bloc/lobby_bloc.dart';
import 'package:ready_or_not/ui/lobby/pages/create_lobby_layout.dart';
import 'package:ready_or_not/ui/lobby/pages/game_layout.dart';
import 'package:ready_or_not/ui/lobby/pages/join_lobby_layout.dart';
import 'package:ready_or_not/ui/lobby/pages/lobby_layout.dart';

class LobbyPage extends StatelessWidget {
  LobbyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) return;

        context.read<LobbyBloc>().add(LeaveLobby());

        Navigator.pop(context);
      },
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 0,
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
        body: BlocBuilder<LobbyBloc, LobbyState>(
          builder: (context, state) {
            Widget child;

            switch (state.status) {
              case LobbyStatus.joining:
                child = JoinLobbyLayout();
                break;
              case LobbyStatus.creating:
                child = const CreateLobbyLayout();
                break;
              case LobbyStatus.waiting:
                return const LobbyLayout();
              case LobbyStatus.playing:
                return GameLayout();
              case LobbyStatus.loading:
                return Center(
                  child: LoadingAnimationWidget.threeRotatingDots(
                    color: Theme.of(context).colorScheme.primary,
                    size: 50,
                  ),
                );
            }

            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              switchInCurve: Curves.easeInOut,
              switchOutCurve: Curves.easeInOut,
              layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
                return Stack(
                  children: [
                    ...previousChildren,
                    if (currentChild != null) currentChild,
                  ],
                );
              },
              transitionBuilder: (Widget widget, Animation<double> animation) {
                final isNewWidget = widget.key == ValueKey(state.status);

                // Determine direction of slide
                Offset beginOffset;
                if (state.status == LobbyStatus.creating) {
                  beginOffset = isNewWidget ? const Offset(1, 0) : const Offset(-1, 0);
                } else if (state.status == LobbyStatus.joining) {
                  beginOffset = isNewWidget ? const Offset(-1, 0) : const Offset(1, 0);
                } else {
                  beginOffset = const Offset(0, 0); // No slide for loading/waiting
                }

                final offsetAnimation = Tween<Offset>(
                  begin: beginOffset,
                  end: Offset.zero,
                ).animate(animation);

                return SlideTransition(
                  position: offsetAnimation,
                  child: widget,
                );
              },
              child: KeyedSubtree(
                key: ValueKey(state.status),
                child: child,
              ),
            );
          },
        ),
      ),
    );
  }
}