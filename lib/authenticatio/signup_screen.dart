// ignore_for_file: prefer_const_constructors, unused_local_variable

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:ride_app/authenticatio/login_screen.dart';
import 'package:ride_app/main.dart';
import 'package:ride_app/methods/main.dart';
import 'package:ride_app/pages/home_page.dart';
import 'package:ride_app/widgets/loading_dialog.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  @override
  Widget build(BuildContext context) {
    TextEditingController nameController = TextEditingController();
    TextEditingController emailController = TextEditingController();
    TextEditingController passwordController = TextEditingController();
    CommonMethods cMethods = CommonMethods();

     registerUser() async {
      showDialog(
          context: context,
          builder: (BuildContext context) =>
              LoadingDialog(messageText: "Registering your Accoutn......"));

      final User? userFirebase = (await FirebaseAuth.instance
              .createUserWithEmailAndPassword(
                  email: emailController.text.trim(),
                  password: passwordController.text.trim())
              // ignore: body_might_complete_normally_catch_error
              .catchError((errorMessage) {
        Navigator.pop(context);
        cMethods.displaySnackBar(errorMessage.toString(), context);
      }))
          .user;

      if (!context.mounted) return;
      Navigator.pop(context);

      DatabaseReference userRef = FirebaseDatabase.instance
          .ref()
          .child("users")
          .child(userFirebase!.uid);

      Map userDataMap = {
        "name": nameController.text.trim(),
        "email": emailController.text.trim(),
        "id": userFirebase.uid,
        "blockStatus": "no",
        "phone":"00905355130437",
      };
      userRef.set(userDataMap);
      context.toNamed(HomePage());
    }

    checkIfNetWorkAvailable() async {
      cMethods.checkConnectivity(context);

      if (nameController.text.trim().length < 4) {
        cMethods.displaySnackBar("name is not right ", context);
      } else if (!emailController.text.contains("@")) {
        cMethods.displaySnackBar("Email is not right ", context);
      } else 
      {
        registerUser();
      }

      //register with firebase
    }

   

    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(10),
          child: Column(children: [
            Image.asset(
              "assets/images/logo.png",
              width: 200,
              height: 200,
            ),
            Text("Create a  Rider Account",style: TextStyle(fontSize: 22),),
            Padding(
              padding: EdgeInsets.all(22),
              child: Column(children: [
                TextField(
                  controller: nameController,
                  keyboardType: TextInputType.name,
                  decoration: InputDecoration(
                    labelText: "User Name",
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
                  child: ElevatedButton(
                      onPressed: () {
                        checkIfNetWorkAvailable();
                      },
                      style: ElevatedButton.styleFrom(
                        shape: ContinuousRectangleBorder(
                            side: BorderSide.none,
                            borderRadius: BorderRadius.circular(75)),
                        backgroundColor: Colors.amber,
                        padding:
                            EdgeInsets.symmetric(horizontal: 0, vertical: 5),
                      ),
                      child: Text(
                        "SignUp",
                        style: TextStyle(fontSize: 22),
                      )),
                ),
              ]),
            ),
           
            TextButton(
                onPressed: () {
                  context.toNamed(LoginScreen());
                },
                child:Text(
                  "Already have an account? Login here",
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
