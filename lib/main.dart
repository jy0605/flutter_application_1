import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:confetti/confetti.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'category_filter_dialog.dart';
import 'manage_menu_dialog.dart';
import 'rigging_dialog.dart';
import 'result_dialog.dart';
import 'lunch_data.dart';
import 'youtube_shorts.dart';
import 'splash_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // 여기에 const가 있으면 안 됩니다!
      title: '점심 메뉴 추천 Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF6347), // 토마토 레드
          surface: const Color(0xFFFFF8E1), // 크림색
          primary: const Color(0xFFFF6347),
        ),
        scaffoldBackgroundColor: const Color(0xFFFFF8E1), // 크림색 배경
        textTheme: GoogleFonts.notoSansKrTextTheme(),

        // 버튼 스타일
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF6347),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
        ),
        // 에러가 났던 cardTheme 부분은 삭제했습니다. (기본 디자인 사용)
      ),
      home: const SplashScreen(),
    );
  }
}

class MyAppContent extends StatefulWidget {
  const MyAppContent({super.key});

  @override
  State<MyAppContent> createState() => _MyAppContentState();
}

class _MyAppContentState extends State<MyAppContent> {
  @override
  Widget build(BuildContext context) {
    return const LunchRoulettePage();
  }
}

class LunchRoulettePage extends StatefulWidget {
  const LunchRoulettePage({super.key});

  @override
  State<LunchRoulettePage> createState() => _LunchRoulettePageState();
}

