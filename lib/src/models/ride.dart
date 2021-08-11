import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

class Ride {

  String id;
  String rideTypeID;
  LatLng pickupPoint;
  String pickupAddress;
  LatLng dropOffPoint;
  String dropOffAddress;
  String rideFee;
  String adminCommission;
  String cancellationFee;
  String cancelledBy;
  String cancellationMessage;
  String duration;
  String distance;
  String clientID;
  String riderID;
  String riderName;
  String riderPhone;
  String riderAvatar;
  String rating;
  String review;
  String status;
  bool isTaken;
  String date;
  String time;
  String startTime;
  String endTime;
  DateTime date1;
  DateTime date2;
  String createdAt;

  DateFormat dateFormat = DateFormat.yMMMMd('en_US');
  DateFormat timeFormat = DateFormat.jm('en_US');

  Ride({this.id, this.pickupPoint, this.pickupAddress, this.dropOffPoint,
    this.dropOffAddress, this.rideFee, this.adminCommission,
    this.cancellationFee, this.cancelledBy, this.cancellationMessage,
    this.duration, this.distance, this.clientID, this.riderID, this.riderName,
    this.riderPhone, this.riderAvatar, this.rating, this.review, this.status,
    this.isTaken, this.date, this.time, this.startTime, this.endTime,
    this.dateFormat, this.timeFormat});

  Ride.fromJson(Map<String, dynamic> json) {

    try {

      id = json['data']['id'] == null ? "" : json['data']['id'].toString();

      try {

        String point = json['data']['pickup_point'] as String;
        List<String> splits = point.split(',');
        pickupPoint = LatLng(double.parse(splits[0]), double.parse(splits[1]));

        point = json['data']['dropoff_point'] as String;
        splits = point.split(',');
        dropOffPoint = LatLng(double.parse(splits[0]), double.parse(splits[1]));
      }
      catch (e) {}

      clientID = json['data']['client_id'] == null ? "" : json['data']['client_id'].toString();

      try {

        riderID = json['data']['rider_id'] == null ? "" : json['data']['rider_id'].toString();
        riderName = json['data']['name'] as String;
        riderPhone = json['data']['phone'] as String;
        riderAvatar = json['data']['avatar'] == 'null' ? null : json['data']['avatar'];
      }
      catch(e) {}

      try {

        rideFee = json['data']['ride_fee'] == null ? "" : json['data']['ride_fee'].toString();
        adminCommission = json['data']['admin_com_fee'] == null ? "" : json['data']['admin_com_fee'].toString();
        cancellationFee = json['data']['cancelation_fee'] == null ? "" : json['data']['cancelation_fee'].toString();
      }
      catch(e) {}

      try {

        cancelledBy = json['data']['canceled_by'] == null ? "" : json['data']['canceled_by'].toString();
        cancellationMessage = json['data']['cancellation_message'] == null ? "" : json['data']['cancellation_message'].toString();
      }
      catch(e) {}

      try {

        rating = json['data']['rating'] == null ? "" : json['data']['rating'].toString();
        review = json['data']['review'] == null ? "" : json['data']['review'].toString();
      }
      catch(e) {}

      try {

        distance = json['data']['distance'] == null ? "" : json['data']['distance'].toString();
      }
      catch(e) {}

      try {

        duration = json['data']['thourmin'] == null ? "" : json['data']['thourmin'].toString();
      }
      catch(e) {}

      try {

        rideTypeID = json['data']['rider_types_id'].toString();
      }
      catch(e) {}

      try {

        createdAt = json['data']['created_at'].toString();

        var date = DateTime.parse(createdAt);

        createdAt = dateFormat.format(date) + "    " + timeFormat.format(date);
      }
      catch(e) {}

      try {

        String time = json['data']['ride_duration'].toString();

        var list = time.split(",");

        int timeInMillis = int.parse(list[0]);
        date1 = DateTime.fromMillisecondsSinceEpoch(timeInMillis * 1000);

        startTime = dateFormat.format(date1) + "    " + timeFormat.format(date1);

        timeInMillis = int.parse(list[1]);
        date2 = DateTime.fromMillisecondsSinceEpoch(timeInMillis * 1000);

        endTime = dateFormat.format(date2) + "    " + timeFormat.format(date2);
      }
      catch(e) {}

      status = json['data']['ride_status'] == null ? "" : json['data']['ride_status'].toString();

      DateTime now = DateTime.now();

      date = dateFormat.format(now);
      time = timeFormat.format(now);
    }
    catch(e) {
      print(e);
    }
  }

  toJson() {

    Map<String, dynamic> map = {
      "id" : id,
      "ride_status" : status,
      "ride_fee" : rideFee,
      "admin_com_fee" : adminCommission,
      "cancelation_fee" : cancellationFee,
      "message" : cancellationMessage,
      "distance" : distance,
      "rating" : rating,
      "review" : review
    };

    return map;
  }
}


class Rides {

  List<Ride> rides;

  Rides({this.rides});

  Rides.fromJson(Map<String, dynamic> json) {

    rides = List();

    if(json['data'] != null) {

      json['data'].forEach((ride) {

        Map<String, dynamic> map = {
          'data': ride,
        };

        rides.add(Ride.fromJson(map));
      });
    }
  }
}