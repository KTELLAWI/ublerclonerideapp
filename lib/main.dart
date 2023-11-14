// ignore_for_file: prefer_const_constructors, avoid_print, unused_import

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:ride_app/appInfo/app_info.dart';
import 'package:ride_app/authenticatio/signup_screen.dart';
import 'package:ride_app/pages/home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  // var status = await Permission.camera.status;
  // if (status.isDenied) {

  //     print("camerrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrr");

  // }
  await Permission.locationWhenInUse.isDenied.then((valuOfPermissione) => {
        if (valuOfPermissione) {Permission.locationWhenInUse.request()}
      });
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AppInfo(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Flutter Demo',
        theme: ThemeData.dark().copyWith(scaffoldBackgroundColor: Colors.black),
        home: //const HomePage(),
            FirebaseAuth.instance.currentUser == null
                ? SignUpScreen()
                : HomePage(),
      ),
    );
  }
}

extension RouterContext on BuildContext {
  toNamed(routeName, {Object? args}) =>
      Navigator.push(this, MaterialPageRoute(builder: (e) => routeName));
}
