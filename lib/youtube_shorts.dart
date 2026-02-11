// lib/youtube_shorts.dart

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class YoutubeShortsPage extends StatefulWidget {
  final String menu; // 메인 화면에서 전달받은 메뉴 이름

  const YoutubeShortsPage({super.key, required this.menu});

  @override
  State<YoutubeShortsPage> createState() => _YoutubeShortsPageState();
}

class _YoutubeShortsPageState extends State<YoutubeShortsPage> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();

    // 1. 웹뷰 컨트롤러 설정
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted) // 자바스크립트 허용 (유튜브 필수)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {},
          onPageFinished: (String url) {},
          onWebResourceError: (WebResourceError error) {},
        ),
      )
      // 2. 유튜브 검색 URL 로딩 (쇼츠 키워드 추가)
      ..loadRequest(
        Uri.parse(
          'https://m.youtube.com/results?search_query=${Uri.encodeComponent("${widget.menu} 먹방 shorts")}',
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.menu} 쇼츠 🎬'),
        backgroundColor: Colors.red, // 유튜브 느낌의 빨간색
        foregroundColor: Colors.white,
      ),
      // 3. 실제 웹 화면이 표시되는 곳
      body: WebViewWidget(controller: _controller),
    );
  }
}
