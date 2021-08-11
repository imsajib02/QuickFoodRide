import 'package:google_maps_flutter/google_maps_flutter.dart';

class Constants {

  static const int GROCERY = 766;
  static const int RIDE = 457;

  static final MarkerId USER_LOCATION_MARKER = MarkerId("bryhuh");
  static final MarkerId PICK_UP_POINT_MARKER = MarkerId("neiyiuh");
  static final MarkerId DROP_OFF_POINT_MARKER = MarkerId("onyfigu");
  static final MarkerId SEARCHED_ADDRESS_MARKER = MarkerId("nffgubdv");

  static bool shouldPopTwo = false;

  static final String requested = "0";
  static final String accepted = "1";
  static final String canceled = "2";
  static final String completed = "3";
  static final String started = "4";
}