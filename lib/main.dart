import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart';
import 'home_screen.dart';
import 'create_workout_screen.dart'; // Nouveau !

void main() {
  runApp(
    DevicePreview(
      enabled: true,
      builder: (context) => const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      useInheritedMediaQuery: true,
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      title: 'BasedFit',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomeScreen(),
      routes: {
        '/create-workout': (context) => const CreateWorkoutScreen(), // Navigation
      },
    );
  }
}
