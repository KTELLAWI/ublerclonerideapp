// ignore_for_file: prefer_const_literals_to_create_immutables, prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:restart_app/restart_app.dart';

class InfoDialog extends StatefulWidget {
  const InfoDialog({super.key});

  @override
  State<InfoDialog> createState() => _InfoDialogState();
}

class _InfoDialogState extends State<InfoDialog> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      backgroundColor: Colors.black,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(6),),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: SingleChildScrollView(
                  child: Column(
                children: [
                  const SizedBox(
                    height: 12,
                  ),
                  Text(
                    "No Driver Available ",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color:Colors.white,
                    ),
                  ),
                  SizedBox(height: 27),
                  Text(
                    "NO driver found in The nearby location , please try again shortly",
                    style:TextStyle(color:Colors.white70,),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 32),
                  SizedBox(
                    width: 202,
                    child: ElevatedButton(
                      style:ElevatedButton.styleFrom(
                        backgroundColor:Colors.amber
                      ),
                      child: Text('OK'),
                      onPressed: () {
                        Navigator.pop(context);
                            Restart.restartApp();

                      },
                    ),
                  ),
                  SizedBox(height: 27),
                ],
              )),
            )),
      
    );
  }
}
