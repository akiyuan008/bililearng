import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/src/kit/view_utils.dart';

class NotifyError extends StatelessWidget {
  const NotifyError({
    super.key,
    required this.msg,
  });

  final String msg;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        color: ThemeStyle.backgroundColor,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        spacing: 5,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 22, color: ThemeStyle.textColor),
          Text(msg, style: TextStyle(color: ThemeStyle.textColor)),
        ],
      ),
    );
  }
}
