import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:ready_or_not/ui/home/pages/bloc/login_bloc.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final LoginBloc loginBloc = context.read<LoginBloc>();

    String? displayName = loginBloc.state.user.name;
    if (displayName != null && displayName.isEmpty) {
      displayName = null;
    }

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: IconButton(
              onPressed: () {
                
              },
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all(Theme.of(context).colorScheme.primary),
                shape: WidgetStateProperty.all(CircleBorder()),
                padding: WidgetStateProperty.all(EdgeInsets.all(8)),
              ),
              icon: Icon(
                Symbols.question_mark_rounded,
                color: Theme.of(context).colorScheme.onPrimary,
                fill: 1,
              ),
            ),
          ),
          Text(
            displayName == null ? 'Welcome back!' : 'Hello, $displayName!',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: IconButton(
              onPressed: () {
                loginBloc.add(LogOut());
              },
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all(Theme.of(context).colorScheme.primary),
                shape: WidgetStateProperty.all(CircleBorder()),
                padding: WidgetStateProperty.all(EdgeInsets.all(8)),
              ),
              icon: Icon(
                Symbols.logout_rounded,
                color: Theme.of(context).colorScheme.onPrimary,
                fill: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}