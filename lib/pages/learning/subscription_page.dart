// [PiliPlus Learning] 专注订阅极简瀑布流 UI
// 从登录账号的关注列表选择 UP 主,无需手动输入 UID。
import 'package:PiliPlus/http/search.dart';
import 'package:PiliPlus/pages/follow_search/view.dart';
import 'package:PiliPlus/pages/share/view.dart';
import 'package:PiliPlus/utils/accounts.dart';
import 'package:PiliPlus/utils/extension/get_ext.dart';
import 'package:PiliPlus/utils/extension/string_ext.dart';
import 'package:PiliPlus/utils/page_utils.dart';
import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:waterfall_flow/waterfall_flow.dart';

import 'feed_aggregator.dart';
import 'subscription_controller.dart';
import 'white_list_repo.dart';

class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({super.key});

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  final SubscriptionController _ctr =
      Get.putOrFind(SubscriptionController.new);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('专注订阅'),
        actions: [
          IconButton(
            tooltip: '从关注列表添加',
            icon: const Icon(Icons.person_add_outlined),
            onPressed: _addFromFollowList,
          ),
          IconButton(
            tooltip: '搜索',
            icon: const Icon(Icons.search),
            onPressed: () => Get.toNamed('/search'),
          ),
        ],
      ),
      body: Obx(() {
        if (_ctr.isLoading.value && _ctr.feedList.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (_ctr.feedList.isEmpty) {
          return _buildEmpty();
        }
        return RefreshIndicator(
          onRefresh: _ctr.refreshFeed,
          child: WaterfallFlow.builder(
            gridDelegate:
                const SliverWaterfallFlowDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            padding: const EdgeInsets.all(8),
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: _ctr.feedList.length,
            itemBuilder: (context, index) {
              return _VideoCard(item: _ctr.feedList[index]);
            },
          ),
        );
      }),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inbox_outlined, size: 56, color: Colors.grey),
          const SizedBox(height: 12),
          Text(
            _ctr.errMsg.value.isEmpty ? '暂无订阅内容' : _ctr.errMsg.value,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          FilledButton.tonalIcon(
            onPressed: _addFromFollowList,
            icon: const Icon(Icons.person_add_outlined),
            label: const Text('从关注列表添加 UP 主'),
          ),
        ],
      ),
    );
  }

  /// 从关注列表选择 UP 主
  void _addFromFollowList() async {
    final mid = Accounts.main.mid;
    if (!Accounts.main.isLogin) {
      SmartDialog.showToast('请先登录 B站账号');
      return;
    }

    // 打开关注列表搜索页,支持选择返回
    final UserModel? userModel = await Navigator.of(context).push<UserModel>(
      GetPageRoute(
        page: () => FollowSearchPage(mid: mid, isFromSelect: true),
      ),
    );

    if (userModel != null) {
      await _ctr.addUp(UpInfo(
        mid: userModel.mid.toString(),
        name: userModel.name,
        face: userModel.avatar,
      ));
      await _ctr.refreshFeed();
      SmartDialog.showToast('已添加: ${userModel.name}');
    }
  }

  /// 白名单管理底部弹窗
  void _showWhiteListSheet() {
    showModalBottomSheet<void>(
      context: context,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      builder: (ctx) => SafeArea(
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(ctx).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(16),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '白名单管理',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _addFromFollowList();
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('添加'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: Obx(() {
                  if (_ctr.whiteList.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('白名单为空',
                            style: TextStyle(color: Colors.grey)),
                      ),
                    );
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    itemCount: _ctr.whiteList.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final up = _ctr.whiteList[index];
                      return ListTile(
                        leading: up.face.isNotEmpty
                            ? CircleAvatar(
                                backgroundImage: NetworkImage(
                                  up.face.http2https,
                                  headers: const {
                                    'referer': 'https://www.bilibili.com'
                                  },
                                ),
                                child: up.face.isEmpty
                                    ? const Icon(Icons.person)
                                    : null,
                              )
                            : const CircleAvatar(
                                child: Icon(Icons.person),
                              ),
                        title: Text(up.name),
                        subtitle: Text('UID: ${up.mid}'),
                        trailing: IconButton(
                          tooltip: '移除',
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () async {
                            await _ctr.removeUp(up.mid);
                            await _ctr.refreshFeed();
                          },
                        ),
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VideoCard extends StatelessWidget {
  final FeedItem item;
  const _VideoCard({required this.item});

  Widget _buildCover(String? cover) {
    final url = cover?.http2https ?? '';
    if (url.isEmpty) {
      return Container(
        color: Colors.black12,
        child: const Center(
          child: Icon(Icons.image_not_supported_outlined, color: Colors.grey),
        ),
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (_, __) => Container(color: Colors.black12),
      errorBuilder: (_, __, ___) => Container(
        color: Colors.black12,
        child: const Center(
          child: Icon(Icons.broken_image_outlined, color: Colors.grey),
        ),
      ),
      httpHeaders: const {'referer': 'https://www.bilibili.com'},
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        if (item.bvid == null && item.aid == null) return;
        SmartDialog.showLoading<dynamic>(msg: '获取视频中...');
        try {
          final cid = await SearchHttp.ab2c(
            aid: item.aid,
            bvid: item.bvid,
          );
          if (cid != null) {
            PageUtils.toVideoPage(
              aid: item.aid,
              bvid: item.bvid,
              cid: cid,
              cover: item.cover,
              title: item.title,
            );
          } else {
            SmartDialog.showToast('获取视频信息失败');
          }
        } catch (e) {
          SmartDialog.showToast('跳转失败: $e');
        } finally {
          SmartDialog.dismiss();
        }
      },
      child: Card(
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: _buildCover(item.cover),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
              child: Text(
                item.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Row(
                children: [
                  Icon(
                    Icons.account_circle_outlined,
                    size: 14,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      item.upName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
