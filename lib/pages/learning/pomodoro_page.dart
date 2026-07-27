// [PiliPlus Learning] 番茄钟页面
// 专注学习倒计时工具,支持 25/15/5 分钟预设和自定义时长。
// 完成专注后自动记录学习时长到统计系统。
// 采用极简设计:大号倒计时圆环 + 开始/暂停/重置按钮。
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'stats_repo.dart';

class PomodoroPage extends StatefulWidget {
  const PomodoroPage({super.key});

  @override
  State<PomodoroPage> createState() => _PomodoroPageState();
}

class _PomodoroPageState extends State<PomodoroPage>
    with SingleTickerProviderStateMixin {
  /// 预设时长(分钟)
  static const List<int> _presetMinutes = [25, 15, 5, 10];

  /// 选中的时长(秒)
  int _selectedSeconds = 25 * 60;

  /// 剩余秒数
  int _remainingSeconds = 25 * 60;

  /// 是否正在运行
  bool _isRunning = false;

  /// 是否已暂停
  bool _isPaused = false;

  /// 已完成的番茄钟数量
  int _completedCount = 0;

  /// 计时器
  Timer? _timer;

  /// 动画控制器(用于圆环进度)
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: Duration(seconds: _selectedSeconds),
    );
    _loadCompletedCount();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  void _loadCompletedCount() async {
    await StatsRepo.ensureInit();
    final today = DateTime.now();
    final seconds = StatsRepo.getSeconds(today);
    setState(() {
      _completedCount = seconds ~/ (25 * 60);
    });
  }

  /// 格式化时间 mm:ss
  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  /// 选择时长
  void _selectDuration(int minutes) {
    if (_isRunning) return;
    setState(() {
      _selectedSeconds = minutes * 60;
      _remainingSeconds = minutes * 60;
      _animController.duration = Duration(seconds: minutes * 60);
    });
  }

  /// 开始/暂停
  void _toggleTimer() {
    if (_isRunning) {
      _pauseTimer();
    } else {
      _startTimer();
    }
  }

  void _startTimer() {
    setState(() {
      _isRunning = true;
      _isPaused = false;
    });

    if (!_isPaused) {
      _animController.forward(from: 1.0 - (_remainingSeconds / _selectedSeconds));
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _onComplete();
        }
      });
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    _animController.stop();
    setState(() {
      _isRunning = false;
      _isPaused = true;
    });
  }

  /// 重置
  void _resetTimer() {
    _timer?.cancel();
    _animController.reset();
    setState(() {
      _isRunning = false;
      _isPaused = false;
      _remainingSeconds = _selectedSeconds;
    });
  }

  /// 完成
  void _onComplete() async {
    _timer?.cancel();
    _animController.stop();
    _animController.value = 1.0;

    // 记录学习时长到统计系统
    await StatsRepo.ensureInit();
    await StatsRepo.addSeconds(DateTime.now(), _selectedSeconds);

    setState(() {
      _isRunning = false;
      _isPaused = false;
      _remainingSeconds = _selectedSeconds;
      _completedCount++;
    });

    // 显示完成提示
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('专注完成!已学习 ${_selectedSeconds ~/ 60} 分钟'),
          duration: const Duration(seconds: 3),
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        ),
      );
    }

    _animController.reset();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final progress = 1.0 - (_remainingSeconds / _selectedSeconds);

    return Scaffold(
      appBar: AppBar(
        title: const Text('番茄钟'),
        actions: [
          IconButton(
            tooltip: '学习统计',
            icon: const Icon(Icons.bar_chart),
            onPressed: () => Get.toNamed('/stats'),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 完成次数
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.local_fire_department,
                      size: 18,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '今日已完成 $_completedCount 个番茄钟',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // 倒计时圆环
              SizedBox(
                width: 240,
                height: 240,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // 背景圆环
                    SizedBox(
                      width: 240,
                      height: 240,
                      child: CircularProgressIndicator(
                        value: 1.0,
                        strokeWidth: 8,
                        color:
                            colorScheme.surfaceContainerHighest,
                      ),
                    ),
                    // 进度圆环
                    SizedBox(
                      width: 240,
                      height: 240,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 8,
                        color: _isRunning
                            ? colorScheme.primary
                            : colorScheme.outline,
                        backgroundColor: Colors.transparent,
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    // 时间显示
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatTime(_remainingSeconds),
                          style: TextStyle(
                            fontSize: 56,
                            fontWeight: FontWeight.w200,
                            color: colorScheme.onSurface,
                            fontFeatures: const [
                              FontFeature.tabularFigures()
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isRunning
                              ? '专注中...'
                              : (_isPaused ? '已暂停' : '准备开始'),
                          style: TextStyle(
                            fontSize: 14,
                            color: colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // 控制按钮
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 重置
                  IconButton.filledTonal(
                    onPressed: _isRunning || _isPaused
                        ? _resetTimer
                        : null,
                    icon: const Icon(Icons.refresh, size: 28),
                    iconSize: 28,
                  ),
                  const SizedBox(width: 24),
                  // 开始/暂停
                  FilledButton(
                    onPressed: _toggleTimer,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(80, 80),
                      shape: const CircleBorder(),
                    ),
                    child: Icon(
                      _isRunning
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      size: 36,
                    ),
                  ),
                  const SizedBox(width: 24),
                  // 跳过
                  IconButton.filledTonal(
                    onPressed: _isRunning || _isPaused
                        ? _onComplete
                        : null,
                    icon: const Icon(Icons.skip_next, size: 28),
                    iconSize: 28,
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // 时长选择
              if (!_isRunning && !_isPaused) ...[
                Text(
                  '选择专注时长',
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.outline,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: _presetMinutes.map((minutes) {
                    final isSelected =
                        _selectedSeconds == minutes * 60;
                    return ChoiceChip(
                      label: Text('$minutes 分钟'),
                      selected: isSelected,
                      onSelected: (_) => _selectDuration(minutes),
                      selectedColor: colorScheme.primaryContainer,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSurfaceVariant,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    );
                  }).toList(),
                ),
              ],

              const SizedBox(height: 32),

              // 提示文字
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          size: 18,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '使用建议',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '25分钟专注 + 5分钟休息 = 1个番茄钟\n'
                      '保持专注,远离手机,高效学习\n'
                      '完成的专注时长会自动记录到学习统计',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.6,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
