import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:ready_or_not/ui/lobby/pages/bloc/lobby_bloc.dart';
import 'package:ready_or_not/ui/lobby/widgets/gamemode_widget/gamemode_widget.dart';

class CreateLobbyLayout extends StatefulWidget {
  const CreateLobbyLayout({Key? key}) : super(key: key);

  @override
  _CreateLobbyLayoutState createState() => _CreateLobbyLayoutState();
}

class _CreateLobbyLayoutState extends State<CreateLobbyLayout> {
  List<GameModeWidget> gameModes = [
    GameModeWidget(
      name: 'Classic',
      code: 'classic',
      imageAssetPath: 'assets/gamemodes/classic.jpg',
      isNew: true,
    ),
    GameModeWidget(
      name: 'Shrink',
      code: 'shrink',
      imageAssetPath: 'assets/gamemodes/shrink.jpg',
      isComingSoon: true,
    ),
    GameModeWidget(
      name: 'Infection',
      code: 'infection',
      imageAssetPath: 'assets/gamemodes/infection.jpg',
      isComingSoon: true,
    ),
    GameModeWidget(
      name: 'Fog of War',
      code: 'fog_of_war',
      imageAssetPath: 'assets/gamemodes/fog_of_war.jpg',
      isComingSoon: true,
    ),
  ];
  int selectedGameModeIndex = 0;

  final int dividerLocation = 1;

  @override
  void initState() {
    super.initState();
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
              'Create Game',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.onPrimary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
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
                TextButton.icon(
                  onPressed: () {
                    context.read<LobbyBloc>().add(OpenJoinLobby());
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: Icon(
                    Symbols.group_rounded,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                  label: Text(
                    'Join Game',
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
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              'Select a game mode to create a game',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 20,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: gameModes.length + 1,
              itemBuilder: (context, index) {
                if (index == dividerLocation) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Divider(
                      height: 5,
                      thickness: 2,
                      color: Theme.of(context).colorScheme.tertiary,
                    ),
                  );
                } else if (index >= dividerLocation) {
                  index -= 1;
                }

                // Set border colour
                Color borderColor = selectedGameModeIndex == index
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent;

                return InkWell(
                  onTap: () {
                    if (gameModes[index].isComingSoon) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('This game mode is coming soon!'),
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

                    setState(() {
                      selectedGameModeIndex = index;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor, width: 4),
                      color: Theme.of(context).colorScheme.surface,
                    ),
                    child: gameModes[index],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  context.read<LobbyBloc>().add(CreateLobby(gameMode: gameModes[selectedGameModeIndex].code));
                },
                style: TextButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Create Game',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
