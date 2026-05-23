import 'package:flutter/material.dart';

class Customboutton extends StatelessWidget {
  final String titleBoutton;
  final void Function()? onPressed;
  const Customboutton({super.key, required this.titleBoutton, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return     MaterialButton(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              height: 50,
              color: Colors.orange,
              onPressed:onPressed,
              child: Text(
                titleBoutton,
                style: TextStyle(color: Colors.white),
              ),
            );;
  }
}