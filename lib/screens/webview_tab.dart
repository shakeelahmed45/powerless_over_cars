import 'dart:async';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class WebviewTab extends StatefulWidget {
  final String title;
  final String url;

  // ✅ globalKeys for back handling from main.dart
  static final List<GlobalKey<_WebviewTabState>> globalKeys = List.generate(
    5,
    (index) => GlobalKey<_WebviewTabState>(),
  );

  const WebviewTab({super.key, required this.title, required this.url});

  @override
  State<WebviewTab> createState() => _WebviewTabState();
}

class _WebviewTabState extends State<WebviewTab> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasInternet = true;
  StreamSubscription<List<ConnectivityResult>>? _connSub;

  @override
  void initState() {
    super.initState();

    // ✅ WebView controller setup with Hybrid Composition
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..enableZoom(false) // disable pinch zoom for smoother UX
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            setState(() => _isLoading = true);
          },
          onPageFinished: (_) {
            setState(() => _isLoading = false);
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));

    // ✅ Internet connectivity listener
    _connSub = Connectivity().onConnectivityChanged.listen((result) {
      final hasInternet = result.isNotEmpty && result.first != ConnectivityResult.none;
      setState(() {
        _hasInternet = hasInternet;
      });
    });
  }

  // ✅ Handle back button
  Future<bool> handleBackIntent() async {
    if (await _controller.canGoBack()) {
      await _controller.goBack();
      return true;
    }
    return false;
  }

  @override
  void dispose() {
    _connSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasInternet) {
      return const Center(
        child: Text(
          "No Internet Connection",
          style: TextStyle(fontSize: 16, color: Colors.black54),
        ),
      );
    }

    return Stack(
      children: [
        // ✅ Hybrid composition for faster rendering
        WebViewWidget(controller: _controller),
        if (_isLoading)
          const Center(
            child: CircularProgressIndicator(
              color: Color(0xFFeb761c), // brand orange loader
              strokeWidth: 3,
            ),
          ),
      ],
    );
  }
}
