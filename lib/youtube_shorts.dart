import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:webview_flutter/webview_flutter.dart';

class YoutubeShortsPage extends StatefulWidget {
  final String menu;

  const YoutubeShortsPage({super.key, required this.menu});

  @override
  State<YoutubeShortsPage> createState() => _YoutubeShortsPageState();
}

class _YoutubeShortsPageState extends State<YoutubeShortsPage> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (!mounted) return;
            setState(() => _isLoading = true);
          },
          onPageFinished: (_) {
            if (!mounted) return;
            setState(() => _isLoading = false);
          },
        ),
      )
      ..loadRequest(
        Uri.parse(
          'https://m.youtube.com/results?search_query=${Uri.encodeComponent("${widget.menu} 맛집 shorts")}',
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.menu} 쇼츠 탐색',
          style: GoogleFonts.notoSansKr(fontWeight: FontWeight.w800),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            Container(
              color: Colors.white.withValues(alpha: 0.85),
              child: const Center(
                child: CircularProgressIndicator(color: Color(0xFFFF6B35)),
              ),
            ),
        ],
      ),
    );
  }
}
