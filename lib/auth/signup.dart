import 'package:fast_livraison_mobile/components/CustomBoutton.dart';
import 'package:fast_livraison_mobile/components/CustomTextFormField.dart';
import 'package:fast_livraison_mobile/components/customLogoAuth.dart';
import 'package:flutter/material.dart';

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  TextEditingController myEmailcontroller = TextEditingController();
  TextEditingController myPasswordcontroller = TextEditingController();
  TextEditingController myUsernamecontroller = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: EdgeInsets.all(25),
        child: ListView(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 50),
                Customlogoauth(),

                Container(height: 30),
                Text(
                  "Se Connecter a FASTTOSSEL",
                  style: TextStyle(color: Colors.grey),
                ),
                Container(height: 20),
                Text(
                  "Username",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Container(height: 10),
                Customtextformfield(
                  hintText: "Entre Votre Username",
                  mycontroller: myEmailcontroller,
                ),
                Container(height: 10),
                Text(
                  "Email",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Container(height: 10),

                Customtextformfield(
                  hintText: "Entre Votre Email",
                  mycontroller: myEmailcontroller,
                ),

                Container(height: 10),
                Text(
                  "Mot de passe",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Container(height: 10),
                Customtextformfield(
                  hintText: "Entre Votre Mot de passe",
                  mycontroller: myPasswordcontroller,
                ),
                Container(height: 10),
              ],
            ),

            Customboutton(titleBoutton: "Login", onPressed: () => {}),
          ],
        ),
      ),
    );
  }
}
