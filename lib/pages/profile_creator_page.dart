import 'package:flutter/material.dart';

class ProfileCreatorPage extends StatefulWidget {
  const ProfileCreatorPage({super.key});

  @override
  State<ProfileCreatorPage> createState() => _ProfileCreatorPageState();
}

class _ProfileCreatorPageState extends State<ProfileCreatorPage> {
  final TextEditingController _controllerName = TextEditingController();
  final TextEditingController _controllerSurname = TextEditingController();
  final TextEditingController _controllerDateOfBirth = TextEditingController();

  Widget _entryField(String title, TextEditingController controller) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(labelText: title),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: double.infinity,
        width: double.infinity,
        padding: const EdgeInsets.all(40),
        child: Column(
          children: <Widget>[
            _entryField("Name", _controllerName),
            _entryField("Surname", _controllerSurname),
            _entryField("Date of Birth", _controllerDateOfBirth),
          ]
        ),
      ),
    );
  }
}