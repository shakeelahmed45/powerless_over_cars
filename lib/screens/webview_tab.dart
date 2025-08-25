import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class WebviewTab extends StatefulWidget {
  final String title;
  final String url;

  /// Keep using raw GlobalKey objects so other files don't need to reference private types.
  static final List<GlobalKey> globalKeys = List.generate(5, (_) => GlobalKey());

  const WebviewTab({super.key, required this.title, required this.url});

  @override
  State<WebviewTab> createState() => _WebviewTabState();
}

class _WebviewTabState extends State<WebviewTab>
    with SingleTickerProviderStateMixin {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasInternet = true;

  /// connectivity_plus emits Stream<List<ConnectivityResult>>
  StreamSubscription<List<ConnectivityResult>>? _connSub;

  // Local navigation history (fallback when native canGoBack() is false)
  final List<String> _history = [];

  // Car icon spinner
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

  void _listenConnectivity() {
    _connSub = Connectivity().onConnectivityChanged.listen((results) async {
      final connectedLayer1 =
          results.isNotEmpty && !results.contains(ConnectivityResult.none);
      await _updateInternetState(connectedLayer1);
      if (_hasInternet && mounted) {
        try {
          await _controller.reload();
        } catch (_) {}
      }
    });
  }

  Future<void> _initialConnectivityCheck() async {
    final res = await Connectivity().checkConnectivity();
    bool connected;
    if (res is List<ConnectivityResult>) {
      connected = res.any((e) => e != ConnectivityResult.none);
    } else if (res is ConnectivityResult) {
      connected = res != ConnectivityResult.none;
    } else {
      connected = true;
    }
    await _updateInternetState(connected);
  }

  Future<void> _updateInternetState(bool connectedLayer1) async {
    if (!connectedLayer1) {
      setState(() => _hasInternet = false);
      return;
    }
    try {
      final lookup =
          await InternetAddress.lookup('example.com').timeout(const Duration(seconds: 3));
      final ok = lookup.isNotEmpty && lookup.first.rawAddress.isNotEmpty;
      setState(() => _hasInternet = ok);
    } catch (_) {
      setState(() => _hasInternet = false);
    }
  }

  Future<void> _maybePushCurrentUrlToHistory() async {
    try {
      final cur = await _controller.currentUrl();
      if (cur == null) return;
      if (_history.isEmpty || _history.last != cur) {
        _history.add(cur);
        if (kDebugMode) {
          // ignore: avoid_print
          print('[webview] history push: $cur (len=${_history.length})');
        }
      }
    } catch (_) {
      // ignore
    }
  }

  /// Back button inside the WebView history
  /// returns true when handled (we went back inside WebView)
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
    } catch (_) {
      // ignore
    }
    return false;
  }

  /// Pull-to-refresh & external refresh button support
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
                "connection lost please connect your internet and retry button.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.black87),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFeb761c),
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

    // Use a single EagerGestureRecognizer factory to avoid duplicate-type assertion.
    return RefreshIndicator(
      onRefresh: reloadPage,
      child: Stack(
        children: [
          ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              // Add +1 px height to avoid "stuck at very end" edge cases
              SizedBox(
                height: MediaQuery.of(context).size.height + 1,
                child: WebViewWidget(
                  controller: _controller,
                  gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                    Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
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
