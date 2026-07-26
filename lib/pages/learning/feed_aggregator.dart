// [PiliPlus Learning] 专注订阅聚合器
// 顺序调用原项目已有的 MemberHttp.searchArchive 获取指定 UID 的视频,
// 按 pubdate 倒序聚合,每次请求间加 2 秒延迟防风控。
//
// 说明:原项目无 UserService 类,获取指定 UP 主投稿视频的对外接口为
// MemberHttp.searchArchive(返回 LoadingState<SearchArchiveData>),
// 其内部 item 模型 VListItemModel 带有精确的 pubdate(created)时间戳,
// 正好用于跨 UP 主倒序聚合。
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/http/member.dart';
import 'package:PiliPlus/models_new/member/search_archive/vlist.dart';

/// 聚合后的极简视频条目:封面 / 标题 / UP主(去除播放量)
class FeedItem {
  final String title;
  final String? cover;
  final String? bvid;
  final int? aid;
  final String upName;

  /// 发布时间戳(秒),用于倒序聚合
  final int? pubdate;

  const FeedItem({
    required this.title,
    this.cover,
    this.bvid,
    this.aid,
    required this.upName,
    this.pubdate,
  });

  factory FeedItem.fromVList(VListItemModel v) {
    // title / owner 是 late 字段,fromJson 总会赋值,但加 try 保护防止意外
    String title;
    try {
      title = v.title;
    } catch (_) {
      title = '';
    }
    String upName;
    try {
      upName = v.owner.name ?? '';
    } catch (_) {
      upName = '';
    }
    return FeedItem(
      title: title,
      cover: v.cover,
      bvid: v.bvid,
      aid: v.aid,
      upName: upName,
      pubdate: v.pubdate,
    );
  }
}

class FeedAggregator {
  FeedAggregator._();

  /// 防风控延迟(毫秒)
  static const int _antiCrawlDelayMs = 2000;

  /// 并发获取多个 UP 主的视频,并按 pubdate 倒序聚合
  ///
  /// [uids] 白名单 UP 主 UID 列表
  /// [ps] 每个 UP 主拉取条数(默认 30)
  static Future<List<FeedItem>> fetch(
    List<String> uids, {
    int ps = 30,
  }) async {
    if (uids.isEmpty) return <FeedItem>[];

    final all = <FeedItem>[];

    // 顺序拉取每个 UP 主的最新投稿(防风控:不能用 Future.wait 并发)
    for (int i = 0; i < uids.length; i++) {
      final items = await _fetchOne(uids[i], ps: ps);
      all.addAll(items);
      // 每次请求之间加延迟,避免触发 B 站风控
      if (i < uids.length - 1) {
        await Future.delayed(const Duration(milliseconds: _antiCrawlDelayMs));
      }
    }

    // 按 pubdate 倒序聚合(pubdate 为空视为 0,排到末尾)
    all.sort((a, b) => (b.pubdate ?? 0).compareTo(a.pubdate ?? 0));

    return all;
  }

  static Future<List<FeedItem>> _fetchOne(String uid, {required int ps}) async {
    try {
      final mid = int.tryParse(uid);
      if (mid == null) return <FeedItem>[];
      // searchArchive 默认 order=pubdate(按发布时间),正好用于聚合
      final res = await MemberHttp.searchArchive(
        mid: mid,
        pn: 1,
        ps: ps,
      );
      if (res case Success(:final response)) {
        final vlist = response.list?.vlist ?? const <VListItemModel>[];
        return vlist
            .map(FeedItem.fromVList)
            .where((e) => e.bvid != null || e.aid != null)
            .toList();
      }
      return <FeedItem>[];
    } catch (_) {
      // 单个 UP 主拉取失败不影响整体聚合
      return <FeedItem>[];
    }
  }
}
