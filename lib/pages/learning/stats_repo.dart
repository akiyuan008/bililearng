// [PiliPlus Learning] 学习统计仓库
// 使用 Hive 按日期记录学习时长(秒)和视频观看明细,独立 Box 不污染原 GStorage。
// 存储 Key 设计:
//   "d:yyyy-MM-dd"       -> int    (每日总学习秒数)
//   "v:yyyy-MM-dd"       -> List   (每日视频观看记录, JSON 编码)
import 'dart:convert';
import 'package:hive_ce/hive.dart';

/// 单条视频观看记录
class VideoWatchRecord {
  final String title;
  final String upName;
  final String? cover;
  final String? bvid;
  final int seconds;
  final DateTime watchedAt;

  VideoWatchRecord({
    required this.title,
    required this.upName,
    this.cover,
    this.bvid,
    required this.seconds,
    required this.watchedAt,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'upName': upName,
        'cover': cover,
        'bvid': bvid,
        'seconds': seconds,
        'ts': watchedAt.millisecondsSinceEpoch,
      };

  factory VideoWatchRecord.fromJson(Map<String, dynamic> json) {
    return VideoWatchRecord(
      title: json['title'] as String? ?? '',
      upName: json['upName'] as String? ?? '',
      cover: json['cover'] as String?,
      bvid: json['bvid'] as String?,
      seconds: json['seconds'] as int? ?? 0,
      watchedAt: DateTime.fromMillisecondsSinceEpoch(
        json['ts'] as int? ?? 0,
      ),
    );
  }
}

/// 按日期分组的视频记录
class DateGroupedRecords {
  final DateTime date;
  final int totalSeconds;
  final List<VideoWatchRecord> records;

  DateGroupedRecords({
    required this.date,
    required this.totalSeconds,
    required this.records,
  });
}

/// 日报/周报/月报汇总数据
class PeriodSummary {
  final int totalSeconds;
  final int studyDays;
  final int videoCount;
  final List<VideoWatchRecord> records;
  final List<({DateTime date, int seconds})> dailyData;
  final int averageDailySeconds;
  final int studyStreak;
  final int maxDaySeconds;
  final DateTime? maxDayDate;
  final List<DateGroupedRecords> recordsByDate;

  PeriodSummary({
    required this.totalSeconds,
    required this.studyDays,
    required this.videoCount,
    required this.records,
    required this.dailyData,
    required this.averageDailySeconds,
    required this.studyStreak,
    required this.maxDaySeconds,
    this.maxDayDate,
    required this.recordsByDate,
  });
}

/// 打卡日历单日数据(用于热力图)
class CalendarDay {
  final DateTime date;
  final int seconds;
  final bool isCheckIn;
  final bool isFuture;
  final bool isToday;

  const CalendarDay({
    required this.date,
    required this.seconds,
    required this.isCheckIn,
    required this.isFuture,
    required this.isToday,
  });
}

class StatsRepo {
  StatsRepo._();

  static const String _boxName = 'learningStats';
  static Box<dynamic>? _box;
  static bool _initializing = false;

  /// 每日打卡目标时长(秒) — 60分钟,仿多邻国打卡制度
  static const int dailyGoalSeconds = 3600;

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

  // ======================== 学习时长 ========================

  /// 获取指定日期的学习时长(秒)
  static int getSeconds(DateTime date) {
    return _safeBox.get('d:${_dateKey(date)}', defaultValue: 0) as int;
  }

  /// 增加指定日期的学习时长
  static Future<void> addSeconds(DateTime date, int seconds) async {
    final key = 'd:${_dateKey(date)}';
    final current = _safeBox.get(key, defaultValue: 0) as int;
    await _safeBox.put(key, current + seconds);
  }

  /// 获取最近 N 天的学习时长列表(只含今天及之前,不含未来日期)
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

  /// 获取总学习时长(秒)
  static int getTotalSeconds() {
    int total = 0;
    for (final key in _safeBox.keys) {
      if (key is String && key.startsWith('d:')) {
        total += _safeBox.get(key, defaultValue: 0) as int;
      }
    }
    return total;
  }

