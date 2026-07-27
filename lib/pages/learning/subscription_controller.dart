// [PiliPlus Learning] 专注订阅控制器(GetX)
// 管理白名单 UP 主与聚合视频流的数据流
import 'package:get/get.dart';

import 'feed_aggregator.dart';
import 'white_list_repo.dart';

class SubscriptionController extends GetxController {
  /// 聚合后的视频流(按 pubdate 倒序)
  final RxList<FeedItem> feedList = <FeedItem>[].obs;

  /// 白名单 UP 主信息列表
  final RxList<UpInfo> whiteList = <UpInfo>[].obs;

  /// 加载状态
  final RxBool isLoading = false.obs;

  /// 错误信息(空字符串表示无错误)
  final RxString errMsg = ''.obs;

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

  /// 刷新聚合视频流(下拉刷新调用)
  Future<void> refreshFeed() async {
    if (whiteList.isEmpty) {
      feedList.clear();
      errMsg.value = '请先添加关注的 UP 主';
      return;
    }
    isLoading.value = true;
    errMsg.value = '';
    try {
      final uids = whiteList.map((e) => e.mid).toList();
      final list = await FeedAggregator.fetch(uids);
      feedList.value = list;
      if (list.isEmpty) {
        errMsg.value = '暂无视频,请检查白名单或网络';
      }
    } catch (e) {
      errMsg.value = '加载失败: $e';
      feedList.clear();
    } finally {
      isLoading.value = false;
    }
  }
}
