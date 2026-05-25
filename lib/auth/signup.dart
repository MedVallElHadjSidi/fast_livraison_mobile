import 'package:fast_livraison_mobile/components/CustomBoutton.dart';
import 'package:fast_livraison_mobile/components/CustomTextFormField.dart';
import 'package:fast_livraison_mobile/components/customLogoAuth.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  GlobalKey<FormState> formKey = GlobalKey<FormState>();
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
                    "Username",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Container(height: 10),
                  Customtextformfield(
                    hintText: "Entre Votre Username",
                    mycontroller: myUsernamecontroller,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Ce champ est obligatoire";
                      }
                    },
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
                  Container(height: 10),
                  InkWell(
                    onTap: () => {
                      Navigator.pushReplacementNamed(context, "login"),
                    },
                    child: Center(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: "S'avez-vous un compte ? "),

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
            Customboutton(
              titleBoutton: "S'inscrire",
              onPressed: () async {
                // 1. Fermer le clavier
                FocusScope.of(context).unfocus();
                await Future.delayed(Duration(milliseconds: 150));

                // 2. Valider les champs
                // if (myUsernamecontroller.text.isEmpty ||
                //     myEmailcontroller.text.isEmpty ||
                //     myPasswordcontroller.text.isEmpty) {
                //   ScaffoldMessenger.of(context).showSnackBar(
                //     SnackBar(content: Text("Veuillez remplir tous les champs")),
                //   );
                //   // return;
                // }

                // 3. Appel Firebase
                if (formKey.currentState!.validate()) {
                  try {
                    final credential = await FirebaseAuth.instance
                        .createUserWithEmailAndPassword(
                          email: myEmailcontroller.text.trim(),
                          password: myPasswordcontroller.text.trim(),
                        );

                    // 4. Sauvegarder le username
                    await credential.user?.updateDisplayName(
                      myUsernamecontroller.text.trim(),
                    );

                    credential.user?.sendEmailVerification();
                    Navigator.of(context).pushReplacementNamed("login");
                  } on FirebaseAuthException catch (e) {
                    String message = "Une erreur est survenue";
                    if (e.code == 'weak-password') {
                      message = "Mot de passe trop faible (min. 6 caractères)";
                    } else if (e.code == 'email-already-in-use') {
                      message = "Cet email est déjà utilisé";
                    } else if (e.code == 'invalid-email') {
                      message = "Email invalide";
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(message),
                        backgroundColor: Colors.red,
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Erreur : $e"),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
