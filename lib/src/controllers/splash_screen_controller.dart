import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geocoder/geocoder.dart';
import '../pages/ride/ride_home.dart';
import '../helpers/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ride.dart';
import '../repository/ride/ride_repository.dart';
import 'package:mvc_pattern/mvc_pattern.dart';

import '../../generated/l10n.dart';
import '../helpers/custom_trace.dart';
import '../repository/settings_repository.dart' as settingRepo;
import '../repository/user_repository.dart' as userRepo;
import 'ride/ride_home_controller.dart';

class SplashScreenController extends ControllerMVC with ChangeNotifier {

  ValueNotifier<Map<String, double>> progress = new ValueNotifier(new Map());

  GlobalKey<ScaffoldState> scaffoldKey;

  final FirebaseMessaging firebaseMessaging = FirebaseMessaging();

  SplashScreenController() {
    this.scaffoldKey = new GlobalKey<ScaffoldState>();
    // Should define these variables before the app loaded
    progress.value = {"Setting": 0, "User": 0};
  }

  @override
  void initState() {

    super.initState();

    firebaseMessaging.requestNotificationPermissions(const IosNotificationSettings(sound: true, badge: true, alert: true));
    configureFirebase(firebaseMessaging);

    settingRepo.setting.addListener(() {

      if (settingRepo.setting.value.appName != null && settingRepo.setting.value.appName != '' && settingRepo.setting.value.mainColor != null) {
        progress.value["Setting"] = 41;
        // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
        progress?.notifyListeners();
      }
    });

    userRepo.currentUser.addListener(() {

      if (userRepo.currentUser.value.auth != null) {
        progress.value["User"] = 59;
        progress?.notifyListeners();
      }
    });

    Timer(Duration(seconds: 20), () {

      scaffoldKey?.currentState?.showSnackBar(SnackBar(
        content: Text(AppLocalization.of(context).verify_your_internet_connection),
      ));
    });
  }

  void configureFirebase(FirebaseMessaging _firebaseMessaging) {

    try {
      _firebaseMessaging.configure(
        onMessage: notificationOnMessage,
        onLaunch: notificationOnLaunch,
        onResume: notificationOnResume,
      );
    } catch (e) {
      print(CustomTrace(StackTrace.current, message: e));
      print(CustomTrace(StackTrace.current, message: 'Error Config Firebase'));
    }
  }

  Future notificationOnResume(Map<String, dynamic> message) async {

    if(message['data']['id'] == "ride_accept") {

      _onRideRequestAccepted(message, false);
    }
    else if(message['data']['id'] == "ride_start") {

      _onRideStarted(message, false);
    }
    else if(message['data']['id'] == "ride_complete") {

      _onRideCompleted(message, false);
    }
    else if(message['data']['id'] == "ride_canceled") {

      _onRideCancelled(message, false);
    }
    else {

      print(CustomTrace(StackTrace.current, message: message['data']['id']));

      try {
        if (message['data']['id'] == "orders") {
          settingRepo.navigatorKey.currentState.pushReplacementNamed('/Pages', arguments: 3);
        }
      } catch (e) {
        print(CustomTrace(StackTrace.current, message: e));
      }
    }
  }

  Future notificationOnLaunch(Map<String, dynamic> message) async {

    if(message['data']['id'] == "ride_accept") {

      _onRideRequestAccepted(message, false);
    }
    else if(message['data']['id'] == "ride_start") {

      _onRideStarted(message, false);
    }
    else if(message['data']['id'] == "ride_complete") {

      _onRideCompleted(message, false);
    }
    else if(message['data']['id'] == "ride_canceled") {

      _onRideCancelled(message, false);
    }
    else {

      String messageId = await settingRepo.getMessageId();

      try {
        if (messageId != message['google.message_id']) {
          if (message['data']['id'] == "orders") {
            await settingRepo.saveMessageId(message['google.message_id']);
            settingRepo.navigatorKey.currentState.pushReplacementNamed('/Pages', arguments: 3);
          }
        }
      } catch (e) {
        print(CustomTrace(StackTrace.current, message: e));
      }
    }
  }

