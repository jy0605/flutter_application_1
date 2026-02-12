import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../lunch_data.dart';

class RiggingDialog extends StatefulWidget {
  final List<Menu> filteredMenus;
  final Function(String) onMenuSelected;

  const RiggingDialog({
    super.key,
    required this.filteredMenus,
    required this.onMenuSelected,
  });

  @override
  State<RiggingDialog> createState() => _RiggingDialogState();
}

class _RiggingDialogState extends State<RiggingDialog> {
  String searchText = '';

  @override
  Widget build(BuildContext context) {
    final displayMenus = widget.filteredMenus
        .where((menu) => menu.name.contains(searchText))
        .toList();

    return Dialog(
      backgroundColor: const Color(0xFFE6DABF),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      elevation: 10,
      shadowColor: Colors.black54,
      child: Container(
        padding: const EdgeInsets.all(24),
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.auto_fix_high_rounded, color: Color(0xFFFF6347)),
                SizedBox(width: 10),
                Text(
                  '쉿! 오늘은 이거야 🤫',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '원하는 메뉴를 선택하면 100% 당첨됩니다.',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            TextField(
              style: GoogleFonts.notoSansKr(), // 한글 입력 문제 해결
              decoration: InputDecoration(
                hintText: '메뉴 검색...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchText = value;
                });
              },
            ),
            const SizedBox(height: 10),
            Expanded(
              child: displayMenus.isEmpty
                  ? Center(
                      child: Text(
                        '검색 결과가 없어요 😢',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    )
                  : ListView.builder(
                      itemCount: displayMenus.length,
                      itemBuilder: (context, index) {
                        final menu = displayMenus[index];
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
                              '[${menu.category}] ${menu.name}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            trailing: const Icon(
                              Icons.check_circle_outline,
                              color: Colors.grey,
                            ),
                            onTap: () {
                              widget.onMenuSelected(menu.name);
                              Navigator.pop(context);
                            },
                          ),
                        );
                      },
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
