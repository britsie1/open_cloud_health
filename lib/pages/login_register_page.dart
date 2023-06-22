import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String? errorMessage = '';
  bool isLogin = true;

  final TextEditingController _controllerEmail = TextEditingController();
  final TextEditingController _controllerPassword = TextEditingController();
  final TextEditingController _controllerConfirmPassword = TextEditingController();

  Future<void> signInWithEmailAndPassword() async {
    try {
      await Auth().signInWithEmailAndPassword(
        email: _controllerEmail.text,
        password: _controllerPassword.text,
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        errorMessage = e.message;
      });
    }
  }

  Future<void> createUserWithEmailAndPassword() async {
    try {
      await Auth().createUserWithEmailAndPassword(
        email: _controllerEmail.text,
        password: _controllerPassword.text,
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        errorMessage = e.message;
      });
    }
  }

  Widget _title() {
    return Text(isLogin ? 'Login' : 'Register');
  }

  Widget _entryEmailField(String title, TextEditingController controller) {
    return TextField(
      keyboardType: TextInputType.emailAddress,
      controller: controller,
      decoration: InputDecoration(labelText: title),
    );
  }

  Widget _entryPasswordField(String title, TextEditingController controller, bool visible) {
    return Visibility(
      visible: visible,
      child: TextField(
        obscureText: true,
        enableSuggestions: false,
        autocorrect: false,
        controller: controller,
        decoration: InputDecoration(labelText: title),
      ),
    );
  }

  Widget _errorMessage() {
    return Text(errorMessage == '' ? '' : '$errorMessage');
  }

  Widget _submitButton() {
    return ElevatedButton(
      onPressed: (){
        if (isLogin)
        {
          signInWithEmailAndPassword();
        }
        else if (_controllerPassword.text == _controllerConfirmPassword.text)
        {
          createUserWithEmailAndPassword();
        }
        else {
          setState(() {
            errorMessage = 'Password missmatch';
          });
        }
      },
      child: Text(isLogin ? 'Login' : 'Register'),
    );
  }

  Widget _loginOrRegisterButton() {
    return TextButton(onPressed: (){
      setState(() {
        isLogin = !isLogin;
      });
    }, child: Text(isLogin ? 'Don\'t have an account? Register.' : 'Already have an account? Login.'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _title(),
      ),
      body: Container(
        height: double.infinity,
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _entryEmailField('Email', _controllerEmail),
            _entryPasswordField('Password', _controllerPassword, true),
            _entryPasswordField('Confirm Password', _controllerConfirmPassword, !isLogin),
            const SizedBox(
              height: 20,
            ),
            _errorMessage(),
            _submitButton(),
            _loginOrRegisterButton()
          ]),
      ),
    );
  }
}