  Future notificationOnMessage(Map<String, dynamic> message) async {

    print(message);

    SharedPreferences prefs = await SharedPreferences.getInstance();
    int service = await prefs.getInt('service');

    if(service == Constants.RIDE && message['data']['id'] == "ride_accept") {

      _onRideRequestAccepted(message, true);
    }
    else if(service == Constants.RIDE && message['data']['id'] == "ride_start") {

      _onRideStarted(message, true);
    }
    else if(service == Constants.RIDE && message['data']['id'] == "ride_complete") {

      _onRideCompleted(message, true);
    }
    else if(service == Constants.RIDE && message['data']['id'] == "ride_canceled") {

      _onRideCancelled(message, true);
    }
    else if(service == Constants.GROCERY) {

      Fluttertoast.showToast(
        msg: message['notification']['title'],
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.TOP,
        timeInSecForIosWeb: 5,
      );
    }
  }

  Future<void> _onRideRequestAccepted(Map<String, dynamic> message, bool isForeground) async {

    try {

      Ride ride = Ride.fromJson(message);
      ride.id = message['data']['ride_id'] as String;

      if(ride != null && ride.riderID != null && requestedRide.value.id != null && ride.id == requestedRide.value.id) {

        requestedRide.value.riderID = ride.riderID;
        requestedRide.value.riderName = ride.riderName;
        requestedRide.value.riderPhone = ride.riderPhone;
        requestedRide.value.riderAvatar = ride.riderAvatar;
        requestedRide.value.status = Constants.accepted;

        requestedRide.notifyListeners();

        if(!isForeground) {
          Navigator.of(context).pushNamed('/RideHome');
        }
        else {
          RideHomeController.searchingRideController.reverse();
          RideHomeController.rideAcceptedController.forward();
        }
      }
    }
    catch (e) {
      print(e);
    }
  }

  void _onRideStarted(Map<String, dynamic> message, bool isForeground) {

    try {

      Ride ride = Ride.fromJson(message);
      ride.id = message['data']['ride_id'] as String;

      if(ride != null && ride.riderID != null && requestedRide.value.id != null && ride.id == requestedRide.value.id) {

        requestedRide.value.status = Constants.started;
        requestedRide.value.pickupPoint = ride.pickupPoint;
        requestedRide.value.rideTypeID = ride.rideTypeID;
        requestedRide.notifyListeners();

        if(!isForeground) {
          Navigator.of(context).pushNamed('/RideHome');
        }
        else {
          RideHomeController.rideAcceptedController.reverse();
          RideHomeController.rideStartedController.forward();
        }
      }
    }
    catch (e) {
      print(e);
    }
  }

  Future<void> _onRideCompleted(Map<String, dynamic> message, bool isForeground) async {

    try {

      Ride ride = Ride.fromJson(message);
      ride.id = message['data']['ride_id'] as String;

      if(ride != null && ride.riderID != null && requestedRide.value.id != null && ride.id == requestedRide.value.id) {

        requestedRide.value = ride;
        requestedRide.value.status = Constants.completed;
        requestedRide.notifyListeners();

        if(!isForeground) {
          Navigator.of(context).pushNamed('/RideHome');
        }
      }
    }
    catch (e) {
      print(e);
    }
  }

  Future<void> _onRideCancelled(Map<String, dynamic> message, bool isForeground) async {

    try {

      Ride ride = Ride.fromJson(message);
      ride.id = message['data']['ride_id'] as String;

      if(ride != null && ride.riderID != null && requestedRide.value.id != null && ride.id == requestedRide.value.id) {

        requestedRide.value = ride;
        requestedRide.value.status = Constants.canceled;
        requestedRide.notifyListeners();

        if(!isForeground) {
          Navigator.of(context).pushNamed('/RideHome');
        }
      }
    }
    catch (e) {
      print(e);
    }
  }
}