  /// 获取学习天数(有记录且>0的天数)
  static int getStudyDays() {
    int count = 0;
    for (final key in _safeBox.keys) {
      if (key is String && key.startsWith('d:')) {
        if ((_safeBox.get(key, defaultValue: 0) as int) > 0) count++;
      }
    }
    return count;
  }

  /// 获取今日学习时长(秒)
  static int getTodaySeconds() => getSeconds(DateTime.now());

  /// 获取连续学习天数(从今天往前数,连续有学习记录的天数)
  /// 如果今天还没学习但昨天有,则从昨天开始算
  static int getStudyStreak() {
    final now = DateTime.now();
    var date = DateTime(now.year, now.month, now.day);
    // 如果今天还没学习,从昨天开始算
    if (getSeconds(date) == 0) {
      date = date.subtract(const Duration(days: 1));
    }
    int streak = 0;
    while (getSeconds(date) > 0) {
      streak++;
      date = date.subtract(const Duration(days: 1));
    }
    return streak;
  }

  // ======================== 多邻国式打卡制度 ========================
  // 每日学习满 60 分钟才算"打卡成功",未满 60 分钟算"断卡"。

  /// 判断指定日期是否打卡成功(学习时长 >= dailyGoalSeconds)
  static bool isCheckIn(DateTime date) {
    return getSeconds(date) >= dailyGoalSeconds;
  }

  /// 今日是否已打卡
  static bool isTodayCheckedIn() => isCheckIn(DateTime.now());

  /// 今日打卡进度(0.0 ~ 1.0)
  static double getTodayProgress() {
    final seconds = getTodaySeconds();
    return (seconds / dailyGoalSeconds).clamp(0.0, 1.0);
  }

  /// 今日还需多少秒才能打卡
  static int getTodayRemainingSeconds() {
    final remaining = dailyGoalSeconds - getTodaySeconds();
    return remaining > 0 ? remaining : 0;
  }

  /// 获取连续打卡天数(从今天往前数,连续满足60分钟的天数)
  /// 如果今天还没打卡但昨天打卡了,则从昨天开始算(宽容设计)
  static int getCheckInStreak() {
    final now = DateTime.now();
    var date = DateTime(now.year, now.month, now.day);
    // 如果今天还没打卡,从昨天开始算
    if (!isCheckIn(date)) {
      date = date.subtract(const Duration(days: 1));
    }
    int streak = 0;
    while (isCheckIn(date)) {
      streak++;
      date = date.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// 获取总打卡天数(满足60分钟的天数)
  static int getCheckInDays() {
    int count = 0;
    for (final key in _safeBox.keys) {
      if (key is String && key.startsWith('d:')) {
        if ((_safeBox.get(key, defaultValue: 0) as int) >= dailyGoalSeconds) {
          count++;
        }
      }
    }
    return count;
  }

  /// 获取最近 N 周的打卡日历数据(用于热力图/GitHub式贡献图)
  /// 返回按周分组的列表,每周7天(周日~周六),每天包含日期和是否打卡
  static List<List<CalendarDay>> getCheckInCalendar(int weeks) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // 找到本周周日(日历起始)
    final thisSunday = today.subtract(Duration(days: today.weekday % 7));
    // 日历起始日 = thisSunday 往前推 weeks-1 周
    final startDate = thisSunday.subtract(Duration(days: (weeks - 1) * 7));

    final result = <List<CalendarDay>>[];
    for (int w = 0; w < weeks; w++) {
      final week = <CalendarDay>[];
      for (int d = 0; d < 7; d++) {
        final date = startDate.add(Duration(days: w * 7 + d));
        final seconds = getSeconds(date);
        week.add(CalendarDay(
          date: date,
          seconds: seconds,
          isCheckIn: seconds >= dailyGoalSeconds,
          isFuture: date.isAfter(today),
          isToday: date == today,
        ));
      }
      result.add(week);
    }
    return result;
  }

  /// 获取最长连续打卡天数(历史最高)
  static int getMaxCheckInStreak() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // 从今天往前扫描所有有记录的日期
    var date = today;
    // 先跳到最早有记录的日期
    DateTime? earliest;
    for (final key in _safeBox.keys) {
      if (key is String && key.startsWith('d:')) {
        final dateStr = key.substring(2);
        try {
          final parts = dateStr.split('-');
          final d = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
          if (earliest == null || d.isBefore(earliest)) {
            earliest = d;
          }
        } catch (_) {}
      }
    }
    if (earliest == null) return 0;

    int maxStreak = 0;
    int currentStreak = 0;
    var scanDate = earliest;
    while (!scanDate.isAfter(today)) {
      if (isCheckIn(scanDate)) {
        currentStreak++;
        if (currentStreak > maxStreak) maxStreak = currentStreak;
      } else {
        currentStreak = 0;
      }
      scanDate = scanDate.add(const Duration(days: 1));
    }
    return maxStreak;
  }

