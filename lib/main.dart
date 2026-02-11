import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 저장 기능
import 'package:share_plus/share_plus.dart'; // 공유 기능

import 'lunch_data.dart';
import 'youtube_shorts.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '점심 메뉴 추천 Pro',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true, // 최신 디자인 적용
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

  // 1. 메뉴 관리 변수들
  List<Menu> myMenus = []; // 현재 사용 중인 전체 메뉴
  List<Menu> filteredMenus = []; // 필터링된(실제 룰렛에 들어갈) 메뉴

  // 2. 카테고리 필터 (체크된 것만 룰렛에 포함)
  // 처음엔 모든 카테고리를 다 켜둡니다.
  Map<String, bool> categoryFilter = {
    '한식': true,
    '중식': true,
    '일식': true,
    '양식': true,
    '분식': true,
    '아시안': true,
    '간편식': true,
    '다이어트': true,
    '치킨': true,
  };

  @override
  void initState() {
    super.initState();
    _scrollController = FixedExtentScrollController();
    _loadMenuData(); // 저장된 메뉴 불러오기

    _accelerometerSubscription = accelerometerEvents.listen((
      AccelerometerEvent event,
    ) {
      double velocity = sqrt(
        pow(event.x, 2) + pow(event.y, 2) + pow(event.z, 2),
      );
      if (velocity > 20 && !isSpinning) {
        spinRoulette();
      }
    });
  }

  // 저장된 데이터 불러오기 (없으면 기본값 사용)
  Future<void> _loadMenuData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedMenus = prefs.getString('my_menus');

    setState(() {
      if (savedMenus != null) {
        // 저장된 게 있으면 불러오기
        List<dynamic> jsonList = jsonDecode(savedMenus);
        myMenus = jsonList.map((json) => Menu.fromJson(json)).toList();
      } else {
        // 없으면 기본 메뉴 사용
        myMenus = List.from(defaultMenus);
      }
      _applyFilter(); // 필터 적용
    });
  }

  // 메뉴 저장하기
  Future<void> _saveMenuData() async {
    final prefs = await SharedPreferences.getInstance();
    String jsonString = jsonEncode(myMenus.map((e) => e.toJson()).toList());
    await prefs.setString('my_menus', jsonString);
    _applyFilter();
  }

  // 필터 적용 함수 (룰렛용 리스트 새로고침)
  void _applyFilter() {
    setState(() {
      filteredMenus = myMenus.where((menu) {
        // 해당 카테고리가 켜져 있는지 확인 (없으면 기타 취급해서 true)
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
        const SnackBar(content: Text('선택된 메뉴가 없습니다! 필터를 확인해주세요.')),
      );
      return;
    }

    setState(() {
      isSpinning = true;
    });

    int randomItemIndex = Random().nextInt(filteredMenus.length);
    int targetIndex =
        _scrollController.selectedItem +
        (filteredMenus.length * 5) +
        randomItemIndex;

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
          int finalIndex = targetIndex % filteredMenus.length;
          _showResultDialog(filteredMenus[finalIndex].name);
        });
  }

  // ---------------- UI 관련 함수들 ----------------

  // 1. 필터 설정 팝업
  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          // 다이얼로그 안에서 상태 변경하려면 필요
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('못 먹는 음식 빼기 🚫'),
              content: SingleChildScrollView(
                child: Column(
                  children: categoryFilter.keys.map((key) {
                    return CheckboxListTile(
                      title: Text(key),
                      value: categoryFilter[key],
                      onChanged: (bool? value) {
                        setDialogState(() {
                          categoryFilter[key] = value!;
                        });
                        _applyFilter(); // 메인 화면에도 반영
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('완료'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // 2. 메뉴 관리 (추가/삭제) 팝업
  void _showManageMenuDialog() {
    TextEditingController nameController = TextEditingController();
    String selectedCategory = '한식'; // 기본 선택

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('나만의 메뉴 관리 📝'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 메뉴 추가 영역
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: nameController,
                            decoration: const InputDecoration(
                              hintText: '메뉴 이름',
                            ),
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
                              selectedCategory = newValue!;
                            });
                          },
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (nameController.text.isNotEmpty) {
                          setState(() {
                            myMenus.add(
                              Menu(
                                name: nameController.text,
                                category: selectedCategory,
                              ),
                            );
                            _saveMenuData(); // 저장
                          });
                          nameController.clear();
                          setDialogState(() {}); // 리스트 갱신
                        }
                      },
                      child: const Text('추가하기'),
                    ),
                    const Divider(),
                    // 메뉴 목록 영역 (삭제 기능)
                    Expanded(
                      child: ListView.builder(
                        itemCount: myMenus.length,
                        itemBuilder: (context, index) {
                          // 최신순으로 보여주기 위해 역순 접근
                          final menu = myMenus[myMenus.length - 1 - index];
                          return ListTile(
                            title: Text(menu.name),
                            subtitle: Text(menu.category),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  myMenus.remove(menu); // 원본에서 삭제
                                  _saveMenuData();
                                });
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Column(
          children: [
            Icon(Icons.restaurant_menu, color: Colors.orange, size: 50),
            SizedBox(height: 10),
            Text(
              '오늘의 메뉴 당첨!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          menu,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: Colors.deepOrange,
          ),
        ),
        actions: [
          // 공유하기 버튼 (NEW!)
          Center(
            child: ElevatedButton.icon(
              onPressed: () {
                // 카카오톡, 문자 등으로 공유
                Share.share('오늘 점심 메뉴는 [$menu] 어때? 🍽️ (점심 추천 앱에서 당첨됨!)');
              },
              icon: const Icon(Icons.share),
              label: const Text('친구에게 공유하기'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.yellow[700],
                foregroundColor: Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => YoutubeShortsPage(menu: menu),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text(
                  '쇼츠 보기 🎬',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _searchNearBy(menu);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                child: const Text(
                  '식당 찾기 🗺️',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('다시하기', style: TextStyle(color: Colors.grey)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _searchNearBy(String menu) async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    // ignore: unused_local_variable
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    final url = Uri.parse(
      'https://m.map.naver.com/search2/search.naver?query=${Uri.encodeComponent("$menu 맛집")}&sm=hty&style=v5',
    );

    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      print('지도 열기 실패: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('오늘 뭐 먹지?'),
        backgroundColor: Colors.orange,
        centerTitle: true,
        actions: [
          // 상단바에 설정 버튼 2개 추가
          IconButton(
            icon: const Icon(Icons.filter_list), // 필터 아이콘
            onPressed: _showFilterDialog,
            tooltip: '못 먹는 음식 제외',
          ),
          IconButton(
            icon: const Icon(Icons.edit_note), // 메뉴 관리 아이콘
            onPressed: _showManageMenuDialog,
            tooltip: '메뉴 추가/삭제',
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '총 ${filteredMenus.length}개의 메뉴 대기 중!',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 10),

            // 룰렛 부분
            SizedBox(
              height: 250,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    height: 60,
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.orange, width: 2),
                    ),
                  ),
                  ListWheelScrollView.useDelegate(
                    controller: _scrollController,
                    itemExtent: 60,
                    perspective: 0.005,
                    diameterRatio: 1.5,
                    physics: const FixedExtentScrollPhysics(),
                    childDelegate: ListWheelChildLoopingListDelegate(
                      children: filteredMenus.map((menu) {
                        return Center(
                          child: Text(
                            menu.name, // 메뉴 이름만 표시
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 50),
            ElevatedButton(
              onPressed: isSpinning ? null : spinRoulette,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 50,
                  vertical: 15,
                ),
                backgroundColor: isSpinning ? Colors.grey : Colors.deepOrange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text(
                isSpinning ? '돌아가는 중...' : '메뉴 추첨 시작! 🎲',
                style: const TextStyle(fontSize: 20, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
