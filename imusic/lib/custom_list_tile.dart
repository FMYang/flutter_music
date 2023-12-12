import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CustomListTile extends StatelessWidget {
  final String img;
  final String name;
  final String author;
  final bool isSelected;

  const CustomListTile(
      {super.key,
      required this.img,
      required this.name,
      required this.author,
      required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return ListTileTheme(
      dense: true,
      contentPadding: EdgeInsets.zero,
      child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          // decoration: const BoxDecoration(
          //   border: Border(
          //       bottom: BorderSide(
          //     color: Colors.grey,
          //     width: 0.0,
          //   )),
          // ),
          child: Container(
            color: isSelected
                ? const Color(0x11EBEFFF).withOpacity(0.4)
                : Colors.white,
            child: Row(
              children: [
                Container(
                    // decoration: BoxDecoration(
                    //   color: Colors.grey,
                    //   borderRadius: BorderRadius.circular(8.0),
                    // ),
                    margin: const EdgeInsets.only(left: 15),
                    width: 50,
                    height: 50,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: CachedNetworkImage(
                          width: 54,
                          height: 54,
                          imageUrl: img,
                          placeholder: (context, url) {
                            return Image.asset(
                                'assets/images/svg_kg_playpage__album_default_01@3x.png');
                          }),
                    )),
                const SizedBox(width: 10.0),
                Expanded(
                  child: Column(children: [
                    Container(
                        // color: Colors.white,
                        height: 25,
                        alignment: Alignment.centerLeft,
                        margin: const EdgeInsets.only(left: 10, right: 10),
                        child: Text(name,
                            style: !isSelected
                                ? const TextStyle(
                                    fontSize: 16,
                                    color: Colors.black,
                                    fontWeight: FontWeight.normal,
                                  )
                                : const TextStyle(
                                    fontSize: 16,
                                    color: Color.fromARGB(255, 26, 174, 244),
                                    fontWeight: FontWeight.bold,
                                  ))),
                    const SizedBox(height: 4.0),
                    Container(
                        // color: Colors.white,
                        height: 25,
                        alignment: Alignment.centerLeft,
                        margin: const EdgeInsets.only(left: 10, right: 10),
                        child: Text(author,
                            style: !isSelected
                                ? const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black,
                                    fontWeight: FontWeight.normal,
                                  )
                                : const TextStyle(
                                    fontSize: 14,
                                    color: Color.fromARGB(255, 26, 174, 244),
                                    fontWeight: FontWeight.normal,
                                  ))),
                  ]),
                )
              ],
            ),
          )),
    );
  }
}
