import 'package:flutter/material.dart';
import '../models/ride.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/places.dart';

abstract class RideContact {

  void setPickUpAddress(String address);
  void setDropOffAddress(String address);
  void showAddressSuggestions(List<Places> addresses);
  void setAppBarTitle(String title);
  void hideMarkers();
  void addMarkers(Marker marker, bool showInfo);
  void showPreviousMarkers();
  void setPickupPointMarker(BuildContext context);
  void setDestinationPointMarker(BuildContext context);
  void setUserLocationMarker(BuildContext context);
  void showSearchedAddressMarker(LatLng latLng, String placeName);
  void clearSuggestions();
  void hideSearchedListView();
  void showMainLocationPickerView();
  void hidePolyLines();
  void showRoutePath();
  void chooseRide();
  void onRequestSent();
  void resetPage();
  void onRequestFailed(BuildContext context, String message);
  void onRideCancelled(BuildContext context, Ride ride, {List<LatLng> paths});
  void onCancelConfirmed(BuildContext context, String message);
  void onActiveRideFound(BuildContext context, List<Ride> rides);
  void onConnectFail(BuildContext context, String message);
  void showRideHomePage();
}