// ignore_for_file: prefer_const_constructors, unused_import, unused_element, unused_local_variable, unnecessary_brace_in_string_interps

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:ride_app/authenticatio/signup_screen.dart';
import 'package:ride_app/global/global_var.dart';
import 'package:ride_app/main.dart';
import 'package:ride_app/methods/main.dart';
import 'package:ride_app/pages/home_page.dart';
import 'package:ride_app/widgets/loading_dialog.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  Widget build(BuildContext context) {

    TextEditingController emailController = TextEditingController();
    TextEditingController passwordController = TextEditingController();
    CommonMethods cMethods = CommonMethods();

    registerUser() async {
      showDialog(
          context: context,
          builder: (BuildContext context) =>
              LoadingDialog(messageText: "logging to your account ......"));

      final User? userFirebase = (await FirebaseAuth.instance
              .signInWithEmailAndPassword(
                  email: emailController.text.trim(),
                  password: passwordController.text.trim())
              // ignore: body_might_complete_normally_catch_error
              .catchError((errorMessage) {
        Navigator.pop(context);
        cMethods.displaySnackBar(errorMessage.toString(), context);
      })
      )
          .user;

      if (!context.mounted) return;
      Navigator.pop(context);

      DatabaseReference userRef = FirebaseDatabase.instance
          .ref()
          .child("users")
          .child(userFirebase!.uid);

      userRef.once().then((snap) {
        if (snap.snapshot.value != null) {
          if ((snap.snapshot.value as Map)["blockStatus"] == "no") {
            userName = (snap.snapshot.value as Map)["name"];
            userPhone = (snap.snapshot.value as Map)["phone"];
            context.toNamed(HomePage());
            cMethods.displaySnackBar("Welcome ${userName}", context);
          } else {
            FirebaseAuth.instance.signOut();
            cMethods.displaySnackBar("Your are blocked", context);
          }
        } else {
          FirebaseAuth.instance.signOut();
          cMethods.displaySnackBar(
              "Your record donot exists as a User", context);
        }
      });
      context.toNamed(HomePage());
    }

    checkIfNetWorkAvailable() async {
      cMethods.checkConnectivity(context);

      if (!emailController.text.contains("@")) {
        cMethods.displaySnackBar("Email is not right ", context);
      } else {
        registerUser();
      }
    }

    return  Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(10),
          child: Column(children: [
            Image.asset(
              "assets/images/logo.png",
              width: 200,
              height: 200,
            ),
            Padding(
              padding: EdgeInsets.all(22),
              child: Column(children: [
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: "Email",
                    labelStyle: TextStyle(
                      fontSize: 14,
                    ),
                  ),
                  style: TextStyle(color: Colors.grey, fontSize: 15),
                ),
                SizedBox(
                  height: 22,
                ),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  keyboardType: TextInputType.text,
                  decoration: InputDecoration(
                    labelText: "Password",
                    labelStyle: TextStyle(
                      fontSize: 14,
                    ),
                  ),
                  style: TextStyle(color: Colors.grey, fontSize: 15),
                ),
                SizedBox(
                  height: 32,
                ),
                 SizedBox(
                  width: double.infinity,
                  child:
                ElevatedButton(
                    onPressed: () {
                      checkIfNetWorkAvailable();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      shape: ContinuousRectangleBorder(side: BorderSide.none,borderRadius:BorderRadius.circular(75)),
                      padding:
                          EdgeInsets.symmetric(horizontal: 0, vertical: 5),
                    ),
                    child: Text("Login",style: TextStyle(fontSize: 22,),))),
              ]),
            ),
             TextButton(
                onPressed: () {
                  context.toNamed(SignUpScreen());
                },
                child: Text(
                  "You dont have an account? Sign up here",
                  style: TextStyle(
                    decoration: TextDecoration.underline,
                    fontSize: 15,
                    color: Colors.grey,
                  ),
                ))
          ]),
        ),
      ),
    );
  }
  
}
