// [PiliPlus Learning] 高中专属视频过滤算法
// 核心逻辑:
//   1. 竖屏短视频 —— 一律过滤(防分心)
//   2. 黑名单优先 —— 命中直接过滤
//   3. 白名单 —— 命中放行(标题/简介含高中学习关键词)
//   4. 未命中白名单 —— 仅允许知识区(tid=36)中时长>10分钟的视频通过
//   5. 删除科技区(tid=188),专注学科系统性内容
import 'package:PiliPlus/models/model_hot_video_item.dart';

abstract final class LearningFilter {
  /// ======================== 高中专属白名单关键词 ========================
  /// 包含学段/年级、教材/考纲、学科/题型、学习阶段。
  /// 视频标题或简介命中关键词即放行。
  static const List<String> _highSchoolWhitelist = [
    // —— 学段/年级 ——
    '高中', '高一', '高二', '高三', '高考', '中考', '初升高',
    '高一新生', '高二选科', '高三冲刺', '高三复习', '高考冲刺', '中考冲刺',
    '高三党', '高一数学', '高二数学', '高三数学',
    '高一物理', '高二物理', '高三物理', '高一化学', '高二化学', '高三化学',
    '高一英语', '高二英语', '高三英语', '高一语文', '高二语文', '高三语文',
    '高一生物', '高二生物', '高三生物',

    // —— 教材/考纲 ——
    '必修', '选修', '人教版', '北师大版', '苏教版', '鲁科版',
    '新高考', '新教材', '新课程', '考纲', '课标', '大纲',
    '人教A版', '人教B版', '沪教版', '浙教版',

    // —— 学科 ——
    '数学', '物理', '化学', '生物', '语文', '英语', '地理', '历史', '政治',
    '理科', '文科', '文综', '理综',

    // —— 数学知识点 ——
    '函数', '导数', '三角函数', '数列', '不等式', '立体几何', '解析几何',
    '圆锥曲线', '向量', '复数', '排列组合', '二项式', '概率统计',
    '集合', '对数', '指数', '幂函数', '单调性', '奇偶性', '周期性',
    '空间向量', '极坐标', '参数方程',

    // —— 物理知识点 ——
    '力学', '运动学', '动力学', '电磁学', '电学', '光学', '热学',
    '牛顿定律', '动量', '能量', '电路', '磁场', '电场', '感应',
    '万有引力', '圆周运动', '平抛运动', '简谐运动', '波的传播',
    '洛伦兹力', '安培力', '法拉第', '能量守恒', '动量守恒',

    // —— 化学知识点 ——
    '氧化还原', '离子反应', '物质的量', '元素周期', '化学键',
    '有机化学', '无机化学', '化学平衡', '电化学', '电解质',
    '原电池', '电解池', '盐类水解', '沉淀溶解',

    // —— 生物知识点 ——
    '细胞', '光合作用', '呼吸作用', 'DNA', 'RNA', '遗传', '变异',
    '基因', '生态系统', '生物圈', '减数分裂', '有丝分裂',

    // —— 语文知识点 ——
    '文言文', '古诗词', '阅读理解', '作文', '现代文', '诗歌鉴赏',
    '成语', '病句', '论述类文本',

    // —— 英语知识点 ——
    '语法', '词汇', '完形填空', '书面表达', '听力',
    '定语从句', '状语从句', '名词性从句', '虚拟语气',

    // —— 地理知识点 ——
    '自然地理', '人文地理', '区域地理', '气候', '洋流', '地形',
    '地球运动', '大气环流', '人口', '城市', '农业', '工业',

    // —— 历史知识点 ——
    '中国古代史', '中国近代史', '中国现代史', '世界史',
    '辛亥革命', '抗日战争', '解放战争', '改革开放',

    // —— 政治知识点 ——
    '经济生活', '政治生活', '文化生活', '生活与哲学',
    '马克思主义', '社会主义核心价值观',

    // —— 学习阶段 ——
    '一轮复习', '二轮复习', '三轮复习', '一轮', '二轮', '三轮',
    '真题解析', '真题', '模拟题', '模拟卷', '押题', '预测卷',
    '冲刺', '复习', '预习', '课后作业', '课后练习',
    '知识点', '考点', '重点', '难点', '易错点',
    '课后题', '练习题', '例题', '习题', '讲义',

    // —— 学习方法 ——
    '笔记', '错题本', '思维导图', '知识网络', '学习方法',
  ];

