// [PiliPlus Learning] 学习统计页面 — 多邻国式打卡制度
// 每日学习满60分钟才算打卡成功,未满则断卡。
// 顶部:打卡进度环 + 连续打卡天数 + 今日状态
// 中部:GitHub风格打卡热力图(近12周)
// 底部:日报/周报/月报 Tab(保留原有柱状图和视频记录)
import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'stats_repo.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtr;
  PeriodSummary? _dailyReport;
  PeriodSummary? _weeklyReport;
  PeriodSummary? _monthlyReport;
  int _totalSeconds = 0;
  int _studyDays = 0;
  int _totalVideos = 0;
  int _checkInStreak = 0;
  int _maxCheckInStreak = 0;
  int _checkInDays = 0;
  int _todaySeconds = 0;
  List<List<CalendarDay>> _calendar = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabCtr = TabController(length: 3, vsync: this);
    _loadData();
  }

  void _loadData() async {
    await StatsRepo.ensureInit();
    setState(() {
      _dailyReport = StatsRepo.getDailyReport();
      _weeklyReport = StatsRepo.getWeeklyReport();
      _monthlyReport = StatsRepo.getMonthlyReport();
      _totalSeconds = StatsRepo.getTotalSeconds();
      _studyDays = StatsRepo.getStudyDays();
      _totalVideos = StatsRepo.getTotalVideoCount();
      _checkInStreak = StatsRepo.getCheckInStreak();
      _maxCheckInStreak = StatsRepo.getMaxCheckInStreak();
      _checkInDays = StatsRepo.getCheckInDays();
      _todaySeconds = StatsRepo.getTodaySeconds();
      _calendar = StatsRepo.getCheckInCalendar(12);
      _loading = false;
    });
  }

  @override
  void dispose() {
    _tabCtr.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('学习统计'),
        bottom: TabBar(
          controller: _tabCtr,
          tabs: const [
            Tab(text: '今日'),
            Tab(text: '周报'),
            Tab(text: '月报'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: '刷新',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _loading = true);
              _loadData();
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabCtr,
              children: [
                _buildTodayView(colorScheme),
                _buildWeeklyView(colorScheme),
                _buildMonthlyView(colorScheme),
              ],
            ),
    );
  }

  // ======================== 今日(打卡主页) ========================
  Widget _buildTodayView(ColorScheme colorScheme) {
    final report = _dailyReport!;
    final isCheckedIn = StatsRepo.isTodayCheckedIn();
    final progress = StatsRepo.getTodayProgress();
    final remainingSeconds = StatsRepo.getTodayRemainingSeconds();
    final remainingMin = remainingSeconds ~/ 60;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ===== 打卡进度环 =====
        _buildCheckInRing(colorScheme, isCheckedIn, progress, remainingMin),
        const SizedBox(height: 20),

        // ===== 连续打卡统计卡片 =====
        _buildStreakCards(colorScheme, isCheckedIn),
        const SizedBox(height: 20),

        // ===== 打卡热力图 =====
        _buildCheckInHeatmap(colorScheme),
        const SizedBox(height: 20),

        // ===== 今日数据卡片 =====
        _buildSummaryCards(
          colorScheme,
          todaySeconds: report.totalSeconds,
          videoCount: report.videoCount,
        ),
        const SizedBox(height: 16),

        // ===== 今日视频观看明细 =====
        _buildSectionTitle(
          colorScheme,
          icon: Icons.play_circle_outline,
          title: '今日观看视频 (${report.videoCount})',
        ),
        const SizedBox(height: 8),
        if (report.records.isEmpty)
          _buildEmptyHint('今天还没有学习记录\n去看几个学习视频吧~')
        else
          ...report.records.map((r) => _buildVideoRecordTile(colorScheme, r)),
      ],
    );
  }

  /// 打卡进度环(多邻国风格大圆环)
  Widget _buildCheckInRing(
    ColorScheme colorScheme,
    bool isCheckedIn,
    double progress,
    int remainingMin,
  ) {
    final ringColor = isCheckedIn ? Colors.green : colorScheme.primary;
    final bgColor = isCheckedIn
        ? Colors.green.withValues(alpha: 0.1)
        : colorScheme.primaryContainer.withValues(alpha: 0.3);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isCheckedIn
              ? [Colors.green.shade400, Colors.green.shade600]
              : [colorScheme.primary, colorScheme.primary.withValues(alpha: 0.7)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          // 圆环
          SizedBox(
            width: 160,
            height: 160,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 背景环
                SizedBox(
                  width: 160,
                  height: 160,
                  child: CircularProgressIndicator(
                    value: 1.0,
                    strokeWidth: 10,
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
                // 进度环
                SizedBox(
                  width: 160,
                  height: 160,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 10,
                    color: Colors.white,
                    backgroundColor: Colors.transparent,
                    strokeCap: StrokeCap.round,
                  ),
                ),
                // 中心内容
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isCheckedIn ? Icons.check_circle : Icons.local_fire_department,
                      color: Colors.white,
                      size: 36,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isCheckedIn ? '已打卡' : '${remainingMin}分钟',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isCheckedIn ? '今日目标已完成' : '距离打卡还差',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // 今日时长
          Text(
            '今日学习 ${StatsRepo.formatDuration(_todaySeconds)}',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// 连续打卡统计卡片
  Widget _buildStreakCards(ColorScheme colorScheme, bool isCheckedIn) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.local_fire_department,
            label: '连续打卡',
            value: '$_checkInStreak天',
            color: isCheckedIn ? Colors.green : Colors.orange,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            icon: Icons.emoji_events_outlined,
            label: '最长打卡',
            value: '$_maxCheckInStreak天',
            color: Colors.amber,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            icon: Icons.check_circle_outline,
            label: '累计打卡',
            value: '$_checkInDays天',
            color: Colors.teal,
          ),
        ),
      ],
    );
  }

  /// GitHub风格打卡热力图(近12周)
  Widget _buildCheckInHeatmap(ColorScheme colorScheme) {
    final weekdays = ['', '一', '', '三', '', '五', ''];
    final monthLabels = _getMonthLabels(_calendar);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_month_outlined,
                    size: 18, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  '打卡记录 (近12周)',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '每天学习满60分钟自动打卡',
              style: TextStyle(fontSize: 11, color: colorScheme.outline),
            ),
            const SizedBox(height: 16),
            // 热力图主体
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              reverse: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 月份标签
                  Row(
                    children: [
                      const SizedBox(width: 24),
                      ...monthLabels.map((m) => SizedBox(
                        width: 14 * 4 + 3 * 4,
                        child: Text(m, style: TextStyle(fontSize: 9, color: colorScheme.outline)),
                      )),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // 日历网格
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 星期标签
                      Column(
                        children: weekdays.map((w) => SizedBox(
                          height: 14,
                          width: 20,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text(w, style: TextStyle(fontSize: 9, color: colorScheme.outline)),
                          ),
                        )).toList(),
                      ),
                      const SizedBox(width: 4),
                      // 周列
                      ..._calendar.map((week) => Column(
                        children: week.map((day) => _buildHeatmapCell(colorScheme, day)).toList(),
                      )),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // 图例
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('少', style: TextStyle(fontSize: 10, color: colorScheme.outline)),
                const SizedBox(width: 4),
                _buildLegendCell(colorScheme, 0),
                const SizedBox(width: 2),
                _buildLegendCell(colorScheme, 1),
                const SizedBox(width: 2),
                _buildLegendCell(colorScheme, 2),
                const SizedBox(width: 2),
                _buildLegendCell(colorScheme, 3),
                const SizedBox(width: 4),
                Text('多', style: TextStyle(fontSize: 10, color: colorScheme.outline)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeatmapCell(ColorScheme colorScheme, CalendarDay day) {
    Color cellColor;
    if (day.isFuture) {
      cellColor = Colors.transparent;
    } else if (day.seconds == 0) {
      cellColor = colorScheme.surfaceContainerHighest.withValues(alpha: 0.5);
    } else if (day.seconds >= StatsRepo.dailyGoalSeconds) {
      cellColor = Colors.green;
    } else {
      final ratio = day.seconds / StatsRepo.dailyGoalSeconds;
      if (ratio >= 0.75) {
        cellColor = Colors.green.withValues(alpha: 0.75);
      } else if (ratio >= 0.5) {
        cellColor = Colors.green.withValues(alpha: 0.5);
      } else if (ratio >= 0.25) {
        cellColor = Colors.green.withValues(alpha: 0.3);
      } else {
        cellColor = Colors.green.withValues(alpha: 0.15);
      }
    }

    return Container(
      width: 14,
      height: 14,
      margin: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: cellColor,
        borderRadius: BorderRadius.circular(2),
        border: day.isToday
            ? Border.all(color: colorScheme.primary, width: 1.5)
            : null,
      ),
    );
  }

  Widget _buildLegendCell(ColorScheme colorScheme, int level) {
    Color color;
    switch (level) {
      case 0:
        color = colorScheme.surfaceContainerHighest.withValues(alpha: 0.5);
        break;
      case 1:
        color = Colors.green.withValues(alpha: 0.3);
        break;
      case 2:
        color = Colors.green.withValues(alpha: 0.6);
        break;
      case 3:
        color = Colors.green;
        break;
      default:
        color = Colors.grey;
    }
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  List<String> _getMonthLabels(List<List<CalendarDay>> calendar) {
    final labels = <String>[];
    int? lastMonth;
    for (final week in calendar) {
      final firstDay = week.first;
      if (firstDay.date.month != lastMonth) {
        labels.add('${firstDay.date.month}月');
        lastMonth = firstDay.date.month;
      } else {
        labels.add('');
      }
    }
    return labels;
  }

  // ======================== 周报 ========================
  Widget _buildWeeklyView(ColorScheme colorScheme) {
    final report = _weeklyReport!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildPeriodSummary(
          colorScheme,
          title: '本周学习概览',
          subtitle: '近7天学习数据汇总',
          totalSeconds: report.totalSeconds,
          studyDays: report.studyDays,
          videoCount: report.videoCount,
          averageDailySeconds: report.averageDailySeconds,
          maxDaySeconds: report.maxDaySeconds,
          maxDayDate: report.maxDayDate,
        ),
        const SizedBox(height: 16),
        _buildChartCard(
          colorScheme,
          report.dailyData,
          '近7天学习时长',
          is30Days: false,
        ),
        const SizedBox(height: 16),
        // 打卡达标线说明
        _buildCheckInLineCard(colorScheme, report.dailyData),
        const SizedBox(height: 16),
        _buildSectionTitle(
          colorScheme,
          icon: Icons.history,
          title: '本周观看记录 (${report.videoCount})',
        ),
        const SizedBox(height: 8),
        if (report.recordsByDate.isEmpty)
          _buildEmptyHint('本周还没有学习记录')
        else
          ...report.recordsByDate.map((group) =>
              _buildDateGroupedRecords(colorScheme, group, maxItems: 15)),
      ],
    );
  }

  // ======================== 月报 ========================
  Widget _buildMonthlyView(ColorScheme colorScheme) {
    final report = _monthlyReport!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildPeriodSummary(
          colorScheme,
          title: '本月学习概览',
          subtitle: '近30天学习数据汇总',
          totalSeconds: report.totalSeconds,
          studyDays: report.studyDays,
          videoCount: report.videoCount,
          averageDailySeconds: report.averageDailySeconds,
          maxDaySeconds: report.maxDaySeconds,
          maxDayDate: report.maxDayDate,
        ),
        const SizedBox(height: 16),
        _buildChartCard(
          colorScheme,
          report.dailyData,
          '近30天学习时长',
          is30Days: true,
        ),
        const SizedBox(height: 16),
        _buildCheckInLineCard(colorScheme, report.dailyData),
        const SizedBox(height: 16),
        _buildSectionTitle(
          colorScheme,
          icon: Icons.history,
          title: '本月观看记录 (${report.videoCount})',
        ),
        const SizedBox(height: 8),
        if (report.recordsByDate.isEmpty)
          _buildEmptyHint('本月还没有学习记录')
        else
          ...report.recordsByDate.map((group) =>
              _buildDateGroupedRecords(colorScheme, group, maxItems: 10)),
      ],
    );
  }

  /// 柱状图中标注打卡达标线(60分钟)
  Widget _buildCheckInLineCard(
    ColorScheme colorScheme,
    List<({DateTime date, int seconds})> data,
  ) {
    int checkedDays = 0;
    for (final d in data) {
      if (d.seconds >= StatsRepo.dailyGoalSeconds) checkedDays++;
    }
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(Icons.task_alt, color: Colors.green, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '打卡达标 $checkedDays/${data.length} 天',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '每日学习满60分钟即为打卡成功',
                    style: TextStyle(fontSize: 11, color: colorScheme.outline),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ======================== 组件 ========================

  Widget _buildSummaryCards(
    ColorScheme colorScheme, {
    required int todaySeconds,
    required int videoCount,
  }) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.access_time,
            label: '今日学习',
            value: StatsRepo.formatDuration(todaySeconds),
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            icon: Icons.calendar_today_outlined,
            label: '累计天数',
            value: '$_studyDays天',
            color: Colors.orange,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            icon: Icons.play_circle_outline,
            label: '今日视频',
            value: '$videoCount个',
            color: Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodSummary(
    ColorScheme colorScheme, {
    required String title,
    required String subtitle,
    required int totalSeconds,
    required int studyDays,
    required int videoCount,
    required int averageDailySeconds,
    required int maxDaySeconds,
    DateTime? maxDayDate,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(subtitle, style: TextStyle(fontSize: 12, color: colorScheme.outline)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _SummaryItem(label: '学习时长', value: StatsRepo.formatDuration(totalSeconds), color: colorScheme.primary)),
                Expanded(child: _SummaryItem(label: '学习天数', value: '$studyDays天', color: Colors.orange)),
                Expanded(child: _SummaryItem(label: '观看视频', value: '$videoCount个', color: Colors.green)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _SummaryItem(label: '日均时长', value: StatsRepo.formatDuration(averageDailySeconds), color: Colors.teal)),
                if (maxDayDate != null && maxDaySeconds > 0) ...[
                  Expanded(child: _SummaryItem(
                    label: '最高单日',
                    value: '${StatsRepo.formatDateShort(maxDayDate)} ${StatsRepo.formatDurationShort(maxDaySeconds)}',
                    color: Colors.purple,
                  )),
                ] else
                  Expanded(child: _SummaryItem(label: '最高单日', value: '暂无', color: Colors.purple)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard(
    ColorScheme colorScheme,
    List<({DateTime date, int seconds})> data,
    String title, {
    required bool is30Days,
  }) {
    if (data.isEmpty) return const Card(child: ListTile(title: Text('暂无数据')));

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final displayData = data.where((d) => !d.date.isAfter(today)).toList();
    if (displayData.isEmpty) return const Card(child: ListTile(title: Text('暂无数据')));

    final maxSeconds = displayData.fold<int>(0, (prev, e) => e.seconds > prev ? e.seconds : prev);
    final maxY = ((maxSeconds / 3600).ceil().clamp(1, 999)) * 3600.0;
    // 打卡线 = 60分钟 = 3600秒
    final checkInLineY = StatsRepo.dailyGoalSeconds.toDouble();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 8, height: 8, decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(2))),
                      const SizedBox(width: 4),
                      Text('打卡线 60min', style: TextStyle(fontSize: 10, color: Colors.green.shade700)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  maxY: maxY,
                  minY: 0,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxY / 4,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                      strokeWidth: 1,
                    ),
                  ),
                  extraLinesData: ExtraLinesData(
                    horizontalLines: [
                      HorizontalLine(
                        y: checkInLineY,
                        color: Colors.green.withValues(alpha: 0.6),
                        strokeWidth: 1.5,
                        dashArray: [4, 4],
                      ),
                    ],
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 36,
                        interval: maxY / 4,
                        getTitlesWidget: (value, meta) {
                          final hours = (value / 3600).toStringAsFixed(0);
                          return SideTitleWidget(
                            meta: meta,
                            child: Text('${hours}h', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        interval: is30Days ? 5 : 1,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= displayData.length) return const SizedBox.shrink();
                          if (is30Days && idx % 5 != 0) return const SizedBox.shrink();
                          final d = displayData[idx].date;
                          return SideTitleWidget(
                            meta: meta,
                            child: Text('${d.month}/${d.day}', style: const TextStyle(fontSize: 9, color: Colors.grey)),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: displayData.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final seconds = entry.value.seconds;
                    final isToday = _isSameDay(entry.value.date, today);
                    final isChecked = seconds >= StatsRepo.dailyGoalSeconds;
                    return BarChartGroupData(
                      x: idx,
                      barRods: [
                        BarChartRodData(
                          toY: seconds.toDouble(),
                          color: isChecked
                              ? Colors.green
                              : (isToday ? colorScheme.primary : colorScheme.primary.withValues(alpha: 0.4)),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                          width: is30Days ? 6 : 16,
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateGroupedRecords(
    ColorScheme colorScheme,
    DateGroupedRecords group, {
    int maxItems = 15,
  }) {
    final isToday = _isSameDay(group.date, DateTime.now());
    final isChecked = group.totalSeconds >= StatsRepo.dailyGoalSeconds;
    final dateLabel = isToday
        ? '今天'
        : '${group.date.month}/${group.date.day} ${StatsRepo.weekdayChinese(group.date)}';
    final displayRecords = group.records.take(maxItems).toList();
    final remaining = group.records.length - displayRecords.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 6),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isChecked
                      ? Colors.green.withValues(alpha: 0.15)
                      : (isToday ? colorScheme.primary.withValues(alpha: 0.15) : colorScheme.surfaceContainerHighest),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isChecked ? Icons.check_circle : (isToday ? Icons.today : Icons.calendar_today_outlined),
                      size: 14,
                      color: isChecked ? Colors.green : (isToday ? colorScheme.primary : colorScheme.outline),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      dateLabel,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isChecked ? Colors.green : (isToday ? colorScheme.primary : colorScheme.onSurfaceVariant),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      StatsRepo.formatDurationShort(group.totalSeconds),
                      style: TextStyle(fontSize: 11, color: colorScheme.outline),
                    ),
                    if (isChecked) ...[
                      const SizedBox(width: 6),
                      Text('已打卡', style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.w600)),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        ...displayRecords.map((r) => _buildVideoRecordTile(colorScheme, r)),
        if (remaining > 0)
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 4),
            child: Text('还有 $remaining 条记录...', style: TextStyle(fontSize: 11, color: colorScheme.outline)),
          ),
      ],
    );
  }

  Widget _buildSectionTitle(
    ColorScheme colorScheme, {
    required IconData icon,
    required String title,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: colorScheme.primary),
        const SizedBox(width: 8),
        Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
      ],
    );
  }

  Widget _buildVideoRecordTile(ColorScheme colorScheme, VideoWatchRecord record) {
    final timeStr = _formatTime(record.watchedAt);
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: record.bvid != null && record.bvid!.isNotEmpty
            ? () => _navigateToVideo(record.bvid!)
            : null,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  width: 64,
                  height: 40,
                  child: record.cover != null && record.cover!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: record.cover!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(color: colorScheme.surfaceContainerHighest),
                          errorBuilder: (_, __, ___) => Container(
                            color: colorScheme.surfaceContainerHighest,
                            child: Icon(Icons.image_not_supported_outlined, size: 20, color: colorScheme.outline),
                          ),
                          httpHeaders: const {'referer': 'https://www.bilibili.com'},
                        )
                      : Container(
                          color: colorScheme.surfaceContainerHighest,
                          child: Icon(Icons.play_circle_outline, size: 20, color: colorScheme.outline),
                        ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(record.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (record.upName.isNotEmpty) ...[
                          Icon(Icons.account_circle_outlined, size: 12, color: colorScheme.outline),
                          const SizedBox(width: 2),
                          Expanded(child: Text(record.upName, maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 11, color: colorScheme.outline))),
                        ] else
                          Expanded(child: Container()),
                        Text(timeStr, style: TextStyle(fontSize: 10, color: colorScheme.outline)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(StatsRepo.formatDurationShort(record.seconds),
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: colorScheme.onPrimaryContainer)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToVideo(String bvid) {
    try {
      Get.toNamed('/video?bvid=$bvid');
    } catch (_) {}
  }

  Widget _buildEmptyHint(String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            Icon(Icons.inbox_outlined, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(text, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final watchDay = DateTime(dt.year, dt.month, dt.day);
    final timeStr = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    if (watchDay == today) return timeStr;
    return '${dt.month}/${dt.day} $timeStr';
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

// ======================== 小组件 ========================

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(value, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
            const SizedBox(height: 2),
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryItem({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, maxLines: 1, overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}
