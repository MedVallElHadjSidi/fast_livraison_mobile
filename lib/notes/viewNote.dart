import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fast_livraison_mobile/categories/editCategories.dart';
import 'package:fast_livraison_mobile/components/CustomLoading.dart';
import 'package:fast_livraison_mobile/notes/addNote.dart';
import 'package:fast_livraison_mobile/notes/editNote.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ViewNote extends StatefulWidget {
  final String? categorieId;
  const ViewNote({super.key, required this.categorieId});

  @override
  State<ViewNote> createState() => _ViewNoteState();
}

class _ViewNoteState extends State<ViewNote> {
List<QueryDocumentSnapshot> notes=[];
bool isLoading=true;

getDataNotes() async{
  QuerySnapshot querySnapshot=  await FirebaseFirestore.instance.collection("categories").doc(widget.categorieId).collection("note").get();
     isLoading=false;
  notes.addAll(querySnapshot.docs);


  setState(() {
   
  });
}

@override
  void initState() {
    // TODO: implement initState
    getDataNotes();
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
    
        backgroundColor: Colors.orange,
        onPressed: (){
          // Navigator.of(context).pushNamed("add-categorie");
          Navigator.of(context).push(MaterialPageRoute(builder: (context)=>AddNote(docid: widget.categorieId,)));
        },
      child: Icon(Icons.add, color: Colors.white,),
      
      ),
      appBar: AppBar(
        title: Text("Home Page"),
        actions: [
          IconButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushNamedAndRemoveUntil(
                context,
                "login-phone",
                (route) => false,
              );
            },
            icon: Icon(Icons.logout),
          ),
        ],
        
      ),

      body: WillPopScope(
        onWillPop: () async {
          Navigator.of(context).pushNamedAndRemoveUntil("home", (route) => false);
          return false;
        },
        child: isLoading ? CustomLoading() : GridView.builder(
        itemCount: notes.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisExtent: 200,
        ),
        itemBuilder:(context,item){
            return   InkWell(
              onLongPress: (){
                      AwesomeDialog(
                        context: context,
                        dialogType: DialogType.warning,
                        animType: AnimType.rightSlide,
                        title: 'Suppression',
                        desc: 'Vous etes sur a supprimer ce categories?.',

                        btnCancelOnPress: (){},
                        btnOkOnPress: () async {
                              FirebaseFirestore.instance.collection("categories")
  .doc(widget.categorieId).collection("note").doc(notes[item].id).delete();
                          Navigator.of(context).push(MaterialPageRoute(builder: (context)=>ViewNote(categorieId: widget.categorieId,)));

                          // await FirebaseFirestore.instance.collection("categories").doc(categories[item].id).delete();
                          // Navigator.of(context).pushNamedAndRemoveUntil("home", (route) => false);
                        }
                      ).show();
              },
              onTap:(){
                Navigator.of(context).push(MaterialPageRoute(builder: (context)=>EditNote(
                  docid: notes[item].id,
                  categorieId: widget.categorieId,
                  valueNote: notes[item]['note']
                )));
                
              },
              child: Card(
              child: Container(
                child: Column(
                  children: [
                    // Image.asset("images/folder.jpg", height: 100),
                    Text('${notes[item]['note']}'),
                  ],
                ),
              ),
                        ),
            );

        } 
      
         
        ,
      
        ),
      ),
    );
  }
}
