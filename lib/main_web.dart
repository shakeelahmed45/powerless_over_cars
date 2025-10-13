import 'package:flutter/material.dart';

void main() {
  runApp(const WebPreview());
}

class WebPreview extends StatelessWidget {
  const WebPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Powerless Over Cars (Preview)',
      home: const Scaffold(
        backgroundColor: Color(0xFF022135),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.car_repair, size: 72, color: Color(0xFFeb761c)),
                SizedBox(height: 16),
                Text(
                  'iOS/Android build only',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  'This is a web preview. The real app loads your site inside a secure in-app WebView on iOS and Android.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
