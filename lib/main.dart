import 'dart:io';

import 'package:android_intent/android_intent.dart';
import 'package:background_fetch/background_fetch.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'home.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());

  BackgroundFetch.registerHeadlessTask(backgroundFetchHeadlessTask);
}

/// This "Headless Task" is run when app is terminated.
void backgroundFetchHeadlessTask(HeadlessTask task) async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  var taskId = task.taskId;
  var timeout = task.timeout;

  if (timeout) {
    print("[BackgroundFetch] Headless task timed-out: $taskId");
    BackgroundFetch.finish(taskId);
    return;
  }

  print("background fetch headless task received $taskId and timeout $timeout");
  updateChildLocation(taskId);


}

Future updateChildLocation(String taskId) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String childCode = prefs.getString("childCode") ?? "no code";
  if(childCode != "no code"){
    _determinePosition().then((value) {
      print("updated value in headless lat:  ${value.latitude} and code $childCode");
      CollectionReference children = FirebaseFirestore.instance.collection('children');
      children.doc(childCode).update({
        'lat': value.latitude,
        'long': value.longitude,
      });
    });

  }
  BackgroundFetch.finish(taskId);
}

Future<Position> _determinePosition() async {
  bool serviceEnabled;
  LocationPermission permission;


  // Test if location services are enabled.
  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    // Location services are not enabled don't continue
    // accessing the position and request users of the
    // App to enable the location services.
    return Future.error('Location services are disabled.');
  }

  permission = await Geolocator.checkPermission();
  if(permission != LocationPermission.always){
    await Geolocator.openAppSettings();
    Fluttertoast.showToast(msg: "Please allow location permission all the time",
    toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0);
  }

    if (permission == LocationPermission.denied) {
      await Geolocator.openAppSettings();
      Fluttertoast.showToast(msg: "Please allow location permission all the time",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0);
      // Permissions are denied, next time you could try
      // requesting permissions again (this is also where
      // Android's shouldShowRequestPermissionRationale
      // returned true. According to Android guidelines
      // your App should show an explanatory UI now.
      return Future.error('Location permissions are denied');
    }

  if (permission == LocationPermission.deniedForever) {
    await Geolocator.openAppSettings();
    Fluttertoast.showToast(msg: "Please allow location permission all the time",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0);

    // Permissions are denied forever, handle appropriately.
    return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.');
  }

  // When we reach here, permissions are granted and we can
  // continue accessing the position of the device.
  return await Geolocator.getCurrentPosition();
}





class MyApp extends StatelessWidget {

  static const Map<int, Color> color =
  {
    50: Color.fromRGBO(4,131,184, .1),
    100: Color.fromRGBO(4,131,184, .2),
    200: Color.fromRGBO(4,131,184, .3),
    300: Color.fromRGBO(4,131,184, .4),
    400: Color.fromRGBO(4,131,184, .5),
    500: Color.fromRGBO(4,131,184, .6),
    600: Color.fromRGBO(4,131,184, .7),
    700: Color.fromRGBO(4,131,184, .8),
    800: Color.fromRGBO(4,131,184, .9),
    900: Color.fromRGBO(4,131,184, 1),
  };
 static const MaterialColor myColor = MaterialColor(0xff016A5B, color);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: myColor,
      ),
    home: Home(),

      routes: const {

      },
    );
  }
}