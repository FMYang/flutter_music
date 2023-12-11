import 'package:flutter/material.dart';
import 'app_bar.dart';

class ListDetail extends StatelessWidget {
  final String index;

  const ListDetail({super.key, required this.index});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: const SharedAppBar(titleText: 'Detail'),
        body: ContentWidget(index: index));
  }
}

class ContentWidget extends StatelessWidget {
  final String index;
  const ContentWidget({super.key, required this.index});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
      },
      child: Container(
        color: Colors.white,
        child: Center(
            child: Text(index,
                style: const TextStyle(
                    color: Colors.black,
                    fontSize: 50,
                    fontWeight: FontWeight.normal,
                    decoration: TextDecoration.none))),
      ),
    );
  }
}
