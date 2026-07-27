// [PiliPlus Learning] 学习推荐控制器
// 调用 B站排行榜 API 获取知识区(rid=1010)和科技区(rid=1012)的热门视频,
// 聚合后按播放量倒序排列,确保只展示学习类内容。
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/http/video.dart';
import 'package:PiliPlus/models/model_hot_video_item.dart';
import 'package:get/get.dart';

class RecommendController extends GetxController {
  /// 推荐视频列表
  final RxList<HotVideoItemModel> videoList = <HotVideoItemModel>[].obs;

  /// 加载状态
  final RxBool isLoading = false.obs;

  /// 错误信息
  final RxString errMsg = ''.obs;

  /// 学习类分区 rid
  static const int _knowledgeRid = 1010; // 知识区
  static const int _techRid = 1012; // 科技区

  @override
  void onInit() {
    super.onInit();
    refreshRecommend();
  }

  /// 刷新学习推荐列表
  Future<void> refreshRecommend() async {
    isLoading.value = true;
    errMsg.value = '';
    try {
      // 并发拉取知识区和科技区排行榜
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

      // 去重(同一视频可能同时出现在两个分区榜)
      final seen = <String>{};
      final deduped = <HotVideoItemModel>[];
      for (final v in all) {
        final key = v.bvid ?? v.aid.toString();
        if (key != null && seen.add(key)) {
          deduped.add(v);
        }
      }

      // 按播放量倒序
      deduped.sort((a, b) {
        final av = a.stat?.view ?? 0;
        final bv = b.stat?.view ?? 0;
        return bv.compareTo(av);
      });

      videoList.value = deduped;
      if (deduped.isEmpty) {
        errMsg.value = '暂无学习推荐视频';
      }
    } catch (e) {
      errMsg.value = '加载失败: $e';
      videoList.clear();
    } finally {
      isLoading.value = false;
    }
  }
}
