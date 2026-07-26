import 'package:flutter_smart_dialog/src/config/enum_config.dart';
import 'package:flutter_smart_dialog/src/helper/dialog_proxy.dart';

/// widget controller
abstract class BaseController {
  Future<void> dismiss({CloseType closeType = CloseType.normal});

  bool judgeDismissDialogType(
    CloseType closeType,
    SmartNonAnimationType nonAnimationType,
  ) {
    return switch (nonAnimationType) {
      SmartNonAnimationType.closeDialog_nonAnimation => true,
      SmartNonAnimationType.routeClose_nonAnimation =>
        closeType == CloseType.route,
      SmartNonAnimationType.maskClose_nonAnimation =>
        closeType == CloseType.mask,
      SmartNonAnimationType.backClose_nonAnimation =>
        closeType == CloseType.back,
      _ => false,
    };
  }
}
