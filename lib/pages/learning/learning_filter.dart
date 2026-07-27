// [PiliPlus Learning] 学习视频过滤算法
// 基于 B站分区名(tname)和标题关键词,判断视频是否为学习类内容。
// 过滤策略:
//   1. 分区白名单 —— 只保留学习相关子分区
//   2. 标题黑名单 —— 过滤标题含非学习关键词的视频
//   3. 标题白名单 —— 标题含强学习关键词时即使分区不在白名单也放行
import 'package:PiliPlus/models/model_hot_video_item.dart';

abstract final class LearningFilter {
  /// ======================== 分区白名单 ========================
  /// 知识区(rid=36)子分区 + 科技区(rid=188)子分区中,与学习强相关的分区。
  /// 只有 tname 命中以下关键词的视频才会被保留。
  static const Set<String> _zoneWhitelist = {
    // —— 知识区子分区 ——
    '科学科普',
    '社科·法律·心理',
    '演讲·公开课',
    '职业职场',
    '职场发展',
    '科技树',
    '应试教育',
    '非应试语言学习',
    '大学专业知识',
    '商业财经',
    '社会观察',
    '时政解读',
    '人文历史',
    '设计艺术',
    '心理杂谈',
    // —— 科技区子分区 ——
    '计算机技术',
    '软件应用',
    '工业工程',
    '设计创新',
    '科学生物',
  };

  /// ======================== 分区黑名单 ========================
  /// 即使在知识/科技区大分区下,以下子分区不属于学科学习,直接过滤。
  static const Set<String> _zoneBlacklist = {
    '野生技术协会', // DIY/极客类,非系统学习
    '数码', // 产品评测/开箱
    '星海', // 天文爱好者,偏娱乐
    '其他知识杂谈', // 内容太杂
  };

  /// ======================== 标题黑名单关键词 ========================
  /// 标题含以下关键词的视频将被过滤(不区分大小写)。
  static const List<String> _titleBlacklist = [
    // 娱乐/生活类
    '美食',
    '测评',
    '开箱',
    '日常',
    'vlog',
    'v log',
    '生活',
    '搞笑',
    '整活',
    '挑战',
    '游戏',
    '直播',
    '翻唱',
    '舞蹈',
    '宅舞',
    '鬼畜',
    '杂谈',
    '闲聊',
    '聊天',
    '吐槽',
    'reaction',
    '看剧',
    '追剧',
    '观影',
    '看电影',
    // 非学习DIY类
    '手工',
    'diy',
    '改造',
    '装修',
    '做菜',
    '烹饪',
    '食谱',
    '菜谱',
    // 营销/推广类
    '推广',
    '广告',
    '赞助',
    '带货',
    '下单',
    '购买',
  ];

  /// ======================== 标题白名单关键词 ========================
  /// 标题含以下关键词时,即使分区不在白名单中也放行(强学习信号)。
  static const List<String> _titleWhitelist = [
    '教程',
    '课程',
    '公开课',
    'lecture',
    'tutorial',
    '学习',
    '复习',
    '考试',
    '考研',
    '高考',
    '四六级',
    '雅思',
    '托福',
    '编程',
    '算法',
    '数据结构',
    '数学',
    '物理',
    '化学',
    '生物',
    '英语',
    '日语',
    '法语',
    '德语',
    '历史',
    '哲学',
    '经济学',
    '金融学',
    '会计',
    '法律',
    '心理学',
    '计算机科学',
    '机器学习',
    '深度学习',
    '人工智能',
    '神经网络',
    '量子',
    '相对论',
    '微积分',
    '线性代数',
    '概率论',
    '统计学',
    '操作系统',
    '编译原理',
    '计算机网络',
    '数据库',
    'leetcode',
    '面试题',
  ];

  /// ======================== 主过滤方法 ========================
  /// 返回 true 表示该视频应被过滤掉(不展示),false 表示保留。
  static bool shouldFilter(HotVideoItemModel video) {
    final tname = (video.tname ?? '').trim();
    final title = (video.title ?? '').toLowerCase();

    // 1. 分区黑名单 —— 直接过滤
    if (tname.isNotEmpty && _zoneBlacklist.contains(tname)) {
      return true;
    }

    // 2. 标题黑名单 —— 直接过滤(除非标题同时命中白名单)
    if (_titleBlacklist.any((kw) => title.contains(kw.toLowerCase()))) {
      if (!_titleWhitelist.any((kw) => title.contains(kw.toLowerCase()))) {
        return true;
      }
    }

    // 3. 分区白名单 —— 放行
    if (tname.isNotEmpty && _zoneWhitelist.contains(tname)) {
      return false;
    }

    // 4. 标题白名单 —— 放行(分区不在白名单但标题含强学习关键词)
    if (_titleWhitelist.any((kw) => title.contains(kw.toLowerCase()))) {
      return false;
    }

    // 5. 分区既不在白名单也不在黑名单 —— 默认过滤
    // 保守策略:未识别的分区一律过滤,确保只展示学习内容
    if (tname.isNotEmpty) {
      return true;
    }

    // 6. 无分区信息 —— 默认过滤
    return true;
  }

  /// 批量过滤,返回通过过滤的视频列表
  static List<HotVideoItemModel> filterList(List<HotVideoItemModel> videos) {
    return videos.where((v) => !shouldFilter(v)).toList();
  }
}
