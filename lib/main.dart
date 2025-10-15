import 'dart:io';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:powerless_over_cars/screens/webview_tab.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Platform-specific WebView setup
  if (Platform.isAndroid) {
    WebViewPlatform.instance = SurfaceAndroidWebView();
  } else if (Platform.isIOS) {
    WebViewPlatform.instance = WebKitWebViewPlatform();
  }

  runApp(const PowerlessOverCarsApp());
}

class PowerlessOverCarsApp extends StatelessWidget {
  const PowerlessOverCarsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Powerless Over Cars',
      theme: ThemeData(
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF222732),
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Color(0xFFeb761c),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
          iconTheme: IconThemeData(color: Color(0xFFeb761c)),
          foregroundColor: Color(0xFFeb761c),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          selectedItemColor: Color(0xFFeb761c),
          unselectedItemColor: Colors.grey,
          backgroundColor: Color(0xFF222732),
          type: BottomNavigationBarType.fixed,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const String homeUrl = "https://powerlessovercars.com/app/";
  final GlobalKey _webKey = WebviewTab.globalKeys.isNotEmpty
      ? WebviewTab.globalKeys[0]
      : GlobalKey();

  Future<bool> _onWillPop() async {
    final dynamic state = _webKey.currentState;
    final handled = await (state?.handleBackIntent?.call() ?? Future.value(false)) as bool;
    return !handled;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: SafeArea(
          child: WebviewTab(
            key: _webKey,
            title: "Home",
            url: homeUrl,
          ),
        ),
      ),
    );
  }
}
