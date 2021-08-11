import 'dart:io';

import 'package:android_intent/android_intent.dart';
import 'package:async_textformfield/async_textformfield.dart';
import 'package:background_fetch/background_fetch.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';


class Home extends StatefulWidget {

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {

  GlobalKey<FormState> formKey = GlobalKey();
  final fatherCodeController = TextEditingController();
  final childNameController = TextEditingController();
  bool isLoading = false;
  bool isTracking = false;

  @override
  void initState() {
    initPlatformState();
    _determinePosition().then((value) async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      CollectionReference children = FirebaseFirestore.instance.collection('children');
      bool isStored = prefs.getBool("isStored") ?? false;
      if(isStored){
        print("is stored");
        setState(() {
          isTracking = true;
        });
        String childCode = prefs.getString("childCode") ?? "no code";
        if(childCode != "no cod"){
          children.doc(childCode).update({
            'lat': value.latitude,
            'long': value.longitude,
          });
        }
      }
    });
    super.initState();
  }

  Future updateChildLocation(String taskId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String childCode = prefs.getString("childCode") ?? "no code";
    if(childCode != "no code"){
      _determinePosition().then((value) {
        print("updated value lat:  ${value.latitude} and code $childCode");
        CollectionReference children = FirebaseFirestore.instance.collection('children');
        children.doc(childCode).update({
          'lat': value.latitude,
          'long': value.longitude,
        });
      });

    }
    BackgroundFetch.finish(taskId);
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {

    // Configure BackgroundFetch.
    try {
      var status = await BackgroundFetch.configure(BackgroundFetchConfig(
        minimumFetchInterval: 15,
        forceAlarmManager: false,
        stopOnTerminate: false,
        startOnBoot: true,
        enableHeadless: true,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresStorageNotLow: false,
        requiresDeviceIdle: false,
        requiredNetworkType: NetworkType.ANY,
      ), updateChildLocation, null);
      print('[BackgroundFetch] configure success: $status');

      // Schedule a "one-shot" custom-task in 10000ms.
      // These are fairly reliable on Android (particularly with forceAlarmManager) but not iOS,
      // where device must be powered (and delay will be throttled by the OS).
      BackgroundFetch.scheduleTask(TaskConfig(
          taskId: "com.example.customtask",
          delay: 10000,
          periodic: false,
          forceAlarmManager: true,
          stopOnTerminate: false,
          enableHeadless: true
      ));



    } catch(e) {
      print("[BackgroundFetch] configure ERROR: $e");
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Start Track"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isTracking ? Center(
          child: Column(
            children:  [
              const SizedBox(height: 40,),
              const Text("Child is tracked", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),),
              const SizedBox(height: 60,),
              GestureDetector(
                onTap: (){
                  stopTracking().then((value) {
                    setState(() {
                      isTracking = false;
                    });
                  });
                },
                child: Container(
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                    color: Colors.blueAccent,
                  ),
                  width: double.infinity,
                  alignment: Alignment.center,
                  height: 40,
                  child: const Text(
                    'Stop Tracking',
                    style: TextStyle(color: Colors.white, fontSize: 17),
                  ),
                ),
              ),
            ],
          ),
        ) : Form(
          key: formKey,
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Father's Code", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w400),),
            const SizedBox(height: 15,),
            Container(
              height: 56,
              decoration: BoxDecoration(
                borderRadius:  const BorderRadius.all(Radius.circular(5)),
                color: Colors.grey.shade200,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),

                child: AsyncTextFormField(
                  controller: fatherCodeController,
                  validationDebounce: const Duration(milliseconds: 500),
                  validator: searchFatherCode,
                  hintText: 'Ex: 8ITEHR52MVDS124',
                  valueIsEmptyMessage: "Enter Father's Code",
                  isValidatingMessage: "Checking Validation",
                  valueIsInvalidMessage: "Invalid Code",
                ),
              ),
            ),
            const SizedBox(height: 20,),
            const Text("Child Name", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w400),),
            const SizedBox(height: 15,),
            Container(
              height: 56,
              decoration: BoxDecoration(
                borderRadius:  const BorderRadius.all(Radius.circular(5)),
                color: Colors.grey.shade200,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                child: TextFormField(
                  controller: childNameController,
                  keyboardType: TextInputType.text,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: "Ex: Ahmed Ali",
                    labelStyle: TextStyle(fontSize: 18),
                    hintStyle: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  validator: (value) {
                    if(value!.isEmpty){
                      return "Enter Child Name";
                    }
                    return null;
                  },
                  style: const TextStyle(fontSize: 15),
                ),
              ),
            ),
            const Spacer(),
            isTracking ? Container() : GestureDetector(
              onTap: (){
                storeData();
              },
              child: Container(
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                  color: Colors.blueAccent,
                ),
                width: double.infinity,
                alignment: Alignment.center,
                height: 40,
                child: const Text(
                  'Start Tracking',
                  style: TextStyle(color: Colors.white, fontSize: 17),
                ),
              ),
            ),
          ],
        ),

        ),
      ),
    );
  }

   Future<bool> searchFatherCode(String fatherCode) async {
    late bool isExists;
    CollectionReference users = FirebaseFirestore.instance.collection('users');
     await users.doc(fatherCode).get().then((value) {
       if(value.exists){
         isExists = true;
       }else {
         isExists = false;
       }
    });
     return isExists;
  }



  Future storeData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final isValid = formKey.currentState!.validate();

    if(isValid){

      _determinePosition().then((value) {

        CollectionReference children = FirebaseFirestore.instance.collection('children');
        children.add({
          'fatherCode': fatherCodeController.text,
          'childName': childNameController.text,
          'lat': value.latitude,
          'long': value.longitude,
        }).then((value) {
          children.doc(value.id).update({'childCode': value.id});
          prefs.setString("fatherCode", fatherCodeController.text);
          prefs.setString("childName", childNameController.text);
          prefs.setBool("isStored", true);
          prefs.setString("childCode", value.id);
          setState(() {
            isTracking = true;
          });
          formKey.currentState!.reset();

        });

      });

    }
  }

  Future stopTracking() async {

    CollectionReference children = FirebaseFirestore.instance.collection('children');

      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setBool("isStored", false);
      String docId = prefs.getString("childCode") ?? "no code";

      if(docId != "no code"){
        children.doc(docId).delete();
      }


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


}
