import 'package:flutter/material.dart';

void main() => runApp(const CccdScannerApp());

class CccdScannerApp extends StatelessWidget {
  const CccdScannerApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'CCCD Scanner',
      home: Scaffold(body: Center(child: Text('CCCD Scanner'))),
    );
  }
}
