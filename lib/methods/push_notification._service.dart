// ignore_for_file: unused_local_variable, non_constant_identifier_names

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ride_app/appInfo/app_info.dart';
import 'package:ride_app/global/global_var.dart';
import 'package:http/http.dart' as http;

class PushNotificationService {
  static sendNotificationToSelectedDriver(
      String deviceToken, BuildContext context, String tripID) async {
    String droppOffLocation = Provider.of<AppInfo>(context, listen: false)
        .dropOffLocation!
        .placeName
        .toString();
    String PickUpAddress = Provider.of<AppInfo>(context, listen: false)
        .pickUpLocation!
        .placeName
        .toString();

    Map<String, String> headerNotification = {
      "content-Type": "application/json",
      "Authorization": "AAAAK49qr5I:APA91bHjA7yLr4JVJGBTwU13xVplyBugDXNZUMFBo1WS0-hCXy-3S1m_vcqjfO2MFUKkDtXbM-zQNhsZQiwmfUIUjO50SbepXJI73B3MtjP094Ufml8Lr4SDU4MDAZqp7ZSbodvnBj7K",
    };

    Map titleBodyNotification = {
      "title": "New Trip from $userName",
      "body":
          "PickUp Location: $PickUpAddress \nDropOff Location: $droppOffLocation "
    };
    Map dataMapNotification = {
      "click_action": "FLUTTER_NOTIFICATION_CLICK",
      "id": "1",
      "status": "done",
      "tripID": tripID ?? "sssss",
    };
    Map bodyNotificationMap = {
      "notification": titleBodyNotification,
      "data": dataMapNotification,
      "priority": "high",
      "to": deviceToken,
    };

    await http.post(Uri.parse("https://fcm.googleapis.com/fcm/send"),
        headers: headerNotification, body: jsonEncode(bodyNotificationMap));
  }
}
