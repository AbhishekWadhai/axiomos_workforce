import 'package:axiomos_workforce/constants/colors.dart';
import 'package:flutter/material.dart';

class MyAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget title;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;

  const MyAppBar({super.key, required this.title, this.actions, this.bottom});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: IconButton(
        onPressed: () {
          Navigator.pop(context);
        },
        icon: const Icon(Icons.arrow_back_ios_rounded),
      ),
      title: title,
      actions: actions,
      bottom: bottom,
      elevation: 0,
      backgroundColor: Colors.transparent,

      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Colors.white],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              offset: const Offset(0, 4),
              blurRadius: 2,
              spreadRadius: 0.5,
            ),
          ],
        ),

        child: Stack(
          children: [
            /// Border Highlight
            Align(
              alignment: Alignment.topCenter,
              child: Container(height: 1, color: Colors.white.withOpacity(.25)),
            ),

            /// Bottom Shadow Line
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: 1,
                decoration: BoxDecoration(color: Colors.black.withOpacity(.25)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));
}
