// [PiliPlus Learning] 专注订阅控制器(GetX)
// 管理白名单 UP 主与聚合视频流的数据流
// 仿推荐页:视频池+分页+换一批+撤回
import 'dart:math';
import 'package:get/get.dart';

import 'feed_aggregator.dart';
import 'white_list_repo.dart';

class SubscriptionController extends GetxController {
  /// 当前页显示的视频列表(每页8个)
  final RxList<FeedItem> currentPage = <FeedItem>[].obs;

  /// 白名单 UP 主信息列表
  final RxList<UpInfo> whiteList = <UpInfo>[].obs;

  /// 加载状态
  final RxBool isLoading = false.obs;

  /// 错误信息(空字符串表示无错误)
  final RxString errMsg = ''.obs;

  /// 当前页码(从1开始,用于顺序浏览)
  final RxInt pageIndex = 1.obs;

  /// 总页数
  final RxInt totalPages = 1.obs;

  /// 是否可以撤回刷新
  final RxBool canUndo = false.obs;

  /// 刷新次数
  final RxInt refreshCount = 0.obs;

  /// 每页视频数量
  static const int pageSize = 8;

  /// 视频池(去重+倒序后的完整列表)
  List<FeedItem> _videoPool = [];

  /// 刷新历史栈(用于撤回)
  final List<List<FeedItem>> _refreshHistory = [];

  /// 顺序浏览模式的历史页索引
  int _lastPageIndex = 1;

  @override
  void onInit() {
    super.onInit();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await WhiteListRepo.ensureInit();
    await loadWhiteList();
    if (whiteList.isNotEmpty) {
      await refreshFeed();
    }
  }

  /// 加载白名单
  Future<void> loadWhiteList() async {
    await WhiteListRepo.ensureInit();
    whiteList.value = WhiteListRepo.getUpList();
  }

  /// 添加白名单 UP 主
  Future<void> addUp(UpInfo up) async {
    if (up.mid.isEmpty) return;
    await WhiteListRepo.addUp(up);
    await loadWhiteList();
  }

  /// 移除白名单 UP 主
  Future<void> removeUp(String mid) async {
    await WhiteListRepo.removeUp(mid);
    await loadWhiteList();
  }

  /// 重新拉取数据(从API获取,重置一切)
  Future<void> refreshFeed() async {
    if (whiteList.isEmpty) {
      currentPage.clear();
      _videoPool = [];
      errMsg.value = '请先添加关注的 UP 主';
      return;
    }
    isLoading.value = true;
    errMsg.value = '';
    try {
      final uids = whiteList.map((e) => e.mid).toList();
      final list = await FeedAggregator.fetch(uids);

      // 去重
      final seen = <String>{};
      final deduped = <FeedItem>[];
      for (final v in list) {
        final key = v.bvid ?? v.aid.toString();
        if (key != null && seen.add(key)) {
          deduped.add(v);
        }
      }

      // 按 pubdate 倒序(FeedAggregator 已排序,去重后保持)
      deduped.sort((a, b) => (b.pubdate ?? 0).compareTo(a.pubdate ?? 0));

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
        errMsg.value = '暂无视频,请检查白名单或网络';
      }
    } catch (e) {
      errMsg.value = '加载失败: $e';
      currentPage.clear();
      _videoPool = [];
    } finally {
      isLoading.value = false;
    }
  }

  /// 下拉刷新: 从视频池中随机抽取新的8个视频(换一批)
  Future<void> shuffleRefresh() async {
    if (_videoPool.isEmpty) {
      await refreshFeed();
      return;
    }

    // 保存当前页到历史栈
    if (currentPage.isNotEmpty) {
      _refreshHistory.add(List.from(currentPage));
      if (_refreshHistory.length > 10) {
        _refreshHistory.removeAt(0);
      }
      canUndo.value = true;
    }

    // 随机抽取8个不重复的视频(与当前页不重复)
    final currentKeys = currentPage
        .map((v) => v.bvid ?? v.aid.toString())
        .toSet();
    final available = _videoPool
        .where((v) => !currentKeys.contains(v.bvid ?? v.aid.toString()))
        .toList();

    List<FeedItem> newPage;
    if (available.length >= pageSize) {
      available.shuffle(Random());
      newPage = available.take(pageSize).toList();
    } else if (_videoPool.length >= pageSize) {
      _videoPool.shuffle(Random());
      newPage = _videoPool.take(pageSize).toList();
    } else {
      newPage = List.from(_videoPool)..shuffle(Random());
    }

    currentPage.value = newPage;
    refreshCount.value++;
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
    pageIndex.value = _lastPageIndex;
  }

  /// 下一页(顺序浏览视频池)
  Future<void> nextPage() async {
    if (_videoPool.isEmpty) return;
    if (pageIndex.value < totalPages.value) {
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

  /// 更新当前页数据
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
