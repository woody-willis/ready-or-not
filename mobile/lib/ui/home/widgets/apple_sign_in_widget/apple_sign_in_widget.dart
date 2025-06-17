import 'dart:io';

import 'package:flutter/material.dart';

class AppleSignInWidget extends StatelessWidget {
  const AppleSignInWidget({
    Key? key,
    required this.onTap,
  }) : super(key: key);

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (!Platform.isIOS) return const SizedBox();
    
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
              Image.asset('assets/sign_in_widgets/apple.png', height: 40),
              const SizedBox(width: 8),
              const Text('Sign in with Apple'),
            ],
          ),
        ),
      ),
    );
  }
}