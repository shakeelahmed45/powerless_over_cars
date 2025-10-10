import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

class WebviewTab extends StatefulWidget {
  final String title;
  final String url;

  static final List<GlobalKey> globalKeys =
      List.generate(5, (_) => GlobalKey());

  const WebviewTab({super.key, required this.title, required this.url});

  @override
  State<WebviewTab> createState() => _WebviewTabState();
}

class _WebviewTabState extends State<WebviewTab>
    with SingleTickerProviderStateMixin {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasInternet = true;

  StreamSubscription<InternetStatus>? _connSub;
  final List<String> _history = [];

  late final AnimationController _spinCtrl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
        ..repeat();
  late final Animation<double> _turns =
      Tween<double>(begin: 0, end: 1).animate(_spinCtrl);

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..enableZoom(false)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            setState(() => _isLoading = true);
          },
          onPageFinished: (_) async {
            setState(() => _isLoading = false);
            await _maybePushCurrentUrlToHistory();
          },
          onNavigationRequest: (request) {
            return NavigationDecision.navigate;
          },
          onWebResourceError: (_) {
            setState(() => _isLoading = false);
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));

    _initialConnectivityCheck();
    _listenConnectivity();
  }

  /// 🔍 Listen for internet connection changes
  void _listenConnectivity() {
    _connSub = InternetConnection().onStatusChange.listen((status) async {
      final connected = status == InternetStatus.connected;

      if (connected != _hasInternet) {
        setState(() => _hasInternet = connected);
      }

      // Only reload when connection is restored
      if (connected && mounted) {
        try {
          await Future.delayed(const Duration(seconds: 1)); // small delay for stability
          await _controller.reload();
        } catch (_) {}
      }
    });
  }

  /// 🔍 Check initial connection on startup
  Future<void> _initialConnectivityCheck() async {
    final connected = await InternetConnection().hasInternetAccess;
    setState(() => _hasInternet = connected);
  }

  /// ✅ Manage internal WebView history
  Future<void> _maybePushCurrentUrlToHistory() async {
    try {
      final cur = await _controller.currentUrl();
      if (cur == null) return;
      if (_history.isEmpty || _history.last != cur) {
        _history.add(cur);
        if (kDebugMode) {
          print('[webview] history push: $cur (len=${_history.length})');
        }
      }
    } catch (_) {}
  }

  /// ✅ Handle back button inside WebView
  Future<bool> handleBackIntent() async {
    try {
      if (await _controller.canGoBack()) {
        await _controller.goBack();
        return true;
      }

      if (_history.length > 1) {
        _history.removeLast();
        final prev = _history.isNotEmpty ? _history.last : widget.url;
        await _controller.loadRequest(Uri.parse(prev));
        return true;
      }
    } catch (_) {}
    return false;
  }

  /// ✅ Reload manually or pull-to-refresh
  Future<void> reloadPage() async {
    setState(() => _isLoading = true);
    try {
      await _controller.reload();
    } catch (_) {}
  }

  Future<void> _retryConnectivity() async {
    setState(() => _isLoading = true);
    await _initialConnectivityCheck();
    if (_hasInternet) {
      await _controller.loadRequest(Uri.parse(widget.url));
    }
  }

  @override
  void dispose() {
    _connSub?.cancel();
    _spinCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasInternet) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off, size: 64, color: Colors.black54),
              const SizedBox(height: 16),
              const Text(
                "Connection lost. Please connect your internet and tap Retry.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.black87),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFeb761c),
                  foregroundColor: Colors.white,
                ),
                onPressed: _retryConnectivity,
                child: const Text("Retry"),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: reloadPage,
      child: Stack(
        children: [
          ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height + 1,
                child: WebViewWidget(
                  controller: _controller,
                  gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                    Factory<OneSequenceGestureRecognizer>(
                        () => EagerGestureRecognizer()),
                  },
                ),
              ),
            ],
          ),
          if (_isLoading)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RotationTransition(
                    turns: _turns,
                    child: const Icon(
                      Icons.directions_car_rounded,
                      size: 56,
                      color: Color(0xFFeb761c),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text("Loading...", style: TextStyle(color: Colors.black54)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
