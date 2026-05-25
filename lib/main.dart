import 'package:fast_livraison_mobile/HomePage.dart';
import 'package:fast_livraison_mobile/auth/login.dart';
import 'package:fast_livraison_mobile/auth/signup.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:fast_livraison_mobile/geolocations/Mygeo.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';

void main() async {
    WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
  );
    await GoogleSignIn.instance.initialize(
  serverClientId: "1028398623935-1il9pgsk4hituur6tejmth87ase5p47d.apps.googleusercontent.com",
    );
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // This widget is the root of your application.

  @override
  void initState() {
    // TODO: implement initState
    FirebaseAuth.instance
  .authStateChanges()
  .listen((User? user) {
    if (user == null) {
      print('User is currently signed out!');
    } else {
      print('User is signed in!');
    }
  });
    super.initState();

  }
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: (FirebaseAuth.instance.currentUser !=null  && FirebaseAuth.instance.currentUser !.emailVerified  ) ? Homepage(): login(),
      routes: {
        "singup": (context) => Signup(),
        "home": (context) => Homepage(),
        "login": (context) => login(),
        // "geo": (context) => Mygeo(),
      },
    );
  }
}




