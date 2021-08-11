import 'package:flutter/material.dart';
import '../models/ride.dart';

abstract class MyRideContact {

  void onFailed(BuildContext context, String message);
  void showMyRides(List<Ride> rides);
  void onReviewSuccess(BuildContext context, Ride ride);
  void onReviewFailed(BuildContext context);
}