import 'package:flutter/material.dart';
import 'package:ip_calculator/ip_calculator.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IP Calculator',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const IPCalculatorScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
