// [PiliPlus Learning] 学习统计页面
// 日报/周报/月报三种视图,展示学习时长柱状图和视频观看明细。
// 顶部总览展示累计数据(总时长/连续天数/学习天数/视频数),
// 每个报表含汇总卡片、柱状图、按日期分组的视频观看记录。
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
  int _studyStreak = 0;
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
      _studyStreak = StatsRepo.getStudyStreak();
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
            Tab(text: '日报'),
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
                _buildDailyView(colorScheme),
                _buildWeeklyView(colorScheme),
                _buildMonthlyView(colorScheme),
              ],
            ),
    );
  }

  // ======================== 日报 ========================
  Widget _buildDailyView(ColorScheme colorScheme) {
    final report = _dailyReport!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 总览头部
        _buildOverviewHeader(colorScheme),
        const SizedBox(height: 16),
        // 今日数据卡片
        _buildSummaryCards(
          colorScheme,
          todaySeconds: report.totalSeconds,
          studyStreak: report.studyStreak,
          videoCount: report.videoCount,
        ),
        const SizedBox(height: 16),
        // 今日视频观看明细
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

  // ======================== 周报 ========================
  Widget _buildWeeklyView(ColorScheme colorScheme) {
    final report = _weeklyReport!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 周报汇总
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
        // 柱状图
        _buildChartCard(
          colorScheme,
          report.dailyData,
          '近7天学习时长',
          is30Days: false,
        ),
        const SizedBox(height: 16),
        // 按日期分组的视频记录
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
        // 月报汇总
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
        // 柱状图
        _buildChartCard(
          colorScheme,
          report.dailyData,
          '近30天学习时长',
          is30Days: true,
        ),
        const SizedBox(height: 16),
        // 按日期分组的视频记录
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

  // ======================== 总览头部 ========================
  Widget _buildOverviewHeader(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary,
            colorScheme.primary.withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.local_fire_department,
                color: Colors.white.withValues(alpha: 0.9),
                size: 28,
              ),
              const SizedBox(width: 8),
              Text(
                '$_studyStreak',
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                '天连续学习',
                style: TextStyle(fontSize: 14, color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _OverviewItem(
                  icon: Icons.access_time,
                  label: '总学习时长',
                  value: StatsRepo.formatDuration(_totalSeconds),
                ),
              ),
              Expanded(
                child: _OverviewItem(
                  icon: Icons.calendar_today_outlined,
                  label: '学习天数',
                  value: '$_studyDays天',
                ),
              ),
              Expanded(
                child: _OverviewItem(
                  icon: Icons.play_circle_outline,
                  label: '观看视频',
                  value: '$_totalVideos个',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ======================== 组件 ========================

  Widget _buildSummaryCards(
    ColorScheme colorScheme, {
    required int todaySeconds,
    required int studyStreak,
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
            icon: Icons.local_fire_department,
            label: '连续天数',
            value: '$studyStreak天',
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
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: colorScheme.outline),
            ),
            const SizedBox(height: 16),
            // 主要数据行
            Row(
              children: [
                Expanded(
                  child: _SummaryItem(
                    label: '学习时长',
                    value: StatsRepo.formatDuration(totalSeconds),
                    color: colorScheme.primary,
                  ),
                ),
                Expanded(
                  child: _SummaryItem(
                    label: '学习天数',
                    value: '$studyDays天',
                    color: Colors.orange,
                  ),
                ),
                Expanded(
                  child: _SummaryItem(
                    label: '观看视频',
                    value: '$videoCount个',
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // 次要数据行
            Row(
              children: [
                Expanded(
                  child: _SummaryItem(
                    label: '日均时长',
                    value: StatsRepo.formatDuration(averageDailySeconds),
                    color: Colors.teal,
                  ),
                ),
                if (maxDayDate != null && maxDaySeconds > 0) ...[
                  Expanded(
                    child: _SummaryItem(
                      label: '最高单日',
                      value:
                          '${StatsRepo.formatDateShort(maxDayDate)} ${StatsRepo.formatDurationShort(maxDaySeconds)}',
                      color: Colors.purple,
                    ),
                  ),
                ] else
                  Expanded(
                    child: _SummaryItem(
                      label: '最高单日',
                      value: '暂无',
                      color: Colors.purple,
                    ),
                  ),
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
    if (data.isEmpty) {
      return const Card(child: ListTile(title: Text('暂无数据')));
    }

    // 过滤掉未来日期(双重保险)
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final displayData = data.where((d) => !d.date.isAfter(today)).toList();
    if (displayData.isEmpty) {
      return const Card(child: ListTile(title: Text('暂无数据')));
    }

    final maxSeconds = displayData.fold<int>(
      0,
      (prev, e) => e.seconds > prev ? e.seconds : prev,
    );
    final maxY = (maxSeconds / 3600).ceil().clamp(1, 999) * 3600.0;

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
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
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
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 36,
                        interval: maxY / 4,
                        getTitlesWidget: (value, meta) {
                          final hours = (value / 3600).toStringAsFixed(0);
                          return SideTitleWidget(
                            meta: meta,
                            child: Text(
                              '${hours}h',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
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
                          if (idx < 0 || idx >= displayData.length) {
                            return const SizedBox.shrink();
                          }
                          if (is30Days && idx % 5 != 0) {
                            return const SizedBox.shrink();
                          }
                          final d = displayData[idx].date;
                          return SideTitleWidget(
                            meta: meta,
                            child: Text(
                              '${d.month}/${d.day}',
                              style: const TextStyle(
                                fontSize: 9,
                                color: Colors.grey,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: displayData.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final seconds = entry.value.seconds;
                    final isToday = _isSameDay(entry.value.date, today);
                    return BarChartGroupData(
                      x: idx,
                      barRods: [
                        BarChartRodData(
                          toY: seconds.toDouble(),
                          color: isToday
                              ? colorScheme.primary
                              : colorScheme.primary.withValues(alpha: 0.5),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
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

  /// 按日期分组的视频记录
  Widget _buildDateGroupedRecords(
    ColorScheme colorScheme,
    DateGroupedRecords group, {
    int maxItems = 15,
  }) {
    final isToday = _isSameDay(group.date, DateTime.now());
    final dateLabel = isToday
        ? '今天'
        : '${group.date.month}/${group.date.day} ${StatsRepo.weekdayChinese(group.date)}';
    final displayRecords = group.records.take(maxItems).toList();
    final remaining = group.records.length - displayRecords.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 日期分组标题
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 6),
          child: Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isToday
                      ? colorScheme.primary.withValues(alpha: 0.15)
                      : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isToday ? Icons.today : Icons.calendar_today_outlined,
                      size: 14,
                      color: isToday
                          ? colorScheme.primary
                          : colorScheme.outline,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      dateLabel,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isToday
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      StatsRepo.formatDurationShort(group.totalSeconds),
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // 视频记录列表
        ...displayRecords
            .map((r) => _buildVideoRecordTile(colorScheme, r)),
        if (remaining > 0)
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 4),
            child: Text(
              '还有 $remaining 条记录...',
              style: TextStyle(fontSize: 11, color: colorScheme.outline),
            ),
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
        Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildVideoRecordTile(
    ColorScheme colorScheme,
    VideoWatchRecord record,
  ) {
    final timeStr = _formatTime(record.watchedAt);
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
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
              // 视频封面缩略图
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  width: 64,
                  height: 40,
                  child: record.cover != null && record.cover!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: record.cover!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                              color: colorScheme.surfaceContainerHighest),
                          errorBuilder: (_, __, ___) => Container(
                            color: colorScheme.surfaceContainerHighest,
                            child: Icon(
                              Icons.image_not_supported_outlined,
                              size: 20,
                              color: colorScheme.outline,
                            ),
                          ),
                          httpHeaders: const {
                            'referer': 'https://www.bilibili.com',
                          },
                        )
                      : Container(
                          color: colorScheme.surfaceContainerHighest,
                          child: Icon(
                            Icons.play_circle_outline,
                            size: 20,
                            color: colorScheme.outline,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 10),
              // 标题和UP主
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (record.upName.isNotEmpty) ...[
                          Icon(
                            Icons.account_circle_outlined,
                            size: 12,
                            color: colorScheme.outline,
                          ),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              record.upName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: colorScheme.outline,
                              ),
                            ),
                          ),
                        ] else
                          Expanded(child: Container()),
                        Text(
                          timeStr,
                          style: TextStyle(
                            fontSize: 10,
                            color: colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // 时长
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  StatsRepo.formatDurationShort(record.seconds),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
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
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final watchDay = DateTime(dt.year, dt.month, dt.day);
    final timeStr =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    if (watchDay == today) return timeStr;
    return '${dt.month}/${dt.day} $timeStr';
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

// ======================== 小组件 ========================

class _OverviewItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _OverviewItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.8), size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 10,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

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
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
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

  const _SummaryItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ],
    );
  }
}
