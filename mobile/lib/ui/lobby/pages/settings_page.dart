import 'dart:async';
import 'dart:convert';

import 'package:animated_toggle_switch/animated_toggle_switch.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:ready_or_not/models/lobby.dart';
import 'package:ready_or_not/ui/lobby/pages/bloc/lobby_bloc.dart';

class LobbySettingsPage extends StatefulWidget {
  final String gameMode;
  const LobbySettingsPage({
    super.key,
    required this.gameMode,
  });

  @override
  State<LobbySettingsPage> createState() => _LobbySettingsPageState();
}

class _LobbySettingsPageState extends State<LobbySettingsPage> {
  late final LobbyBloc lobbyBloc;
  late final List settingsInfo;

  late final StreamSubscription lobbySubscription;

  late Map settings;

  @override
  void initState() {
    super.initState();
    
    lobbyBloc = context.read<LobbyBloc>();
    settingsInfo = jsonDecode(FirebaseRemoteConfig.instance.getValue("gamemode_${widget.gameMode}_defaultSettings").asString());
    settings = lobbyBloc.state.lobby!.settings!;

    lobbySubscription = lobbyBloc.lobbyRepository.currentLobbyStream.listen(lobbyUpdateListener);
  }

  Future<void> lobbyUpdateListener(Lobby lobby) async {
    if (!mounted) return;
    
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 0,
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: Text(
              'Settings',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.onPrimary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: settingsInfo.length,
              itemBuilder: (context, index) {
                final settingSection = settingsInfo[index];

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        settingSection['name'],
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ...settingSection['settings'].map<Widget>((setting) {
                      return generateSettingWidget(
                        setting: setting,
                        onChanged: (value) {
                          setState(() {
                            settings[setting['key']] = value;
                          });

                          lobbyBloc.add(
                            UpdateSetting(
                              key: setting['key'],
                              value: value,
                            )
                          );
                        },
                      );
                    }).toList(),
                  ],
                );
              },
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: TextButton.icon(
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
                  'Back',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget generateSettingWidget({
    required Map<String, dynamic> setting,
    required Function(dynamic) onChanged,
  }) {
    Widget inputWidget;

    TextEditingController _textController;
    bool switchValue;

    switch (setting['type']) {
      case 'integer':
        _textController = TextEditingController(
          text: settings[setting['key']].toString(),
        );
        inputWidget = SizedBox(
          width: 60,
          child: TextField(
            controller: _textController,
            keyboardType: TextInputType.number,
            onChanged: (value) {
              if (value.isEmpty) return;

              if (value.isNotEmpty && !RegExp(r'^[0-9]+$').hasMatch(value)) {
                _textController.text = value.substring(0, value.length - 1);
                return;
              }

              if (value.length > 3) {
                _textController.text = value.substring(0, 3);
                return;
              }
              
              onChanged(int.parse(value));
            },
            onTapOutside: (event) {
              FocusScope.of(context).unfocus();
            },
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
        );
        break;
      case 'boolean':
        switchValue = settings[setting['key']] as bool;

        inputWidget = SizedBox(
          width: 60,
          child: AnimatedToggleSwitch.dual(
            current: switchValue,
            first: false,
            second: true,
            height: 24,
            iconBuilder: (value) {
              return Icon(
                value ? Symbols.check_rounded : Symbols.close_rounded,
                size: 18,
                color: value
                    ? Color(0xFF4CAF50)
                    : Color(0xFFF44336),
              );
            },
            styleBuilder: (value) {
              return ToggleStyle(
                indicatorColor: Colors.white,
                backgroundColor: value
                    ? Color(0xFF4CAF50)
                    : Color(0xFFF44336),
                borderColor: value
                    ? Color(0xFF4CAF50)
                    : Color(0xFFF44336),
              );
            },
            onChanged: (value) {
              onChanged(value);
            },
          ),
        );
        break;
      default:
        throw Exception('Unknown setting type: ${setting['type']}');
    }

    final settingRow = Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              setting['label'] + (setting['units'] != null ? ' in ${setting['units']}' : ''),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
      
          Padding(
            padding: const EdgeInsets.only(left: 32, right: 8),
            child: inputWidget,
          ),
        ],
      ),
    );

    return settingRow;
  }
}