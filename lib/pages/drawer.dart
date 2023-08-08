import 'package:flutter/material.dart';

class DrawerPage extends StatelessWidget {
  const DrawerPage({super.key});

  navigateTo(String route, BuildContext context) {
    Navigator.of(context).pushReplacementNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          const SizedBox(
            height: 100.0,
            child: DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'OpenCloudHealth',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () {
              navigateTo("/home", context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.medical_information),
            title: const Text('Medical Information'),
            onTap: () {
              navigateTo("/medical_information", context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Medical History'),
            onTap: () {
              navigateTo("/medical_history", context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.timeline),
            title: const Text('Trackers'),
            onTap: () {
              navigateTo("/trackers", context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.star),
            title: const Text('Badges'),
            onTap: () {
              navigateTo("/badges", context);
            },
          ),
          const AboutListTile(
            icon: Icon(Icons.info),
            applicationIcon: Icon(Icons.local_play),
            applicationName: 'OpenCloudHealth',
            applicationVersion: '1.0.0',
            applicationLegalese: '© 2023 Company',
            child: Text('About'),
          )
        ],
      ),
    );
  }
}
