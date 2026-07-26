import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/src/config/enum_config.dart';
import 'package:flutter_smart_dialog/src/config/smart_config.dart';
import 'package:flutter_smart_dialog/src/custom/custom_dialog.dart';
import 'package:flutter_smart_dialog/src/custom/custom_loading.dart';
import 'package:flutter_smart_dialog/src/custom/custom_notify.dart';
import 'package:flutter_smart_dialog/src/custom/toast/custom_toast.dart';
import 'package:flutter_smart_dialog/src/data/dialog_info.dart';
import 'package:flutter_smart_dialog/src/data/loading_info.dart';
import 'package:flutter_smart_dialog/src/data/notify_info.dart';
import 'package:flutter_smart_dialog/src/data/notify_style.dart';
import 'package:flutter_smart_dialog/src/data/show_param.dart';
import 'package:flutter_smart_dialog/src/init_dialog.dart';
import 'package:flutter_smart_dialog/src/widget/helper/smart_overlay_entry.dart';
import 'package:flutter_smart_dialog/src/widget/helper/toast_helper.dart';

enum CloseType {
  // back event
  back,

  // route pop
  route,

  // mask event
  mask,

  // normal dismiss
  normal,
}

enum DialogType {
  dialog,
  custom,
  attach,
  notify,
  allDialog,
  allCustom,
  allAttach,
  allNotify,
}

class DialogProxy {
  late SmartConfig config;
  late SmartOverlayEntry entryLoading;
  late Queue<DialogInfo> dialogQueue;
  late Queue<NotifyInfo> notifyQueue;
  late LoadingInfo loadingInfo = LoadingInfo();

  static DialogProxy? _instance;

  static DialogProxy get instance => _instance ??= DialogProxy._internal();

  static late BuildContext contextCustom;
  static late BuildContext contextAttach;
  static late BuildContext contextNotify;
  static late BuildContext contextToast;

  static BuildContext? contextNavigator;

  ///set default loading widget
  late FlutterSmartLoadingBuilder loadingBuilder;

  ///set default toast widget
  late FlutterSmartToastBuilder toastBuilder;

  ///set default toast widget
  late FlutterSmartNotifyStyle notifyStyle;

  DialogProxy._internal() {
    config = SmartConfig();
    dialogQueue = ListQueue();
    notifyQueue = ListQueue();
  }

  void initialize(Set<SmartInitType> initType) {
    if (initType.contains(SmartInitType.loading)) {
      entryLoading = SmartOverlayEntry(builder: (_) {
        return loadingInfo.loadingWidget.getWidget();
      });
      loadingInfo.loadingWidget = CustomLoading(overlayEntry: entryLoading);
    }
  }

  Future<T?> show<T>({
    required SmartShowCustomParam param,
  }) {
    CustomDialog? dialog;
    var entry = SmartOverlayEntry(
      builder: (BuildContext context) => dialog!.getWidget(),
    );
    dialog = CustomDialog(overlayEntry: entry);
    return dialog.show<T>(param: param);
  }

  Future<T?> showNotify<T>({
    required SmartShowNotifyParam param,
  }) {
    CustomNotify? dialog;
    var entry = SmartOverlayEntry(
      builder: (BuildContext context) => dialog!.getWidget(),
    );
    dialog = CustomNotify(overlayEntry: entry);
    return dialog.showNotify<T>(param: param);
  }

  Future<T?> showAttach<T>({
    required SmartShowAttachParam param,
  }) {
    CustomDialog? dialog;
    var entry = SmartOverlayEntry(
      builder: (BuildContext context) => dialog!.getWidget(),
    );
    dialog = CustomDialog(overlayEntry: entry);
    return dialog.showAttach<T>(param: param);
  }

  Future<T?> showLoading<T>({
    required SmartShowLoadingParam param,
  }) {
    loadingInfo
      ..onBack = param.onBack
      ..backType = param.backType;
    return loadingInfo.loadingWidget.showLoading<T>(param: param);
  }

  Future<void> showToast({
    required SmartShowToastParam param,
  }) {
    CustomToast? toast;
    var entry = SmartOverlayEntry(
      builder: (BuildContext context) => toast!.getWidget(),
    );
    toast = CustomToast(overlayEntry: entry);
    return toast.showToast(
      param: param.copyWith(
        widget:
            ToastHelper(consumeEvent: param.consumeEvent, child: param.widget),
      ),
    );
  }

  Future<void>? dismiss<T>({
    required SmartStatus status,
    String? tag,
    T? result,
    bool force = false,
    CloseType closeType = CloseType.normal,
  }) {
    switch (status) {
      case SmartStatus.smart:
        var loading = config.loading.isExist;

        if (loading &&
            (tag == null || (dialogQueue.isEmpty && notifyQueue.isEmpty))) {
          return loadingInfo.loadingWidget.dismiss(closeType: closeType);
        }

        if (notifyQueue.isNotEmpty) {
          bool useNotify = (tag == null);
          if (tag != null) {
            for (var element in notifyQueue) {
              if (element.tag == tag) {
                useNotify = true;
              }
            }
          }
          if (useNotify) {
            return CustomNotify.dismiss<T>(
              type: DialogType.notify,
              tag: tag,
              result: result,
              force: force,
              closeType: closeType,
            );
          }
        }

        if (dialogQueue.isNotEmpty) {
          return CustomDialog.dismiss<T>(
            type: DialogType.dialog,
            tag: tag,
            result: result,
            force: force,
            closeType: closeType,
          );
        }
      case SmartStatus.toast:
        return CustomToast.dismiss();
      case SmartStatus.allToast:
        return CustomToast.dismiss(closeAll: true);
      case SmartStatus.loading:
        return loadingInfo.loadingWidget.dismiss(closeType: closeType);
      case SmartStatus.notify:
      case SmartStatus.allNotify:
        return CustomNotify.dismiss<T>(
          type: _convertEnum(status)!,
          tag: tag,
          result: result,
          force: force,
          closeType: closeType,
        );
      case _:
    }
    DialogType? type = _convertEnum(status);
    if (type == null) return null;
    return CustomDialog.dismiss<T>(
      type: type,
      tag: tag,
      result: result,
      force: force,
      closeType: closeType,
    );
  }

  DialogType? _convertEnum(SmartStatus status) {
    return switch (status) {
      SmartStatus.custom => DialogType.custom,
      SmartStatus.attach => DialogType.attach,
      SmartStatus.dialog => DialogType.dialog,
      SmartStatus.notify => DialogType.notify,
      SmartStatus.allCustom => DialogType.allCustom,
      SmartStatus.allAttach => DialogType.allAttach,
      SmartStatus.allDialog => DialogType.allDialog,
      SmartStatus.allNotify => DialogType.allNotify,
      _ => null,
    };
  }
}