  /// ======================== 高中专属黑名单关键词 ========================
  /// 过滤考研、四六级、大学内容、游戏、伪学习及泛娱乐关键词。
  static const List<String> _highSchoolBlacklist = [
    // —— 大学/考研/非高中 ——
    '考研', '研究生', '四六级', 'CET4', 'CET6', '大学英语',
    '大学物理', '大学化学', '大学数学', '高等数学', '高数',
    '线代', '线性代数课程', '概率论课程', '复变函数', '数值分析',
    '微分方程', '离散数学', '抽象代数', '拓扑学',
    '专升本', '自考', '成人高考', 'MBA', '公务员',

    // —— 游戏 ——
    '原神', '星铁', '星穹铁道', '崩坏', '明日方舟',
    '王者荣耀', '和平精英', '英雄联盟', 'LOL', 'DOTA',
    '我的世界', 'minecraft', '迷你世界', '蛋仔派对',
    '第五人格', '阴阳师', 'FGO', '碧蓝航线', 'fate',
    '游戏实况', '游戏攻略', '游戏解说', 'speedrun',
    '主机游戏', 'steam', 'switch', 'PS5', 'Xbox',

    // —— 伪学习/标题党 ——
    '逆袭', '速成', '一周搞定', '三天学会', '小时速成',
    '秒杀', '必过', '包过', '保过', '零基础',
    '月入过万', '副业', '赚钱', '兼职',

    // —— 泛娱乐 ——
    '美食', '测评', '开箱', 'vlog', 'v log', 'VLOG',
    '搞笑', '整活', '翻唱', '舞蹈', '宅舞', '鬼畜',
    '追剧', '看剧', '观影', '看电影', '综艺',
    '美妆', '穿搭', '护肤', '发型',
    '宠物', '猫', '狗', '萌宠',
    '旅行', '旅游', '游记',
    '手工', 'diy', 'DIY', '改造', '装修',
    '做菜', '烹饪', '食谱', '菜谱', '美食制作',
    '健身', '减肥', '瑜伽',
    '相亲', '恋爱', '情感',

    // —— 营销/推广 ——
    '推广', '广告', '赞助', '带货', '下单', '购买',
    '优惠券', '折扣', '促销', '直播带货',

    // —— 非学习类分区内容 ——
    '数码评测', '手机开箱', '电脑装机',
    'ASMR', '助眠', '白噪音',
    '街舞', '说唱', 'rap', 'Rap',
  ];

  /// ======================== 分区黑名单 ========================
  /// 即使在知识区大分区下,以下子分区不属于高中学科学习,直接过滤。
  static const Set<String> _zoneBlacklist = {
    '野生技术协会',
    '数码',
    '星海',
    '其他知识杂谈',
    '设计艺术',
    '商业财经',
    '职场发展',
    '职业职场',
    '大学专业知识',
    '非应试语言学习',
    '社科·法律·心理',
    '社会观察',
    '时政解读',
    '心理杂谈',
  };

  /// ======================== 知识区 tid ========================
  static const int _knowledgeTid = 36;

  /// ======================== 最小时长(秒) ========================
  /// 未命中白名单的视频,时长需>10分钟(600秒)才放行。
  static const int _minDurationSeconds = 600;

  /// ======================== 主过滤方法 ========================
  /// 返回 true 表示该视频应被过滤掉(不展示),false 表示保留。
  static bool shouldFilter(HotVideoItemModel video) {
    final tname = (video.tname ?? '').trim();
    final title = (video.title ?? '').toLowerCase();
    final desc = (video.desc ?? '').toLowerCase();
    final tid = video.tid;
    final duration = video.duration;

    final textForMatch = '$title $desc';

    // 0. 竖屏短视频 —— 一律过滤(防分心)
    if (isVerticalVideo(video)) {
      return true;
    }

    // 1. 黑名单优先 —— 命中直接过滤
    if (_highSchoolBlacklist
        .any((kw) => textForMatch.contains(kw.toLowerCase()))) {
      return true;
    }

    // 2. 分区黑名单 —— 直接过滤
    if (tname.isNotEmpty && _zoneBlacklist.contains(tname)) {
      return true;
    }

    // 3. 白名单 —— 命中放行(返回 false = 不过滤)
    if (_highSchoolWhitelist
        .any((kw) => textForMatch.contains(kw.toLowerCase()))) {
      return false;
    }

    // 4. 未命中白名单 —— 仅允许知识区(tid=36)中时长>10分钟的视频通过
    if (tid == _knowledgeTid && duration > _minDurationSeconds) {
      return false;
    }

    // 5. 其他情况 —— 过滤
    return true;
  }

  /// 判断是否为竖屏短视频
  static bool isVerticalVideo(HotVideoItemModel video) {
    final dimension = video.dimension;
    if (dimension != null) {
      final width = dimension.width;
      final height = dimension.height;
      if (width != null && height != null && height > width) {
        return true;
      }
    }
    if (video.duration > 0 && video.duration < 60) {
      return true;
    }
    return false;
  }

  /// 批量过滤,返回通过过滤的视频列表
  static List<HotVideoItemModel> filterList(List<HotVideoItemModel> videos) {
    return videos.where((v) => !shouldFilter(v)).toList();
  }

  // ======================== 搜索结果过滤 ========================

  /// 搜索结果过滤:基于标题、简介、标签和时长判断
  static bool shouldFilterSearchItem({
    required String title,
    required String desc,
    String? tag,
    required int duration,
  }) {
    final titleLower = title.toLowerCase();
    final descLower = desc.toLowerCase();
    final tagLower = (tag ?? '').toLowerCase();
    final textForMatch = '$titleLower $descLower $tagLower';

    // 0. 短视频 —— 时长<60秒一律过滤
    if (duration > 0 && duration < 60) {
      return true;
    }

    // 1. 黑名单优先 —— 命中直接过滤
    if (_highSchoolBlacklist
        .any((kw) => textForMatch.contains(kw.toLowerCase()))) {
      return true;
    }

    // 2. 白名单 —— 命中放行
    if (_highSchoolWhitelist
        .any((kw) => textForMatch.contains(kw.toLowerCase()))) {
      return false;
    }

    // 3. 未命中白名单 —— 时长>10分钟才放行
    if (duration > _minDurationSeconds) {
      return false;
    }

    // 4. 其他 —— 过滤
    return true;
  }
}
