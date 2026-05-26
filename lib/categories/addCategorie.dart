import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fast_livraison_mobile/components/CustomBoutton.dart';
import 'package:fast_livraison_mobile/components/CustomLoading.dart';
import 'package:fast_livraison_mobile/components/CustomtextformfieldAdd.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddCategorie extends StatefulWidget {
  const AddCategorie({super.key});

  @override
  State<AddCategorie> createState() => _AddCategorieState();
}

class _AddCategorieState extends State<AddCategorie> {
  bool isLoading = false;
  GlobalKey<FormState> formKey = GlobalKey<FormState>();
  TextEditingController mycontroller = TextEditingController();
  // Create a CollectionReference called users that references the firestore collection
  CollectionReference categories = FirebaseFirestore.instance.collection(
    'categories',
  );
  

  Future<void> addCategorie() {
    // Call the user's CollectionReference to add a new user
    isLoading=true;
    setState(() {});
    return categories
        .add({
          'name': mycontroller.text, // John Doe
          'userid':  FirebaseAuth.instance.currentUser!.uid, // Stokes and Sons
        })
        .then((value) {
              isLoading=false;
    setState(() {});
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil("home", (route) => false);
        })
        .catchError((error){            isLoading=false;
    setState(() {});});
  }

@override
  void dispose() {
    // TODO: implement dispose
    mycontroller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Add Categorie")),
      body: isLoading ? CustomLoading() : Form(
        key: formKey,
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: CustomtextformfieldAdd(
                hintText: "Categorie",
                mycontroller: mycontroller,
                validator: (val) {
                  return "Please enter a categorie";
                },
              ),
            ),
            Customboutton(
              titleBoutton: "Add",
              onPressed: () {
                addCategorie();
              },
            ),
          ],
        ),
      ),
    );
  }
}
