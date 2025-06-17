import 'package:flutter/material.dart';

class GameModeWidget extends StatelessWidget {
  const GameModeWidget({
    Key? key,
    required this.name,
    required this.code,
    required this.imageAssetPath,
    this.isNew = false,
    this.isComingSoon = false,
  }) : super(key: key);

  final String name;
  final String code;
  final String imageAssetPath;
  final bool isNew;
  final bool isComingSoon;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              imageAssetPath,
              fit: BoxFit.cover,
              width: double.infinity,
              height: 100,
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: 0,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                color: Colors.black.withAlpha(40),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(120),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Text(
                name,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ),
          ),
          if (isNew)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'NEW',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSecondary,
                  ),
                ),
              ),
            ),
          if (isComingSoon)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.tertiary,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'COMING SOON',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onTertiary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}