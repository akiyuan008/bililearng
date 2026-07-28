// [PiliPlus Learning] 专注订阅页
// 仿推荐页:视频池+分页+换一批+撤回
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
import 'follow_select_page.dart';
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
            tooltip: '从关注列表多选',
            icon: const Icon(Icons.people_alt_outlined),
            onPressed: _addFromFollowListMulti,
          ),
          IconButton(
            tooltip: '搜索添加',
            icon: const Icon(Icons.person_search_outlined),
            onPressed: _addFromFollowList,
          ),
          IconButton(
            tooltip: '搜索视频',
            icon: const Icon(Icons.search),
            onPressed: () => Get.toNamed('/search'),
          ),
          IconButton(
            tooltip: '白名单管理',
            icon: const Icon(Icons.manage_accounts_outlined),
            onPressed: _showWhiteListSheet,
          ),
        ],
      ),
      body: Obx(() {
        if (_ctr.isLoading.value && _ctr.currentPage.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (_ctr.currentPage.isEmpty) {
          return _buildEmpty();
        }
        return Column(
          children: [
            // 页码指示器
            _buildPageIndicator(),
            // 视频列表
            Expanded(
              child: RefreshIndicator(
                onRefresh: _ctr.shuffleRefresh,
                child: WaterfallFlow.builder(
                  gridDelegate:
                      const SliverWaterfallFlowDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: _ctr.currentPage.length,
                  itemBuilder: (context, index) {
                    return _VideoCard(item: _ctr.currentPage[index]);
                  },
                ),
              ),
            ),
            // 底部导航栏
            _buildBottomBar(),
          ],
        );
      }),
    );
  }

  Widget _buildPageIndicator() {
    return Obx(() => Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.subscriptions_outlined,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 6),
              if (_ctr.refreshCount.value > 0) ...[
                Text(
                  '已刷新 ${_ctr.refreshCount.value} 次',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ] else ...[
                Text(
                  '第 ${_ctr.pageIndex.value} / ${_ctr.totalPages.value} 页',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primaryContainer
                      .withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '池中 ${_ctr.poolSize} 个',
                  style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '下拉换一批',
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ],
          ),
        ));
  }

  Widget _buildBottomBar() {
    return Obx(() => Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              top: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // 撤回
              TextButton.icon(
                onPressed:
                    _ctr.canUndo.value ? _ctr.undoRefresh : null,
                icon: const Icon(Icons.undo, size: 18),
                label: const Text('撤回'),
              ),
              // 换一批
              FilledButton.tonalIcon(
                onPressed: () => _ctr.shuffleRefresh(),
                icon: const Icon(Icons.shuffle, size: 18),
                label: const Text('换一批'),
              ),
              // 下一页
              TextButton.icon(
                onPressed: () => _ctr.nextPage(),
                icon: const Icon(Icons.arrow_forward, size: 18),
                label: const Text('下一页'),
              ),
            ],
          ),
        ));
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
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          FilledButton.tonalIcon(
            onPressed: _addFromFollowListMulti,
            icon: const Icon(Icons.people_alt_outlined),
            label: const Text('从关注列表选择 UP 主'),
          ),
          const SizedBox(height: 8),
          FilledButton.tonalIcon(
            onPressed: _addFromFollowList,
            icon: const Icon(Icons.person_search_outlined),
            label: const Text('搜索关注列表添加'),
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

  /// 从关注列表多选页面批量添加 UP 主
  void _addFromFollowListMulti() async {
    if (!Accounts.main.isLogin) {
      SmartDialog.showToast('请先登录 B站账号');
      return;
    }

    final List<UserModel>? result = await Navigator.of(context)
        .push<List<UserModel>>(GetPageRoute(page: () => const FollowSelectPage()));

    if (result != null && result.isNotEmpty) {
      int added = 0;
      for (final user in result) {
        await _ctr.addUp(UpInfo(
          mid: user.mid.toString(),
          name: user.name,
          face: user.avatar,
        ));
        added++;
      }
      await _ctr.refreshFeed();
      SmartDialog.showToast('已添加 $added 个UP主');
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
                        _addFromFollowListMulti();
                      },
                      icon: const Icon(Icons.people_alt_outlined),
                      label: const Text('多选添加'),
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
                        leading: CircleAvatar(
                          backgroundImage: up.face.isNotEmpty
                              ? NetworkImage(
                                  up.face.http2https,
                                  headers: const {
                                    'referer': 'https://www.bilibili.com'
                                  },
                                )
                              : null,
                          child: const Icon(Icons.person),
                        ),
                        title: Text(up.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text('UID: ${up.mid}', maxLines: 1, overflow: TextOverflow.ellipsis),
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
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
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
