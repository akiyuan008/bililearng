import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

enum DebounceType {
  custom,
  attach,
  notify,
  toast,
  mask,
}

class DebounceUtils {
  static DebounceUtils? _instance;

  static DebounceUtils get instance => _instance ??= DebounceUtils._();

  DebounceUtils._();

  Map<DebounceType, DateTime> map = {};

  bool banContinue(DebounceType type, bool debounce) {
    if (!debounce) {
      return false;
    }

    var limitTime = switch (type) {
      DebounceType.custom => SmartDialog.config.custom.debounceTime,
      DebounceType.attach => SmartDialog.config.attach.debounceTime,
      DebounceType.notify => SmartDialog.config.notify.debounceTime,
      DebounceType.toast => SmartDialog.config.toast.debounceTime,
      DebounceType.mask => const Duration(milliseconds: 500),
    };

    var curTime = DateTime.now();
    DateTime? lastTime = map[type];
    map[type] = curTime;
    var banContinue = false;
    if (lastTime != null) {
      banContinue = curTime.difference(lastTime) < limitTime;
    }

    return banContinue;
  }
}
