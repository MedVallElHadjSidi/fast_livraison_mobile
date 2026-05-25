import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Home Page"),
        actions: [
          IconButton(
              onPressed: () async {
            
                await FirebaseAuth.instance.signOut();
                Navigator.pushNamedAndRemoveUntil(context, "login", (route) => false);
              },
              icon: Icon(Icons.logout))
        ],
      ),
      
      body: ListView(

        children : [
          FirebaseAuth.instance.currentUser!.emailVerified ? Text("Email Verifié") : MaterialButton(
            color: Colors.blue,
            textColor: Colors.white,
            onPressed: () async {
              print("------------Verification email sent--------------");
              await FirebaseAuth.instance.currentUser!.sendEmailVerification();
            },
            child: Text("Verifier votre email"),
          ),
        ]
      )
    );
  }
}