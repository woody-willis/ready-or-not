import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ready_or_not/ui/lobby/pages/bloc/lobby_bloc.dart';
import 'package:ready_or_not/ui/lobby/pages/gamemodes/classic/classic_layout.dart';

class GameLayout extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    LobbyBloc lobbyBloc = context.read<LobbyBloc>();
    
    switch (lobbyBloc.state.lobby!.gameMode) {
      case 'classic':
        return ClassicLayout();
      default:
        return Container(
          color: Theme.of(context).colorScheme.surface,
          child: Center(
            child: Text('Unknown Game Mode'),
          ),
        );
    }
  }
}
