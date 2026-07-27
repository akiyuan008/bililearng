// [PiliPlus Learning] 学习推荐页
// 展示知识区和科技区排行榜视频,极简瀑布流 UI。
// 只显示学习类视频,屏蔽所有非学习内容。
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
          IconButton(
            tooltip: '搜索',
            icon: const Icon(Icons.search),
            onPressed: () => Get.toNamed('/search'),
          ),
          IconButton(
            tooltip: '刷新',
            icon: const Icon(Icons.refresh),
            onPressed: _ctr.refreshRecommend,
          ),
        ],
      ),
      body: Obx(() {
        if (_ctr.isLoading.value && _ctr.videoList.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (_ctr.videoList.isEmpty) {
          return _buildEmpty();
        }
        return RefreshIndicator(
          onRefresh: _ctr.refreshRecommend,
          child: WaterfallFlow.builder(
            gridDelegate:
                const SliverWaterfallFlowDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            padding: const EdgeInsets.all(8),
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: _ctr.videoList.length,
            itemBuilder: (context, index) {
              return _VideoCard(item: _ctr.videoList[index]);
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
          const Icon(Icons.school_outlined, size: 56, color: Colors.grey),
          const SizedBox(height: 12),
          Text(
            _ctr.errMsg.value.isEmpty ? '暂无推荐内容' : _ctr.errMsg.value,
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
    final view = item.stat?.view;

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
        // 没有 cid 时通过 ab2c 获取
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
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
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
                        style: TextStyle(
                          fontSize: 10,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
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
