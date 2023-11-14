// ignore_for_file: must_be_immutable, avoid_unnecessary_containers, prefer_const_constructors, prefer_const_literals_to_create_immutables, unused_local_variable, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ride_app/appInfo/app_info.dart';
import 'package:ride_app/global/global_var.dart';
import 'package:ride_app/methods/main.dart';
import 'package:ride_app/models/address_model.dart';
import 'package:ride_app/models/prediction_model.dart';
import 'package:ride_app/widgets/loading_dialog.dart';

class PredictionPlaceUI extends StatefulWidget {
  PredictionModel? predictionPlaceData;
  PredictionPlaceUI({super.key, this.predictionPlaceData});

  @override
  State<PredictionPlaceUI> createState() => _PredictionPlaceUIState();
}

class _PredictionPlaceUIState extends State<PredictionPlaceUI> {
  fetchClickedPlaceDetail(String placeID) async {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => LoadingDialog(messageText: "Gettig details"));

    String iPlaceDetailsApi =
        "https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeID&key=$googleMapKey";
    var responseFromPlaceDetilasApi =
        await CommonMethods.sendRequestApi(iPlaceDetailsApi);
    Navigator.pop(context);

    if (responseFromPlaceDetilasApi == "error") {
      return;
    }

    if (responseFromPlaceDetilasApi['status'] == 'OK') {
      //print("object" + )
      AddressModel dropOffLocation = AddressModel();
      dropOffLocation.placeName = responseFromPlaceDetilasApi['result']['name'];
      dropOffLocation.latitudePosition =
          responseFromPlaceDetilasApi['result']['geometry']['location']['lat'];
      dropOffLocation.longitudePosition =
          responseFromPlaceDetilasApi['result']['geometry']['location']['lng'];
      dropOffLocation.placeId = placeID;

      Provider.of<AppInfo>(context, listen: false)
          .updateDropOffLocation(dropOffLocation);
      print("providerDatais" + dropOffLocation.placeName.toString());
      Navigator.pop(context, "placeSelected");
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
        onPressed: () {
          print(widget.predictionPlaceData!.place_id.toString());
          fetchClickedPlaceDetail(
              widget.predictionPlaceData!.place_id.toString());
        },
        style: ElevatedButton.styleFrom(backgroundColor: Colors.amberAccent),
        child: Container(
          child: Column(children: [
            const SizedBox(height: 7),
            Row(
              children: [
                const Icon(
                  Icons.share_location,
                  color: Colors.black,
                ),
                SizedBox(
                  width: 5,
                ),
                Expanded(
                    child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      widget.predictionPlaceData!.main_text.toString(),
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(
                      height: 3,
                    ),
                    Text(widget.predictionPlaceData!.Secondary_text.toString(),
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black,
                        ))
                  ],
                ))
              ],
            ),
            const SizedBox(height: 7),
          ]),
        ));
  }
}
