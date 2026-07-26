import 'dart:async';

import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:flutter_smart_dialog/src/data/base_dialog.dart';
import 'package:flutter_smart_dialog/src/kit/typedef.dart';

class NotifyInfo {
  NotifyInfo({
    required this.dialog,
    required this.tag,
    required this.backType,
    required this.onBack,
  });

  final BaseDialog dialog;

  String? tag;

  SmartBackType backType;

  Timer? displayTimer;

  final SmartOnBack? onBack;
}
