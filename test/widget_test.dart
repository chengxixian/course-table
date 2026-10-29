import 'package:flutter/material.dart';

void main() {
  runApp(const PlaceholderApp());
}

class PlaceholderApp extends StatelessWidget {
  const PlaceholderApp({super.key});
  @override
  Widget build(BuildContext context) => const MaterialApp(home: Scaffold(body: Center(child: Text('HSU'))));
}
