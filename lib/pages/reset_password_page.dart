import 'package:flutter/material.dart';
import 'package:open_cloud_health/auth.dart';

class ResetPasswordPage extends StatelessWidget {
  const ResetPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController _controllerEmail = TextEditingController();

    return Scaffold(
      appBar: AppBar(),
      body: Container(
        height: double.infinity,
        width: double.infinity,
        padding: const EdgeInsets.all(40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              keyboardType: TextInputType.emailAddress,
              controller: _controllerEmail,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(
              height: 20,
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              onPressed: (){
                Auth().sendPasswordResetEmail(email: _controllerEmail.text);
              },
              child: const Text('Send Reset Email'),
            )
          ]     
        )
      )
    );
  }
}