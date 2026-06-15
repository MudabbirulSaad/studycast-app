import 'package:flutter/material.dart';

class StudycastApp extends StatelessWidget {
  const StudycastApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'studyCast',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      home: const _BackendCoreHome(),
    );
  }
}

class _BackendCoreHome extends StatelessWidget {
  const _BackendCoreHome();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Center(child: Text('studyCast backend core ready')),
      ),
    );
  }
}
