// ignore_for_file: prefer_const_literals_to_create_immutables, prefer_const_constructors, must_be_immutable


import 'package:flutter/material.dart';
// import 'package:restart_app/restart_app.dart';
//import 'package:ride_app/methods/main.dart';

class PaymentDialog extends StatefulWidget {
  PaymentDialog({required this.fareAmout, super.key});

  String fareAmout;

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  ///CommonMethods commonMethods = CommonMethods();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      backgroundColor: Colors.black87,
      child: Container(
          margin: EdgeInsets.all(5),
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 21,
              ),
              Text("pay Cash",
                  style: TextStyle(
                    color: Colors.grey,
                  )),
              SizedBox(
                height: 21,
              ),
              Divider(
                height: 1.5,
                color: Colors.white70,
                thickness: 1.0,
              ),
              SizedBox(
                height: 16,
              ),
              Text(
                "\$${widget.fareAmout}",
                style: TextStyle(
                    color: Colors.grey,
                    fontSize: 36,
                    fontWeight: FontWeight.bold),
              ),
              SizedBox(
                height: 16,
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                    "this is fare Amout (\$${widget.fareAmout}) you have to pay to driver",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey,
                    )),
              ),
              SizedBox(
                height: 31,
              ),
              ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context,"paid");
                   
                    //Restart.restartApp();
                  },
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                  child: Text("Pay Cash")),
              SizedBox(
                height: 41,
              ),
            ],
          )),
    );
  }
}
