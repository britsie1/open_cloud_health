import 'package:flutter/material.dart';

class SharedAppBar extends StatelessWidget implements PreferredSizeWidget {
  const SharedAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
        title: const Text("Open Cloud Health"),
        centerTitle: true,
        actions: <Widget>[
          IconButton(
              onPressed: () {
                debugPrint('user');
              },
              icon: const Icon(Icons.person))
        ],
      );
  }
}