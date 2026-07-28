// [PiliPlus Learning] 关注列表多选页面
// 浏览全部关注列表,支持批量勾选多个UP主加入白名单。
// 替代原有"搜索一个选一个"的单选模式,提升效率。
import 'package:PiliPlus/common/widgets/pendant_avatar.dart';
import 'package:PiliPlus/http/follow.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/models_new/follow/data.dart';
import 'package:PiliPlus/models_new/follow/list.dart';
import 'package:PiliPlus/pages/share/view.dart' show UserModel;
import 'package:PiliPlus/utils/accounts.dart';
import 'package:PiliPlus/utils/extension/get_ext.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';

import 'white_list_repo.dart';

class FollowSelectPage extends StatefulWidget {
  const FollowSelectPage({super.key});

  @override
  State<FollowSelectPage> createState() => _FollowSelectPageState();
}

class _FollowSelectPageState extends State<FollowSelectPage> {
  final ScrollController _scrollCtr = ScrollController();
  final Set<int> _selectedMids = {};
  final Map<int, UserModel> _selectedMap = {};

  List<FollowItemModel> _list = [];
  int _page = 1;
  int? _total;
  bool _loading = false;
  bool _loadingMore = false;
  bool _isEnd = false;

  // 已在白名单中的 mid 集合(用于标记)
  final Set<String> _existingMids = {};

  @override
  void initState() {
    super.initState();
    _loadExisting();
    _loadData();
    _scrollCtr.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtr.removeListener(_onScroll);
    _scrollCtr.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtr.position.pixels >=
            _scrollCtr.position.maxScrollExtent - 200 &&
        !_loadingMore &&
        !_isEnd &&
        !_loading) {
      _loadMore();
    }
  }

  Future<void> _loadExisting() async {
    await WhiteListRepo.ensureInit();
    final uids = WhiteListRepo.getUids();
    setState(() {
      _existingMids.addAll(uids);
    });
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final mid = Accounts.main.mid;
    final res = await FollowHttp.followings(vmid: mid, pn: 1, ps: 20);
    if (mounted) {
      setState(() {
        if (res is Success<FollowData>) {
          final data = res.response;
          _list = data?.list ?? [];
          _total = data?.total;
          _page = 1;
          _isEnd = _list.length >= (_total ?? 0);
        }
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _isEnd) return;
    setState(() => _loadingMore = true);

    final mid = Accounts.main.mid;
    final res = await FollowHttp.followings(vmid: mid, pn: _page + 1, ps: 20);

    if (mounted) {
      setState(() {
        if (res is Success<FollowData>) {
          final data = res.response;
          final newList = data?.list ?? [];
          // 去重(防止重复)
          final existingMids = _list.map((e) => e.mid).toSet();
          final uniqueNew = newList.where((e) => !existingMids.contains(e.mid)).toList();
          _list.addAll(uniqueNew);
          _page++;
          _isEnd = _list.length >= (_total ?? 0);
        }
        _loadingMore = false;
      });
    }
  }

  void _toggleSelect(FollowItemModel item) {
    setState(() {
      if (_selectedMids.contains(item.mid)) {
        _selectedMids.remove(item.mid);
        _selectedMap.remove(item.mid);
      } else {
        _selectedMids.add(item.mid);
        _selectedMap[item.mid] = UserModel(
          mid: item.mid,
          name: item.uname ?? '',
          avatar: item.face ?? '',
          selected: true,
        );
      }
    });
  }

  void _confirm() {
    if (_selectedMids.isEmpty) {
      SmartDialog.showToast('请至少选择一个UP主');
      return;
    }
    final result = _selectedMap.values.toList();
    Get.back(result: result);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('从关注列表选择'),
        actions: [
          if (_selectedMids.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Text(
                  '已选 ${_selectedMids.length}',
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _list.isEmpty
              ? _buildEmpty(colorScheme)
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.builder(
                    controller: _scrollCtr,
                    itemCount: _list.length + 1,
                    itemBuilder: (context, index) {
                      if (index == _list.length) {
                        return _buildFooter();
                      }
                      final item = _list[index];
                      final isSelected = _selectedMids.contains(item.mid);
                      final isExisting = _existingMids.contains(item.mid.toString());
                      return _buildItem(colorScheme, item, isSelected, isExisting);
                    },
                  ),
                ),
      bottomNavigationBar: _selectedMids.isNotEmpty
          ? SafeArea(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  border: Border(
                    top: BorderSide(color: colorScheme.outlineVariant),
                  ),
                ),
                child: FilledButton.icon(
                  onPressed: _confirm,
                  icon: const Icon(Icons.check),
                  label: Text('添加 ${_selectedMids.length} 个UP主到白名单'),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildItem(
    ColorScheme colorScheme,
    FollowItemModel item,
    bool isSelected,
    bool isExisting,
  ) {
    return InkWell(
      onTap: isExisting ? null : () => _toggleSelect(item),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            // 复选框
            if (isExisting)
              Icon(Icons.check_circle, size: 24, color: colorScheme.outline)
            else
              Icon(
                isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 24,
                color: isSelected ? colorScheme.primary : colorScheme.outline,
              ),
            const SizedBox(width: 10),
            // 头像
            PendantAvatar(
              size: 45,
              badgeSize: 14,
              item.face,
              officialType: item.officialVerify?.type,
            ),
            const SizedBox(width: 10),
            // 名称和签名
            Expanded(
              child: Column(
                spacing: 3,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          item.uname ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            color: isExisting ? colorScheme.outline : null,
                          ),
                        ),
                      ),
                      if (isExisting) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '已添加',
                            style: TextStyle(fontSize: 10, color: colorScheme.outline),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (item.sign != null)
                    Text(
                      item.sign!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, color: colorScheme.outline),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    if (_loadingMore) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    if (_isEnd) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Text(
            '已全部加载 (${_list.length}人)',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildEmpty(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_off_outlined, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            '关注列表为空',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
