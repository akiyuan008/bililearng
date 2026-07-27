// [PiliPlus Learning] 学习推荐控制器
// 调用 B站排行榜 API 获取知识区(rid=36)和科技区(rid=188)的热门视频,
// 经学习过滤算法过滤后存入视频池,按每页8个分页展示。
// 下拉刷新: 从视频池中随机抽取新的8个视频(可撤回上一次刷新)。
// 底部按钮: 上一页/下一页 用于按顺序浏览视频池。
import 'dart:math';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/http/video.dart';
import 'package:PiliPlus/models/model_hot_video_item.dart';
import 'package:get/get.dart';

import 'learning_filter.dart';

class RecommendController extends GetxController {
  /// 当前页显示的视频列表(每页8个)
  final RxList<HotVideoItemModel> currentPage = <HotVideoItemModel>[].obs;

  /// 加载状态
  final RxBool isLoading = false.obs;

  /// 错误信息
  final RxString errMsg = ''.obs;

  /// 当前页码(从1开始,用于顺序浏览)
  final RxInt pageIndex = 1.obs;

  /// 总页数(用于顺序浏览)
  final RxInt totalPages = 1.obs;

  /// 是否可以撤回刷新
  final RxBool canUndo = false.obs;

  /// 刷新次数(用户刷新了多少次换一批)
  final RxInt refreshCount = 0.obs;

  /// 每页视频数量
  static const int pageSize = 8;

  /// 视频池(过滤+去重后的完整列表)
  List<HotVideoItemModel> _videoPool = [];

  /// 刷新历史栈(用于撤回"换一批"操作)
  /// 每次刷新前将当前页存入历史,撤回时弹出恢复
  final List<List<HotVideoItemModel>> _refreshHistory = [];

  /// 顺序浏览模式的历史页索引(用于区分刷新和翻页)
  int _lastPageIndex = 1;

  /// 学习类分区 rid
  static const int _knowledgeRid = 36; // 知识区
  static const int _techRid = 188; // 科技区

  @override
  void onInit() {
    super.onInit();
    refreshRecommend();
  }

  /// 重新拉取数据(从API获取,重置一切)
  Future<void> refreshRecommend() async {
    isLoading.value = true;
    errMsg.value = '';
    try {
      final results = await Future.wait([
        VideoHttp.getRankVideoList(_knowledgeRid),
        VideoHttp.getRankVideoList(_techRid),
      ]);

      final all = <HotVideoItemModel>[];
      for (final result in results) {
        if (result case Success(:final response)) {
          all.addAll(response);
        }
      }

      // 学习视频过滤
      final filtered = LearningFilter.filterList(all);

      // 去重
      final seen = <String>{};
      final deduped = <HotVideoItemModel>[];
      for (final v in filtered) {
        final key = v.bvid ?? v.aid.toString();
        if (key != null && seen.add(key)) {
          deduped.add(v);
        }
      }

      // 随机打乱顺序
      deduped.shuffle(Random());

      _videoPool = deduped;
      totalPages.value =
          (_videoPool.length / pageSize).ceil().clamp(1, 999999);
      pageIndex.value = 1;
      _lastPageIndex = 1;
      refreshCount.value = 0;
      _refreshHistory.clear();
      canUndo.value = false;
      _updateCurrentPage();

      if (deduped.isEmpty) {
        errMsg.value = '暂无学习推荐视频';
      }
    } catch (e) {
      errMsg.value = '加载失败: $e';
      currentPage.clear();
    } finally {
      isLoading.value = false;
    }
  }

  /// 下拉刷新: 从视频池中随机抽取新的8个视频(换一批)
  /// 将当前页存入历史栈,支持撤回
  Future<void> shuffleRefresh() async {
    if (_videoPool.isEmpty) {
      await refreshRecommend();
      return;
    }

    // 保存当前页到历史栈
    if (currentPage.isNotEmpty) {
      _refreshHistory.add(List.from(currentPage));
      // 最多保留 10 次历史
      if (_refreshHistory.length > 10) {
        _refreshHistory.removeAt(0);
      }
      canUndo.value = true;
    }

    // 随机抽取8个不重复的视频(与当前页不重复)
    final currentBvids = currentPage
        .map((v) => v.bvid ?? v.aid.toString())
        .toSet();
    final available = _videoPool
        .where((v) => !currentBvids.contains(v.bvid ?? v.aid.toString()))
        .toList();

    List<HotVideoItemModel> newPage;
    if (available.length >= pageSize) {
      available.shuffle(Random());
      newPage = available.take(pageSize).toList();
    } else if (_videoPool.length >= pageSize) {
      // 可用不够8个但池子够,直接从全池随机
      _videoPool.shuffle(Random());
      newPage = _videoPool.take(pageSize).toList();
    } else {
      // 池子不够8个,全部展示
      newPage = List.from(_videoPool)..shuffle(Random());
    }

    currentPage.value = newPage;
    refreshCount.value++;
    // 刷新后页码模式不适用,重置
    pageIndex.value = 1;
    _lastPageIndex = 1;
  }

  /// 撤回上一次"换一批"刷新
  void undoRefresh() {
    if (_refreshHistory.isEmpty) return;
    final lastPage = _refreshHistory.removeLast();
    currentPage.value = lastPage;
    refreshCount.value = refreshCount.value > 0 ? refreshCount.value - 1 : 0;
    canUndo.value = _refreshHistory.isNotEmpty;
    // 恢复页码状态
    pageIndex.value = _lastPageIndex;
  }

  /// 下一页(顺序浏览视频池)
  Future<void> nextPage() async {
    if (_videoPool.isEmpty) return;
    if (pageIndex.value < totalPages.value) {
      // 保存当前状态到历史(如果是顺序浏览模式)
      if (refreshCount.value == 0) {
        _refreshHistory.add(List.from(currentPage));
        if (_refreshHistory.length > 10) {
          _refreshHistory.removeAt(0);
        }
        canUndo.value = true;
      }
      _lastPageIndex = pageIndex.value;
      pageIndex.value++;
      _updateCurrentPage();
    } else {
      // 已到最后一页,换一批
      await shuffleRefresh();
    }
  }

  /// 上一页(顺序浏览视频池)
  void prevPage() {
    if (_videoPool.isEmpty) return;
    if (pageIndex.value > 1) {
      _lastPageIndex = pageIndex.value;
      pageIndex.value--;
      _updateCurrentPage();
    }
  }

  /// 是否可以返回上一页
  bool get canPrev => pageIndex.value > 1 && refreshCount.value == 0;

  /// 更新当前页数据(顺序浏览模式)
  void _updateCurrentPage() {
    final start = (pageIndex.value - 1) * pageSize;
    final end = min(start + pageSize, _videoPool.length);
    if (start < _videoPool.length) {
      currentPage.value = _videoPool.sublist(start, end);
    } else {
      currentPage.clear();
    }
  }

  /// 视频池大小
  int get poolSize => _videoPool.length;
}
