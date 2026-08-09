import 'package:flutter/material.dart';

import 'screens/home_page.dart';

void main() {
  runApp(const FinTrackApp());
}

class FinTrackApp extends StatelessWidget {
  const FinTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      title: 'FinTrack',

      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
        ),

        useMaterial3: true,
      ),

      home: const HomePage(),
    );
  }
}