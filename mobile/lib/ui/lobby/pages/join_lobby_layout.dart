import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:ready_or_not/ui/lobby/pages/bloc/lobby_bloc.dart';
import 'package:ready_or_not/ui/lobby/pages/scan_qr_page.dart';

class JoinLobbyLayout extends StatelessWidget {
  final TextEditingController lobbyCodeController = TextEditingController();

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
              'Join Game',
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
                !context.read<LobbyBloc>().lobbyRepository.isGuest() ? TextButton.icon(
                  onPressed: () {
                    context.read<LobbyBloc>().add(OpenCreateLobby());
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: Icon(
                    Symbols.add_rounded,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                  label: Text(
                    'Create Game',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ) : const SizedBox(),
              ],
            ),
          ),
          const Spacer(),
          Text(
            'Enter the lobby code to join a game.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: TextField(
              controller: lobbyCodeController,
              keyboardType: TextInputType.numberWithOptions(signed: false, decimal: false),
              onChanged: (value) {
                if (value.length > 5) {
                  lobbyCodeController.text = value.substring(0, 5);
                  return;
                }

                if (value.isNotEmpty && !RegExp(r'^[0-9]+$').hasMatch(value)) {
                  lobbyCodeController.text = value.substring(0, value.length - 1);
                  return;
                }
              },
              decoration: InputDecoration(
                labelText: 'Lobby Code',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
          ),
          if (context.read<LobbyBloc>().state.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                context.read<LobbyBloc>().state.error!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  context.read<LobbyBloc>().add(JoinLobby(gameCode: lobbyCodeController.text));
                },
                style: TextButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Join',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'OR',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () async {
                  final String? result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ScanQrPage(),
                    ),
                  );

                  if (!context.mounted || result == null) return;

                  context.read<LobbyBloc>().add(JoinLobby(gameCode: result));
                },
                style: TextButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: Icon(
                  Symbols.qr_code_scanner_rounded,
                  color: Theme.of(context).colorScheme.onPrimary,
                  size: 24,
                  fill: 1,
                ),
                label: Text(
                  'Scan QR Code',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 64),
          const Spacer(),
        ],
      ),
    );
  }
}
