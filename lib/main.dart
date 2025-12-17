import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:jazone_1/screens/home.dart';
import 'package:jazone_1/screens/splast_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Platform.isAndroid
      ? await Firebase.initializeApp(
          options: const FirebaseOptions(
            apiKey: "AIzaSyDmES7xivY4kGv9kppCLJxOhfHbj_iX3sQ",
            appId: "1:562766211236:android:661eaf41eb468bc14cde31",
            messagingSenderId: "562766211236",
            projectId: "jazonee-4765b",
            storageBucket: "jazonee-4765b.firebasestorage.app",
          ),
        )
      : await Firebase.initializeApp();
  await FirebaseAppCheck.instance.activate();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'JAzone',
      routes: {
        '/': (context) => const SplashScreen(child: HomePage()),
        '/home': (context) => const HomePage(),
      },
    );
  }
}
