import 'package:flutter/material.dart';

// 共享导航栏
class SharedAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String titleText;
  final Widget? leading;
  const SharedAppBar({super.key, required this.titleText, this.leading});

  @override
  Size get preferredSize => const Size.fromHeight(kMinInteractiveDimension);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        titleText,
        style: const TextStyle(color: Colors.black),
      ),
      leading: leading,
      leadingWidth: 150,
      centerTitle: true,
      // backgroundColor: Colors.white,
      elevation: 0,
    );
  }
}
