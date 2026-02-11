import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'lunch_data.dart';
import 'youtube_shorts.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ThemeData(useMaterial3: true);
    return MaterialApp(
      title: '점심 메뉴 추천 Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF6B35),
          surface: const Color(0xFFFFF8F2),
        ),
        scaffoldBackgroundColor: const Color(0xFFFFF8F2),
        textTheme: GoogleFonts.notoSansKrTextTheme(base.textTheme),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          foregroundColor: const Color(0xFF1E1E1E),
          titleTextStyle: GoogleFonts.notoSansKr(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1E1E1E),
          ),
        ),
      ),
      home: const LunchRoulettePage(),
    );
  }
}

class LunchRoulettePage extends StatefulWidget {
  const LunchRoulettePage({super.key});

  @override
  State<LunchRoulettePage> createState() => _LunchRoulettePageState();
}

class _LunchRoulettePageState extends State<LunchRoulettePage> {
  late FixedExtentScrollController _scrollController;
  StreamSubscription? _accelerometerSubscription;
  bool isSpinning = false;

  List<Menu> myMenus = [];
  List<Menu> filteredMenus = [];

  Map<String, bool> categoryFilter = {
    '한식': true,
    '중식': true,
    '일식': true,
    '양식': true,
    '분식': true,
    '야식': true,
    '간편식': true,
    '다이어트': true,
    '치킨': true,
  };

  @override
  void initState() {
    super.initState();
    _scrollController = FixedExtentScrollController();
    _loadMenuData();

    _accelerometerSubscription = accelerometerEvents.listen((
      AccelerometerEvent event,
    ) {
      final velocity = sqrt(pow(event.x, 2) + pow(event.y, 2) + pow(event.z, 2));
      if (velocity > 20 && !isSpinning) {
        spinRoulette();
      }
    });
  }

  Future<void> _loadMenuData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedMenus = prefs.getString('my_menus');