class _LunchRoulettePageState extends State<LunchRoulettePage>
    with TickerProviderStateMixin {
  late FixedExtentScrollController _scrollController;
  late AnimationController _blinkController;
  late Animation<double> _blinkAnimation;
  late ConfettiController _confettiController;
  StreamSubscription? _accelerometerSubscription;
  bool isSpinning = false;
  String? _fixedMenu; // 확률 조작(치트)을 위한 변수

  int _titleIndex = 1; // '점심'부터 시작
  Timer? _titleTimer;
  final List<String> _timeOptions = ['아침', '점심', '저녁', '간식', '야식'];

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

    // 텍스트 반짝임 효과를 위한 컨트롤러
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _blinkAnimation = Tween<double>(begin: 1.0, end: 0.3).animate(
      CurvedAnimation(parent: _blinkController, curve: Curves.easeInOut),
    );

    // 폭죽 컨트롤러 초기화
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );

    _loadMenuData();

    // 현재 시간에 맞춰 시작 인덱스 설정
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 11) {
      _titleIndex = 0; // 아침 (05:00 ~ 10:59)
    } else if (hour >= 11 && hour < 15) {
      _titleIndex = 1; // 점심 (11:00 ~ 14:59)
    } else if (hour >= 17 && hour < 21) {
      _titleIndex = 2; // 저녁 (17:00 ~ 20:59)
    } else if (hour >= 21 || hour < 5) {
      _titleIndex = 4; // 야식 (21:00 ~ 04:59)
    } else {
      _titleIndex = 3; // 간식 (15:00 ~ 16:59)
    }

    // 3초마다 상단 문구 변경 (아침 -> 점심 -> 저녁...)
    _titleTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        setState(() => _titleIndex = (_titleIndex + 1) % _timeOptions.length);
      }
    });

    _accelerometerSubscription = accelerometerEvents.listen((event) {
      final velocity = sqrt(
        pow(event.x, 2) + pow(event.y, 2) + pow(event.z, 2),
      );
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

      // 2. 카테고리 데이터 로드 (저장된 카테고리가 있으면 불러와서 덮어쓰기)
      final List<String>? savedCategories = prefs.getStringList(
        'my_categories',
      );
      if (savedCategories != null) {
        categoryFilter.clear(); // 기존 하드코딩 초기값 제거
        for (var category in savedCategories) {
          categoryFilter[category] = true;
        }
      }

      // 3. 메뉴에 있는 카테고리가 필터에 없으면 강제로 추가 (데이터 불일치 방지)
      for (var menu in myMenus) {
        if (!categoryFilter.containsKey(menu.category)) {
          categoryFilter[menu.category] = true;
        }
      }

      _applyFilter();
    });
  }

  Future<void> _saveMenuData() async {
    final prefs = await SharedPreferences.getInstance();

    // 메뉴 저장
    final jsonString = jsonEncode(myMenus.map((e) => e.toJson()).toList());
    await prefs.setString('my_menus', jsonString);

    // 카테고리 목록 저장 (키 값만 저장)
    await prefs.setStringList('my_categories', categoryFilter.keys.toList());

    _applyFilter();
  }

  void _applyFilter() {
    setState(() {
      filteredMenus = myMenus
          .where((menu) => categoryFilter[menu.category] ?? true)
          .toList();
    });
  }

  @override
  void dispose() {
    _blinkController.dispose();
    _confettiController.dispose();
    _titleTimer?.cancel();
    _accelerometerSubscription?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void spinRoulette() {
    if (isSpinning) return;
    if (filteredMenus.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('메뉴가 없어요! 필터를 확인해주세요.')));
      return;
    }

    // GIF가 처음부터 재생되도록 캐시에서 제거
    imageCache.evict(const AssetImage('assets/images/charactermove.gif'));

    setState(() => isSpinning = true);
    _blinkController.repeat(reverse: true); // 반짝임 시작

    int randomItemIndex = Random().nextInt(filteredMenus.length);

    // 확률 조작(치트)이 설정되어 있고, 해당 메뉴가 현재 리스트에 있다면
    if (_fixedMenu != null) {
      final fixedIndex = filteredMenus.indexWhere((m) => m.name == _fixedMenu);
      if (fixedIndex != -1) {
        randomItemIndex = fixedIndex;
      }
    }

    // 현재 룰렛 위치를 기준으로 목표까지의 거리 계산
    final currentItem = _scrollController.selectedItem;
    final currentCycleIndex = currentItem % filteredMenus.length;

    int distance = randomItemIndex - currentCycleIndex;
    if (distance <= 0) distance += filteredMenus.length; // 바로 앞이거나 같으면 한 바퀴 더

    final targetIndex = currentItem + (filteredMenus.length * 5) + distance;

    // 룰렛이 돌아가는 동안 진동 효과 주기 (다다다다...)
    Timer vibrationTimer = Timer.periodic(const Duration(milliseconds: 100), (
      timer,
    ) {
      HapticFeedback.lightImpact();
    });

    _scrollController
        .animateToItem(
          targetIndex,
          duration: const Duration(seconds: 3),
          curve: Curves.easeInOutCubic,
        )
        .then((_) {
          vibrationTimer.cancel(); // 진동 멈춤
          HapticFeedback.heavyImpact(); // 멈출 때 묵직한 진동
          HapticFeedback.heavyImpact(); // 2번 호출하여 더 강한 진동
          _blinkController.stop(); // 반짝임 멈춤
          _blinkController.reset(); // 원래대로 복구
          _confettiController.play(); // 폭죽 터뜨리기! 🎉
          if (!mounted) return; // 화면이 닫혀있으면 여기서 중단 (크래시 방지)
          setState(() {
            isSpinning = false;
            _fixedMenu = null; // 한 번 당첨되면 조작 초기화 (증거 인멸)
          });
          final finalIndex = targetIndex % filteredMenus.length;
          _showResultDialog(filteredMenus[finalIndex].name);
        });
  }

  void _showResultDialog(String menu) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ResultDialog(menu: menu),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  '오늘 ',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                SizedBox(
                  height: 20,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    layoutBuilder: (currentChild, previousChildren) {
                      return ClipRect(
                        child: Stack(
                          alignment: Alignment.centerLeft,
                          children: <Widget>[
                            ...previousChildren,
                            if (currentChild != null) currentChild,
                          ],
                        ),
                      );
                    },
                    transitionBuilder:
                        (Widget child, Animation<double> animation) {
                          // 위에서 아래로 떨어지는 효과
                          final inAnimation = Tween<Offset>(
                            begin: const Offset(0.0, -1.0),
                            end: const Offset(0.0, 0.0),
                          ).animate(animation);
                          final outAnimation = Tween<Offset>(
                            begin: const Offset(0.0, 1.0),
                            end: const Offset(0.0, 0.0),
                          ).animate(animation);

                          return SlideTransition(
                            position: (child.key == ValueKey<int>(_titleIndex))
                                ? inAnimation
                                : outAnimation,
                            child: child,
                          );
                        },
                    child: Text(
                      '${_timeOptions[_titleIndex]},',
                      key: ValueKey<int>(_titleIndex),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFFFF6347), // 토마토 레드로 변경
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const Text(
              '무엇을 먹을까요? 😋',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        actions: [
          // 확률 조작 버튼 (카테고리 필터 왼쪽)
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: const Color(0xFFE6DABF), blurRadius: 4),
                ],
              ),
              child: const Icon(
                Icons.auto_fix_high_rounded, // 요술봉 아이콘
                size: 20,
                color: Colors.black87,
              ),
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => RiggingDialog(
                  filteredMenus: filteredMenus,
                  onMenuSelected: (menuName) {
                    setState(() {
                      _fixedMenu = menuName;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('답은 정해져 있고 너는 [$menuName] 먹으면 돼! 😎'),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: const Color(0xFFFF6347),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        margin: EdgeInsets.only(
                          bottom: MediaQuery.of(context).size.height - 140,
                          left: 20,
                          right: 20,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: const Color(0xFFE6DABF), blurRadius: 4),
                ],
              ),
              child: const Icon(
                Icons.tune_rounded,
                size: 20,
                color: Colors.black87,
              ),
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => CategoryFilterDialog(
                  categoryFilter: categoryFilter,
                  onApplyFilter: _applyFilter,
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: const Color(0xFFE6DABF), blurRadius: 4),
                ],
              ),
              child: const Icon(
                Icons.edit_rounded,
                size: 20,
                color: Colors.black87,
              ),
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => ManageMenuDialog(
                  myMenus: myMenus,
                  categoryFilter: categoryFilter,
                  onSave: _saveMenuData,
                ),
              );
            },
          ),
          const SizedBox(width: 16),
        ],
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 80,
      ),
      body: Column(
        children: [
          // 폭죽 위젯 (화면 상단 중앙에서 터짐)
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive, // 사방으로 터짐
              shouldLoop: false,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple,
              ],
              createParticlePath: drawStar, // 별 모양 폭죽
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(24, 10, 24, 30), // 상단 여백을 줄임
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF6347).withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: 20),
                  Image.asset(
                    isSpinning
                        ? 'assets/images/charactermove.gif'
                        : 'assets/images/character.png',
                    height: 160,
                    gaplessPlayback: true,
                  ),
                  const SizedBox(height: 10),
                  FadeTransition(
                    opacity: _blinkAnimation,
                    child: const Text(
                      'M E O M E O K',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        color: Color(0xFFFF6347),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 250, // 입체감을 위해 높이를 조금 키움
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // 1. 룰렛 (스크롤 가능)
                        ListWheelScrollView.useDelegate(
                          controller: _scrollController,
                          itemExtent: 60,
                          perspective: 0.005, // 굴곡을 더 주어 입체감 UP
                          diameterRatio: 1.2, // 원통을 더 타이트하게
                          physics: const FixedExtentScrollPhysics(),
                          useMagnifier: true, // 돋보기 효과 활성화
                          magnification: 1.5, // 가운데 항목 1.5배 확대
                          overAndUnderCenterOpacity: 0.4, // 위아래 항목 흐리게 처리
                          childDelegate: ListWheelChildLoopingListDelegate(
                            children: filteredMenus.map((menu) {
                              return Center(
                                child: Text(
                                  menu.name,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900, // 더 두껍게 변경
                                    color: Color(0xFF333333),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        // 2. 위/아래 그라데이션 (원통형 입체감 효과)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: Column(
                              children: [
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.white,
                                          Colors.white.withOpacity(0.0),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 60), // 중앙 선택 영역 비우기
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.bottomCenter,
                                        end: Alignment.topCenter,
                                        colors: [
                                          Colors.white,
                                          Colors.white.withOpacity(0.0),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // 3. 중앙 선택 박스 (유리창 하이라이트 효과)
                        IgnorePointer(
                          child: Container(
                            height: 64,
                            width: double.infinity,
                            margin: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: Colors.transparent, // 배경색 제거
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFFF6347),
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.vibration, size: 16, color: Colors.grey[400]),
                      const SizedBox(width: 8),
                      Text(
                        '휴대폰을 흔들거나 버튼을 누르세요',
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 50), // 하단에 공간을 주어 전체 내용을 위로 올림
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
            child: Container(
              height: 60,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isSpinning
                      ? [Colors.grey.shade400, Colors.grey.shade500]
                      : [const Color(0xFFFF6347), const Color(0xFFFF4500)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: isSpinning
                        ? Colors.grey.withOpacity(0.4)
                        : const Color(0xFFFF6347).withOpacity(0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: isSpinning ? null : spinRoulette,
                  borderRadius: BorderRadius.circular(30),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (!isSpinning) ...[
                        const Icon(Icons.restaurant_menu, color: Colors.white),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        isSpinning ? '두근두근... 🎲' : '메뉴 추천 받기',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 별 모양 그리기 함수
  Path drawStar(Size size) {
    double degToRad(double deg) => deg * (pi / 180.0);
    const numberOfPoints = 5;
    final halfWidth = size.width / 2;
    final externalRadius = halfWidth;
    final internalRadius = halfWidth / 2.5;
    final degreesPerStep = degToRad(360 / numberOfPoints);
    final halfDegreesPerStep = degreesPerStep / 2;
    final path = Path();
    final fullAngle = degToRad(360);
    path.moveTo(size.width, halfWidth);
    for (double step = 0; step < fullAngle; step += degreesPerStep) {
      path.lineTo(
        halfWidth + externalRadius * cos(step),
        halfWidth + externalRadius * sin(step),
      );
      path.lineTo(
        halfWidth + internalRadius * cos(step + halfDegreesPerStep),
        halfWidth + internalRadius * sin(step + halfDegreesPerStep),
      );
    }
    path.close();
    return path;
  }
}
