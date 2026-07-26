// [PiliPlus Learning] 白名单 UP 主仓库
// 使用 Hive(hive_ce)存储白名单 UP 主 UID 列表 (List<String>)
// 复用原项目已初始化的 Hive 运行时,独立开一个 Box,不污染原 GStorage。
import 'package:hive_ce/hive.dart';

class WhiteListRepo {
  WhiteListRepo._();

  static const String _boxName = 'learningWhiteList';
  static const String _key = 'upUids';

  static Box<dynamic>? _box;
  static bool _initializing = false;

  /// 确保 Box 已打开(幂等)。
  /// 必须在原项目 GStorage.init() 完成之后调用(main.dart 已在启动时完成)。
  static Future<void> ensureInit() async {
    if (_box != null && _box!.isOpen) {
      return;
    }
    if (_initializing) {
      // 等待正在进行的初始化完成,避免重复 openBox
      while (_initializing) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
      return;
    }
    _initializing = true;
    try {
      _box = await Hive.openBox<dynamic>(_boxName);
    } finally {
      _initializing = false;
    }
  }

  static Box<dynamic> get _safeBox {
    final box = _box;
    if (box == null || !box.isOpen) {
      throw StateError(
        'WhiteListRepo 未初始化,请先调用 WhiteListRepo.ensureInit()',
      );
    }
    return box;
  }

  /// 读取白名单 UID 列表
  static List<String> getUids() {
    final raw = _safeBox.get(_key);
    if (raw == null) return <String>[];
    if (raw is List) {
      return raw.map((e) => e.toString()).toList(growable: true);
    }
    return <String>[];
  }

  /// 添加 UID(自动去重)
  static Future<void> addUid(String uid) async {
    final uids = getUids();
    if (!uids.contains(uid)) {
      uids.add(uid);
      await _safeBox.put(_key, uids);
    }
  }

  /// 移除 UID
  static Future<void> removeUid(String uid) async {
    final uids = getUids();
    if (uids.remove(uid)) {
      await _safeBox.put(_key, uids);
    }
  }

  /// 覆盖设置整个白名单
  static Future<void> setUids(List<String> uids) async {
    await _safeBox.put(_key, uids);
  }

  /// 清空白名单
  static Future<void> clear() async {
    await _safeBox.put(_key, <String>[]);
  }
}
