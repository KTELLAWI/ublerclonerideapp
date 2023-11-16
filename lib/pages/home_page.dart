// ignore_for_file: prefer_const_constructors, unused_local_variable, unused_element, non_constant_identifier_names, avoid_unnecessary_containers, unnecessary_brace_in_string_interps, use_build_context_synchronously, sized_box_for_whitespace, prefer_interpolation_to_compose_strings, prefer_const_literals_to_create_immutables, avoid_print, prefer_collection_literals

import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_geofire/flutter_geofire.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';
import 'package:restart_app/restart_app.dart';
import 'package:ride_app/appInfo/app_info.dart';
import 'package:ride_app/authenticatio/login_screen.dart';
import 'package:ride_app/global/global_var.dart';
import 'package:ride_app/global/trip_var.dart';
import 'package:ride_app/main.dart';
import 'package:ride_app/methods/main.dart';
import 'package:ride_app/methods/manage_drivers_methods.dart';
import 'package:ride_app/methods/push_notification._service.dart';
import 'package:ride_app/models/direction_details.dart';
import 'package:ride_app/models/online_nearby_drivers.dart';
import 'package:ride_app/pages/search_destination_page.dart';
import 'package:ride_app/widgets/info_dialog.dart';
import 'package:ride_app/widgets/loading_dialog.dart';
import 'package:ride_app/widgets/payment_dialog.dart';
import 'package:url_launcher/url_launcher.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Completer<GoogleMapController> googleMapCompleterController =
      Completer<GoogleMapController>();
  GoogleMapController? controllerGoogleMap;
  Position? currentPositionOfUser;
  CommonMethods cMethods = CommonMethods();
  double searchContainerHeight = 276;
  double bottomPadding = 0;
  double rideDetialsContainerHeight = 0;
  double requestContainerHeight = 0;
  double tripContainerHeight = 0;
  DirectionDetails? tripDirectionDetails;
  List<LatLng> polyLineCoOrdinates = [];
  Set<Polyline> polylineSet = {};
  Set<Marker> markerSet = {};
  Set<Circle> circleSet = {};
  bool isDRawerOpen = true;
  String stateOfApp = "normal";
  bool nearbyOnlineDriverKeyLoaded = false;
  BitmapDescriptor? carIconNearbyDriver;
  DatabaseReference? tripRequestRef;
  List<OnlineNearbyDrivers> avilableNearbyOnlineDriversList = [];
  StreamSubscription<DatabaseEvent>? tripStreamSubscription;
  bool requestingDirectionDetailsInfo = false;

  makeDriverCarIcon() {
    if (carIconNearbyDriver == null) {
      ImageConfiguration configuration = createLocalImageConfiguration(
        context,
        size: Size(0.5, 0.5),
      );
      BitmapDescriptor.fromAssetImage(configuration, "assets/images/xx.png")
          .then((icon) {
        carIconNearbyDriver = icon;
      });
    }
  }

  GlobalKey<ScaffoldState> sKey = GlobalKey<ScaffoldState>();
  setGoogleMapStyle(String value, GoogleMapController controller) {
    controller.setMapStyle(value);
  }

  Future<String> getJsonFileFromThemes(String mapStylePath) async {
    ByteData byteData = await rootBundle.load(mapStylePath);
    var list = byteData.buffer
        .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);
    return utf8.decode(list);
  }

  void updateMapStyle(GoogleMapController controller) {
    getJsonFileFromThemes('lib/themes/night_style.json')
        .then((value) => setGoogleMapStyle(value, controller));
  }

  getCurrentLiveLocation() async {
    Position positionOfUser = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation);
    currentPositionOfUser = positionOfUser;
    LatLng positionOfUserInLatLang = LatLng(
        currentPositionOfUser!.latitude, currentPositionOfUser!.longitude);
    CameraPosition cameraPosition =
        CameraPosition(target: positionOfUserInLatLang, zoom: 15);
    controllerGoogleMap!
        .animateCamera(CameraUpdate.newCameraPosition(cameraPosition));

    await CommonMethods.convertGeoGraphicCoordinatesIntoHumanReadableAddress(
        currentPositionOfUser!, context);

    //await getUserInfoAndCheckedBlockStatus();
    await initializeGeoFireListner();
  }

  getUserInfoAndCheckedBlockStatus() async {
    DatabaseReference userRef = FirebaseDatabase.instance
        .ref()
        .child("users")
        .child(FirebaseAuth.instance.currentUser!.uid);

    await userRef.once().then((snap) {
      if (snap.snapshot.value != null) {
        if ((snap.snapshot.value as Map)["blockStatus"] == "no") {
          setState(() {
            userName = (snap.snapshot.value as Map)["name"];
            userPhone = (snap.snapshot.value as Map)["phone"];
          });

          //  context.toNamed(HomePage());
          // cMethods.displaySnackBar("Welcome ${userName}", context);
        } else {
          FirebaseAuth.instance.signOut();
          context.toNamed(LoginScreen());
          cMethods.displaySnackBar("Your are blocked", context);
        }
      } else {
        FirebaseAuth.instance.signOut();
        //cMethods.displaySnackBar("Your record donot exists as a User", context);
      }
    });
  }

  displayUserRideDetailsContainer() async {
    ////RetriveDirection
    await retriveDirectionDetails();
    setState(() {
      searchContainerHeight = 0;
      bottomPadding = 240;
      rideDetialsContainerHeight = 242;
      isDRawerOpen = false;
    });
  }

  retriveDirectionDetails() async {
    var pickUpLocation =
        Provider.of<AppInfo>(context, listen: false).pickUpLocation;
    var dropOffLocation =
        Provider.of<AppInfo>(context, listen: false).dropOffLocation;

    var pickupGeoCodingOrdinators = LatLng(
        pickUpLocation!.latitudePosition!, pickUpLocation.longitudePosition!);
    var dropoffGecodingOrdinators = LatLng(
        dropOffLocation!.latitudePosition!, dropOffLocation.longitudePosition!);

    showDialog(
        //context: context,
        barrierDismissible: false,
        context: context,
        builder: ((context) =>
            LoadingDialog(messageText: "Geting Directions...............")));
    print("start caluclating.........................................");
    var detailsDirectionFromApi =
        await CommonMethods.getDirectionDetailsFromApi(
            pickupGeoCodingOrdinators, dropoffGecodingOrdinators);
    setState(() {
      tripDirectionDetails = detailsDirectionFromApi;
    });

    PolylinePoints pointsPloyLine = PolylinePoints();
    List<PointLatLng> latlngPontsFromPickUpToDestination =
        pointsPloyLine.decodePolyline(tripDirectionDetails!.encodedPoints!);
    polyLineCoOrdinates.clear();
    latlngPontsFromPickUpToDestination.forEach((PointLatLng latLngPoint) {
      polyLineCoOrdinates
          .add(LatLng(latLngPoint.latitude, latLngPoint.longitude));
    });

    polylineSet.clear();
    setState(() {
      Polyline polyLine = Polyline(
        polylineId: const PolylineId("polyLineID"),
        color: Colors.amberAccent,
        points: polyLineCoOrdinates,
        jointType: JointType.round,
        width: 4,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        geodesic: true,
      );
      polylineSet.add(polyLine);
    });
    LatLngBounds boundlatLngBounds;
    if (pickupGeoCodingOrdinators.latitude >
            dropoffGecodingOrdinators.latitude &&
        pickupGeoCodingOrdinators.longitude >
            dropoffGecodingOrdinators.longitude) {
      boundlatLngBounds = LatLngBounds(
          southwest: dropoffGecodingOrdinators,
          northeast: pickupGeoCodingOrdinators);
    } else if (pickupGeoCodingOrdinators.longitude >
        dropoffGecodingOrdinators.longitude) {
      boundlatLngBounds = LatLngBounds(
          southwest: LatLng(pickupGeoCodingOrdinators.latitude,
              dropoffGecodingOrdinators.longitude),
          northeast: LatLng(dropoffGecodingOrdinators.latitude,
              pickupGeoCodingOrdinators.longitude));
    } else if (pickupGeoCodingOrdinators.latitude >
        dropoffGecodingOrdinators.latitude) {
      boundlatLngBounds = LatLngBounds(
          southwest: LatLng(dropoffGecodingOrdinators.latitude,
              pickupGeoCodingOrdinators.longitude),
          northeast: LatLng(pickupGeoCodingOrdinators.latitude,
              dropoffGecodingOrdinators.longitude));
    } else {
      boundlatLngBounds = LatLngBounds(
          southwest: pickupGeoCodingOrdinators,
          northeast: dropoffGecodingOrdinators);
    }

    controllerGoogleMap!
        .animateCamera(CameraUpdate.newLatLngBounds(boundlatLngBounds, 72));

    Marker pickUpPointMarker = Marker(
      markerId: const MarkerId("PickUpMarkerId"),
      position: pickupGeoCodingOrdinators,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      infoWindow:
          InfoWindow(title: pickUpLocation.placeName, snippet: 'Location'),
    );
    Marker dropOffPointMarker = Marker(
      markerId: const MarkerId("dropOffMarkerId"),
      position: dropoffGecodingOrdinators,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      infoWindow: InfoWindow(
          title: dropOffLocation.placeName, snippet: 'DestinationLocation'),
    );
    setState(() {
      markerSet.add(pickUpPointMarker);
      markerSet.add(dropOffPointMarker);
    });

    Circle pickPointCircle = Circle(
      circleId: const CircleId("pickUpCircleId"),
      strokeColor: Colors.pink,
      strokeWidth: 4,
      radius: 14,
      center: pickupGeoCodingOrdinators,
      fillColor: Colors.pink,
    );
    Circle droppPointCircle = Circle(
      circleId: const CircleId("dropOffCircleId"),
      strokeColor: Colors.blue,
      strokeWidth: 4,
      radius: 14,
      center: dropoffGecodingOrdinators,
      fillColor: Colors.pink,
    );
    setState(() {
      circleSet.add(pickPointCircle);
      circleSet.add(droppPointCircle);
    });

    Navigator.pop(context);
  }

  resetAppNow() {
    setState(() {
      polyLineCoOrdinates.clear();
      polylineSet.clear();
      markerSet.clear();
      circleSet.clear();
      rideDetialsContainerHeight = 0;
      requestContainerHeight = 0;
      tripContainerHeight = 0;
      searchContainerHeight = 276;
      bottomPadding = 300;
      isDRawerOpen = true;

      status = "";
      nameDriver = '';
      phoneNumberDriver = '';
      photoDriver = '';
      carDetailsDriver = '';
      tripStatusDriverDisplay = "Driver is Arrivig";
    });
  }

  displayReuestContainer() {
    setState(() {
      rideDetialsContainerHeight = 0;
      requestContainerHeight = 220;
      bottomPadding = 200;
      isDRawerOpen = true;
    });
    makeTripRequest();
  }

  makeTripRequest() {
    tripRequestRef =
        FirebaseDatabase.instance.ref().child('tripRequests').push();
 
    var pickLocation =
        Provider.of<AppInfo>(context, listen: false).pickUpLocation;
    var dropOffDestinationLocation =
        Provider.of<AppInfo>(context, listen: false).dropOffLocation;

    Map pickupCooredinatesMap = {
      "latitude": pickLocation!.latitudePosition.toString(),
      "longitude": pickLocation.longitudePosition.toString(),
    };

    Map dropOffDestinationCooredinatesMap = {
      "latitude":  dropOffDestinationLocation!.latitudePosition.toString(),
      "longitude": dropOffDestinationLocation.longitudePosition.toString(),
      
      
    };
    Map driverCoordinates = {
      "latitude": 0.0,
      "longitude": 0.0,
    };

    Map dataMap = {
      "tripID": tripRequestRef!.key,
      "publishDateTime": DateTime.now().toString(),
      "userName": userName,
      "userPhone": userPhone,
      "userID": userID,
      "pickuplatlng": pickupCooredinatesMap,
      "dropofflatlng": dropOffDestinationCooredinatesMap,
      "pickupAddress": pickLocation!.placeName ,
      "dropoffAddress": dropOffDestinationLocation!.placeName,
      "driverID": "waiting",
      "carDetails": "",
      "driverLocation": driverCoordinates,
      "driverName": "",
      "driverPhone": "",
      "driverPhot": "",
      "fareAmount": "",
      "status": "new",
    };

    tripRequestRef!.set(dataMap);
   tripStreamSubscription =
        tripRequestRef!.onValue.listen((eventSnapshot) async {
      if (eventSnapshot.snapshot.value == null) {
        return;
      }
      if ((eventSnapshot.snapshot.value as Map)['driverName'] != null) {
        nameDriver = (eventSnapshot.snapshot.value as Map)['driverName'];
      }
      if ((eventSnapshot.snapshot.value as Map)['driverPhoto'] != null) {
        photoDriver = (eventSnapshot.snapshot.value as Map)['driverPhoto'];
      }
      if ((eventSnapshot.snapshot.value as Map)['driverPhone'] != null) {
        phoneNumberDriver =
            (eventSnapshot.snapshot.value as Map)['driverPhone'];
      }
      if ((eventSnapshot.snapshot.value as Map)['carDetails'] != null) {
        carDetailsDriver = (eventSnapshot.snapshot.value as Map)['carDetails'];
      }
      if ((eventSnapshot.snapshot.value as Map)['status'] != null) {
        status = (eventSnapshot.snapshot.value as Map)['status'];
      }
      if ((eventSnapshot.snapshot.value as Map)['driverLocation'] != null) {
        double driverlatitude = double.parse(
            (eventSnapshot.snapshot.value as Map)['driverLocation']['latitude']
                .toString());
        double driverLongitud = double.parse(
            (eventSnapshot.snapshot.value as Map)['driverLocation']['longitude']
                .toString());
        LatLng driverCurrentLocation = LatLng(driverlatitude, driverLongitud);
        if (status == "accepted") {
          updtaeFrmDriverCurrentLocationToPickUp(driverCurrentLocation);
        } else if (status == "arrived") {
          setState(() {
            tripStatusDriverDisplay = "Driver has arrived";
          });
        } else if (status == "onTrip") {
          updtaeFrmDriverCurrentLocationToDropOffLocation(
              driverCurrentLocation);
        }
      }
      if (status == "accepted") {
        displayTripDetailsContainer();
        Geofire.stopListener();
        //removerDriverMarker
        setState(() {
          markerSet.removeWhere(
              (element) => element.markerId.value.contains("driver"));
        });
      }
      if (status == "ended") {
        if ((eventSnapshot.snapshot.value as Map)['fareAmount'] != null) {
          double fareAmount = double.parse(
              (eventSnapshot.snapshot.value as Map)['fareAmount'].toString());
          var responefromdialog = await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) =>
                PaymentDialog(fareAmout: fareAmount.toString()),
          );
          if (responefromdialog == 'paid') {
            tripRequestRef!.onDisconnect();
            tripRequestRef = null;
            tripStreamSubscription!.cancel();
            tripStreamSubscription = null;

            resetAppNow();
            Restart.restartApp();
          }
        }
      }
    });
  }

  displayTripDetailsContainer() {
    setState(() {
      requestContainerHeight = 0;
      tripContainerHeight = 291;
      bottomPadding = 281;
    });
  }

  updtaeFrmDriverCurrentLocationToPickUp(
      LatLng driverCurrentLocationLatLng) async {
    if (!requestingDirectionDetailsInfo) {
      requestingDirectionDetailsInfo = true;
      var userPickUpLoadingLatLng = LatLng(
          currentPositionOfUser!.latitude, currentPositionOfUser!.longitude);
      var directionDetailsPickUp =
          await CommonMethods.getDirectionDetailsFromApi(
              userPickUpLoadingLatLng, userPickUpLoadingLatLng);
      if (directionDetailsPickUp == null) {
        return;
      }
      setState(() {
        tripStatusDriverDisplay =
            "Driver Is Comming - ${directionDetailsPickUp.durationTextString} ";
      });
      requestingDirectionDetailsInfo = false;
    }
  }

  updtaeFrmDriverCurrentLocationToDropOffLocation(
      LatLng driverCurrentLocationLatLng) async {
    if (!requestingDirectionDetailsInfo) {
      requestingDirectionDetailsInfo = true;
      var userDropOffLocation = Provider.of<AppInfo>(context).dropOffLocation;
      var dropOffLocationLatLng = LatLng(userDropOffLocation!.latitudePosition!,
          userDropOffLocation.longitudePosition!);
      var directionDetailsPickUp =
          await CommonMethods.getDirectionDetailsFromApi(
              driverCurrentLocationLatLng, dropOffLocationLatLng);
      if (directionDetailsPickUp == null) {
        return;
      }
      setState(() {
        tripStatusDriverDisplay =
            "Drivering To Drop Off Destination - ${directionDetailsPickUp.durationTextString} ";
      });
      requestingDirectionDetailsInfo = false;
    }
  }

  cancelRideRequest() {
    setState(() {
      stateOfApp = 'normal';
    });
    tripRequestRef!.remove();
  }

  updateAvailableNearbyOnlineDriversOnMap() {
    setState(() {
      markerSet.clear();
    });

    Set<Marker> markerTempSet = Set<Marker>();
    for (OnlineNearbyDrivers eachonlineNearbyDrivers
        in ManageDriversMethods.nearbyOnlineDriversList) {
      LatLng driverCurrentPosition = LatLng(eachonlineNearbyDrivers.latDriver!,
          eachonlineNearbyDrivers.lngDriver!);
      Marker driverMarker = Marker(
        markerId: MarkerId(
            "driver Id" + eachonlineNearbyDrivers.uidDriver.toString()),
        position: driverCurrentPosition,
        icon: carIconNearbyDriver!,
      );

      markerTempSet.add(driverMarker);
    }

    setState(() {
      markerSet = markerTempSet;
    });
  }

  initializeGeoFireListner() {
    Geofire.initialize("onlineDrivers");
    Geofire.queryAtLocation(currentPositionOfUser!.latitude,
            currentPositionOfUser!.longitude, 22)!
        .listen((driverEvent) {
      if (driverEvent != null) {
        var onlineDriverChild = driverEvent['callBack'];
        switch (onlineDriverChild) {
          case Geofire.onKeyEntered:
            OnlineNearbyDrivers onlineNearbyDrivers = OnlineNearbyDrivers();
            onlineNearbyDrivers.uidDriver = driverEvent['key'];
            onlineNearbyDrivers.latDriver = driverEvent['latitude'];
            onlineNearbyDrivers.lngDriver = driverEvent['longitude'];
            ManageDriversMethods.nearbyOnlineDriversList
                .add(onlineNearbyDrivers);

            if (nearbyOnlineDriverKeyLoaded == true) {
              ///updateDriversonMaps
              updateAvailableNearbyOnlineDriversOnMap();
            }
            break;
          case Geofire.onKeyExited:
            ManageDriversMethods.removerDriverFromList(driverEvent['key']);
            updateAvailableNearbyOnlineDriversOnMap();
            break;
          case Geofire.onKeyMoved:
            OnlineNearbyDrivers onlineNearbyDrivers = OnlineNearbyDrivers();
            onlineNearbyDrivers.uidDriver = driverEvent['key'];
            onlineNearbyDrivers.latDriver = driverEvent['latitude'];
            onlineNearbyDrivers.lngDriver = driverEvent['longitude'];
            ManageDriversMethods.updateOnLineNearbyDriversLocation(
                onlineNearbyDrivers);
            updateAvailableNearbyOnlineDriversOnMap();

            break;
          case Geofire.onGeoQueryReady:
            nearbyOnlineDriverKeyLoaded = true;
            updateAvailableNearbyOnlineDriversOnMap();

            break;

          default:
        }
      }
    });
  }

  noDriverAvailable() {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => InfoDialog());
  }

  searchDriver() {
    if (avilableNearbyOnlineDriversList.isEmpty) {
      cancelRideRequest();
      resetAppNow();
      noDriverAvailable();
      return;
    }
    var currentDriver = avilableNearbyOnlineDriversList[0];
    sendNotificationToDriver(currentDriver);

    avilableNearbyOnlineDriversList.removeAt(0);
  }

  sendNotificationToDriver(OnlineNearbyDrivers currentDriver) {
    DatabaseReference currentDriverRef = FirebaseDatabase.instance
        .ref()
        .child('drivers')
        .child(currentDriver.uidDriver!.toString())
        .child('newTripStatus');

    currentDriverRef.set(tripRequestRef!.key);

    /////getToken
    DatabaseReference currentDriverToken = FirebaseDatabase.instance
        .ref()
        .child('drivers')
        .child(currentDriver.uidDriver.toString())
        .child("deviceToken");

    currentDriverToken.once().then((dataSnapshot) {
      if (dataSnapshot.snapshot.value != null) {
        String devicetoken = dataSnapshot.snapshot.value.toString();
        String tripid = tripRequestRef!.key.toString();
        PushNotificationService.sendNotificationToSelectedDriver(
            devicetoken, context, tripid);
      } else {
        return;
      }
    
       

      const oneTickPerSec = Duration(seconds: 1);
      var timerCountDown = Timer.periodic(oneTickPerSec, (timer) {
        requestTimeOutDriver = requestTimeOutDriver - 1;

        if (stateOfApp != "requesting") {
          timer.cancel();
          currentDriverRef.set("cancelled");
          currentDriverRef.onDisconnect();
          requestTimeOutDriver = 20;
        }
        //when tri is accepting by driver
        currentDriverRef.onValue.listen((data) {
          if (data.snapshot.value.toString() == "accepted") {
       
            timer.cancel();
            currentDriverRef.onDisconnect();
            requestTimeOutDriver = 20;
          }
        });

        if (requestTimeOutDriver == 0) {
          currentDriverRef.set("timeout");
          currentDriverRef.onDisconnect();
          requestTimeOutDriver = 20;

          searchDriver();
        }
      }
      );
    }
    );
  }

  @override
  Widget build(BuildContext context) {
    makeDriverCarIcon();
    CameraPosition kGooglePlex = CameraPosition(
      target: LatLng(41.42796133580664, 28.085749655962),
      zoom: 14.4746,
    );

    return SafeArea(
      child: Scaffold(
        // floatingActionButton: FloatingActionButton(
        //   onPressed: getCurrentLiveLocation,
        //   child: Icon(Icons.my_location),
        // ),
        key: sKey,
        drawer: Container(
          width: 255,
          color: Colors.black87,
          child: Drawer(
            backgroundColor: Colors.amberAccent,
            child: ListView(
              children: [
                Container(
                  color: Colors.black,
                  height: 160,
                  child: DrawerHeader(
                      decoration: BoxDecoration(),
                      child: Row(
                        children: [
                          Icon(
                            Icons.person,
                            size: 60,
                          ),
                          const SizedBox(
                            width: 16,
                          ),
                          Column(children: [
                            Text(
                              userName,
                              style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold),
                            ),
                            Text(
                              "Profile",
                              style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                          ]),
                        ],
                      )),
                ),
                Divider(
                  thickness: 1,
                  height: 1,
                  color: Colors.white,
                ),
                ListTile(
                  title: Text("About"),
                  leading: IconButton(
                      icon: Icon(
                        Icons.info,
                        color: Colors.black,
                      ),
                      onPressed: () {}),
                ),
                ListTile(
                  title: Text("Logout"),
                  leading: IconButton(
                    icon: Icon(
                      Icons.logout,
                      color: Colors.black,
                    ),
                    onPressed: () {},
                  ),
                )
              ],
            ),
          ),
        ),
        body: Stack(
          children: [
            GoogleMap(
              padding: EdgeInsets.only(top: 26, bottom: bottomPadding),
              initialCameraPosition: kGooglePlex,
              myLocationButtonEnabled: true,
              polylines: polylineSet,
              markers: markerSet,
              circles: circleSet,
              //initialCameraPosition: CameraPosition(target: target),
              // mapType: MapType.terrain,
              myLocationEnabled: true,
              zoomControlsEnabled: false,
              onMapCreated: (GoogleMapController mapController) {
                controllerGoogleMap = mapController;
                updateMapStyle(controllerGoogleMap!);
                getCurrentLiveLocation();
                googleMapCompleterController.complete(controllerGoogleMap);
                setState(() {
                  bottomPadding = 140;
                });
              },
            ),
            Positioned(
                top: 42,
                left: 20,
                child: GestureDetector(
                  onTap: () {
                    if (isDRawerOpen) {
                      sKey.currentState!.openDrawer();
                    } else {
                      resetAppNow();
                    }
                  },
                  child: Container(
                      decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [
                            BoxShadow(
                                color: Colors.amberAccent,
                                blurRadius: 2,
                                spreadRadius: 0.2,
                                offset: Offset(0.5, 0.5))
                          ]),
                      child: CircleAvatar(
                        backgroundColor: Colors.amber,
                        radius: 20,
                        child: Icon(
                          isDRawerOpen ? Icons.menu : Icons.close,
                          color: Colors.black,
                        ),
                      )),
                )),
            // mylocation
            Positioned(
                bottom: 175,
                right: 20,
                child: GestureDetector(
                  onTap: () {
                    getCurrentLiveLocation();
                  },
                  child: Container(
                      decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [
                            BoxShadow(
                                color: Colors.amberAccent,
                                blurRadius: 2,
                                spreadRadius: 0.2,
                                offset: Offset(0.5, 0.5))
                          ]),
                      child: CircleAvatar(
                        backgroundColor: Colors.amber,
                        radius: 20,
                        child: Icon(
                          Icons.my_location_rounded,
                          color: Colors.black,
                        ),
                      )),
                )),
            Positioned(
                left: 0,
                bottom: -80,
                right: 0,
                child: Container(
                  //color: Colors.amber,
                  height: searchContainerHeight,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      ElevatedButton(
                          style: ButtonStyle(
                            backgroundColor:
                                MaterialStateProperty.all(Colors.amber),
                            shape: MaterialStateProperty.all<
                                RoundedRectangleBorder>(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    20.0), // Adjust the border radius for an elegant shape
                              ),
                            ),
                          ),
                          onPressed: () async {
                            var responseFromSearchPage = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (c) => SearchDestinationPage()));
                            // if (responseFromSearchPage == "placeSelected") {
                            String droppoff =
                                Provider.of<AppInfo>(context, listen: false)
                                        .dropOffLocation!
                                        .placeName ??
                                    "";
                            print("Destiontions is " + droppoff.toString());
                            displayUserRideDetailsContainer();
                            // }
                          },
                          child: Padding(
                              padding: EdgeInsets.all(10),
                              child: Icon(
                                Icons.search,
                                size: 25,
                                color: Colors.black,
                              ))),
                      ElevatedButton(
                          style: ButtonStyle(
                            backgroundColor:
                                MaterialStateProperty.all(Colors.amber),
                            shape: MaterialStateProperty.all<
                                RoundedRectangleBorder>(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    20.0), // Adjust the border radius for an elegant shape
                              ),
                            ),
                          ),
                          onPressed: () {},
                          child: Padding(
                              padding: EdgeInsets.all(10),
                              child: Icon(
                                Icons.home,
                                size: 25,
                                color: Colors.black,
                              ))),
                      ElevatedButton(
                          style: ButtonStyle(
                            backgroundColor:
                                MaterialStateProperty.all(Colors.amber),
                            shape: MaterialStateProperty.all<
                                RoundedRectangleBorder>(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    20.0), // Adjust the border radius for an elegant shape
                              ),
                            ),
                          ),
                          onPressed: () {},
                          child: Padding(
                              padding: EdgeInsets.all(10),
                              child: Icon(
                                Icons.work,
                                size: 25,
                                color: Colors.black,
                              )))
                    ],
                  ),
                )),

            ///riderDetailsContainer
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                  height: rideDetialsContainerHeight,
                  decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(50),
                          topRight: Radius.circular(50)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber,
                          blurRadius: 5,
                          spreadRadius: 0.2,
                          offset: Offset(.5, .5),
                        )
                      ]),
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 18),
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(left: 16, right: 16),
                            child: SizedBox(
                              height: 190,
                              child: Card(
                                color: Colors.transparent,
                                elevation: 1,
                                child: Container(
                                  width:
                                      MediaQuery.of(context).size.width * .75,
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withOpacity(.6),
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.only(top: 8, bottom: 8),
                                    child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceAround,
                                            children: [
                                              Text(
                                                (tripDirectionDetails != null)
                                                    ? tripDirectionDetails!
                                                        .distanceTextString!
                                                    : "",
                                                style: TextStyle(
                                                    fontSize: 16,
                                                    color: Colors.white,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              Text(
                                                (tripDirectionDetails != null)
                                                    ? tripDirectionDetails!
                                                        .durationTextString!
                                                    : "",
                                                style: TextStyle(
                                                    fontSize: 16,
                                                    color: Colors.white,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                          GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                stateOfApp = 'requesting';
                                              });
                                              displayReuestContainer();
                                              //Get Bearest Available Drivers
                                              avilableNearbyOnlineDriversList =
                                                  ManageDriversMethods
                                                      .nearbyOnlineDriversList;
                                              print("ddddddddddddddddddddddddd" +
                                                  avilableNearbyOnlineDriversList[
                                                          0]
                                                      .lngDriver
                                                      .toString());

                                              ///get nearest available drivers from
                                              ///searchDr
                                              searchDriver();
                                            },
                                            child: Image.network(
                                              'https://th.bing.com/th/id/R.dfccca7ce13c4252c2bad49936a1e85d?rik=NFtas%2bW4Iq5HdQ&riu=http%3a%2f%2fpngimg.com%2fuploads%2fmercedes%2fmercedes_PNG1889.png&ehk=GRcl%2b7%2bY4gZmo0LACXxN0dLvzFsddlfrPFnmZiEY9hQ%3d&risl=&pid=ImgRaw&r=0',
                                              width: 122,
                                              height: 122,
                                            ),
                                          ),
                                          Text(
                                            (tripDirectionDetails != null)
                                                ? "\$ ${(cMethods.calculateFareAmount(tripDirectionDetails!)).toStringAsFixed(2)}"
                                                : "\$ 0 ",
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          )
                                        ]),
                                  ),
                                ),
                              ),
                            ),
                          )
                        ]),
                  )),
            ),
            // request Container
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: requestContainerHeight,
                //color: Colors.black54,
                decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16)),
                    // boxShadow: [
                    //   BoxShadow(
                    //     color: Colors.amber,
                    //     blurRadius: 5,
                    //     spreadRadius: .3,
                    //     offset: Offset(.3, .3),
                    //   )
                    // ]
                    ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 200,
                          child: LoadingAnimationWidget.flickr(
                            leftDotColor: Colors.amberAccent,
                            rightDotColor: Colors.pink,
                            size: 50,
                          ),
                        ),
                        SizedBox(
                          height: 20,
                        ),
                        GestureDetector(
                          onTap: () {
                            resetAppNow();
                            cancelRideRequest();
                          },
                          child: Container(
                            height: 50,
                            width: 50,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(
                                  width: 1.5, color: Colors.amberAccent),
                            ),
                            child: Icon(
                              Icons.close,
                              color: Colors.black,
                              size: 25,
                            ),
                          ),
                        )
                      ]),
                ),
              ),
            ),

            ///TripDetailsContainer
            ///
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: tripContainerHeight,
                //color: Colors.black54,
                decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(25),
                        topRight: Radius.circular(25)),
                    // boxShadow: [
                    //   BoxShadow(
                    //     color: Colors.amber,
                    //     blurRadius: 5,
                    //     spreadRadius: .3,
                    //     offset: Offset(.3, .3),
                    //   )
                    // ]
                    ),
                child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 5),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                tripStatusDriverDisplay,
                                style:
                                    TextStyle(fontSize: 19, color: Colors.grey),
                              ),
                            ],
                          ),
                          SizedBox(height: 19),
                          Divider(
                            color: Colors.white70,
                            thickness: .5,
                            height: 1,
                          ),

                          ///drivernaem and phot
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              ClipOval(
                                child: Image.network(
                                  photoDriver == "" ? "https://th.bing.com/th/id/R.0d9051f2fdf8418c2edae540d3f9229a?rik=h7s9Iu6Zf%2b7YJg&pid=ImgRaw&r=0" : photoDriver,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              SizedBox(
                                width: 8,
                              ),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(nameDriver,
                                      style: TextStyle(
                                          color: Colors.grey, fontSize: 20)),
                                  Text(carDetailsDriver,
                                      style: TextStyle(
                                          color: Colors.grey, fontSize: 14)),
                                ],
                              )
                            ],
                          ),
                          SizedBox(height: 19),
                          Divider(
                            color: Colors.white70,
                            thickness: .5,
                            height: 1,
                          ),
                          SizedBox(height: 19),
                          //call driver button
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  launchUrl(
                                      Uri.parse("tel://$phoneNumberDriver"));
                                },
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Container(
                                          height: 50,
                                          width: 50,
                                          decoration: BoxDecoration(
                                              color: Colors.black54,
                                              borderRadius: BorderRadius.all(
                                                  Radius.circular(25))),
                                          child: Icon(Icons.phone,
                                              color: Colors.white)),
                                      SizedBox(height: 11),
                                      Text("Call",
                                          style: TextStyle(color: Colors.grey))
                                    ]),
                              ),
                            ],
                          )
                        ])),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
