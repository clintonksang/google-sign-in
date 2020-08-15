import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:chat_clone/Pages/HomePage.dart';
import 'package:chat_clone/Widgets/ProgressWidget.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  LoginScreen({Key key}) : super(key: key);
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  //instance
  final GoogleSignIn googleSignIn = GoogleSignIn();
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  SharedPreferences sharedPreferences;
  bool isLoggedIn = false;
  bool isLoading = false;
  FirebaseUser currentUser;

  @override
  void initState() {
    super.initState();
    isSignedIn();
  }

  void isSignedIn() async{
    this.setState(() {
      isLoggedIn = true;
    });

    SharedPreferences preferences = await SharedPreferences.getInstance();
    isLoggedIn= await googleSignIn.isSignedIn();
    if (isLoggedIn) {
      Navigator.push(context, MaterialPageRoute(builder: (context)=>HomeScreen(currentUserId: preferences.getString("id"))));


    } 
   this.setState(() { 
     isLoading=false;
   });

    
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Center(
                child: Text(
              'ChatApp',
              style: TextStyle(
                  fontSize: 60,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.bold),
            )),
            SizedBox(
              height: 10,
            ),
            GestureDetector(
              onTap: controlSignIn,
              child: Column(
                children: <Widget>[
                  Container(
                      width: 270,
                      height: 65,
                      decoration: BoxDecoration(
                          image: DecorationImage(
                              image: AssetImage(
                                  "assets/images/google_signin_button.png"),
                              fit: BoxFit.cover)),
                      child: Padding(
                          padding: EdgeInsets.all(1),
                          child: isLoading ? circularProgress() : Container())),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<Null> controlSignIn() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    this.setState(() {
      isLoading = true;
    });

    GoogleSignInAccount googleUser = await googleSignIn.signIn();
    GoogleSignInAuthentication googleAuthentication =
        await googleUser.authentication;

    final AuthCredential credential = GoogleAuthProvider.getCredential(
      idToken: googleAuthentication.idToken,
      accessToken: googleAuthentication.accessToken,
    );
    FirebaseUser firebaseUser =
        (await firebaseAuth.signInWithCredential(credential)).user;

    if (firebaseUser != null) {
      //SignIn sucess

      // Check if user is Signed Up
      final QuerySnapshot resultQuery = await Firestore.instance
          .collection('users')
          .where("id", isEqualTo: firebaseUser.uid)
          .getDocuments();
      final List<DocumentSnapshot> documentSnapshots = resultQuery.documents;

      //save users data in Firestore db
      if (documentSnapshots.length == 0) {
        Firestore.instance
            .collection("users")
            .document(firebaseUser.uid)
            .setData({
          "nickname": firebaseUser.displayName,
          "photoURL": firebaseUser.photoUrl,
          "id": firebaseUser.uid,
          "aboutMe": "I love Flutter",
          "createdAt": DateTime.now().millisecondsSinceEpoch.toString(),
          "chattingWith": null,
        });

        //SharedPreferences write data to local
        currentUser = firebaseUser;
        await preferences.setString("id", currentUser.uid);
        await preferences.setString("nickname", currentUser.displayName);
        await preferences.setString("photoURL", currentUser.photoUrl);
      } else {
        //SharedPreferences write data to local
        currentUser = firebaseUser;
        await preferences.setString("id", documentSnapshots[0]["id"]);
        await preferences.setString(
            "nickname", documentSnapshots[0]["nickname"]);
        await preferences.setString(
            "photoURL", documentSnapshots[0]["photoURL"]);
        await preferences.setString("aboutMe", documentSnapshots[0]["aboutMe"]);
      }
      Fluttertoast.showToast(msg: 'Congrats Sign In Successful');
      this.setState(() {
        isLoading = false;
      });
      Navigator.push(context, MaterialPageRoute(builder: (context)=>HomeScreen(currentUserId: firebaseUser.uid)));
    } else {
      // SignIn FAILED
      Fluttertoast.showToast(msg: 'Try , Again, Sign In Failed');
      this.setState(() {
        isLoading = false;
      });
    }
  }
}
