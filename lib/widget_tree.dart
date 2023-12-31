import 'package:open_cloud_health/auth.dart';
import 'package:open_cloud_health/pages/home_page.dart';
import 'package:open_cloud_health/pages/login_register_page.dart';
import 'package:flutter/material.dart';

class WidgetTree extends StatefulWidget {
  const WidgetTree({super.key});

  @override
  State<WidgetTree> createState() => _WidgetTreeState();
}

class _WidgetTreeState extends State<WidgetTree> {
  Future<void> signOut() async {
    await Auth().signOut();
  }

  @override
  void dispose(){
    signOut();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: Auth().authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.hasData){
          return HomePage();
        }
        else {
          return const LoginPage();
        }
      },
    );
  }
}