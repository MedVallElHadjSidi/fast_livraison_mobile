import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fast_livraison_mobile/components/CustomBoutton.dart';
import 'package:fast_livraison_mobile/components/CustomLoading.dart';
import 'package:fast_livraison_mobile/components/CustomtextformfieldAdd.dart';
import 'package:fast_livraison_mobile/notes/viewNote.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditNote extends StatefulWidget {
  final String? docid;
  final String? categorieId;
  final String? valueNote;
  const EditNote({super.key, this.docid, this.categorieId, this.valueNote});

  @override
  State<EditNote> createState() => _EditNoteState();
}

class _EditNoteState extends State<EditNote> {
  bool isLoading = false;
  GlobalKey<FormState> formKey = GlobalKey<FormState>();
  TextEditingController mycontrollerNote = TextEditingController();
  // Create a CollectionReference called users that references the firestore collection

  @override
  void initState() {
    // TODO: implement initState
    mycontrollerNote.text=widget.valueNote!;
    super.initState();
  }

 Future<void> EditNote() {
      CollectionReference categoriesCollection = FirebaseFirestore.instance.collection("categories")
  .doc(widget.categorieId).collection("note");
    // Call the user's CollectionReference to add a new user
    isLoading=true;
    setState(() {});
    return categoriesCollection
        .doc(widget.docid).update({
          'note': mycontrollerNote.text, // John Doe

        })
        .then((value) {
              isLoading=false;
    setState(() {});
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (context) => ViewNote(categorieId: widget.categorieId,)));
        })
        .catchError((error){            isLoading=false;
    setState(() {});});
  }

@override
  void dispose() {
    // TODO: implement dispose
    mycontrollerNote.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Add Note")),
      body: isLoading ? CustomLoading() : Form(
        key: formKey,
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: CustomtextformfieldAdd(
                hintText: "Note",
                mycontroller: mycontrollerNote,
                validator: (val) {
                  return "Please enter a Note";
                },
              ),
            ),
            Customboutton(
              titleBoutton: "Add",
              onPressed: () {
                EditNote();
              },
            ),
          ],
        ),
      ),
    );
  }
}
