import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FilterFireStore extends StatefulWidget {
  const FilterFireStore({super.key});

  @override
  State<FilterFireStore> createState() => _FilterFireStoreState();
}

class _FilterFireStoreState extends State<FilterFireStore> {
  bool isLoading=true;
  List<QueryDocumentSnapshot> users=[];

  getDataUsers() async{

  QuerySnapshot querySnapshot=  await FirebaseFirestore.instance.collection("users").orderBy("age").get();
     isLoading=false;
  users.addAll(querySnapshot.docs);


  setState(() {
   
  });

  }

  @override
  void initState() {
    // TODO: implement initState
    getDataUsers();
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Filter FireStore"),
      ),
      body: isLoading? Center(child: CircularProgressIndicator(),) : Container(
        // padding: EdgeInsets.all(10),
        child: ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index){
            return InkWell(
              onTap: (){
DocumentReference documentReference = FirebaseFirestore.instance
  .collection('users')
  .doc(users[index].id);
   FirebaseFirestore.instance.runTransaction((transaction) async {
  // Get the document
  DocumentSnapshot snapshot = await transaction.get(documentReference);

  if (!snapshot.exists) {
    throw Exception("User does not exist!");
  }

  // Update the follower count based on the current count
  // Note: this could be done without a transaction
  // by updating the population using FieldValue.increment()

  var snapshotData = snapshot.data();
  if(snapshotData is Map<String, dynamic>){
    double currentFollowerCount = snapshotData['money'] ?? 0;
    double newMoney = currentFollowerCount + 100;
    
  // Perform an update on the document
  transaction.update(documentReference, {'money': newMoney});


    
    }


})
.then((value){
  print("Follower count updated to $value");
  Navigator.push(context, MaterialPageRoute(builder: (context)=>FilterFireStore()));
})
.catchError((error) => print("Failed to update user money: $error"));
              },
              child: Card(
                child: ListTile(
              
                  title: Text(users[index]['username']),
                  subtitle: Text(users[index]['age'].toString()),
                  trailing: Text('${users[index]['money'].toString()} MRU' , style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red[400]),)
                  ,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}