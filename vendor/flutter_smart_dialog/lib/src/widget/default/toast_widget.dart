import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/src/kit/view_utils.dart';

class ToastWidget extends StatelessWidget {
  const ToastWidget({super.key, required this.msg});

  ///toast msg
  final String msg;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 30, vertical: 50),
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
      decoration: BoxDecoration(
        color: ThemeStyle.backgroundColor,
        borderRadius: const BorderRadius.all(Radius.circular(20)),
      ),
      child: Text(msg, style: TextStyle(color: ThemeStyle.textColor)),
    );
  }
}
