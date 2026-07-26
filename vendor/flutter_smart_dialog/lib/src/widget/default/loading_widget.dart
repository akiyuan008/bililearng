import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/src/kit/view_utils.dart';

class LoadingWidget extends StatelessWidget {
  const LoadingWidget({super.key, required this.msg});

  ///loading msg
  final String msg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
      decoration: BoxDecoration(
        color: ThemeStyle.backgroundColor,
        borderRadius: const BorderRadius.all(Radius.circular(15)),
      ),
      child: Column(
        spacing: 20,
        mainAxisSize: MainAxisSize.min,
        children: [
          //loading animation
          CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation(ThemeStyle.textColor),
          ),

          //msg
          Text(msg, style: TextStyle(color: ThemeStyle.textColor)),
        ],
      ),
    );
  }
}
