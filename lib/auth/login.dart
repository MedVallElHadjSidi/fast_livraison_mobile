import 'package:fast_livraison_mobile/components/CustomBoutton.dart';
import 'package:fast_livraison_mobile/components/CustomTextFormField.dart';
import 'package:fast_livraison_mobile/components/customLogoAuth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:google_sign_in/google_sign_in.dart';

class login extends StatefulWidget {
  const login({super.key});

  @override
  State<login> createState() => _loginState();
}

class _loginState extends State<login> {
  TextEditingController myEmailcontroller = TextEditingController();
  TextEditingController myPasswordcontroller = TextEditingController();
  GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // auth with google
  Future signInWithGoogle() async {
    try {
      final GoogleSignInAccount googleUser = await GoogleSignIn.instance
          .authenticate();

      if(googleUser == null) {
        print("L'utilisateur a annulé la connexion Google.");
        return; // Arrêtez la fonction si l'utilisateur annule la connexion
      }

      final googleAuth = googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      // ✅ context reçu en paramètre
      Navigator.of(context).pushNamedAndRemoveUntil("home", (route) => false);
    } on GoogleSignInException catch (e) {
      print("Erreur Google : ${e.code.name}");
    } catch (e) {
      print("Erreur : $e");
    }
  }

  // auth with google
  @override
  void initState() {
    // TODO: implement initState

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: EdgeInsets.all(25),
        child: ListView(
          physics:
              NeverScrollableScrollPhysics(), // ← arrête ListView d'intercepter
          shrinkWrap: true,
          children: [
            Form(
              key: formKey,
              child: Column(
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

                  Customtextformfield(
                    hintText: "Entre Votre Email",
                    mycontroller: myEmailcontroller,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Ce champ est obligatoire";
                      }
                    },
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
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Ce champ est obligatoire";
                      }
                    },
                  ),

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
            ),
            Customboutton(
              titleBoutton: "Login",
              onPressed: () async {
                print("-------------------login-------------------");
                if (formKey.currentState!.validate()) {
                  try {
                    final credential = await FirebaseAuth.instance
                        .signInWithEmailAndPassword(
                          email: myEmailcontroller.text,
                          password: myPasswordcontroller.text,
                        );
                    if (credential.user!.emailVerified) {
                      Navigator.of(context).pushReplacementNamed("home");
                    } else {
                      credential.user?.sendEmailVerification();
                      AwesomeDialog(
                        context: context,
                        dialogType:
                            DialogType.error, // success, error, warning, info
                        animType: AnimType.bottomSlide,
                        title: 'Email',
                        desc:
                            'Vous avez besoin de vérifier votre email pour se connecter !',
                      ).show();
                    }
                  } on FirebaseAuthException catch (e) {
                    if (e.code == 'user-not-found') {
                      // print('No user found for that email.');
                      AwesomeDialog(
                        context: context,
                        dialogType:
                            DialogType.error, // success, error, warning, info
                        animType: AnimType.bottomSlide,
                        title: 'Succès',
                        desc: 'Connexion réussie !',
                      ).show();
                    } else if (e.code == 'wrong-password') {
                      print('Wrong password provided for that user.');
                      AwesomeDialog(
                        context: context,
                        dialogType: DialogType.error,
                        animType: AnimType.rightSlide,
                        title: 'error Title',
                        desc: 'Wrong password provided for that user.',
                      ).show();
                    }
                  }
                }
              },
            ),

            Container(height: 20),
            MaterialButton(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              height: 50,
              color: Colors.red[700],
              onPressed: () {
                print("-------------------Google Sign In-------------------");
                signInWithGoogle();
              },
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
              onTap: () => {Navigator.pushReplacementNamed(context, "singup")},
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
