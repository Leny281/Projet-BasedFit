import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'home_screen.dart';
import 'auth_screen.dart';
import 'programme_creation/create_workout_screen.dart';
import 'services/auth_service.dart';
import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Initialiser le service d'authentification
  await AuthService().init();

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
    final authService = AuthService();

    return MaterialApp(
      useInheritedMediaQuery: true,
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      title: 'BasedFit',
      theme: ThemeData(primarySwatch: Colors.blue),
      // Afficher AuthScreen si non connecté, sinon HomeScreen
      home: authService.isLoggedIn ? const HomeScreen() : const AuthScreen(),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fr', 'FR'),
      ],
      routes: {
        '/create-workout': (context) => const CreateWorkoutScreen(),
        '/home': (context) => const HomeScreen(),
        '/auth': (context) => const AuthScreen(),
      },
    );
  }
}
