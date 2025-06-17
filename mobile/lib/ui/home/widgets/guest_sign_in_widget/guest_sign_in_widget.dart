import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

class GuestSignInWidget extends StatelessWidget {
  const GuestSignInWidget({
    Key? key,
    required this.onTap,
  }) : super(key: key);

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 16, 32, 0),
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 50,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Symbols.person_filled_rounded,
                size: 30,
                color: Colors.black,
                fill: 1,
              ),
              const SizedBox(width: 16),
              const Text('Continue as Guest'),
            ],
          ),
        ),
      ),
    );
  }
}