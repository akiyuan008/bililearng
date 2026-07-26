import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:flutter_smart_dialog/src/data/base_controller.dart';
import 'package:flutter_smart_dialog/src/helper/dialog_proxy.dart';

void main() {
  group('BaseController.judgeDismissDialogType', () {
    final controller = _TestController();

    test('uses backClose_nonAnimation only for back dismissals', () {
      expect(
        controller.judgeDismissDialogType(
          CloseType.back,
          SmartNonAnimationType.backClose_nonAnimation,
        ),
        isTrue,
      );
      expect(
        controller.judgeDismissDialogType(
          CloseType.back,
          SmartNonAnimationType.maskClose_nonAnimation,
        ),
        isFalse,
      );
    });
  });

  testWidgets('onlyRefresh keeps refreshing after a mask dismissal',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: const Scaffold(body: SizedBox.expand()),
      builder: FlutterSmartDialog.init(),
    ));
    await tester.pump();

    void showToast(String message) {
      SmartDialog.showToast(
        message,
        clickMaskDismiss: true,
        usePenetrate: false,
        useAnimation: false,
        displayTime: const Duration(seconds: 1),
        displayType: SmartToastType.onlyRefresh,
      );
    }

    showToast('before-dismiss');
    await tester.pump();
    showToast('before-dismiss-refresh');
    await tester.pump();
    expect(find.text('before-dismiss-refresh'), findsOneWidget);

    await tester.tapAt(const Offset(10, 10));
    showToast('after-dismiss');
    await tester.pump();
    showToast('after-dismiss-refresh');
    await tester.pump();

    expect(find.text('after-dismiss-refresh'), findsOneWidget);
    expect(find.text('after-dismiss'), findsNothing);

    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
  });
}

class _TestController extends BaseController {
  @override
  Future<void> dismiss({CloseType closeType = CloseType.normal}) async {}
}
