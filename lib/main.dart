import 'package:flutter/material.dart';
import 'package:powerless_over_cars/screens/webview_tab.dart';

void main() {
  runApp(const PowerlessOverCarsApp());
}

class PowerlessOverCarsApp extends StatelessWidget {
  const PowerlessOverCarsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // ✅ Removes DEBUG banner
      title: 'Powerless Over Cars',
      theme: ThemeData(
        primaryColor: const Color(0xFF222732),
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

  final List<String> urls = [
    "https://powerlessovercars.com/app/",
    "https://powerlessovercars.com/app-car-clubs/",
    "https://powerlessovercars.com/app-car-shows/",
    "https://powerlessovercars.com/app-advertisers-and-sponsors/",
    "https://powerlessovercars.com/app-blog/",
  ];

  // ✅ Keep WebViews alive with IndexedStack
  late final List<Widget> _tabs = List.generate(
    urls.length,
    (i) => WebviewTab(
      key: WebviewTab.globalKeys[i],
      title: "Tab $i",
      url: urls[i],
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF222732), // ✅ Header background
        title: const Text(
          "POWERLESS OVER CARS",
          style: TextStyle(
            color: Color(0xFFeb761c), // ✅ Title color
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),

      // ✅ IndexedStack keeps each WebView alive → fast switching
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFFeb761c), // ✅ Orange selected item
        unselectedItemColor: Colors.grey, // Gray for unselected
        backgroundColor: const Color(0xFF222732), // ✅ Dark background
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.groups), label: "Car Clubs"),
          BottomNavigationBarItem(icon: Icon(Icons.event), label: "Car Shows"),
          BottomNavigationBarItem(icon: Icon(Icons.business), label: "Sponsors"),
          BottomNavigationBarItem(icon: Icon(Icons.article), label: "Blog"),
        ],
      ),
    );
  }
}
