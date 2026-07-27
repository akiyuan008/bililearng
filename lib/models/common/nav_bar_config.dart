import 'package:PiliPlus/common/widgets/custom_icon.dart';
import 'package:PiliPlus/models/common/enum_with_label.dart';
import 'package:PiliPlus/pages/dynamics/view.dart';
import 'package:PiliPlus/pages/home/view.dart';
import 'package:PiliPlus/pages/learning/library_page.dart';
import 'package:PiliPlus/pages/learning/recommend_page.dart';
import 'package:PiliPlus/pages/learning/stats_page.dart';
import 'package:PiliPlus/pages/learning/subscription_page.dart';
import 'package:PiliPlus/pages/mine/view.dart';
import 'package:PiliPlus/pages/setting/view.dart';
import 'package:flutter/material.dart';

enum NavigationBarType implements EnumWithLabel {
  // [PiliPlus Learning] 保留 home / dynamics 枚举值,避免原项目中其它文件
  // (main/controller.dart、main/view.dart 等)引用 NavigationBarType.home /
  // .dynamics 时出现编译报错;但底部导航实际不再包含它们(见 MainController.setNavBarConfig)。
  home(
    '首页',
    Icon(Icons.home_outlined),
    Icon(Icons.home),
    HomePage(),
  ),
  dynamics(
    '动态',
    Icon(CustomIcons.motion_photos_on_outlined),
    Icon(CustomIcons.motion_photos_on),
    DynamicsPage(),
  ),
  // [PiliPlus Learning] 保留原"我的"枚举不动(原项目多处引用),不纳入导航。
  mine(
    '我的',
    Icon(Icons.person_outline),
    Icon(Icons.person),
    MinePage(),
  ),
  // [PiliPlus Learning] 新增:设置 Tab —— 复用原项目 SettingPage
  setting(
    '设置',
    Icon(Icons.settings_outlined),
    Icon(Icons.settings),
    SettingPage(),
  ),
  // [PiliPlus Learning] 新增:学习库 Tab —— 复用稍后再看 / 收藏 / 历史 路由
  learning(
    '学习库',
    Icon(Icons.menu_book_outlined),
    Icon(Icons.menu_book),
    LearningLibraryPage(),
  ),
  // [PiliPlus Learning] 新增:专注订阅 Tab —— 白名单 UP 主聚合瀑布流
  subscription(
    '专注订阅',
    Icon(Icons.rss_feed_outlined),
    Icon(Icons.rss_feed),
    SubscriptionPage(),
  ),
  // [PiliPlus Learning] 新增:学习推荐 Tab —— 知识区+科技区排行榜
  recommend(
    '学习推荐',
    Icon(Icons.school_outlined),
    Icon(Icons.school),
    RecommendPage(),
  ),
  // [PiliPlus Learning] 新增:学习统计 Tab —— 学习时长统计图表
  stats(
    '学习统计',
    Icon(Icons.bar_chart_outlined),
    Icon(Icons.bar_chart),
    StatsPage(),
  ),
  ;

  @override
  final String label;
  final Icon icon;
  final Icon selectIcon;
  final Widget page;

  const NavigationBarType(this.label, this.icon, this.selectIcon, this.page);
}
