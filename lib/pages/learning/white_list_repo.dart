// [PiliPlus Learning] 白名单 UP 主仓库
// 使用 Hive(hive_ce)存储白名单 UP 主列表
// 复用原项目已初始化的 Hive 运行时,独立开一个 Box,不污染原 GStorage。
import 'package:hive_ce/hive.dart';

/// 白名单 UP 主信息
class UpInfo {
  final String mid;
  final String name;
  final String face;

  const UpInfo({required this.mid, required this.name, required this.face});

  Map<String, dynamic> toJson() => {'mid': mid, 'name': name, 'face': face};

  factory UpInfo.fromJson(Map<dynamic, dynamic> json) => UpInfo(
        mid: json['mid']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        face: json['face']?.toString() ?? '',
      );
}

class WhiteListRepo {
  WhiteListRepo._();

  static const String _boxName = 'learningWhiteList';
  static const String _key = 'upList';

  static Box<dynamic>? _box;
  static bool _initializing = false;

  /// 确保 Box 已打开(幂等)。
  static Future<void> ensureInit() async {
    if (_box != null && _box!.isOpen) {
      return;
    }
    if (_initializing) {
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

  /// 读取白名单 UP 主列表
  static List<UpInfo> getUpList() {
    final raw = _safeBox.get(_key);
    if (raw == null) return <UpInfo>[];
    if (raw is List) {
      return raw
          .map((e) {
            if (e is Map) return UpInfo.fromJson(e);
            // 兼容旧版纯 UID 字符串
            if (e is String) return UpInfo(mid: e, name: 'UID: $e', face: '');
            return null;
          })
          .whereType<UpInfo>()
          .toList(growable: true);
    }
    return <UpInfo>[];
  }

  /// 读取白名单 UID 列表(兼容旧接口)
  static List<String> getUids() => getUpList().map((e) => e.mid).toList();

  /// 添加 UP 主(自动去重)
  static Future<void> addUp(UpInfo up) async {
    final list = getUpList();
    if (!list.any((e) => e.mid == up.mid)) {
      list.add(up);
      await _safeBox.put(_key, list.map((e) => e.toJson()).toList());
    }
  }

  /// 移除 UP 主
  static Future<void> removeUp(String mid) async {
    final list = getUpList();
    final before = list.length;
    list.removeWhere((e) => e.mid == mid);
    if (list.length != before) {
      await _safeBox.put(_key, list.map((e) => e.toJson()).toList());
    }
  }

  /// 清空白名单
  static Future<void> clear() async {
    await _safeBox.put(_key, <UpInfo>[]);
  }
}
