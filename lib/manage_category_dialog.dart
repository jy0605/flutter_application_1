import 'package:flutter/material.dart';
import '../lunch_data.dart';

class ManageCategoryDialog extends StatefulWidget {
  final Map<String, bool> categoryFilter;
  final List<Menu> myMenus; // 메뉴 리스트 추가
  final VoidCallback onUpdate;

  const ManageCategoryDialog({
    super.key,
    required this.categoryFilter,
    required this.myMenus,
    required this.onUpdate,
  });

  @override
  State<ManageCategoryDialog> createState() => _ManageCategoryDialogState();
}

class _ManageCategoryDialogState extends State<ManageCategoryDialog> {
  final TextEditingController controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFFE6DABF),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      elevation: 10,
      shadowColor: Colors.black54,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '카테고리 관리',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: '새 카테고리 추가',
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6347),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.add, color: Colors.white),
                    onPressed: () {
                      if (controller.text.isNotEmpty) {
                        setState(() {
                          widget.categoryFilter[controller.text] = true;
                        });
                        controller.clear();
                        widget.onUpdate();
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 250,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.categoryFilter.length,
                itemBuilder: (context, index) {
                  String key = widget.categoryFilter.keys.elementAt(index);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      title: Text(key),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.remove_circle_outline,
                          color: Colors.redAccent,
                        ),
                        onPressed: () {
                          if (widget.categoryFilter.length <= 1) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('최소 한 개의 카테고리는 필요해요!'),
                              ),
                            );
                            return;
                          }

                          // 해당 카테고리를 사용하는 메뉴가 있는지 확인
                          final menusInCategory = widget.myMenus
                              .where((m) => m.category == key)
                              .toList();

                          if (menusInCategory.isNotEmpty) {
                            // 메뉴가 있다면 확인 팝업 띄우기
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(32),
                                ),
                                elevation: 10,
                                shadowColor: Colors.black54,
                                title: const Text('카테고리 삭제'),
                                content: Text(
                                  "'$key' 카테고리에 ${menusInCategory.length}개의 메뉴가 있습니다.\n모두 함께 삭제하시겠습니까?",
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
                                        widget.myMenus.removeWhere(
                                          (m) => m.category == key,
                                        ); // 메뉴 삭제
                                        widget.categoryFilter.remove(
                                          key,
                                        ); // 카테고리 삭제
                                      });
                                      widget.onUpdate();
                                    },
                                    child: const Text(
                                      '삭제',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          } else {
                            setState(() => widget.categoryFilter.remove(key));
                            widget.onUpdate();
                          }
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('닫기', style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }
}
