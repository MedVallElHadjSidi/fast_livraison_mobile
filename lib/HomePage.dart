import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fast_livraison_mobile/categories/editCategories.dart';
import 'package:fast_livraison_mobile/components/CustomLoading.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
List<QueryDocumentSnapshot> categories=[];
bool isLoading=true;

getDataCategories() async{
  QuerySnapshot querySnapshot=  await FirebaseFirestore.instance.collection("categories").where('userid', isEqualTo:  FirebaseAuth.instance.currentUser!.uid).get();
     isLoading=false;
  categories.addAll(querySnapshot.docs);


  setState(() {
   
  });
}

@override
  void initState() {
    // TODO: implement initState
    getDataCategories();
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
    
        backgroundColor: Colors.orange,
        onPressed: (){
          Navigator.of(context).pushNamed("add-categorie");
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
                "login",
                (route) => false,
              );
            },
            icon: Icon(Icons.logout),
          ),
        ],
        
      ),

      body: isLoading ? CustomLoading() : GridView.builder(
        itemCount: categories.length,
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
                        btnCancelText: "No",
                        btnOkText: "Edit",
                        btnCancelOnPress: (){},
                        btnOkOnPress: () async {
                          Navigator.of(context).push(MaterialPageRoute(builder: (context)=>EditCategorie(docsId: categories[item].id,oldName: categories[item]['name'],)));

                          // await FirebaseFirestore.instance.collection("categories").doc(categories[item].id).delete();
                          // Navigator.of(context).pushNamedAndRemoveUntil("home", (route) => false);
                        }
                      ).show();


              },
              child: Card(
              child: Container(
                child: Column(
                  children: [
                    Image.asset("images/folder.jpg", height: 100),
                    Text('${categories[item]['name']}'),
                  ],
                ),
              ),
                        ),
            );

        } 
      
         
        ,
      ),
    );
  }
}
