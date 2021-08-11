import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:global_configuration/global_configuration.dart';
import '../../helpers/my_ride_contact.dart';
import '../../helpers/constants.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../models/ride.dart';
import '../../../generated/l10n.dart';
import '../../helpers/helper.dart';
import '../../helpers/ride_contact.dart';
import '../../controllers/ride/ride_home_controller.dart';

import 'package:http/http.dart' as http;
import '../user_repository.dart';

ValueNotifier<Ride> requestedRide = ValueNotifier(Ride());

class RideRepository {

  RideContact contact;
  MyRideContact myRideContact;
  OverlayEntry loader;

  RideRepository({this.contact, this.myRideContact});


  Future<void> requestForRide(BuildContext context, String riderTypeId, LatLng pickupPoint, LatLng dropOffPoint, String pickup, String dropOff) async {

    if(currentUser.value != null && currentUser.value.apiToken != null && currentUser.value.apiToken.isNotEmpty) {

      loader = Helper.overlayLoader(context);

      final String url = '${GlobalConfiguration().getString('api_base_url')}ride-request';

      final client = new http.Client();

      Map<String, dynamic> body = {
        'api_token': currentUser.value.apiToken,
        'rider_type': riderTypeId,
        'pickup_point': pickupPoint.latitude.toString() + "," + pickupPoint.longitude.toString(),
        'dropoff_point': dropOffPoint.latitude.toString() + "," + dropOffPoint.longitude.toString()
      };

      Overlay.of(context).insert(loader);

      client.post(

        Uri.encodeFull(url),
        body: json.encode(body),
        headers: {HttpHeaders.contentTypeHeader: "application/json"},

      ).then((response) {

        print(response.body);

        var jsonData = json.decode(response.body);

        if(response.statusCode == 200 || response.statusCode == 201) {

          if(jsonData['status']) {

            requestedRide.value = Ride.fromJson(jsonData);

            requestedRide.value.pickupAddress = pickup;
            requestedRide.value.dropOffAddress = dropOff;

            requestedRide.notifyListeners();

            contact.onRequestSent();
          }
          else {

            if(jsonData['message'] == "Already Requested!!") {

              contact.onRequestFailed(context, AppLocalization.of(context).can_not_request_two_ride);
            }
            else {

              contact.onRequestFailed(context, AppLocalization.of(context).failed_to_request_ride);
            }
          }
        }
        else {

          contact.onRequestFailed(context, AppLocalization.of(context).failed_to_request_ride);
        }

      }).timeout(Duration(seconds: 5), onTimeout: () {

        client.close();
        contact.onRequestFailed(context, AppLocalization.of(context).connection_timed_out);

      }).whenComplete(() {

        loader.remove();
      });
    }
    else {

      contact.onRequestFailed(context, AppLocalization.of(context).not_logged_in);
    }
  }


  Future<Position> getRiderLocation(BuildContext context, String rideID) async {

    Position position = Position(latitude: 0, longitude: 0, heading: 0);

    final String url = '${GlobalConfiguration().getString('api_base_url')}rider-location?api_token=${currentUser.value.apiToken}&rider_id=${rideID}';

    final client = new http.Client();

    final response = await client.get(Uri.parse(url));

    try {

      print(response.body);

      var jsonData = json.decode(response.body);

      position = Position(latitude: double.parse(jsonData['data']['lat']), longitude: double.parse(jsonData['data']['lng']), heading: double.parse(jsonData['data']['rotation']));
    }
    catch(e) {

      print(e);
    }

    return position;
  }


