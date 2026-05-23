import 'package:flutter/material.dart';

class Customtextformfield extends StatelessWidget {
  final String hintText;
  final TextEditingController mycontroller;
  const Customtextformfield({
    super.key,
    required this.hintText,
    required this.mycontroller,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: mycontroller,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        filled: true,
        fillColor: Colors.grey[200],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50),
          borderSide: BorderSide(
            color: const Color.fromARGB(255, 184, 184, 184),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50),
          borderSide: BorderSide(color: Colors.grey),
        ),
      ),
    );
    ;
  }
}
