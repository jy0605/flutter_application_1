import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';

class ResultDialog extends StatefulWidget {
  final String menu;

  const ResultDialog({super.key, required this.menu});

  @override
  State<ResultDialog> createState() => _ResultDialogState();
}

class _ResultDialogState extends State<ResultDialog> {
  late final WebViewController _controller;
  final GlobalKey _globalKey = GlobalKey(); // 캡처를 위한 키
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => _isLoading = false);
          },
        ),
      )
      ..loadRequest(
        Uri.parse(
          'https://m.youtube.com/results?search_query=${Uri.encodeComponent("${widget.menu} 맛집 short")}',
        ),
      );
  }

  Future<void> _searchNearBy() async {
    Position? currentPosition;
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      currentPosition = await Geolocator.getCurrentPosition();
    } catch (_) {}

    final query = Uri.encodeComponent('${widget.menu} 맛집');
    final url = currentPosition != null
        ? Uri.parse(
            'https://m.map.kakao.com/scheme/search?q=$query&p=${currentPosition.latitude},${currentPosition.longitude}',
          )
        : Uri.parse('https://m.map.kakao.com/scheme/search?q=$query');

    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> _captureAndShare() async {
    try {
      // 1. 화면 캡처
      RenderRepaintBoundary boundary =
          _globalKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0); // 고화질 캡처
      ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      // 2. 파일로 저장
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/lunch_result.png');
      await file.writeAsBytes(pngBytes);

      // 3. 이미지와 텍스트 공유
      await Share.shareXFiles(
        [XFile(file.path)],
        text:
            '오늘 메뉴는 [${widget.menu}]! 같이 먹자 🍽️\n\n👇 앱 다운로드\nhttps://play.google.com/store/apps/details?id=com.example.lunchmenu',
      );
    } catch (e) {
      debugPrint('Capture failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent, // 배경을 투명하게 하고 내부에서 그리기 (캡처 위해)
      insetPadding: const EdgeInsets.all(16),
      elevation: 0,
      child: RepaintBoundary(
        key: _globalKey,
        child: Material(
          color: const Color(0xFFE6DABF),
          borderRadius: BorderRadius.circular(32),
          elevation: 10,
          shadowColor: Colors.black54,
          child: Container(
            height: MediaQuery.of(context).size.height * 0.75,
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Text(
                  '오늘의 픽! ${widget.menu}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E1E1E),
                  ),
                ),
                const SizedBox(height: 12),
                // 유튜브 쇼츠 웹뷰 영역
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      children: [
                        WebViewWidget(controller: _controller),
                        if (_isLoading)
                          const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFFFF6347),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // 버튼 영역
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _searchNearBy();
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: const Color(0xFFFF6347),
                    ),
                    child: const Text('🗺️ 내 주변 맛집 찾기'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _captureAndShare, // 캡처 및 공유 함수 연결
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: const Color(0xFFFEE500),
                      foregroundColor: Colors.black87,
                    ),
                    child: const Text('친구에게 공유하기 💬'),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    '다시하기',
                    style: TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