  /// 获取总观看视频数
  static int getTotalVideoCount() {
    int count = 0;
    for (final key in _safeBox.keys) {
      if (key is String && key.startsWith('v:')) {
        final raw = _safeBox.get(key);
        if (raw is String && raw.isNotEmpty) {
          try {
            final list = jsonDecode(raw) as List<dynamic>;
            count += list.length;
          } catch (_) {}
        }
      }
    }
    return count;
  }

  // ======================== 视频观看记录 ========================

  /// 记录一次视频观看
  static Future<void> addVideoRecord(VideoWatchRecord record) async {
    final key = 'v:${_dateKey(record.watchedAt)}';
    final raw = _safeBox.get(key);
    List<dynamic> list = [];
    if (raw is String && raw.isNotEmpty) {
      try {
        list = jsonDecode(raw) as List<dynamic>;
      } catch (_) {}
    }
    list.add(record.toJson());
    // 每天最多保留 200 条记录,防止数据膨胀
    if (list.length > 200) {
      list = list.sublist(list.length - 200);
    }
    await _safeBox.put(key, jsonEncode(list));
  }

  /// 获取指定日期的视频观看记录
  static List<VideoWatchRecord> getVideoRecords(DateTime date) {
    final key = 'v:${_dateKey(date)}';
    final raw = _safeBox.get(key);
    if (raw is String && raw.isNotEmpty) {
      try {
        final list = jsonDecode(raw) as List<dynamic>;
        return list
            .map((e) => VideoWatchRecord.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {}
    }
    return [];
  }

  /// 获取指定日期范围内的视频观看记录(不含未来日期)
  static List<VideoWatchRecord> getVideoRecordsRange(
    DateTime start,
    DateTime end,
  ) {
    final result = <VideoWatchRecord>[];
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    var date = DateTime(start.year, start.month, start.day);
    final endDate = DateTime(end.year, end.month, end.day);
    while (!date.isAfter(endDate)) {
      // 跳过未来日期
      if (!date.isAfter(todayDate)) {
        result.addAll(getVideoRecords(date));
      }
      date = date.add(const Duration(days: 1));
    }
    // 按观看时间倒序排列(最新的在前)
    result.sort((a, b) => b.watchedAt.compareTo(a.watchedAt));
    return result;
  }

  /// 获取按日期分组的视频记录(不含未来日期,按日期倒序)
  static List<DateGroupedRecords> getRecordsGroupedByDate(
    DateTime start,
    DateTime end,
  ) {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final result = <DateGroupedRecords>[];
    var date = DateTime(start.year, start.month, start.day);
    final endDate = DateTime(end.year, end.month, end.day);
    while (!date.isAfter(endDate)) {
      if (!date.isAfter(todayDate)) {
        final records = getVideoRecords(date);
        if (records.isNotEmpty) {
          final totalSeconds = getSeconds(date);
          records.sort((a, b) => b.watchedAt.compareTo(a.watchedAt));
          result.add(DateGroupedRecords(
            date: date,
            totalSeconds: totalSeconds,
            records: records,
          ));
        }
      }
      date = date.add(const Duration(days: 1));
    }
    // 按日期倒序排列
    result.sort((a, b) => b.date.compareTo(a.date));
    return result;
  }

  // ======================== 汇总报表 ========================

  /// 获取日报数据(今天)
  static PeriodSummary getDailyReport() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final records = getVideoRecords(today);
    records.sort((a, b) => b.watchedAt.compareTo(a.watchedAt));
    final seconds = getSeconds(today);
    return PeriodSummary(
      totalSeconds: seconds,
      studyDays: seconds > 0 ? 1 : 0,
      videoCount: records.length,
      records: records,
      dailyData: [(date: today, seconds: seconds)],
      averageDailySeconds: seconds,
      studyStreak: getStudyStreak(),
      maxDaySeconds: seconds,
      maxDayDate: seconds > 0 ? today : null,
      recordsByDate: records.isNotEmpty
          ? [
              DateGroupedRecords(
                date: today,
                totalSeconds: seconds,
                records: records,
              ),
            ]
          : [],
    );
  }

  /// 获取周报数据(近7天)
  static PeriodSummary getWeeklyReport() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekAgo = today.subtract(const Duration(days: 6));
    final dailyData = getRecentDays(7);
    final records = getVideoRecordsRange(weekAgo, today);
    final recordsByDate = getRecordsGroupedByDate(weekAgo, today);
    var totalSeconds = 0;
    var studyDays = 0;
    var maxDaySeconds = 0;
    DateTime? maxDayDate;
    for (final d in dailyData) {
      totalSeconds += d.seconds;
      if (d.seconds > 0) studyDays++;
      if (d.seconds > maxDaySeconds) {
        maxDaySeconds = d.seconds;
        maxDayDate = d.date;
      }
    }
    return PeriodSummary(
      totalSeconds: totalSeconds,
      studyDays: studyDays,
      videoCount: records.length,
      records: records,
      dailyData: dailyData,
      averageDailySeconds: totalSeconds ~/ 7,
      studyStreak: getStudyStreak(),
      maxDaySeconds: maxDaySeconds,
      maxDayDate: maxDayDate,
      recordsByDate: recordsByDate,
    );
  }

