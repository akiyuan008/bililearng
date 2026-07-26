// [PiliPlus Learning] 专注订阅极简瀑布流 UI
// 仅显示:封面 / 标题 / UP主,去除播放量。
// 使用原项目依赖 waterfall_flow 实现瀑布流,cached_network_image_ce 加载封面,
// PageUtils.toVideoPage 复用原项目视频详情页跳转。
import 'package:PiliPlus/http/search.dart';
import 'package:PiliPlus/utils/extension/string_ext.dart';
import 'package:PiliPlus/utils/page_utils.dart';
import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:waterfall_flow/waterfall_flow.dart';

import 'feed_aggregator.dart';
import 'subscription_controller.dart';

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
            tooltip: '添加 UP 主',
            icon: const Icon(Icons.person_add_outlined),
            onPressed: _showAddUpDialog,
          ),
          IconButton(
            tooltip: '白名单管理',
            icon: const Icon(Icons.playlist_remove_check_outlined),
            onPressed: _showWhiteListSheet,
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
            onPressed: _showAddUpDialog,
            icon: const Icon(Icons.person_add_outlined),
            label: const Text('添加 UP 主'),
          ),
        ],
      ),
    );
  }

  void _showAddUpDialog() {
    final controller = TextEditingController();
    Get.dialog<void>(
      AlertDialog(
        title: const Text('添加 UP 主'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'UP 主 UID',
            hintText: '请输入数字 UID',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back<void>(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              final uid = controller.text.trim();
              if (uid.isNotEmpty) {
                Get.back<void>();
                await _ctr.addUp(uid);
                await _ctr.refreshFeed();
              }
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  void _showWhiteListSheet() {
    final ctx = Get.context;
    if (ctx == null) return;
    Get.bottomSheet<void>(
      SafeArea(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.6,
          ),
          decoration: BoxDecoration(
            color: Theme.of(ctx).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(16),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  '白名单管理',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: Obx(() {
                  if (_ctr.whiteList.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('白名单为空', style: TextStyle(color: Colors.grey)),
                      ),
                    );
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    itemCount: _ctr.whiteList.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final uid = _ctr.whiteList[index];
                      return ListTile(
                        leading: const Icon(Icons.account_circle_outlined),
                        title: Text('UID: $uid'),
                        trailing: IconButton(
                          tooltip: '移除',
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () async {
                            await _ctr.removeUp(uid);
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

  /// 构建封面 Widget,处理空 URL / null 情况
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
        // 原项目标准:仅有 bvid 时先通过 ab2c 接口获取 cid 再跳转,
        // cid 传 0 会导致视频详情页无法播放。
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
            // 封面(16:9)
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
            // UP 主(去除播放量)
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
