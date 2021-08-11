import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/animation.dart';
import 'package:flutter/material.dart';
import 'package:geocoder/geocoder.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import '../../helpers/constants.dart';
import '../../models/ride.dart';
import '../../repository/ride/ride_repository.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/rider_type.dart';
import '../../helpers/ride_contact.dart';
import '../../models/places.dart';
import '../../../generated/l10n.dart';
import '../../repository/settings_repository.dart' as settRepo;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../repository/user_repository.dart';
import '../../repository/settings_repository.dart';

import 'package:http/http.dart' as http;
import 'dart:math' show cos, sqrt, asin;

class RideHomeController {

  RideContact _contact;
  RideRepository _rideRepo;

  LatLng userLocation;
  LatLng centerLatLng;
  LatLng searchedLatLng;

  LatLng pickUpPoint;
  LatLng dropOffPoint;

  RiderType selectedRideType;

  AnimationController locationPickerController;
  AnimationController pickUpController;
  AnimationController destinationController;
  AnimationController searchController;
  AnimationController listViewController;
  AnimationController setAddressController;
  AnimationController setSearchedAddressController;
  static AnimationController searchingRideController;
  static AnimationController rideAcceptedController;
  static AnimationController rideStartedController;
  AnimationController completeController;
  AnimationController beforeStartCancelController;
  AnimationController afterStartCancelController;

  Animation<Offset> _locationPickerOffset;
  Animation<Offset> _pickUpOffset;
  Animation<Offset> _destinationOffset;
  Animation<Offset> _searchOffset;
  Animation<Offset> _listViewOffset;
  Animation<Offset> _setAddressOffset;
  Animation<Offset> _setSearchedAddressOffset;
  Animation<Offset> searchingRideOffset;
  Animation<Offset> rideAcceptedOffset;
  Animation<Offset> rideStartedOffset;
  Animation<Offset> _completeOffset;
  Animation<Offset> _beforeStartCancelOffset;
  Animation<Offset> _afterStartCancelOffset;

  TextEditingController addressSearchController = TextEditingController();

  bool isConstructorCalled = false;
  bool isGpsEnabled = false;
  bool isSelectingPickupPoint = false;
  bool isSelectingDropOffPoint = false;
  bool isSearchingPickupPoint = false;
  bool isSearchingDropOffPoint = false;
  bool isSearched = false;
  bool showRideSelection = false;
  bool rideTypeSelected = true;
  bool isShown = false;
  bool isAccepted = false;
  bool isStarted = false;
  bool isCompleted = false;
  bool isCanceled = false;

  List<Places> _addresses = [];

  String pointOnMap = "";
  String searchedAddress = "";

  double totalDistance = 0.0;

  Uint8List currentLocationBitmap;
  Uint8List pickUpPointBitmap;
  Uint8List destinationPointBitmap;
  Uint8List searchedPointBitmap;
  Uint8List riderBitmap;


  RideHomeController(TickerProvider tickerProvider, RideContact contact, RideRepository repository) {

    if(!isConstructorCalled) {

      this._contact = contact;
      this._rideRepo = repository;

      isConstructorCalled = true;
      addressSearchController.text = "";

      locationPickerController = AnimationController(vsync: tickerProvider, duration: Duration(milliseconds: 200));
      _locationPickerOffset = Tween<Offset>(begin: Offset(0.0, -1.0), end: Offset.zero).animate(locationPickerController);

      pickUpController = AnimationController(vsync: tickerProvider, duration: Duration(milliseconds: 150));
      _pickUpOffset = Tween<Offset>(begin: Offset(0.0, -1.0), end: Offset.zero).animate(pickUpController);

      destinationController = AnimationController(vsync: tickerProvider, duration: Duration(milliseconds: 150));;
      _destinationOffset = Tween<Offset>(begin: Offset(0.0, -1.0), end: Offset.zero).animate(destinationController);

      searchController = AnimationController(vsync: tickerProvider, duration: Duration(milliseconds: 500));
      _searchOffset = Tween<Offset>(begin: Offset(0.0, -1.0), end: Offset.zero).animate(searchController);

      listViewController = AnimationController(vsync: tickerProvider, duration: Duration(milliseconds: 100));
      _listViewOffset = Tween<Offset>(begin: Offset(0.0, -1.0), end: Offset.zero).animate(listViewController);

      setAddressController = AnimationController(vsync: tickerProvider, duration: Duration(milliseconds: 200));
      _setAddressOffset = Tween<Offset>(begin: Offset(0.0, 1.0), end: Offset.zero).animate(setAddressController);

      setSearchedAddressController = AnimationController(vsync: tickerProvider, duration: Duration(milliseconds: 200));
      _setSearchedAddressOffset = Tween<Offset>(begin: Offset(0.0, 1.0), end: Offset.zero).animate(setSearchedAddressController);

      searchingRideController = AnimationController(vsync: tickerProvider, duration: Duration(milliseconds: 200));
      searchingRideOffset = Tween<Offset>(begin: Offset(0.0, -2.0), end: Offset.zero).animate(searchingRideController);

      rideAcceptedController = AnimationController(vsync: tickerProvider, duration: Duration(milliseconds: 200));
      rideAcceptedOffset = Tween<Offset>(begin: Offset(0.0, -2.0), end: Offset.zero).animate(rideAcceptedController);

      rideStartedController = AnimationController(vsync: tickerProvider, duration: Duration(milliseconds: 200));
      rideStartedOffset = Tween<Offset>(begin: Offset(0.0, -2.0), end: Offset.zero).animate(rideStartedController);

      completeController = AnimationController(vsync: tickerProvider, duration: Duration(milliseconds: 200));
      _completeOffset = Tween<Offset>(begin: Offset(0.0, -2.0), end: Offset.zero).animate(completeController);

      beforeStartCancelController = AnimationController(vsync: tickerProvider, duration: Duration(milliseconds: 200));
      _beforeStartCancelOffset = Tween<Offset>(begin: Offset(0.0, -2.0), end: Offset.zero).animate(beforeStartCancelController);

      afterStartCancelController = AnimationController(vsync: tickerProvider, duration: Duration(milliseconds: 200));
      _afterStartCancelOffset = Tween<Offset>(begin: Offset(0.0, -2.0), end: Offset.zero).animate(afterStartCancelController);

      Geolocator().isLocationServiceEnabled().then((value) {

        isGpsEnabled = value;
      });

      locationPickerController.forward();
    }
  }