  Future<void> updateRideInfo(BuildContext context, Ride ride, {List<LatLng> paths}) async {

    loader = Helper.overlayLoader(context);

    final String url = '${GlobalConfiguration().getString('api_base_url')}ride-info-update';

    final client = new http.Client();

    Map<String, dynamic> body = {
      'api_token': currentUser.value.apiToken,
    };

    body.addAll(ride.toJson());

    if(ride.pickupPoint != null) {

      body['pickup_point'] =  ride.pickupPoint.latitude.toString() + "," + ride.pickupPoint.longitude.toString();
    }

    if(ride.dropOffPoint != null) {

      body['dropoff_point'] =  ride.dropOffPoint.latitude.toString() + "," + ride.dropOffPoint.longitude.toString();
    }

    Overlay.of(context).insert(loader);

    client.post(

      Uri.encodeFull(url),
      body: json.encode(body),
      headers: {HttpHeaders.contentTypeHeader: "application/json"},

    ).then((response) {

      print(response.body);

      var jsonData = json.decode(response.body);

      if(response.statusCode == 200 || response.statusCode == 201) {

        if(jsonData['status']) {

          if(contact != null) {

            contact.onRideCancelled(context, Ride.fromJson(jsonData), paths: paths);
          }
          else if(myRideContact != null) {

            myRideContact.onReviewSuccess(context, Ride.fromJson(jsonData));
          }
        }
        else {

          if(contact != null) {

            contact.onRequestFailed(context, AppLocalization.of(context).failed_to_cancel_ride);
          }
          else if(myRideContact != null) {

            myRideContact.onReviewFailed(context);
          }
        }
      }
      else {

        if(contact != null) {

          contact.onRequestFailed(context, AppLocalization.of(context).failed_to_cancel_ride);
        }
        else if(myRideContact != null) {

          myRideContact.onReviewFailed(context);
        }
      }

    }).timeout(Duration(seconds: 5), onTimeout: () {

      client.close();

      if(contact != null) {

        contact.onRequestFailed(context, AppLocalization.of(context).connection_timed_out);
      }
      else if(myRideContact != null) {

        myRideContact.onFailed(context, AppLocalization.of(context).connection_timed_out);
      }

    }).whenComplete(() {

      loader.remove();
    });
  }


  Future<void> getRideHistory(BuildContext context) async {

    final String url = '${GlobalConfiguration().getString('api_base_url')}ride-check?api_token=${currentUser.value.apiToken}&status=2';

    final client = new http.Client();

    client.get(

      Uri.encodeFull(url),
      headers: {HttpHeaders.contentTypeHeader: "application/json"},

    ).then((response) {

      print(response.body);

      var jsonData = json.decode(response.body);

      if(response.statusCode == 200 || response.statusCode == 201) {

        if(jsonData['status']) {

          myRideContact.showMyRides(Rides.fromJson(jsonData).rides);
        }
        else {

          myRideContact.onFailed(context, AppLocalization.of(context).failed_to_get_ride_history);
        }
      }
      else {

        myRideContact.onFailed(context, AppLocalization.of(context).failed_to_get_ride_history);
      }

    }).timeout(Duration(seconds: 5), onTimeout: () {

      client.close();
      myRideContact.onFailed(context, AppLocalization.of(context).connection_timed_out);

    }).catchError((error) {

      myRideContact.onFailed(context, AppLocalization.of(context).failed_to_get_ride_history);
    });
  }


  Future<void> getActiveRide(BuildContext context) async {

    final String url = '${GlobalConfiguration().getString('api_base_url')}ride-check?api_token=${currentUser.value.apiToken}&status=1';

    final client = new http.Client();

    client.get(

      Uri.encodeFull(url),
      headers: {HttpHeaders.contentTypeHeader: "application/json"},

    ).then((response) {

      print(response.body);

      var jsonData = json.decode(response.body);

      if(response.statusCode == 200 || response.statusCode == 201) {

        if(jsonData['status']) {

          contact.onActiveRideFound(context, Rides.fromJson(jsonData).rides);
        }
        else {

          contact.onConnectFail(context, AppLocalization.of(context).could_not_connect);
        }
      }
      else {

        if(jsonData['message'] == "Trying to get property 'role_id' of non-object") {

          contact.showRideHomePage();
        }
        else {

          contact.onConnectFail(context, AppLocalization.of(context).could_not_connect);
        }
      }

    }).timeout(Duration(seconds: 5), onTimeout: () {

      client.close();
      contact.onConnectFail(context, AppLocalization.of(context).could_not_connect);

    }).catchError((error) {

      contact.onConnectFail(context, AppLocalization.of(context).could_not_connect);
    });
  }
}