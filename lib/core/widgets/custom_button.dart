import 'package:flutter/material.dart';

import '../constants/app_constants.dart';

/// A reusable primary/secondary button with an optional loading state.
class CustomButton extends StatelessWidget {
  const CustomButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isOutlined = false,
    this.expanded = true,
    this.color,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool isOutlined;
  final bool expanded;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final Widget child = isLoading
        ? const SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Icon(icon, size: 20),
                const SizedBox(width: AppConstants.spacingSm),
              ],
              Flexible(
                child: Text(label, overflow: TextOverflow.ellipsis),
              ),
            ],
          );

    final VoidCallback? handler = isLoading ? null : onPressed;

    final Widget button = isOutlined
        ? OutlinedButton(onPressed: handler, child: child)
        : ElevatedButton(
            onPressed: handler,
            style: color != null
                ? ElevatedButton.styleFrom(backgroundColor: color)
                : null,
            child: child,
          );

    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }
}
