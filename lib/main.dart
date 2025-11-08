import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Initialize OneSignal
  OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
  OneSignal.initialize("5e5292d9-22cc-4c81-bb11-b208477a42b2");
  OneSignal.Notifications.requestPermission(true);

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
        scaffoldBackgroundColor: const Color(0xFF022135),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF222732),
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Color(0xFFeb761c),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
          iconTheme: IconThemeData(color: Color(0xFFeb761c)),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          selectedItemColor: Color(0xFFeb761c),
          unselectedItemColor: Colors.white54,
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
  int _currentIndex = 0;
  bool _isLoading = true;

  // ✅ Website URLs for tabs
  final List<Map<String, String>> _tabs = [
    {"title": "Home", "url": "https://powerlessovercars.com/app/"},
    {"title": "Car Shows", "url": "https://powerlessovercars.com/app-car-shows/"},
    {"title": "Car Clubs", "url": "https://powerlessovercars.com/app-car-clubs/"},
    {"title": "Advertisers", "url": "https://powerlessovercars.com/app-advertisers-and-sponsors/"},
    {"title": "Blog", "url": "https://powerlessovercars.com/app-blog/"},
  ];

  final List<WebViewController> _controllers = [];

  @override
  void initState() {
    super.initState();
    for (var tab in _tabs) {
      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (_) => setState(() => _isLoading = true),
            onPageFinished: (_) => setState(() => _isLoading = false),
          ),
        )
        ..loadRequest(Uri.parse(tab["url"]!));
      _controllers.add(controller);
    }
  }

  // ✅ Pull-to-refresh logic
  Future<void> _onRefresh() async {
    await _controllers[_currentIndex].reload();
  }

  // ✅ Handle Android/iOS back button
  Future<bool> _handleBackButton() async {
    final controller = _controllers[_currentIndex];
    final canGoBack = await controller.canGoBack();
    if (canGoBack) {
      await controller.goBack();
      return false; // Stay inside the app
    }
    if (_currentIndex != 0) {
      setState(() => _currentIndex = 0); // Go back to main (Home) tab
      return false;
    }
    return true; // Exit app if already on Home and no history
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _handleBackButton, // ✅ added back button handler
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Powerless Over Cars"), // ✅ fixed title
        ),
        body: SafeArea(
          child: Stack(
            children: [
              RefreshIndicator(
                onRefresh: _onRefresh,
                color: const Color(0xFFeb761c),
                backgroundColor: const Color(0xFF022135),
                child: WebViewWidget(controller: _controllers[_currentIndex]),
              ),
              if (_isLoading)
                Container(
                  color: const Color(0xFF022135),
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        RotationTransitionSpinner(),
                        SizedBox(height: 20),
                        Text(
                          'Loading...',
                          style: TextStyle(
                            color: Color(0xFFeb761c),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
            BottomNavigationBarItem(icon: Icon(Icons.event), label: "Car Shows"),
            BottomNavigationBarItem(icon: Icon(Icons.group), label: "Car Clubs"),
            BottomNavigationBarItem(icon: Icon(Icons.business), label: "Advertisers"),
            BottomNavigationBarItem(icon: Icon(Icons.article), label: "Blog"),
          ],
        ),
      ),
    );
  }
}

// ✅ Custom loading spinner with rotating car icon
class RotationTransitionSpinner extends StatefulWidget {
  const RotationTransitionSpinner({super.key});

  @override
  State<RotationTransitionSpinner> createState() => _RotationTransitionSpinnerState();
}

class _RotationTransitionSpinnerState extends State<RotationTransitionSpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: const Icon(
        Icons.directions_car,
        size: 64,
        color: Color(0xFFeb761c),
      ),
    );
  }
}
