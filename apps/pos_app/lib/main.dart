import 'package:flutter/material.dart';

void main() {
  runApp(const PosApp());
}

class PosApp extends StatelessWidget {
  const PosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: Text('Tap Hoa POS'));
  }
}
