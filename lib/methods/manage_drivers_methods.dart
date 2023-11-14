import 'package:ride_app/models/online_nearby_drivers.dart';

class ManageDriversMethods {
  static List<OnlineNearbyDrivers> nearbyOnlineDriversList = [];

  static void removerDriverFromList(String driverID) {
    var index = nearbyOnlineDriversList
        .indexWhere((driver) => driver.uidDriver == driverID);
    if (nearbyOnlineDriversList.isNotEmpty) {
      nearbyOnlineDriversList.removeAt(index);
    }
  }

  static updateOnLineNearbyDriversLocation(
      OnlineNearbyDrivers onlineNearbyDriver) {
    var index = nearbyOnlineDriversList.indexWhere(
        (driver) => driver.uidDriver == onlineNearbyDriver.uidDriver);
    nearbyOnlineDriversList[index].latDriver = onlineNearbyDriver.latDriver;
    nearbyOnlineDriversList[index].lngDriver = onlineNearbyDriver.lngDriver;

  }


  
}
