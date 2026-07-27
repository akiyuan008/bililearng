// [PiliPlus Learning] 学习统计页面
// 展示学习时长统计: 总计/今日/学习天数 + 近7天/30天柱状图
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'stats_repo.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  List<({DateTime date, int seconds})> _recent7 = [];
  List<({DateTime date, int seconds})> _recent30 = [];
  int _totalSeconds = 0;
  int _todaySeconds = 0;
  int _studyDays = 0;
  bool _show30Days = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    await StatsRepo.ensureInit();
    setState(() {
      _recent7 = StatsRepo.getRecentDays(7);
      _recent30 = StatsRepo.getRecentDays(30);
      _totalSeconds = StatsRepo.getTotalSeconds();
      _todaySeconds = StatsRepo.getTodaySeconds();
      _studyDays = StatsRepo.getStudyDays();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final data = _show30Days ? _recent30 : _recent7;

    return Scaffold(
      appBar: AppBar(
        title: const Text('学习统计'),
        actions: [
          IconButton(
            tooltip: _show30Days ? '近7天' : '近30天',
            icon: Icon(
              _show30Days ? Icons.calendar_view_week : Icons.calendar_view_month,
            ),
            onPressed: () => setState(() => _show30Days = !_show30Days),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 顶部统计卡片
          _buildStatsCards(colorScheme),
          const SizedBox(height: 24),
          // 柱状图
          _buildChartCard(context, colorScheme, data),
          const SizedBox(height: 16),
          // 详细列表
          _buildDetailList(colorScheme, data),
        ],
      ),
    );
  }

  Widget _buildStatsCards(ColorScheme colorScheme) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.access_time,
            label: '今日学习',
            value: StatsRepo.formatDuration(_todaySeconds),
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.bar_chart,
            label: '总学习时长',
            value: StatsRepo.formatDuration(_totalSeconds),
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.local_fire_department,
            label: '学习天数',
            value: '$_studyDays天',
            color: Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildChartCard(
    BuildContext context,
    ColorScheme colorScheme,
    List<({DateTime date, int seconds})> data,
  ) {
    if (data.isEmpty) {
      return const Card(child: ListTile(title: Text('暂无数据')));
    }

    final maxSeconds = data.fold<int>(
      0,
      (prev, e) => e.seconds > prev ? e.seconds : prev,
    );
    // Y轴最大值: 至少 3600(1小时),避免全为0时图表空白
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
              _show30Days ? '近30天学习时长' : '近7天学习时长',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
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
                        reservedSize: 40,
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
                        interval: _show30Days ? 5 : 1,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= data.length) {
                            return const SizedBox.shrink();
                          }
                          // 30天模式每5天显示一个标签
                          if (_show30Days && idx % 5 != 0) {
                            return const SizedBox.shrink();
                          }
                          final d = data[idx].date;
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
                  barGroups: data.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final seconds = entry.value.seconds;
                    return BarChartGroupData(
                      x: idx,
                      barRods: [
                        BarChartRodData(
                          toY: seconds.toDouble(),
                          color: colorScheme.primary.withValues(alpha: 0.8),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                          width: _show30Days ? 6 : 16,
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

  Widget _buildDetailList(
    ColorScheme colorScheme,
    List<({DateTime date, int seconds})> data,
  ) {
    // 倒序显示(最近在前)
    final reversed = data.reversed.toList();
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(Icons.history, size: 18, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  '每日记录',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...reversed.map((item) {
            final isToday = _isSameDay(item.date, DateTime.now());
            return ListTile(
              dense: true,
              leading: Icon(
                isToday ? Icons.today : Icons.calendar_today_outlined,
                size: 20,
                color: isToday ? colorScheme.primary : Colors.grey,
              ),
              title: Text(
                isToday
                    ? '今天'
                    : '${item.date.month}月${item.date.day}日',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Text(
                StatsRepo.formatDuration(item.seconds),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: item.seconds > 0
                      ? colorScheme.primary
                      : Colors.grey,
                  fontWeight: item.seconds > 0
                      ? FontWeight.w500
                      : FontWeight.normal,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
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
        side: BorderSide(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
