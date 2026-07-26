import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/src/kit/view_utils.dart';

class ToastHelper extends StatefulWidget {
  const ToastHelper({
    super.key,
    required this.consumeEvent,
    required this.child,
  });

  final bool consumeEvent;

  final Widget child;

  @override
  State<ToastHelper> createState() => _ToastHelperState();
}

class _ToastHelperState extends State<ToastHelper> {
  //solve problem of keyboard shelter toast
  double _keyboardHeight = 0;
  BuildContext? _childContext;

  //offset size
  double? _childToBottom;

  @override
  void initState() {
    ViewUtils.addSafeUse(() {
      if (!mounted || !_updateSelfInfo()) {
        return;
      }
      _dealKeyboard();
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var child = Builder(builder: (context) {
      _childContext = context;
      return widget.child;
    });

    return Padding(
      padding: EdgeInsets.only(bottom: _keyboardHeight),
      child: widget.consumeEvent ? child : IgnorePointer(child: child),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _dealKeyboard();
  }

  void _dealKeyboard() {
    ViewUtils.addSafeUse(() {
      if (!mounted || !_updateSelfInfo()) {
        return;
      }

      var keyboardHeight = MediaQuery.viewInsetsOf(context).bottom;
      if (_childToBottom! < 0) {
        _updateKeyboardHeight(keyboardHeight);
        return;
      }
      if (_childToBottom! - keyboardHeight > -30) {
        return;
      }
      _updateKeyboardHeight(keyboardHeight - _childToBottom!);
    });
  }

  bool _updateSelfInfo() {
    if (_childToBottom != null) {
      return true;
    }

    final childContext = _childContext;
    if (!(childContext?.mounted ?? false)) {
      _childToBottom = null;
      return false;
    }

    final renderObject = childContext!.findRenderObject();
    if (renderObject is! RenderBox ||
        !renderObject.attached ||
        !renderObject.hasSize) {
      _childToBottom = null;
      return false;
    }

    try {
      var selfOffset =
          renderObject.localToGlobal(renderObject.size.bottomLeft(Offset.zero));
      var screenHeight = MediaQuery.heightOf(context);
      _childToBottom = screenHeight - selfOffset.dy;
      return true;
    } catch (_) {
      _childToBottom = null;
      return false;
    }
  }

  void _updateKeyboardHeight(double value) {
    if (_keyboardHeight == value) {
      return;
    }
    _keyboardHeight = value;
    setState(() {});
  }
}
