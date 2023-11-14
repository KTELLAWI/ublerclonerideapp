import 'package:flutter/material.dart';
import 'package:ride_app/models/address_model.dart';

class AppInfo extends ChangeNotifier {
  AddressModel? pickUpLocation;
  AddressModel? dropOffLocation;

  void updatePickUpLocation(AddressModel pickupModel) {
    pickUpLocation = pickupModel;
    notifyListeners();
  }
   void updateDropOffLocation(AddressModel dropOffModel) {
    dropOffLocation = dropOffModel;
    notifyListeners();
  }

 

}



