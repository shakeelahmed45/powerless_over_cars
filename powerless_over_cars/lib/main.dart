import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:powerless_over_cars/screens/webview_tab.dart';

void main() async {
  // Ensure Flutter engine & plugins are initialized before any plugin calls or runApp.
  WidgetsFlutterBinding.ensureInitialized();

  // Optional: lock orientation to portrait if desired (uncomment if you want)
  // await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // If you need to do any async initialization (e.g., shared_preferences, Firebase, etc.)
  // do it here and await it before runApp.
  // Example:
  // await someAsyncInitFunction();

  // On Android we sometimes set a specific WebView implementation - not required on iOS.
  // If you use e.g., SurfaceAndroidWebView for Android:
  // if (Platform.isAndroid) {
  //   WebView.platform = SurfaceAndroidWebView();
  // }

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
  // Use the Home (first) URL — app is now single fullscreen webview
  static const String homeUrl = "https://powerlessovercars.com/";

  // Use the provided global key (keeps compatibility with your other code)
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