  /// 获取月报数据(近30天)
  static PeriodSummary getMonthlyReport() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final monthAgo = today.subtract(const Duration(days: 29));
    final dailyData = getRecentDays(30);
    final records = getVideoRecordsRange(monthAgo, today);
    final recordsByDate = getRecordsGroupedByDate(monthAgo, today);
    var totalSeconds = 0;
    var studyDays = 0;
    var maxDaySeconds = 0;
    DateTime? maxDayDate;
    for (final d in dailyData) {
      totalSeconds += d.seconds;
      if (d.seconds > 0) studyDays++;
      if (d.seconds > maxDaySeconds) {
        maxDaySeconds = d.seconds;
        maxDayDate = d.date;
      }
    }
    return PeriodSummary(
      totalSeconds: totalSeconds,
      studyDays: studyDays,
      videoCount: records.length,
      records: records,
      dailyData: dailyData,
      averageDailySeconds: totalSeconds ~/ 30,
      studyStreak: getStudyStreak(),
      maxDaySeconds: maxDaySeconds,
      maxDayDate: maxDayDate,
      recordsByDate: recordsByDate,
    );
  }

  // ======================== 工具方法 ========================

  /// 格式化时长为可读字符串
  static String formatDuration(int seconds) {
    if (seconds <= 0) return '0分钟';
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h > 0) return '$h小时$m分钟';
    if (m > 0) return '$m分钟';
    return '$seconds秒';
  }

  /// 格式化时长为简短形式(用于图表和标签)
  static String formatDurationShort(int seconds) {
    if (seconds <= 0) return '0m';
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h > 0) return '${h}h${m > 0 ? "${m}m" : ""}';
    if (m > 0) return '${m}m';
    return '${seconds}s';
  }

  /// 格式化日期为 MM月dd日
  static String formatDate(DateTime date) {
    return '${date.month}月${date.day}日';
  }

  /// 格式化日期为 MM/dd
  static String formatDateShort(DateTime date) {
    return '${date.month}/${date.day}';
  }

  /// 获取星期几的中文
  static String weekdayChinese(DateTime date) {
    const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return weekdays[date.weekday - 1];
  }
}
