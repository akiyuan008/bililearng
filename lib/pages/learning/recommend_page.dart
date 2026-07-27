// [PiliPlus Learning] 学习推荐页
// 分页展示知识区排行榜视频(已移除科技区),每页8个。
// 下拉刷新: 从视频池随机换一批(可撤回),底部按钮可顺序翻页。
import 'package:PiliPlus/http/search.dart';
import 'package:PiliPlus/models/model_hot_video_item.dart';
import 'package:PiliPlus/utils/extension/string_ext.dart';
import 'package:PiliPlus/utils/page_utils.dart';
import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:waterfall_flow/waterfall_flow.dart';

import 'recommend_controller.dart';

class RecommendPage extends StatefulWidget {
  const RecommendPage({super.key});

  @override
  State<RecommendPage> createState() => _RecommendPageState();
}

class _RecommendPageState extends State<RecommendPage> {
  final RecommendController _ctr = Get.put(RecommendController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('学习推荐'),
        actions: [
          // 撤回按钮
          Obx(() => IconButton(
                tooltip: '撤回刷新',
                icon: const Icon(Icons.undo),
                onPressed: _ctr.canUndo.value ? _ctr.undoRefresh : null,
              )),
          IconButton(
            tooltip: '搜索',
            icon: const Icon(Icons.search),
            onPressed: () => Get.toNamed('/search'),
          ),
          IconButton(
            tooltip: '重新获取',
            icon: const Icon(Icons.autorenew),
            onPressed: _ctr.refreshRecommend,
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
                Icons.school_outlined,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 6),
              if (_ctr.refreshCount.value > 0) ...[
                // 刷新模式
                Text(
                  '已刷新 ${_ctr.refreshCount.value} 次',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ] else ...[
                // 顺序浏览模式
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
          const Icon(Icons.school_outlined, size: 56, color: Colors.grey),
          const SizedBox(height: 12),
          Text(
            _ctr.errMsg.value.isEmpty ? '暂无推荐内容' : _ctr.errMsg.value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          FilledButton.tonalIcon(
            onPressed: _ctr.refreshRecommend,
            icon: const Icon(Icons.refresh),
            label: const Text('重新加载'),
          ),
        ],
      ),
    );
  }
}

class _VideoCard extends StatelessWidget {
  final HotVideoItemModel item;
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
    final title = item.title ?? '';
    final cover = item.cover;
    final bvid = item.bvid;
    final aid = item.aid;
    final upName = item.owner?.name ?? '';
    final tname = item.tname ?? '';

    return GestureDetector(
      onTap: () async {
        if (bvid == null && aid == null) return;
        final cid = item.cid;
        if (cid != null && cid > 0) {
          PageUtils.toVideoPage(
            aid: aid,
            bvid: bvid,
            cid: cid,
            cover: cover,
            title: title,
          );
          return;
        }
        SmartDialog.showLoading<dynamic>(msg: '获取视频中...');
        try {
          final cid = await SearchHttp.ab2c(aid: aid, bvid: bvid);
          if (cid != null) {
            PageUtils.toVideoPage(
              aid: aid,
              bvid: bvid,
              cid: cid,
              cover: cover,
              title: title,
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
              child: _buildCover(cover),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
              child: Text(
                title,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.account_circle_outlined,
                        size: 14,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          upName,
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
                  if (tname.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primaryContainer
                            .withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        tname,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
