import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/src/config/enum_config.dart';

class MaskEvent extends StatefulWidget {
  const MaskEvent({
    super.key,
    required this.maskTriggerType,
    required this.onMask,
    required this.child,
  });

  final SmartMaskTriggerType maskTriggerType;

  final VoidCallback onMask;

  final Widget child;

  @override
  State<MaskEvent> createState() => _MaskEventState();
}

class _MaskEventState extends State<MaskEvent> {
  bool _maskTrigger = false;
  VoidCallback? _onPointerDown;
  VoidCallback? _onPointerMove;
  VoidCallback? _onPointerUp;

  @override
  void initState() {
    super.initState();
    switch (widget.maskTriggerType) {
      case SmartMaskTriggerType.down:
        _onPointerDown = widget.onMask;
      case SmartMaskTriggerType.move:
        _onPointerMove = widget.onMask;
      case SmartMaskTriggerType.up:
        _onPointerUp = widget.onMask;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (event) {
        if (_onPointerDown != null) {
          _onPointerDown!();
          _maskTrigger = true;
        }
      },
      onPointerMove: (event) {
        if (!_maskTrigger) _onPointerMove?.call();
        if (_onPointerMove != null) _maskTrigger = true;
      },
      onPointerUp: (event) {
        _onPointerUp?.call();
        if (_onPointerUp == null && !_maskTrigger) widget.onMask.call();
        _maskTrigger = false;
      },
      child: widget.child,
    );
  }
}
