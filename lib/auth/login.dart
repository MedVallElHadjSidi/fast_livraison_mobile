import 'package:fast_livraison_mobile/components/CustomBoutton.dart';
import 'package:fast_livraison_mobile/components/CustomTextFormField.dart';
import 'package:fast_livraison_mobile/components/customLogoAuth.dart';
import 'package:flutter/material.dart';

class login extends StatefulWidget {
  const login({super.key});

  @override
  State<login> createState() => _loginState();
}

class _loginState extends State<login> {
  TextEditingController myEmailcontroller = TextEditingController();
  TextEditingController myPasswordcontroller = TextEditingController();
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
                  "Email",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Container(height: 10),

                Customtextformfield(hintText: "Entre Votre Email", mycontroller: myEmailcontroller),
    
                Container(height: 10),
                Text(
                  "Mot de passe",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Container(height: 10),
                      Customtextformfield(hintText: "Entre Votre Mot de passe", mycontroller: myPasswordcontroller),
    

                Container(
                  margin: EdgeInsets.only(top: 10, bottom: 20),
                  alignment: Alignment.centerRight,
                  child: Text(
                    "Mot de passe Oublier ?",
                    textAlign: TextAlign.right,
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),

        Customboutton(titleBoutton: "Login", onPressed: ()=>{

      
        },),
            Container(height: 20),
            MaterialButton(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              height: 50,
              color: Colors.red[700],
              onPressed: () => {},
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Se Connecter", style: TextStyle(color: Colors.white)),
                  Image.asset("images/logo_google.png", width: 40),
                ],
              ),
            ),
            Container(height: 20),
            InkWell(
              onTap: () => {
                    Navigator.pushNamed(context, "singup")
              },
              child: Center(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: "Vous n'avez pas un compte "),

                      TextSpan(
                        text: "S'inscrire ",

                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
