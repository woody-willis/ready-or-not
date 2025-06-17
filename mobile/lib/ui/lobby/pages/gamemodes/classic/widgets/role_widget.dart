import 'package:flutter/material.dart';

class RoleWidget extends StatelessWidget {
  final String role;

  const RoleWidget({
    Key? key,
    required this.role,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(150),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'You are a',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.white,
            ),
          ),
          Text(
            role,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 36,
            ),
          ),
        ],
      ),
    );
  }
}