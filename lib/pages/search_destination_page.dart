// ignore_for_file: prefer_const_constructors, prefer_const_declarations, sized_box_for_whitespace, prefer_const_literals_to_create_immutables, avoid_unnecessary_containers, unused_local_variable, non_constant_identifier_names, prefer_interpolation_to_compose_strings, avoid_print

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ride_app/appInfo/app_info.dart';
import 'package:ride_app/methods/main.dart';
import 'package:ride_app/models/prediction_model.dart';
import 'package:ride_app/widgets/prediction_place.dart';

class SearchDestinationPage extends StatefulWidget {
  const SearchDestinationPage({super.key});

  @override
  State<SearchDestinationPage> createState() => _SearchDestinationPageState();
}

class _SearchDestinationPageState extends State<SearchDestinationPage> {
  TextEditingController pickUpEditingController = TextEditingController();
  TextEditingController destinationTextEditingController =
      TextEditingController();
  List<PredictionModel> dropOffPredictionsPlaceList = [];

  searchLocation(String LocationName) async {
    if (LocationName.length > 1) {
      String apiPlacesUrl =
          "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$LocationName&key=AIzaSyD4FMYsCgW55FY7JQiUkJEQKorrlXN8Ro8&components=country:tr";

      var response = await CommonMethods.sendRequestApi(apiPlacesUrl);
      if (response == 'error') {
        return;
      }
      if (response["status"] == 'OK') {
        var predictionResultsInJson = response['predictions'];
        var predictionsList = (predictionResultsInJson as List)
            .map((eachPlacePrediction) =>
                PredictionModel.fromJson(eachPlacePrediction))
            .toList();

        setState(() {
          dropOffPredictionsPlaceList = predictionsList;
        });
        print(
            "ddddddddddddddddddddddddddddddddddddfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff");
        print("Predictions................................" +
            predictionResultsInJson.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String userAddress = Provider.of<AppInfo>(context, listen: true)
            .pickUpLocation!
            .humanReadableAddress ??
        "";
    pickUpEditingController.text = userAddress;

    return SafeArea(
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          padding: const EdgeInsets.all(0.0),
          child: Column(
           // mainAxisAlignment: MainAxisAlignment.center,
           mainAxisSize: MainAxisSize.max,

            children: [
              RoundedBottomCard(
                child: Container(
                    width: double.infinity,
                    height: 200,
                    child: Container(
                      height: 200,
                      decoration:
                          BoxDecoration(color: Colors.amber, boxShadow: [
                        BoxShadow(
                            color: Colors.green,
                            blurRadius: 5,
                            spreadRadius: 0.5,
                            offset: Offset(0.7, 0.7))
                      ]),
                      child: Padding(
                          padding: EdgeInsets.only(
                              left: 24, top: 15, right: 24, bottom: 10),
                          child: Column(
                            children: [
                              SizedBox(
                                height: 2,
                              ),
                              Stack(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.pop(context);
                                    },
                                    child: Icon(
                                      Icons.arrow_back,
                                      color: Colors.black,
                                      size: 25,
                                    ),
                                  ),
                                  Center(
                                    child: Text(
                                      "Set DropOff Location",
                                      style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black),
                                    ),
                                  )
                                ],
                              ),
                              SizedBox(
                                height: 18,
                              ),
                              Row(children: [
                                // Image.asset(
                                //   'assets/images/logo.png',
                                //   width: 16,
                                //   height: 16,
                                // ),
                                const SizedBox(
                                  width: 5,
                                ),
                                Expanded(
                                    child: Container(
                                  decoration: BoxDecoration(
                                      //color:Colors.white,
                                      borderRadius: BorderRadius.circular(25)),
                                  child: Padding(
                                    padding: EdgeInsets.all(3),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(15.0),
                                      child: TextFormField(
                                        controller: pickUpEditingController,
                                        decoration: InputDecoration(
                                          labelText: 'From',
                                          labelStyle:
                                              TextStyle(color: Colors.white),
                                          border: InputBorder.none,

                                          prefixIcon: Icon(
                                            Icons.location_on,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                          hintText: "Pickup Address",
                                          filled: true,
                                          focusColor: Colors.black,
                                          fillColor: Colors.black87,
                                          isDense: true,
                                          // contentPadding: EdgeInsets.only(
                                          //     left: 11, top: 5, bottom: 5)
                                        ),
                                      ),
                                    ),
                                  ),
                                ))
                              ]),
                              SizedBox(
                                height: 5,
                              ),
                              Row(children: [
                                // Image.asset(
                                //   'assets/images/logo.png',
                                //   width: 16,
                                //   height: 16,
                                // ),
                                const SizedBox(
                                  width: 5,
                                ),
                                Expanded(
                                    child: Container(
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10)),
                                  child: Padding(
                                    padding: EdgeInsets.all(3),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(15.0),
                                      child: TextFormField(
                                        controller:
                                            destinationTextEditingController,
                                        onChanged: (value) {
                                          searchLocation(value);
                                        },
                                        decoration: InputDecoration(
                                            labelStyle:
                                                TextStyle(color: Colors.white),
                                            labelText: 'To',
                                            border: InputBorder.none,
                                            prefixIcon: Icon(
                                              Icons.location_on,
                                              color: Colors.white,
                                              size: 18,
                                            ),
                                            hintText: "Choose Destination",
                                            filled: true,
                                            fillColor: Colors.black87,
                                            isDense: true,
                                            contentPadding: EdgeInsets.only(
                                                left: 11, top: 9, bottom: 9)),
                                      ),
                                    ),
                                  ),
                                ))
                              ])
                            ],
                          )),
                    )),
              ),
              (dropOffPredictionsPlaceList.isNotEmpty)
                  ? Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      child: ListView.separated(
                        padding: EdgeInsets.all(0),
                        itemCount: dropOffPredictionsPlaceList.length,
                        shrinkWrap: true,
                        physics: const ClampingScrollPhysics(),                        itemBuilder: (context, index) {
                          return Card(
                            elevation: 3,
                            child: PredictionPlaceUI(predictionPlaceData: dropOffPredictionsPlaceList[index]),
                          );
                        },
                        separatorBuilder: (BuildContext context, index) =>
                            SizedBox(height: 2),
                      ),
                    )
                  : Container(),
            ],
          ),
        ),
      ),
    );
  }
}

class RoundedBottomCard extends StatelessWidget {
  final Widget child;

  RoundedBottomCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: RoundedCardClipper(),
      child: Card(
        shadowColor: Colors.white,

        elevation: 14, // Adjust the shadow intensity
        margin: EdgeInsets.all(0),
        color: Colors.amber.withOpacity(0.8),
        child: child,
      ),
    );
  }
}

class RoundedCardClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final radius = 75.0; // Adjust the curve radius

    path.lineTo(0, size.height - radius);
    path.quadraticBezierTo(0, size.height, radius, size.height);
    path.lineTo(size.width - radius, size.height);
    path.quadraticBezierTo(
        size.width, size.height, size.width, size.height - radius);
    path.lineTo(size.width, 0);

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    return false;
  }
}