    setState(() {
      if (savedMenus != null) {
        final List<dynamic> jsonList = jsonDecode(savedMenus);
        myMenus = jsonList.map((json) => Menu.fromJson(json)).toList();
      } else {
        myMenus = List.from(defaultMenus);
      }
      _applyFilter();
    });
  }

  Future<void> _saveMenuData() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(myMenus.map((e) => e.toJson()).toList());
    await prefs.setString('my_menus', jsonString);
    _applyFilter();
  }

  void _applyFilter() {
    setState(() {
      filteredMenus = myMenus.where((menu) {
        return categoryFilter[menu.category] ?? true;
      }).toList();
    });
  }

  @override
  void dispose() {
    _accelerometerSubscription?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void spinRoulette() {
    if (isSpinning) return;
    if (filteredMenus.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('선택할 메뉴가 없습니다. 필터를 확인해 주세요.')),
      );
      return;
    }

    setState(() {
      isSpinning = true;
    });

    final randomItemIndex = Random().nextInt(filteredMenus.length);
    final targetIndex =
        _scrollController.selectedItem + (filteredMenus.length * 5) + randomItemIndex;

    _scrollController
        .animateToItem(
          targetIndex,
          duration: const Duration(seconds: 3),
          curve: Curves.easeInOutCubic,
        )
        .then((_) {
          setState(() {
            isSpinning = false;
          });
          final finalIndex = targetIndex % filteredMenus.length;
          _showResultDialog(filteredMenus[finalIndex].name);
        });
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('카테고리 필터'),
              content: SingleChildScrollView(
                child: Column(
                  children: categoryFilter.keys.map((key) {
                    return CheckboxListTile(
                      value: categoryFilter[key],
                      title: Text(key),
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor: const Color(0xFFFF6B35),
                      onChanged: (bool? value) {
                        setDialogState(() {
                          categoryFilter[key] = value ?? true;
                        });
                        _applyFilter();
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('닫기'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showManageMenuDialog() {
    final nameController = TextEditingController();
    String selectedCategory = categoryFilter.keys.first;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('내 메뉴 관리'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: nameController,
                            decoration: const InputDecoration(hintText: '메뉴 이름'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        DropdownButton<String>(
                          value: selectedCategory,
                          items: categoryFilter.keys.map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (newValue) {
                            setDialogState(() {
                              selectedCategory = newValue ?? selectedCategory;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        if (nameController.text.trim().isEmpty) return;
                        setState(() {
                          myMenus.add(
                            Menu(
                              name: nameController.text.trim(),
                              category: selectedCategory,
                            ),
                          );
                        });
                        _saveMenuData();
                        nameController.clear();
                        setDialogState(() {});
                      },
                      child: const Text('추가하기'),
                    ),
                    const Divider(height: 22),
                    Expanded(
                      child: ListView.builder(
                        itemCount: myMenus.length,
                        itemBuilder: (context, index) {
                          final menu = myMenus[myMenus.length - 1 - index];
                          return ListTile(
                            dense: true,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            title: Text(menu.name),
                            subtitle: Text(menu.category),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  myMenus.remove(menu);
                                });
                                _saveMenuData();
                                setDialogState(() {});
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('닫기'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showResultDialog(String menu) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Column(
          children: [
            Icon(Icons.restaurant_menu, color: Color(0xFFFF6B35), size: 44),
            SizedBox(height: 10),
            Text(
              '오늘의 메뉴 당첨!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        content: Text(
          menu,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w900,
            color: Color(0xFFFF6B35),
          ),
        ),
        actions: [
          Center(
            child: FilledButton.icon(
              onPressed: () {
                Share.share('오늘 점심 메뉴는 [$menu]! 같이 먹자 🍽️');
              },
              icon: const Icon(Icons.share_rounded),
              label: const Text('친구에게 공유하기'),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              FilledButton.tonal(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => YoutubeShortsPage(menu: menu),
                    ),
                  );
                },
                child: const Text('쇼츠 보기'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _searchNearBy(menu);
                },
                child: const Text('식당 찾기'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('다시하기'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _searchNearBy(String menu) async {
    Position? currentPosition;

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        var permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }

        if (permission == LocationPermission.whileInUse ||
            permission == LocationPermission.always) {
          currentPosition = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
            timeLimit: const Duration(seconds: 5),
          );
        }
      }
    } catch (_) {
      // 위치를 못 받아도 검색은 계속 진행한다.
    }

    final query = Uri.encodeComponent('$menu 맛집');
    final url = currentPosition != null
        ? Uri.parse(
            'https://m.map.kakao.com/scheme/search?q=$query&p=${currentPosition!.latitude},${currentPosition!.longitude}',
          )
        : Uri.parse('https://m.map.kakao.com/scheme/search?q=$query');

    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('지도 열기에 실패했습니다: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('오늘 뭐 먹지?'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            onPressed: _showFilterDialog,
            tooltip: '카테고리 필터',
          ),
          IconButton(
            icon: const Icon(Icons.edit_note_rounded),
            onPressed: _showManageMenuDialog,
            tooltip: '메뉴 관리',
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned(
            top: -90,
            right: -40,
            child: Container(
              width: 220,
              height: 220,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFFFFC28A), Color(0xFFFF8A5B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -110,
            left: -70,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFFDCC4).withValues(alpha: 0.55),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: const Color(0xFFFFB087),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '총 ${filteredMenus.length}개의 메뉴 대기 중',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF5C4A3D),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x22000000),
                            blurRadius: 20,
                            offset: Offset(0, 10),
                          ),
                        ],
                        border: Border.all(
                          color: const Color(0xFFFFD1B5),
                          width: 1.2,
                        ),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.auto_awesome_rounded,
                            size: 30,
                            color: Color(0xFFFF6B35),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Roulette Pick',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.3,
                              color: Color(0xFF2B2B2B),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Expanded(
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  height: 64,
                                  margin: const EdgeInsets.symmetric(horizontal: 8),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(18),
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0x33FF6B35),
                                        Color(0x1AFF9A62),
                                      ],
                                    ),
                                    border: Border.all(
                                      color: const Color(0xFFFF9E70),
                                      width: 1.4,
                                    ),
                                  ),
                                ),
                                ListWheelScrollView.useDelegate(
                                  controller: _scrollController,
                                  itemExtent: 60,
                                  perspective: 0.0035,
                                  diameterRatio: 1.8,
                                  physics: const FixedExtentScrollPhysics(),
                                  childDelegate: ListWheelChildLoopingListDelegate(
                                    children: filteredMenus.map((menu) {
                                      return Center(
                                        child: Text(
                                          menu.name,
                                          style: const TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF202020),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 58,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: isSpinning
                                    ? const LinearGradient(
                                        colors: [Color(0xFFBDBDBD), Color(0xFF9E9E9E)],
                                      )
                                    : const LinearGradient(
                                        colors: [Color(0xFFFF6B35), Color(0xFFFF8A5B)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: isSpinning
                                        ? Colors.transparent
                                        : const Color(0x44FF6B35),
                                    blurRadius: 16,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: isSpinning ? null : spinRoulette,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  disabledBackgroundColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                child: Text(
                                  isSpinning ? '돌아가는 중...' : '메뉴 추첨 시작! 🎯',
                                  style: const TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
