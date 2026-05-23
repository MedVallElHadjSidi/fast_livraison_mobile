import 'package:flutter/material.dart';

class Customlogoauth extends StatelessWidget {
  const Customlogoauth({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: EdgeInsets.only(top: 20),
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(70),
        ),
        width: 100,
        height: 100,
        child: Image.asset('images/fast_tossel.png', height: 80),
      ),
    );
    ;
  }
}
