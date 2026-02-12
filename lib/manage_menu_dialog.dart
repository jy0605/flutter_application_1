import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../lunch_data.dart';
import 'manage_category_dialog.dart';

class ManageMenuDialog extends StatefulWidget {
  final List<Menu> myMenus;
  final Map<String, bool> categoryFilter;
  final VoidCallback onSave;

  const ManageMenuDialog({
    super.key,
    required this.myMenus,
    required this.categoryFilter,
    required this.onSave,
  });

  @override
  State<ManageMenuDialog> createState() => _ManageMenuDialogState();
}

class _ManageMenuDialogState extends State<ManageMenuDialog> {
  final TextEditingController controller = TextEditingController();
  late String selected;
  String? errorMsg;
  String _filterCategory = '전체'; // 필터 상태 변수 추가

  @override
  void initState() {
    super.initState();
    selected = widget.categoryFilter.keys.first;
  }

  void _addMenu() {
    final name = controller.text.trim();
    if (name.isNotEmpty) {
      if (widget.myMenus.any((m) => m.name == name)) {
        setState(() => errorMsg = '이미 있는 메뉴예요! 😅');
        return;
      }
      setState(() {
        widget.myMenus.add(Menu(name: name, category: selected));
      });
      widget.onSave();
      controller.clear();
    }
  }

