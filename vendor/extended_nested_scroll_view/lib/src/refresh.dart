import 'package:flutter/material.dart';

typedef OnDrag = bool Function(double offset, double viewportDimension);

mixin RefreshScrollPhysicsMixin on ScrollPhysics {
  OnDrag get onDrag;

  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    if (offset < 0.0 && onDrag(offset, position.viewportDimension)) {
      return 0.0;
    }
    return parent?.applyPhysicsToUserOffset(position, offset) ?? offset;
  }
}
