import 'package:flutter/material.dart';

import '../constants/app_constants.dart';

/// A centered loading indicator with an optional message.
class LoadingWidget extends StatelessWidget {
  const LoadingWidget({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const CircularProgressIndicator(strokeWidth: 3),
          if (message != null) ...<Widget>[
            const SizedBox(height: AppConstants.spacingMd),
            Text(message!, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}
