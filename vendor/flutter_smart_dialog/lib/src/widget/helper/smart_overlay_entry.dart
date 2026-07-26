import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/src/kit/view_utils.dart';

class SmartOverlayEntry extends OverlayEntry {
  SmartOverlayEntry({
    required super.builder,
    super.opaque,
    super.maintainState,
  });

  bool _disposedByOwner = false;

  @override
  void markNeedsBuild() {
    ViewUtils.addSafeUse(() {
      if (_disposedByOwner || !mounted) {
        return;
      }
      super.markNeedsBuild();
    });
  }

  @override
  void remove() {
    if (_disposedByOwner || !mounted) {
      return;
    }
    _disposedByOwner = true;
    super.remove();
    super.dispose();
  }
}
