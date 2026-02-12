import 'package:flutter/material.dart';

class CategoryFilterDialog extends StatefulWidget {
  final Map<String, bool> categoryFilter;
  final VoidCallback onApplyFilter;

  const CategoryFilterDialog({
    super.key,
    required this.categoryFilter,
    required this.onApplyFilter,
  });

  @override
  State<CategoryFilterDialog> createState() => _CategoryFilterDialogState();
}

class _CategoryFilterDialogState extends State<CategoryFilterDialog> {
  @override
  Widget build(BuildContext context) {
    final isAllSelected = widget.categoryFilter.values.every((e) => e);

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
              '카테고리 필터',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Flexible(
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    FilterChip(
                      label: const Text('전체'),
                      selected: isAllSelected,
                      onSelected: (bool value) {
                        setState(() {
                          widget.categoryFilter.updateAll((key, val) => value);
                        });
                        widget.onApplyFilter();
                      },
                      selectedColor: Colors.white,
                      checkmarkColor: const Color(0xFFFF6347),
                      labelStyle: TextStyle(
                        color: isAllSelected
                            ? const Color(0xFFFF6347)
                            : Colors.black87,
                        fontWeight: isAllSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                      backgroundColor: Colors.grey[100],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isAllSelected
                              ? const Color(0xFFFF6347)
                              : Colors.grey.shade300,
                        ),
                      ),
                      showCheckmark: false,
                    ),
                    ...widget.categoryFilter.keys.map((key) {
                      final isSelected = widget.categoryFilter[key]!;
                      return FilterChip(
                        label: Text(key),
                        selected: isSelected,
                        onSelected: (bool value) {
                          if (!value) {
                            final count = widget.categoryFilter.values
                                .where((e) => e)
                                .length;
                            if (count <= 1) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('최소 한 개는 선택해야 해요!'),
                                ),
                              );
                              return;
                            }
                          }
                          setState(() {
                            widget.categoryFilter[key] = value;
                          });
                          widget.onApplyFilter();
                        },
                        selectedColor: Colors.white,
                        checkmarkColor: const Color(0xFFFF6347),
                        labelStyle: TextStyle(
                          color: isSelected
                              ? const Color(0xFFFF6347)
                              : Colors.black87,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                        backgroundColor: Colors.grey[100],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected
                                ? const Color(0xFFFF6347)
                                : Colors.grey.shade300,
                          ),
                        ),
                        showCheckmark: false,
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                final count = widget.categoryFilter.values
                    .where((e) => e)
                    .length;
                if (count < 1) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('최소 한 개는 선택해야 해요!')),
                  );
                  return;
                }
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6347),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                '완료',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