  SlideTransition locationPicker(BuildContext context, String pickupPointText, String destinationPointText) {

    return SlideTransition(
      position: _locationPickerOffset,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Material(
            elevation: 10,
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.only(top: 30, left: 15, right: 30, bottom: 30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[

                  IntrinsicHeight(
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      children: <Widget>[

                        Expanded(
                          flex: 1,
                          child: Column(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[

                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(color: Colors.black54),
                                ),
                              ),

                              SizedBox(height: 15,),

                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  border: Border.all(color: Colors.black38),
                                ),
                              ),
                            ],
                          ),
                        ),

                        Expanded(
                            flex: 8,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[

                                GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () {

                                    _contact.hideMarkers();
                                    _contact.hidePolyLines();

                                    locationPickerController.reverse();
                                    _contact.setAppBarTitle(AppLocalization.of(context).choose_pickup_point);

                                    addressSearchController.text = "";
                                    _contact.clearSuggestions();

                                    pickUpController.forward();
                                    searchController.forward();
                                  },
                                  child: Container(
                                    alignment: Alignment.centerLeft,
                                    padding: EdgeInsets.all(12),
                                    margin: EdgeInsets.only(left: 5, right: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      border: Border.all(color: Colors.black38),
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: Text(pickupPointText,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 15),
                                    ),
                                  ),
                                ),

                                SizedBox(height: 15,),

                                GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () {

                                    _contact.hideMarkers();
                                    _contact.hidePolyLines();

                                    locationPickerController.reverse();
                                    _contact.setAppBarTitle(AppLocalization.of(context).choose_destination_point);

                                    addressSearchController.text = "";
                                    _contact.clearSuggestions();

                                    destinationController.forward();
                                    searchController.forward();
                                  },
                                  child: Container(
                                    alignment: Alignment.centerLeft,
                                    padding: EdgeInsets.all(12),
                                    margin: EdgeInsets.only(left: 5, right: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      border: Border.all(color: Colors.black38),
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: Text(destinationPointText,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 15),
                                    ),
                                  ),
                                ),
                              ],
                            )
                        ),
                      ],
                    ),
                  ),

                  Visibility(
                    visible: pickUpPoint != null && dropOffPoint != null,
                    child: Padding(
                      padding: EdgeInsets.only(top: 25),
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {

                          _onNext(context);
                        },
                        child: Container(
                          width: 150,
                          padding: EdgeInsets.only(top: 6, bottom: 6),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Theme.of(context).accentColor,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Icon(Icons.arrow_forward, color: Colors.white,),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }


  SlideTransition pickUpPointWidget(BuildContext context) {

    return SlideTransition(
      position: _pickUpOffset,
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          color: Colors.white,
          width: double.infinity,
          padding: EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 15),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[

              Opacity(
                opacity: 0.0,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.black26),
                  ),
                  child: Row(
                    children: <Widget>[

                      Flexible(
                        flex: 1,
                        child: IconButton(
                          icon: Icon(Icons.arrow_back, color: Colors.black),
                          onPressed: () {},
                        ),
                      ),

                      SizedBox(width: 10,),

                      Flexible(
                        flex: 7,
                        child: TextField(
                          controller: addressSearchController,
                          cursorRadius: Radius.circular(10),
                          enabled: true,
                          style: Theme.of(context).textTheme.caption,
                          decoration: InputDecoration(
                            hintText: AppLocalization.of(context).address,
                            border: InputBorder.none,
                          ),
                          onChanged: (String input) {},
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 15,),

              Visibility(
                visible: isGpsEnabled,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {

                    _setUserLocationAsPickupPoint(context);
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[

                      Expanded(
                        flex: 1,
                        child: CircleAvatar(
                          radius: 15,
                          backgroundColor: Color(0xFFE0EDFC),
                          child: Icon(Icons.my_location, color: Colors.blueAccent, size: 20,),
                        ),
                      ),

                      SizedBox(width: 20,),

                      Expanded(
                        flex: 8,
                        child: Text(AppLocalization.of(context).your_location,
                          style: TextStyle(
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Visibility(visible: isGpsEnabled, child: SizedBox(height: 3,)),

              Visibility(
                visible: isGpsEnabled,
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[

                    Expanded(
                      flex: 1,
                      child: Container(),
                    ),

                    SizedBox(width: 20,),

                    Expanded(
                      flex: 8,
                      child: Divider(color: Colors.black26, thickness: 1.2,)
                    ),
                  ],
                ),
              ),

              Visibility(visible: isGpsEnabled, child: SizedBox(height: 3,)),

              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {

                  _contact.hideMarkers();
                  isSelectingPickupPoint = true;

                  pickUpController.reverse();
                  searchController.reverse();
                },
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[

                    Expanded(
                      flex: 1,
                      child: CircleAvatar(
                        radius: 15,
                        backgroundColor: Colors.black12,
                        child: Icon(Icons.map, color: Colors.black54, size: 20,),
                      ),
                    ),

                    SizedBox(width: 20,),

                    Expanded(
                      flex: 8,
                      child: Text(AppLocalization.of(context).choose_on_map,
                        style: TextStyle(
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  SlideTransition destinationPointWidget(BuildContext context) {

    return SlideTransition(
      position: _destinationOffset,
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          color: Colors.white,
          width: double.infinity,
          padding: EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 15),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[

              Opacity(
                opacity: 0.0,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.black26),
                  ),
                  child: Row(
                    children: <Widget>[

                      Flexible(
                        flex: 1,
                        child: IconButton(
                          icon: Icon(Icons.arrow_back, color: Colors.black),
                          onPressed: () {},
                        ),
                      ),

                      SizedBox(width: 10,),

                      Flexible(
                        flex: 7,
                        child: TextField(
                          controller: addressSearchController,
                          cursorRadius: Radius.circular(10),
                          enabled: true,
                          style: Theme.of(context).textTheme.caption,
                          decoration: InputDecoration(
                            hintText: AppLocalization.of(context).address,
                            border: InputBorder.none,
                          ),
                          onChanged: (String input) {},
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 15,),

              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {

                  _contact.hideMarkers();
                  isSelectingDropOffPoint = true;

                  destinationController.reverse();
                  searchController.reverse();
                },
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[

                    Expanded(
                      flex: 1,
                      child: CircleAvatar(
                        radius: 15,
                        backgroundColor: Colors.black12,
                        child: Icon(Icons.map, color: Colors.black54, size: 20,),
                      ),
                    ),

                    SizedBox(width: 20,),

                    Expanded(
                      flex: 8,
                      child: Text(AppLocalization.of(context).choose_on_map,
                        style: TextStyle(
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }


  SlideTransition searchWidget(BuildContext context) {

    return SlideTransition(
      position: _searchOffset,
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.only(left: 20, right: 20, top: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[

              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.black26),
                ),
                child: Row(
                  children: <Widget>[

                    Flexible(
                      flex: 1,
                      child: IconButton(
                        icon: Icon(Icons.arrow_back, color: Colors.black),
                        onPressed: () {

                          if(listViewController.isCompleted) {

                            _contact.hideSearchedListView();
                          }
                          else {

                            _contact.showMainLocationPickerView();
                          }
                        },
                      ),
                    ),

                    SizedBox(width: 10,),

                    Flexible(
                      flex: 7,
                      child: TextField(
                        controller: addressSearchController,
                        cursorRadius: Radius.circular(10),
                        enabled: true,
                        style: Theme.of(context).textTheme.bodyText2,
                        decoration: InputDecoration(
                          hintText: AppLocalization.of(context).address,
                          border: InputBorder.none,
                        ),
                        onChanged: (String input) {

                          if(input.length > 0) {

                            if(pickUpController.isCompleted) {

                              isSearchingPickupPoint = true;
                              pickUpController.reverse();
                            }
                            else if(destinationController.isCompleted) {

                              isSearchingDropOffPoint = true;
                              destinationController.reverse();
                            }

                            listViewController.forward();
                            _getAddressSuggestions(input);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  SlideTransition listViewWidget(List<Places> suggestions, BuildContext context) {

    return SlideTransition(
      position: _listViewOffset,
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          color: Colors.white,
          height: double.infinity,
          width: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[

              SizedBox(height: 60,),

              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.all(15),
                  shrinkWrap: true,
                  itemCount: suggestions == null ? 0 : (suggestions.length > 10 ? 10 : suggestions.length),
                  itemBuilder: (BuildContext context, int index) {

                    return GestureDetector(
                      onTap: () {
                        searchedAddress = suggestions[index].fullAddress;
                        _getLatLngFromAddress(suggestions[index], context);
                      },
                      child: Card(
                        elevation: 2,
                        child: ListTile(
                          leading: Icon(Icons.location_on),
                          title: Text(suggestions[index].mainAddress == null ? "" : suggestions[index].mainAddress, overflow: TextOverflow.ellipsis,),
                          subtitle: Text(suggestions[index].secondaryAddress == null ? "" : suggestions[index].secondaryAddress, overflow: TextOverflow.ellipsis,),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  SlideTransition setPointFromMap(BuildContext context) {

    return SlideTransition(
      position: _setAddressOffset,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: EdgeInsets.only(left: 15, bottom: 25, right: 15),
          child: Material(
            elevation: 10,
            color: Colors.white,
            borderRadius: BorderRadius.all(Radius.circular(10)),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(15),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[

                  Expanded(
                    flex: 8,
                    child: Text(pointOnMap, style: Theme.of(context).textTheme.subtitle2,),
                  ),

                  SizedBox(width: 15,),

                  Expanded(
                    flex: 2,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {

                        if(isSelectingPickupPoint) {

                          isSelectingPickupPoint = false;
                          setAddressController.reverse();

                          pickUpPoint = centerLatLng;

                          _contact.setPickupPointMarker(context);
                          _contact.setPickUpAddress(pointOnMap);
                        }
                        else if(isSelectingDropOffPoint) {

                          isSelectingDropOffPoint = false;
                          setAddressController.reverse();

                          dropOffPoint = centerLatLng;

                          _contact.setDestinationPointMarker(context);
                          _contact.setDropOffAddress(pointOnMap);
                        }
                      },
                      child: CircleAvatar(
                        backgroundColor: Theme.of(context).accentColor,
                        radius: 20,
                        child: Icon(Icons.arrow_right, size: 35, color: Colors.white,),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }


  SlideTransition confirmSearchedAddress(BuildContext context) {

    return SlideTransition(
      position: _setSearchedAddressOffset,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: EdgeInsets.only(left: 15, right: 15),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {

              isSearched = false;

              if(isSearchingPickupPoint) {

                pickUpPoint = searchedLatLng;

                isSearchingPickupPoint = false;

                _contact.setPickupPointMarker(context);
                _contact.setPickUpAddress(searchedAddress);
              }
              else if(isSearchingDropOffPoint) {

                dropOffPoint = searchedLatLng;

                isSearchingDropOffPoint = false;

                _contact.setDestinationPointMarker(context);
                _contact.setDropOffAddress(searchedAddress);
              }

              setSearchedAddressController.reverse();
              locationPickerController.forward();

              _contact.setAppBarTitle(AppLocalization.of(context).ride);
            },
            child: Material(
              elevation: 10,
              color: Theme.of(context).accentColor,
              borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20),),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(20),
                child: Text(isSearchingPickupPoint ? AppLocalization.of(context).set_as_pickup_point : AppLocalization.of(context).set_as_destination_point,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headline5.copyWith(color: Colors.white),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }


  SlideTransition searchingForRide(BuildContext context, String pickupPointText, String destinationPointText) {

    return SlideTransition(
      position: searchingRideOffset,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: DraggableScrollableSheet(
          initialChildSize: 0.815,
          minChildSize: 0.28,
          maxChildSize: .815,
          builder: (context, controller) {

            return Stack(
              children: <Widget>[

                Material(
                  elevation: 10,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
                  color: Colors.white,
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.only(top: 40, left: 20, right: 20, bottom: 15),
                    child: NotificationListener<OverscrollIndicatorNotification>(
                      onNotification: (overscroll) {
                        overscroll.disallowGlow();
                        return;
                      },
                      child: ListView(
                        controller: controller,
                        children: <Widget>[

                          Text(AppLocalization.of(context).looking_for_ride,
                            style: Theme.of(context).textTheme.headline2,
                          ),

                          Padding(
                            padding: EdgeInsets.only(top: 30, bottom: 30),
                            child: LinearProgressIndicator(
                              backgroundColor: Theme.of(context).accentColor.withOpacity(.3),
                              valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).accentColor),
                            ),
                          ),

                          Padding(
                            padding: EdgeInsets.only(bottom: 20),
                            child: Text(AppLocalization.of(context).looking_for_ride_msg,
                              style: Theme.of(context).textTheme.caption.copyWith(fontSize: 18),
                            ),
                          ),

                          IntrinsicHeight(
                            child: Row(
                              mainAxisSize: MainAxisSize.max,
                              children: <Widget>[

                                Expanded(
                                  flex: 1,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.max,
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: <Widget>[

                                      Container(
                                        width: 7,
                                        height: 7,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          border: Border.all(color: Colors.black54),
                                        ),
                                      ),

                                      SizedBox(height: 5,),

                                      Container(
                                        width: 7,
                                        height: 7,
                                        decoration: BoxDecoration(
                                          color: Colors.black,
                                          border: Border.all(color: Colors.black38),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                Expanded(
                                    flex: 8,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: <Widget>[

                                        Container(
                                          alignment: Alignment.centerLeft,
                                          padding: EdgeInsets.all(12),
                                          margin: EdgeInsets.only(left: 5, right: 10),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                          ),
                                          child: Text(pickupPointText,
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 2,
                                            style: TextStyle(fontSize: 15),
                                          ),
                                        ),

                                        SizedBox(height: 5,),

                                        Container(
                                          alignment: Alignment.centerLeft,
                                          padding: EdgeInsets.all(12),
                                          margin: EdgeInsets.only(left: 5, right: 10),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                          ),
                                          child: Text(destinationPointText,
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 2,
                                            style: TextStyle(fontSize: 15),
                                          ),
                                        ),
                                      ],
                                    )
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: 20,),

                          Container(
                            height: 10,
                            width: double.infinity,
                            color: Colors.grey[100],
                          ),

                          SizedBox(height: 15,),

                          Padding(
                            padding: EdgeInsets.only(bottom: 25),
                            child: Text(AppLocalization.of(context).booking_details,
                              style: Theme.of(context).textTheme.caption.copyWith(fontSize: 18),
                            ),
                          ),

                          Padding(
                            padding: EdgeInsets.only(top: 15, bottom: 30),
                            child: Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[

                                Expanded(
                                  flex: 2,
                                  child: selectedRideType != null ? Container(
                                    height: 40,
                                    width: 100,
                                    decoration: BoxDecoration(
                                      image: DecorationImage(
                                          fit: BoxFit.cover,
                                          image: NetworkImage(selectedRideType.icon)),
                                    ),
                                  ) : Container(),
                                ),

                                Expanded(
                                  flex: 5,
                                  child: Container(
                                    alignment: Alignment.centerLeft,
                                    padding: EdgeInsets.only(left: 20, right: 15),
                                    child: Text(selectedRideType == null ? "" : selectedRideType.name,
                                      style: Theme.of(context).textTheme.subtitle1.copyWith(color: Colors.black),
                                    ),
                                  ),
                                ),

                                Expanded(
                                  flex: 2,
                                  child: Container(),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: 20,),

                          Padding(
                            padding: EdgeInsets.only(left: 10, right: 10),
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () async {

                                Ride ride = Ride(id: requestedRide.value.id, status: Constants.canceled);
                                _rideRepo.updateRideInfo(context, ride);
                              },
                              child: Material(
                                elevation: 10,
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(22),
                                child: Padding(
                                  padding: EdgeInsets.only(top: 12, bottom: 12, left: 40, right: 40),
                                  child: Text(AppLocalization.of(context).cancel.toUpperCase(),
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context).textTheme.headline6.copyWith(color: Colors.white, fontSize: 15),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: 30,),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }


  SlideTransition onRideAccepted(BuildContext context) {

    return SlideTransition(
      position: rideAcceptedOffset,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.2,
          maxChildSize: .5,
          builder: (context, controller) {

            return Stack(
              children: <Widget>[

                ValueListenableBuilder(
                  valueListenable: requestedRide,
                  builder: (BuildContext context, Ride ride, _) {

                    return Material(
                      elevation: 10,
                      borderRadius: BorderRadius.only(topRight: Radius.circular(30), topLeft: Radius.circular(30)),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.only(topRight: Radius.circular(30), topLeft: Radius.circular(30)),
                        ),
                        child: NotificationListener<OverscrollIndicatorNotification>(
                          onNotification: (overscroll) {
                            overscroll.disallowGlow();
                            return;
                          },
                          child: Padding(
                            padding: EdgeInsets.only(top: 30, left: 20, right: 20),
                            child: ListView(
                              controller: controller,
                              children: <Widget>[

                                Text(AppLocalization.of(context).rider_found,
                                  style: Theme.of(context).textTheme.headline2,
                                ),

                                SizedBox(height: 20,),

                                Text(AppLocalization.of(context).rider_found_msg,
                                  style: Theme.of(context).textTheme.caption.copyWith(fontSize: 16),
                                ),

                                SizedBox(height: 20,),

                                Container(
                                  height: 10,
                                  width: double.infinity,
                                  color: Colors.grey[100],
                                ),

                                SizedBox(height: 20,),

                                Text(AppLocalization.of(context).rider_details,
                                  style: Theme.of(context).textTheme.caption.copyWith(fontSize: 18),
                                ),

                                SizedBox(height: 30,),

                                ride.riderAvatar != null ? Padding(
                                  padding: EdgeInsets.only(left: 80, right: 80),
                                  child: Container(
                                    width: 150,
                                    height: 170,
                                    decoration: BoxDecoration(
                                      image: DecorationImage(image: NetworkImage(ride.riderAvatar), fit: BoxFit.fill),
                                    ),
                                  ),
                                ) : Container(
                                  width: 150,
                                  height: 150,
                                  decoration: BoxDecoration(
                                    image: DecorationImage(image: AssetImage("assets/img/test_account.png"), fit: BoxFit.contain),
                                  ),
                                ),

                                Padding(
                                  padding: EdgeInsets.only(top: 20),
                                  child: Text(ride.riderName == null ? "" : ride.riderName,
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context).textTheme.headline5,
                                  ),
                                ),

                                SizedBox(height: 40,),

                                Padding(
                                  padding: EdgeInsets.only(left: 40, right: 40),
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () {
                                      ride.riderPhone == null ? null : launch("tel:" + ride.riderPhone);
                                    },
                                    child: Material(
                                      elevation: 10,
                                      color: Colors.blue[300],
                                      borderRadius: BorderRadius.circular(22),
                                      child: Padding(
                                        padding: EdgeInsets.only(top: 12, bottom: 12, left: 40, right: 40),
                                        child: Text(AppLocalization.of(context).call.toUpperCase(),
                                          textAlign: TextAlign.center,
                                          style: Theme.of(context).textTheme.headline6.copyWith(color: Colors.white),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                SizedBox(height: 25,),

                                Padding(
                                  padding: EdgeInsets.only(left: 40, right: 40),
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () async {

                                      Ride ride = Ride(id: requestedRide.value.id, status: Constants.canceled);
                                      _rideRepo.updateRideInfo(context, ride);
                                    },
                                    child: Material(
                                      elevation: 10,
                                      color: Colors.red[400],
                                      borderRadius: BorderRadius.circular(22),
                                      child: Padding(
                                        padding: EdgeInsets.only(top: 12, bottom: 12, left: 40, right: 40),
                                        child: Text(AppLocalization.of(context).cancel.toUpperCase(),
                                          textAlign: TextAlign.center,
                                          style: Theme.of(context).textTheme.headline6.copyWith(color: Colors.white, fontSize: 15),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                SizedBox(height: 40,),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }
                ),
              ],
            );
          },
        ),
      ),
    );
  }


  SlideTransition onRideStarted(BuildContext context) {

    return SlideTransition(
      position: rideStartedOffset,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: DraggableScrollableSheet(
          initialChildSize: 0.32,
          minChildSize: .18,
          maxChildSize: .32,
          builder: (context, controller) {

            return Stack(
              children: <Widget>[

                ValueListenableBuilder(
                    valueListenable: requestedRide,
                    builder: (BuildContext context, Ride ride, _) {

                      return Material(
                        elevation: 10,
                        borderRadius: BorderRadius.only(topRight: Radius.circular(30), topLeft: Radius.circular(30)),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.only(topRight: Radius.circular(30), topLeft: Radius.circular(30)),
                          ),
                          child: NotificationListener<OverscrollIndicatorNotification>(
                            onNotification: (overscroll) {
                              overscroll.disallowGlow();
                              return;
                            },
                            child: Padding(
                              padding: EdgeInsets.only(top: 30, left: 20, right: 20),
                              child: ListView(
                                controller: controller,
                                children: <Widget>[

                                  Text(AppLocalization.of(context).ride_started,
                                    style: Theme.of(context).textTheme.headline2,
                                  ),

                                  SizedBox(height: 20,),

                                  Text(AppLocalization.of(context).ride_started_msg,
                                    style: Theme.of(context).textTheme.caption.copyWith(fontSize: 16),
                                  ),

                                  SizedBox(height: 20,),

                                  Container(
                                    height: 10,
                                    width: double.infinity,
                                    color: Colors.grey[100],
                                  ),

                                  SizedBox(height: 25,),

                                  Padding(
                                    padding: EdgeInsets.only(left: 40, right: 40),
                                    child: GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: () async {

                                        _confirmRideCancellation(context);
                                      },
                                      child: Material(
                                        elevation: 10,
                                        color: Colors.red[400],
                                        borderRadius: BorderRadius.circular(22),
                                        child: Padding(
                                          padding: EdgeInsets.only(top: 12, bottom: 12, left: 40, right: 40),
                                          child: Text(AppLocalization.of(context).cancel.toUpperCase(),
                                            textAlign: TextAlign.center,
                                            style: Theme.of(context).textTheme.headline6.copyWith(color: Colors.white, fontSize: 15),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                  SizedBox(height: 40,),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }
                ),
              ],
            );
          },
        ),
      ),
    );
  }


  SlideTransition rideCompleted(BuildContext context, Ride ride) {

    return SlideTransition(
      position: _completeOffset,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.30,
          maxChildSize: .5,
          builder: (context, controller) {

            return Stack(
              children: <Widget>[

                Material(
                  elevation: 10,
                  borderRadius: BorderRadius.only(topRight: Radius.circular(30), topLeft: Radius.circular(30)),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.only(topRight: Radius.circular(30), topLeft: Radius.circular(30)),
                    ),
                    child: NotificationListener<OverscrollIndicatorNotification>(
                      onNotification: (overscroll) {
                        overscroll.disallowGlow();
                        return;
                      },
                      child: Padding(
                        padding: EdgeInsets.only(top: 30, left: 20, right: 20),
                        child: ListView(
                          controller: controller,
                          children: <Widget>[

                            Text(AppLocalization.of(context).ride_complete,
                              style: Theme.of(context).textTheme.headline2,
                            ),

                            SizedBox(height: 20,),

                            Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[

                                Text(AppLocalization.of(context).distance,
                                  style: Theme.of(context).textTheme.subtitle1,
                                ),

                                Text(ride == null || ride.distance == null ? "" : ride.distance + " " + AppLocalization.of(context).km,
                                  style: Theme.of(context).textTheme.caption.copyWith(fontSize: 18),
                                ),
                              ],
                            ),

                            SizedBox(height: 10,),

                            Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[

                                Text(AppLocalization.of(context).time,
                                  style: Theme.of(context).textTheme.subtitle1,
                                ),

                                Text(ride == null || ride.duration == null ? "" : ride.duration.split(":")[0] + AppLocalization.of(context).hour + " " +
                                    ride.duration.split(":")[1] + AppLocalization.of(context).minute,
                                  style: Theme.of(context).textTheme.caption.copyWith(fontSize: 18),
                                ),
                              ],
                            ),

                            SizedBox(height: 10,),

                            Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[

                                Text(AppLocalization.of(context).fare,
                                  style: Theme.of(context).textTheme.subtitle1,
                                ),

                                Text(setting.value.defaultCurrency + " " + (ride == null || ride.rideFee == null ? "" : ride.rideFee),
                                  style: Theme.of(context).textTheme.caption.copyWith(fontSize: 18),
                                ),
                              ],
                            ),

                            SizedBox(height: 30,),

                            Container(
                              height: 10,
                              width: double.infinity,
                              color: Colors.grey[100],
                            ),

                            SizedBox(height: 30,),

                            IntrinsicHeight(
                              child: Row(
                                mainAxisSize: MainAxisSize.max,
                                children: <Widget>[

                                  Expanded(
                                    flex: 1,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.max,
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: <Widget>[

                                        Container(
                                          width: 7,
                                          height: 7,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            border: Border.all(color: Colors.black54),
                                          ),
                                        ),

                                        SizedBox(height: 10,),

                                        Container(
                                          width: 7,
                                          height: 7,
                                          decoration: BoxDecoration(
                                            color: Colors.black,
                                            border: Border.all(color: Colors.black38),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  Expanded(
                                      flex: 8,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: <Widget>[

                                          Container(
                                            alignment: Alignment.centerLeft,
                                            padding: EdgeInsets.all(12),
                                            margin: EdgeInsets.only(left: 5, right: 10),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                            ),
                                            child: Text(ride == null || ride.pickupAddress == null ? "" : ride.pickupAddress,
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 2,
                                              style: TextStyle(fontSize: 15),
                                            ),
                                          ),

                                          SizedBox(height: 10,),

                                          Container(
                                            alignment: Alignment.centerLeft,
                                            padding: EdgeInsets.all(12),
                                            margin: EdgeInsets.only(left: 5, right: 10),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                            ),
                                            child: Text(ride == null || ride.dropOffAddress == null ? "" : ride.dropOffAddress,
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 2,
                                              style: TextStyle(fontSize: 15),
                                            ),
                                          ),
                                        ],
                                      )
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: 30,),

                            Container(
                              height: 10,
                              width: double.infinity,
                              color: Colors.grey[100],
                            ),

                            SizedBox(height: 30,),

                            Padding(
                              padding: EdgeInsets.only(left: 10, right: 10),
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () async {

                                  await _contact.resetPage();

                                  completeController.reverse();
                                  locationPickerController.forward();
                                },
                                child: Material(
                                  elevation: 10,
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(22),
                                  child: Padding(
                                    padding: EdgeInsets.only(top: 12, bottom: 12, left: 40, right: 40),
                                    child: Text(AppLocalization.of(context).go_back.toUpperCase(),
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context).textTheme.headline6.copyWith(color: Colors.black87, fontSize: 15),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(height: 30,),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }


  SlideTransition rideCancelledBeforeStart(BuildContext context, Ride cancelledRide) {

    return SlideTransition(
      position: _beforeStartCancelOffset,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: DraggableScrollableSheet(
          initialChildSize: 0.30,
          minChildSize: 0.30,
          maxChildSize: 0.30,
          builder: (context, controller) {

            return Stack(
              children: <Widget>[

                Material(
                  elevation: 10,
                  borderRadius: BorderRadius.only(topRight: Radius.circular(30), topLeft: Radius.circular(30)),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.only(topRight: Radius.circular(30), topLeft: Radius.circular(30)),
                    ),
                    child: NotificationListener<OverscrollIndicatorNotification>(
                      onNotification: (overscroll) {
                        overscroll.disallowGlow();
                        return;
                      },
                      child: Padding(
                        padding: EdgeInsets.only(top: 30, left: 20, right: 20),
                        child: ListView(
                          controller: controller,
                          children: <Widget>[

                            Text(AppLocalization.of(context).ride_cancelled,
                              style: Theme.of(context).textTheme.headline2,
                            ),

                            SizedBox(height: 20,),

                            Text(cancelledRide != null && cancelledRide.status != null && cancelledRide.status == Constants.canceled ?
                            (cancelledRide.cancelledBy == currentUser.value.id ? AppLocalization.of(context).ride_canceled :
                            AppLocalization.of(context).ride_cancelled_by_rider) : "",
                              style: Theme.of(context).textTheme.caption.copyWith(fontSize: 16),
                            ),

                            SizedBox(height: 30),

                            Padding(
                              padding: EdgeInsets.only(left: 10, right: 10),
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () async {

                                  await _contact.resetPage();

                                  beforeStartCancelController.reverse();
                                  locationPickerController.forward();
                                },
                                child: Material(
                                  elevation: 10,
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(22),
                                  child: Padding(
                                    padding: EdgeInsets.only(top: 12, bottom: 12, left: 40, right: 40),
                                    child: Text(AppLocalization.of(context).go_back.toUpperCase(),
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context).textTheme.headline6.copyWith(color: Colors.black87, fontSize: 15),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(height: 30,),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }


  SlideTransition rideCancelledAfterStart(BuildContext context, Ride ride) {

    return SlideTransition(
      position: _afterStartCancelOffset,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: DraggableScrollableSheet(
          initialChildSize: .5,
          minChildSize: .45,
          maxChildSize: .5,
          builder: (context, controller) {

            return Stack(
              children: <Widget>[

                Material(
                  elevation: 10,
                  borderRadius: BorderRadius.only(topRight: Radius.circular(30), topLeft: Radius.circular(30)),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.only(topRight: Radius.circular(30), topLeft: Radius.circular(30)),
                    ),
                    child: NotificationListener<OverscrollIndicatorNotification>(
                      onNotification: (overscroll) {
                        overscroll.disallowGlow();
                        return;
                      },
                      child: Padding(
                        padding: EdgeInsets.only(top: 30, left: 20, right: 20),
                        child: ListView(
                          controller: controller,
                          children: <Widget>[

                            Text(AppLocalization.of(context).ride_cancelled,
                              style: Theme.of(context).textTheme.headline2,
                            ),

                            SizedBox(height: 20,),

                            Text(ride != null && ride.status != null && ride.status == Constants.canceled ? (ride.cancelledBy == currentUser.value.id ?
                            AppLocalization.of(context).ride_canceled : AppLocalization.of(context).ride_cancelled_by_rider) : "",
                              style: Theme.of(context).textTheme.caption.copyWith(fontSize: 16),
                            ),

                            SizedBox(height: 20,),

                            Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[

                                Text(AppLocalization.of(context).distance,
                                  style: Theme.of(context).textTheme.subtitle1,
                                ),

                                Text(ride == null || ride.distance == null ? "" : ride.distance + " " + AppLocalization.of(context).km,
                                  style: Theme.of(context).textTheme.caption.copyWith(fontSize: 18),
                                ),
                              ],
                            ),

                            SizedBox(height: 10,),

                            Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[

                                Text(AppLocalization.of(context).time,
                                  style: Theme.of(context).textTheme.subtitle1,
                                ),

                                Text(ride == null || ride.duration == null ? "" : ride.duration.split(":")[0] + AppLocalization.of(context).hour + " " +
                                    ride.duration.split(":")[1] + AppLocalization.of(context).minute,
                                  style: Theme.of(context).textTheme.caption.copyWith(fontSize: 18),
                                ),
                              ],
                            ),

                            Visibility(
                              visible: ride != null && ride.status != null && ride.status == Constants.canceled && ride.cancelledBy == currentUser.value.id,
                              child: SizedBox(height: 10,),
                            ),

                            Visibility(
                              visible: ride != null && ride.status != null && ride.status == Constants.canceled && ride.cancelledBy == currentUser.value.id,
                              child: Row(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: <Widget>[

                                  Text(AppLocalization.of(context).fare,
                                    style: Theme.of(context).textTheme.subtitle1,
                                  ),

                                  Text(setting.value.defaultCurrency + " " + (ride == null || ride.rideFee == null ? "" : ride.rideFee),
                                    style: Theme.of(context).textTheme.caption.copyWith(fontSize: 18),
                                  ),
                                ],
                              ),
                            ),

                            Visibility(
                              visible: ride != null && ride.status != null && ride.status == Constants.canceled && ride.cancelledBy == currentUser.value.id,
                              child: SizedBox(height: 10,),
                            ),

                            Visibility(
                              visible: ride != null && ride.status != null && ride.status == Constants.canceled && ride.cancelledBy == currentUser.value.id,
                              child: Row(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: <Widget>[

                                  Text(AppLocalization.of(context).cancel_fee,
                                    style: Theme.of(context).textTheme.subtitle1,
                                  ),

                                  Text(setting.value.defaultCurrency + " " + (ride == null || ride.cancellationFee == null ? "" : ride.cancellationFee),
                                    style: Theme.of(context).textTheme.caption.copyWith(fontSize: 18),
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: 30,),

                            Container(
                              height: 10,
                              width: double.infinity,
                              color: Colors.grey[100],
                            ),

                            SizedBox(height: 30,),

                            IntrinsicHeight(
                              child: Row(
                                mainAxisSize: MainAxisSize.max,
                                children: <Widget>[

                                  Expanded(
                                    flex: 1,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.max,
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: <Widget>[

                                        Container(
                                          width: 7,
                                          height: 7,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            border: Border.all(color: Colors.black54),
                                          ),
                                        ),

                                        SizedBox(height: 10,),

                                        Container(
                                          width: 7,
                                          height: 7,
                                          decoration: BoxDecoration(
                                            color: Colors.black,
                                            border: Border.all(color: Colors.black38),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  Expanded(
                                      flex: 8,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: <Widget>[

                                          Container(
                                            alignment: Alignment.centerLeft,
                                            padding: EdgeInsets.all(12),
                                            margin: EdgeInsets.only(left: 5, right: 10),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                            ),
                                            child: Text(ride == null || ride.pickupAddress == null ? "" : ride.pickupAddress,
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 2,
                                              style: TextStyle(fontSize: 15),
                                            ),
                                          ),

                                          SizedBox(height: 10,),

                                          Container(
                                            alignment: Alignment.centerLeft,
                                            padding: EdgeInsets.all(12),
                                            margin: EdgeInsets.only(left: 5, right: 10),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                            ),
                                            child: Text(ride == null || ride.dropOffAddress == null ? "" : ride.dropOffAddress,
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 2,
                                              style: TextStyle(fontSize: 15),
                                            ),
                                          ),
                                        ],
                                      )
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: 30,),

                            Container(
                              height: 10,
                              width: double.infinity,
                              color: Colors.grey[100],
                            ),

                            SizedBox(height: 40,),

                            Padding(
                              padding: EdgeInsets.only(left: 10, right: 10),
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () async {

                                  await _contact.resetPage();

                                  afterStartCancelController.reverse();
                                  locationPickerController.forward();
                                },
                                child: Material(
                                  elevation: 10,
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(22),
                                  child: Padding(
                                    padding: EdgeInsets.only(top: 12, bottom: 12, left: 40, right: 40),
                                    child: Text(AppLocalization.of(context).go_back.toUpperCase(),
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context).textTheme.headline6.copyWith(color: Colors.black87, fontSize: 15),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(height: 30,),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }


  Future<void> _setUserLocationAsPickupPoint(BuildContext context) async {

    Position position = await Geolocator().getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    pickUpPoint = LatLng(position.latitude, position.longitude);

    final coordinates = Coordinates(pickUpPoint.latitude, pickUpPoint.longitude);
    var addresses = await Geocoder.local.findAddressesFromCoordinates(coordinates);

    _contact.setPickupPointMarker(context);
    _contact.setPickUpAddress(addresses.first.addressLine);
  }


  void _getAddressSuggestions(String input) async {

    _addresses = [];

    String url = "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=${input}&key=${settRepo.setting.value.googleMapsKey}&language=en";

    try {

      final response = await http.get(url);

      if(response != null) {

        final data = json.decode(response.body);
        print(data);

        if(data["error_message"] != null) {

          print(data["error_message"]);
          _addresses = [];
        }
        else if(data["predictions"] == null) {

          _addresses = [];
        }
        else {

          final List predictions = data["predictions"];

          predictions.forEach((prediction) {

            _addresses.add(Places(
              fullAddress: prediction["description"],
              placeID: prediction["place_id"],
              mainAddress: prediction["structured_formatting"]["main_text"],
              secondaryAddress: prediction["structured_formatting"]["secondary_text"],
            ));
          });

          _contact.showAddressSuggestions(_addresses);
        }
      }
    }
    catch (error) {
      print(error);
    }
  }


  Future<void> _getLatLngFromAddress(Places place, BuildContext context) async {

    //String url = "https://maps.googleapis.com/maps/api/place/details/json?placeid=${place.placeID}&key=${settRepo.setting.value.googleMapsKey}";

    FocusScope.of(context).unfocus();
    isSearched = true;

    var result = await Geolocator().placemarkFromAddress(place.fullAddress);

    searchController.reverse();
    listViewController.reverse();

    searchedLatLng = LatLng(result.first.position.latitude, result.first.position.longitude);
    _contact.showSearchedAddressMarker(searchedLatLng, place.fullAddress);
    setSearchedAddressController.forward();
  }


  Future<List<LatLng>> getPolyLine(LatLng from, LatLng to) async {

    List<LatLng> list = [];

    PolylinePoints polylinePoints = PolylinePoints();

    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(settRepo.setting.value.googleMapsKey, PointLatLng(from.latitude, from.longitude),
        PointLatLng(to.latitude, to.longitude));

    if(result.status == 'OK') {

      list.add(from);

      result.points.forEach((point) {

        list.add(LatLng(point.latitude, point.longitude));
      });

      list.add(to);
    }

    return list;
  }


  Future<void> _onNext(BuildContext context) async {

    if(currentUser.value == null) {

      Navigator.of(context).pushNamed('/Login');
    }
    else {

      locationPickerController.reverse();
      _contact.chooseRide();
    }
  }


  Future<double> getDistance(LatLng from, LatLng to) async {

    var p = 0.017453292519943295;
    var c = cos;

    var a = 0.5 - c((to.latitude - from.latitude) * p) / 2 + c(from.latitude * p) * c(to.latitude * p) * (1 - c((to.longitude - from.longitude) * p)) / 2;

    return 12742 * asin(sqrt(a));
  }


  void _confirmRideCancellation(BuildContext scaffoldContext) {

    showDialog(
      context: scaffoldContext,
      barrierDismissible: false,
      builder: (BuildContext context) {

        return WillPopScope(
          onWillPop: () {
            return Future(() => false);
          },
          child: AlertDialog(
            elevation: 10,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
            title: Padding(
              padding: EdgeInsets.only(top: 15),
              child: Row(
                children: <Widget>[

                  Icon(Icons.error, color: Colors.red, size: 30,),

                  SizedBox(width: 15,),

                  Text(AppLocalization.of(context).cancel_ride,
                    style: Theme.of(context).textTheme.headline4.copyWith(color: Colors.red),
                  ),
                ],
              ),
            ),
            content: Text(AppLocalization.of(context).cancel_ride_confirmation_content, textAlign: TextAlign.justify,
              style: Theme.of(context).textTheme.subtitle1.copyWith(color: Colors.black, fontWeight: FontWeight.normal),
            ),
            contentPadding: EdgeInsets.only(left: 30, top: 20, bottom: 20, right: 30),
            actionsPadding: EdgeInsets.only(right: 20, bottom: 10, top: 5),
            actions: <Widget> [

              FlatButton(
                color: Theme.of(context).accentColor,
                textColor: Colors.white,
                child: Text(AppLocalization.of(context).yes),
                onPressed: () {

                  Navigator.of(context).pop();
                  _cancellationReason(scaffoldContext);
                },
              ),

              SizedBox(width: 10,),

              FlatButton(
                color: Colors.lightBlueAccent,
                textColor: Colors.white,
                child: Text(AppLocalization.of(context).no),
                onPressed: () {

                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }


  void _cancellationReason(BuildContext scaffoldContext) {

    addressSearchController.text = "";
    bool valid = true;

    showDialog(
      context: scaffoldContext,
      barrierDismissible: false,
      builder: (BuildContext context) {

        return WillPopScope(
          onWillPop: () {
            return Future(() => false);
          },
          child: Dialog(
            elevation: 10,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {

                return Container(
                  padding: EdgeInsets.all(15),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[

                      Flexible(
                        child: TextField(
                          controller: addressSearchController,
                          enabled: true,
                          keyboardType: TextInputType.multiline,
                          maxLines: null,
                          minLines: 2,
                          maxLength: 250,
                          style: Theme.of(context).textTheme.bodyText2.copyWith(letterSpacing: .1, wordSpacing: .2, height: 1.3),
                          decoration: InputDecoration(
                            hintText: AppLocalization.of(context).cancellation_hint,
                            hintStyle: Theme.of(context).textTheme.caption,
                            errorText: !valid ? AppLocalization.of(context).cancellation_msg_error : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(width: 0, style: BorderStyle.none,),
                            ),
                            filled: true,
                            contentPadding: EdgeInsets.all(10),
                            fillColor: Colors.black12.withOpacity(.035),
                          ),
                        ),
                      ),

                      SizedBox(height: 20,),

                      FlatButton(
                        color: Theme.of(context).accentColor,
                        textColor: Colors.white,
                        child: Text(AppLocalization.of(context).cancel_ride),
                        onPressed: () {

                          if(addressSearchController.text == null || addressSearchController.text.isEmpty) {

                            setState(() {
                              valid = false;
                            });
                          }
                          else {

                            setState(() {
                              valid = true;
                            });

                            Navigator.of(context).pop();
                            _contact.onCancelConfirmed(scaffoldContext, addressSearchController.text);
                          }
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}