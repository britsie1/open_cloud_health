import 'package:firebase_auth/firebase_auth.dart';
import 'package:open_cloud_health/auth.dart';
import 'package:flutter/material.dart';
import 'package:open_cloud_health/pages/shared_app_bar.dart';
import './drawer.dart';
import 'package:open_cloud_health/main.dart';
import 'package:open_cloud_health/pages/medical_history_page.dart';

class HomePage extends StatelessWidget {
  HomePage({super.key});

  final User? user = Auth().currentUser;

  Future<void> signOut() async {
    await Auth().signOut();
  }

  Widget _title() {
    return const Text('OpenCloudHealth');
  }

  Widget _userUid() {
    return Text(user?.email ?? 'User email');
  }

  Widget _signOutButton() {
    return ElevatedButton(
      onPressed: signOut,
      child: const Text('Sign Out'),
    );
  }

  Widget _createProfileButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () => {
        Navigator.pushNamed(context, "/profile_creator")
      },
      child: const Text('Create Profile'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SharedAppBar(),
      drawer: const DrawerPage(),
      body: Container(
        height: double.infinity,
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _userUid(), 
            _signOutButton(),
            _createProfileButton(context),
          ],
        ),
      ),
    );
  }
}
