import 'package:flutter/material.dart';

class CustomLoading extends StatelessWidget {
  const CustomLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return  Center(child: 
        Image.asset("images/fast_tossel_animated.gif", fit: BoxFit.cover),
        
    
      );
  }
}