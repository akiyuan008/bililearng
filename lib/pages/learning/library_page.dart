// [PiliPlus Learning] 学习库入口页
// 极简入口,复用原项目已有的稍后再看(/later)、收藏(/fav)、历史记录(/history)路由。
// 顶部添加搜索入口,修复原导航裁剪导致搜索不可用的问题。
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LearningLibraryPage extends StatelessWidget {
  const LearningLibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final entries = <_LibraryEntry>[
      _LibraryEntry(
        title: '稍后再看',
        subtitle: '待学习的视频',
        icon: Icons.watch_later_outlined,
        color: Colors.blue,
        route: '/later',
      ),
      _LibraryEntry(
        title: '我的收藏',
        subtitle: '收藏的视频合集',
        icon: Icons.favorite_outline,
        color: Colors.pink,
        route: '/fav',
      ),
      _LibraryEntry(
        title: '历史记录',
        subtitle: '学习足迹',
        icon: Icons.history,
        color: Colors.orange,
        route: '/history',
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('学习库'),
        actions: [
          IconButton(
            tooltip: '搜索',
            icon: const Icon(Icons.search),
            onPressed: () => Get.toNamed('/search'),
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: entries.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final e = entries[index];
          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leading: CircleAvatar(
                backgroundColor: e.color.withValues(alpha: 0.12),
                child: Icon(e.icon, color: e.color),
              ),
              title: Text(e.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16)),
              subtitle: Text(e.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Get.toNamed(e.route),
            ),
          );
        },
      ),
    );
  }
}

class _LibraryEntry {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String route;

  const _LibraryEntry({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.route,
  });
}