  void _showEditMenuDialog(Menu menu) {
    final editController = TextEditingController(text: menu.name);
    String editCategory = menu.category;
    String? editErrorMsg;

    // 카테고리가 현재 필터 목록에 없으면 기본값 설정
    if (!widget.categoryFilter.containsKey(editCategory) &&
        widget.categoryFilter.isNotEmpty) {
      editCategory = widget.categoryFilter.keys.first;
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(32),
            ),
            elevation: 10,
            shadowColor: Colors.black54,
            title: const Text('메뉴 수정'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: editController,
                  style: GoogleFonts.notoSansKr(),
                  decoration: InputDecoration(
                    labelText: '메뉴 이름',
                    border: const OutlineInputBorder(),
                    errorText: editErrorMsg,
                  ),
                  onChanged: (v) {
                    if (editErrorMsg != null)
                      setDialogState(() => editErrorMsg = null);
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: editCategory,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: '카테고리',
                    border: OutlineInputBorder(),
                  ),
                  items: widget.categoryFilter.keys
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setDialogState(() => editCategory = v);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('취소', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: () {
                  final newName = editController.text.trim();
                  if (newName.isNotEmpty) {
                    if (newName != menu.name &&
                        widget.myMenus.any((m) => m.name == newName)) {
                      setDialogState(() => editErrorMsg = '이미 있는 메뉴예요! 😅');
                      return;
                    }

                    setState(() {
                      final index = widget.myMenus.indexOf(menu);
                      if (index != -1) {
                        widget.myMenus[index] = Menu(
                          name: newName,
                          category: editCategory,
                        );
                      }
                    });
                    widget.onSave();
                    Navigator.pop(context);
                  }
                },
                child: const Text('수정 완료'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 선택된 카테고리에 따라 메뉴 리스트 필터링
    final filteredMenus = _filterCategory == '전체'
        ? widget.myMenus
        : widget.myMenus.where((m) => m.category == _filterCategory).toList();

    return Dialog(
      backgroundColor: const Color(0xFFE6DABF),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      elevation: 10,
      shadowColor: Colors.black54,
      child: Container(
        padding: const EdgeInsets.all(24),
        height: MediaQuery.of(context).size.height * 0.75, // 화면 높이의 75% 사용
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Text(
                  '메뉴 관리',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  '(전체 메뉴 ${widget.myMenus.length}개)',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: selected,
                        items: widget.categoryFilter.keys
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => selected = v!),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.settings, color: Colors.black54),
                    onPressed: () async {
                      await showDialog(
                        context: context,
                        builder: (context) => ManageCategoryDialog(
                          categoryFilter: widget.categoryFilter,
                          myMenus: widget.myMenus, // 메뉴 리스트 전달
                          onUpdate: () {
                            setState(() {}); // Refresh dropdown items
                            widget.onSave(); // 카테고리 변경사항 즉시 저장
                          },
                        ),
                      );
                      if (!widget.categoryFilter.containsKey(selected)) {
                        setState(() {
                          selected = widget.categoryFilter.keys.first;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              style: GoogleFonts.notoSansKr(), // 한글 입력 문제 해결을 위해 폰트 직접 지정
              decoration: InputDecoration(
                hintText: '메뉴 이름 (예: 김치볶음밥)',
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                errorText: errorMsg,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              onChanged: (v) {
                if (errorMsg != null) setState(() => errorMsg = null);
              },
              onSubmitted: (_) => _addMenu(),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _addMenu,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6347),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text(
                '추가하기',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 10),
            // 카테고리 필터 칩 (가로 스크롤)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: const Text('전체'),
                      selected: _filterCategory == '전체',
                      onSelected: (selected) {
                        if (selected) setState(() => _filterCategory = '전체');
                      },
                      selectedColor: Colors.white,
                      labelStyle: TextStyle(
                        color: _filterCategory == '전체'
                            ? const Color(0xFFFF6347)
                            : Colors.black87,
                        fontWeight: _filterCategory == '전체'
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                      backgroundColor: Colors.grey[100],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: _filterCategory == '전체'
                              ? const Color(0xFFFF6347)
                              : Colors.grey.shade300,
                        ),
                      ),
                    ),
                  ),
                  ...widget.categoryFilter.keys.map((category) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(category),
                        selected: _filterCategory == category,
                        onSelected: (selected) {
                          if (selected)
                            setState(() => _filterCategory = category);
                        },
                        selectedColor: Colors.white,
                        labelStyle: TextStyle(
                          color: _filterCategory == category
                              ? const Color(0xFFFF6347)
                              : Colors.black87,
                          fontWeight: _filterCategory == category
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                        backgroundColor: Colors.grey[100],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: _filterCategory == category
                                ? const Color(0xFFFF6347)
                                : Colors.grey.shade300,
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: filteredMenus.length, // 필터링된 개수 사용
                itemBuilder: (c, i) {
                  // 필터링된 리스트에서 가져오기 (최신순 정렬 유지)
                  final m = filteredMenus[filteredMenus.length - 1 - i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade100),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      dense: true,
                      title: Text(
                        '[${m.category}] ${m.name}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      onTap: () => _showEditMenuDialog(m),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.close,
                          size: 18,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            widget.myMenus.remove(m);
                          });
                          widget.onSave();
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
            // 초기화 버튼 추가
            TextButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32),
                    ),
                    elevation: 10,
                    shadowColor: Colors.black54,
                    title: const Text('초기화 확인'),
                    content: const Text(
                      '정말 초기화하시겠습니까?\n모든 데이터가 삭제되고 기본값으로 돌아갑니다.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('취소'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(ctx); // 팝업 닫기
                          setState(() {
                            widget.myMenus.clear();
                            // lunch_data.dart의 defaultMenus 내용을 복사해서 넣기
                            widget.myMenus.addAll(defaultMenus);

                            // 카테고리도 초기 상태로 복구
                            widget.categoryFilter.clear();
                            for (var menu in defaultMenus) {
                              widget.categoryFilter[menu.category] = true;
                            }
                            // 선택된 카테고리 재설정
                            selected = widget.categoryFilter.keys.first;
                          });
                          widget.onSave(); // 저장소에도 반영
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('메뉴와 카테고리가 초기 상태로 복구되었습니다! 🔄'),
                            ),
                          );
                        },
                        child: const Text(
                          '초기화',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.refresh, size: 16, color: Colors.grey),
              label: const Text(
                '초기 데이터로 복구',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6347),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  '닫기',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
