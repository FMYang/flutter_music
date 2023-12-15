import 'package:flutter/material.dart';

// 共享导航栏
class SharedAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String titleText;
  const SharedAppBar({super.key, required this.titleText});

  @override
  Size get preferredSize => const Size.fromHeight(kMinInteractiveDimension);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        titleText,
        style: const TextStyle(color: Colors.black),
      ),
      centerTitle: true,
      // backgroundColor: Colors.white,
      elevation: 0,
    );
  }
}
