// [PiliPlus Learning] 学习统计仓库
// 使用 Hive 按日期记录学习时长(秒),独立 Box 不污染原 GStorage。
import 'package:hive_ce/hive.dart';

class StatsRepo {
  StatsRepo._();

  static const String _boxName = 'learningStats';
  static Box<dynamic>? _box;
  static bool _initializing = false;

  static Future<void> ensureInit() async {
    if (_box != null && _box!.isOpen) return;
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
      throw StateError('StatsRepo 未初始化');
    }
    return box;
  }

  /// 生成日期 key: yyyy-MM-dd
  static String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// 获取指定日期的学习时长(秒)
  static int getSeconds(DateTime date) {
    return _safeBox.get(_dateKey(date), defaultValue: 0) as int;
  }

  /// 增加指定日期的学习时长
  static Future<void> addSeconds(DateTime date, int seconds) async {
    final key = _dateKey(date);
    final current = _safeBox.get(key, defaultValue: 0) as int;
    await _safeBox.put(key, current + seconds);
  }

  /// 获取最近 N 天的学习时长列表
  /// 返回 [{date: DateTime, seconds: int}] 列表，按日期正序
  static List<({DateTime date, int seconds})> getRecentDays(int days) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final result = <({DateTime date, int seconds})>[];
    for (int i = days - 1; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      result.add((date: date, seconds: getSeconds(date)));
    }
    return result;
  }

  /// 获取总学习时长(秒) - 所有记录
  static int getTotalSeconds() {
    int total = 0;
    for (final key in _safeBox.keys) {
      total += _safeBox.get(key, defaultValue: 0) as int;
    }
    return total;
  }

  /// 获取学习天数(有记录且>0的天数)
  static int getStudyDays() {
    int count = 0;
    for (final key in _safeBox.keys) {
      if ((_safeBox.get(key, defaultValue: 0) as int) > 0) count++;
    }
    return count;
  }

  /// 获取今日学习时长(秒)
  static int getTodaySeconds() => getSeconds(DateTime.now());

  /// 格式化时长为可读字符串
  static String formatDuration(int seconds) {
    if (seconds <= 0) return '0分钟';
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h > 0) return '$h小时$m分钟';
    if (m > 0) return '$m分钟';
    return '$seconds秒';
  }
}
