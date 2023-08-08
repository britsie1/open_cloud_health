import 'package:open_cloud_health/pages/badges_page.dart';
import 'package:open_cloud_health/pages/reset_password_page.dart';
import 'package:open_cloud_health/pages/home_page.dart';
import 'package:open_cloud_health/pages/medical_history_page.dart';
import 'package:open_cloud_health/pages/medical_information_page.dart';
import 'package:open_cloud_health/pages/profile_creator_page.dart';
import 'package:open_cloud_health/pages/trackers_page.dart';
import 'package:open_cloud_health/widget_tree.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      routes: <String, WidgetBuilder>{
        "/home": (BuildContext context) => HomePage(),
        "/medical_information": (BuildContext context) => const MedicalInformationPage(),
        "/medical_history": (BuildContext context) => const MedicalHistoryPage(),
        "/trackers": (BuildContext context) => const TrackersPage(),
        "/badges": (BuildContext context) => const BadgesPage(),
        "/profile_creator":(BuildContext context) => const ProfileCreatorPage(),
        "/reset_password":(BuildContext context) => const ResetPasswordPage(),
      },
      initialRoute: "/",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const WidgetTree(),
    );
  }
}