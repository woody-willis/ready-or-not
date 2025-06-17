import 'package:flutter/material.dart';

class LoginHeader extends StatelessWidget {
  const LoginHeader({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 80.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              text: 'Welcome to ',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: Theme.of(context).colorScheme.onPrimary,
                fontWeight: FontWeight.w400,
              ),
              children: [
                TextSpan(
                  text: 'Ready or Not',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8.0),
          Text(
            'Choose an option below to get started',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onPrimary,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
