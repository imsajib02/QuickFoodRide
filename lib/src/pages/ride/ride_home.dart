import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoder/geocoder.dart';
import 'package:geolocator/geolocator.dart';
import 'package:screen/screen.dart';
import '../../helpers/dbhelper.dart';
import '../../models/ride.dart';
import '../../repository/ride/ride_repository.dart';
import '../../helpers/constants.dart';
import '../../models/places.dart';
import '../../helpers/ride_contact.dart';
import '../../controllers/ride/ride_home_controller.dart';
import '../../../generated/l10n.dart';
import '../../elements/DrawerWidget.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../repository/settings_repository.dart';
import '../../repository/user_repository.dart';

import 'dart:io' show Platform;
import 'dart:ui' as ui;
import 'package:location/location.dart' as loc;
import 'package:shared_preferences/shared_preferences.dart';

class RideHome extends StatefulWidget {

  static _RideHomeState of(BuildContext context) => context.findRootAncestorStateOfType<_RideHomeState>();

  @override
  _RideHomeState createState() => _RideHomeState();
}

class _RideHomeState extends State<RideHome> with TickerProviderStateMixin, WidgetsBindingObserver implements RideContact {

  List<Permission> permissions = [Permission.location, Permission.locationAlways, Permission.locationWhenInUse];
  GoogleMapController _controller;
  DbHelper _dbHelper;

  bool _isRequested = false;
  bool _isAlertShown = false;

  Set<Marker> _markers = Set();
  Set<Polyline> _polyLines = Set();

  CameraPosition _initialPosition = CameraPosition(
    bearing: 0.0,
    tilt: 0.0,
    target: LatLng(23.759398, 90.378904),
    zoom: 6.5,
  );

  CameraPosition _secondaryPosition = CameraPosition(
    bearing: 0.0,
    tilt: 0.0,
    target: LatLng(23.759398, 90.378904),
    zoom: 10,
  );

  String _appBarTitle = "";
  String _pickUpPointText = "";
  String _destinationPointText = "";

  RideContact _contact;
  RideHomeController _rideController;
  RideRepository _rideRepo;

  List<Places> _suggestions = [];
  List<LatLng> _polyLineLatLongs = [];

  bool _isEnabled = false;
  bool _isCallMade = false;

  Ride _myRide;
  Timer _timer;

  int _currentIndex = 0;


  @override
  void initState() {

    WidgetsBinding.instance.addObserver(this);

    _dbHelper = DbHelper();
    _contact = this;
    _rideRepo = RideRepository(contact: _contact);

    _rideController = RideHomeController(this, _contact, _rideRepo);
    _rideController.addressSearchController.text = "";

    super.initState();
  }


  @override
  void didChangeDependencies() {

    _initBitmapIcons();

    if(!_rideController.isSelectingPickupPoint && !_rideController.isSelectingDropOffPoint) {
      _appBarTitle = AppLocalization.of(context).ride;
    }

    if(_rideController.pickUpPoint == null) {
      _pickUpPointText = AppLocalization.of(context).choose_pickup_point;
    }

    if(_rideController.dropOffPoint == null) {
      _destinationPointText = AppLocalization.of(context).choose_destination_point;
    }

    super.didChangeDependencies();
  }


  @override
  Widget build(BuildContext context) {

    _requestPermission();

    return WillPopScope(
      onWillPop: _onBackPress,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.0,
          centerTitle: true,
          title: Text(_appBarTitle, style: Theme.of(context).textTheme.headline4.copyWith(color: Theme.of(context).accentColor),),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        drawer: DrawerWidget(),
        body: SafeArea(
          child: Builder(
            builder: (BuildContext context) {

              if(!_isCallMade) {

                _isCallMade = true;
                _rideRepo.getActiveRide(context);
              }

              return IndexedStack(
                index: _currentIndex,
                children: <Widget>[

                  Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).accentColor),
                      )
                  ),

                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[

                        Text(AppLocalization.of(context).could_not_connect,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headline6.copyWith(color: Colors.black87),
                        ),

                        SizedBox(height: 30,),

                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () async {

                            setState(() {
                              _currentIndex = 0;
                            });

                            _rideRepo.getActiveRide(context);
                          },
                          child: Material(
                            elevation: 10,
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            child: Padding(
                              padding: EdgeInsets.only(top: 12, bottom: 12, left: 40, right: 40),
                              child: Text(AppLocalization.of(context).try_again.toUpperCase(),
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.headline6.copyWith(color: Colors.black87),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Container(
                    height: double.infinity,
                    width: double.infinity,
                    child: ValueListenableBuilder(
                      valueListenable: requestedRide,
                      builder: (BuildContext context, Ride ride, _) {

                        if(ride != null && ride.status != null) {

                          if(ride.status == Constants.accepted && !_rideController.isAccepted) {

                            _rideController.isAccepted = true;

                            _myRide = ride;

                            _setNewPickupPointMarker();
                            _listenForRiderLocation();
                          }
                          else if(ride.status == Constants.started && !_rideController.isStarted) {

                            _rideController.isStarted = true;

                            _myRide = ride;

                            _setDropOffPointMarker();
                            _listenForRiderLocation();
                          }
                          else if(ride.status == Constants.completed && !_rideController.isCompleted) {

                            _rideController.isCompleted = true;

                            if(_timer != null && _timer.isActive) {
                              _timer.cancel();
                            }

                            _onRideComplete();
                          }
                          else if(ride.status == Constants.canceled && !_rideController.isCanceled) {

                            _rideController.isCanceled = true;

                            if(_timer != null && _timer.isActive) {
                              _timer.cancel();
                            }

                            onRideCancelled(context, ride);
                          }
                        }

                        return Stack(
                          children: <Widget>[

                            GoogleMap(
                              initialCameraPosition: _initialPosition,
                              onTap: (LatLng latLng) {},
                              onLongPress: (LatLng latLng) {},
                              onMapCreated: (GoogleMapController controller) async {

                                _controller = controller;

                                _isEnabled = await Geolocator().isLocationServiceEnabled();

                                if(!_isEnabled) {

                                  _controller.animateCamera(CameraUpdate.newCameraPosition(_secondaryPosition));
                                }
                              },
                              onCameraMove: (CameraPosition cameraPosition) {

                                if(_rideController.isSelectingPickupPoint || _rideController.isSelectingDropOffPoint) {

                                  if(_rideController.setAddressController.isCompleted) {

                                    _rideController.setAddressController.reverse();
                                  }

                                  _rideController.centerLatLng = cameraPosition.target;
                                }
                              },
                              onCameraIdle: () async {

                                if((_rideController.isSelectingPickupPoint || _rideController.isSelectingDropOffPoint) && _rideController.centerLatLng != null) {

                                  final coordinates = Coordinates(_rideController.centerLatLng.latitude, _rideController.centerLatLng.longitude);
                                  var addresses = await Geocoder.local.findAddressesFromCoordinates(coordinates);

                                  setState(() {
                                    _rideController.pointOnMap = addresses.first.addressLine;
                                  });

                                  if(!_rideController.setAddressController.isCompleted) {

                                    _rideController.setAddressController.forward();
                                  }
                                }
                              },
                              markers: _markers,
                              polylines: _polyLines,
                              compassEnabled: false,
                              zoomControlsEnabled: false,
                              mapToolbarEnabled: false,
                              mapType: MapType.normal,
                              myLocationEnabled: _rideController.isSelectingDropOffPoint || _rideController.isSearched ||
                                  (_rideController.pickUpPoint != null && _rideController.dropOffPoint != null) ? false : true,
                              myLocationButtonEnabled: _rideController.isSelectingDropOffPoint || _rideController.isSearched ||
                                  (_rideController.pickUpPoint != null && _rideController.dropOffPoint != null) ? false : true,
                              trafficEnabled: false,
                            ),

                            _rideController.locationPicker(context, _pickUpPointText, _destinationPointText),

                            _rideController.pickUpPointWidget(context),

                            _rideController.destinationPointWidget(context),

                            _rideController.listViewWidget(_suggestions, context),

                            _rideController.searchWidget(context),

                            _rideController.setPointFromMap(context),

                            _rideController.confirmSearchedAddress(context),

                            _rideController.searchingForRide(context, _pickUpPointText, _destinationPointText),

                            _rideController.onRideAccepted(context),

                            _rideController.onRideStarted(context),

                            _rideController.rideCompleted(context, requestedRide.value),

                            _rideController.rideCancelledBeforeStart(context, requestedRide.value),

                            _rideController.rideCancelledAfterStart(context, requestedRide.value),

                            Visibility(
                              visible: _rideController.isSelectingPickupPoint || _rideController.isSelectingDropOffPoint,
                              child: Align(
                                alignment: Alignment.center,
                                child: Container(
                                  margin: EdgeInsets.only(bottom: 60),
                                  child: Image.asset("assets/img/location_picker_pin.png", height: 60,),
                                ),
                              ),
                            ),

                            Visibility(
                              visible: _rideController.isSelectingPickupPoint || _rideController.isSelectingDropOffPoint || _rideController.isSearched,
                              child: Align(
                                alignment: Alignment.topLeft,
                                child: Padding(
                                  padding: EdgeInsets.only(top: 18, left: 20),
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () {

                                      if(_rideController.isSelectingPickupPoint || _rideController.isSelectingDropOffPoint) {

                                        _hideCenterMarkerLocationPicker();
                                      }
                                      else if(_rideController.isSearched) {

                                        _hideSearchedAddressConfirmation();
                                      }
                                    },
                                    child: CircleAvatar(
                                      backgroundColor: Colors.white,
                                      radius: 20,
                                      child: Icon(Icons.arrow_back, color: Colors.black54,),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            Visibility(
                              visible: _rideController.showRideSelection,
                              child: DraggableScrollableSheet(
                                initialChildSize: 0.5,
                                minChildSize: 0.42,
                                maxChildSize: .75,
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
                                          child: Padding(
                                            padding: EdgeInsets.only(top: _rideController.rideTypeSelected ? 100 : 120, bottom: 100),
                                            child: NotificationListener<OverscrollIndicatorNotification>(
                                              onNotification: (overscroll) {
                                                overscroll.disallowGlow();
                                                return;
                                              },
                                              child: ListView.separated(
                                                controller: controller,
                                                padding: EdgeInsets.only(left: 20, right: 20, bottom: 20),
                                                itemCount: setting.value.riderTypes.length,
                                                separatorBuilder: (BuildContext context, int index) {

                                                  return SizedBox(height: 7,);
                                                },
                                                itemBuilder: (BuildContext context, int index) {

                                                  double time = _rideController.totalDistance / double.parse(setting.value.riderTypes[index].speed);
                                                  String esTime = "";

                                                  if(time > 1.0) {
                                                    esTime = time.floor().toString() + " " + AppLocalization.of(context).hour + " " + ((time - time.floorToDouble()) * 60.0).ceil().toString();
                                                  }
                                                  else if(time == 1.0) {
                                                    esTime = "1 " + AppLocalization.of(context).hour;
                                                  }
                                                  else {
                                                    esTime = (time * 60.0).ceil().toString() + " " + AppLocalization.of(context).minute;
                                                  }

                                                  return GestureDetector(
                                                    behavior: HitTestBehavior.opaque,
                                                    onTap: () async {

                                                      SharedPreferences prefs = await SharedPreferences.getInstance();
                                                      await prefs.setString('selected_ride_id', setting.value.riderTypes[index].id);

                                                      setState(() {
                                                        _rideController.selectedRideType = setting.value.riderTypes[index];
                                                      });
                                                    },
                                                    child: Material(
                                                      elevation: _rideController.selectedRideType != null && setting.value.riderTypes[index] == _rideController.selectedRideType ? 5 : 0,
                                                      color: _rideController.selectedRideType != null && setting.value.riderTypes[index] == _rideController.selectedRideType ? Colors.white : Colors.transparent,
                                                      borderRadius: BorderRadius.circular(8),
                                                      child: Padding(
                                                        padding: EdgeInsets.all(15),
                                                        child: IntrinsicHeight(
                                                          child: Row(
                                                            mainAxisSize: MainAxisSize.max,
                                                            mainAxisAlignment: MainAxisAlignment.start,
                                                            crossAxisAlignment: CrossAxisAlignment.center,
                                                            children: <Widget>[

                                                              Expanded(
                                                                flex: 2,
                                                                child: Container(
                                                                  decoration: BoxDecoration(
                                                                    image: DecorationImage(
                                                                        fit: BoxFit.fill,
                                                                        image: NetworkImage(setting.value.riderTypes[index].icon)),
                                                                  ),
                                                                ),
                                                              ),

                                                              Expanded(
                                                                flex: 5,
                                                                child: Container(
                                                                  alignment: Alignment.centerLeft,
                                                                  padding: EdgeInsets.only(left: 20, right: 15),
                                                                  child: Text(setting.value.riderTypes[index].name,
                                                                    style: Theme.of(context).textTheme.subtitle1.copyWith(color: _rideController.selectedRideType != null &&
                                                                        setting.value.riderTypes[index] == _rideController.selectedRideType ? Theme.of(context).accentColor : Colors.black),
                                                                  ),
                                                                ),
                                                              ),

                                                              Expanded(
                                                                flex: 2,
                                                                child: Column(
                                                                  mainAxisSize: MainAxisSize.min,
                                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                                  crossAxisAlignment: CrossAxisAlignment.center,
                                                                  children: <Widget>[

                                                                    Text(setting.value.defaultCurrency + " " +
                                                                        (_rideController.totalDistance * double.tryParse(setting.value.riderTypes[index].fee)).ceil().toString(),
                                                                      style: Theme.of(context).textTheme.subtitle1.copyWith(fontWeight: FontWeight.normal),
                                                                    ),

                                                                    SizedBox(height: 10,),

                                                                    Text(esTime,
                                                                      style: Theme.of(context).textTheme.caption.copyWith(fontWeight: FontWeight.normal),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),

                                      Padding(
                                        padding: EdgeInsets.only(top: 40, left: 30, right: 30),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          mainAxisAlignment: MainAxisAlignment.start,
                                          crossAxisAlignment: CrossAxisAlignment.stretch,
                                          children: <Widget>[

                                            Row(
                                              mainAxisSize: MainAxisSize.max,
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              children: <Widget>[

                                                Text(AppLocalization.of(context).select_ride,
                                                  style: Theme.of(context).textTheme.headline2,
                                                ),

                                                Text(_rideController.totalDistance.toStringAsFixed(2) + " " + AppLocalization.of(context).km,
                                                  style: Theme.of(context).textTheme.caption.copyWith(fontSize: 18),
                                                ),
                                              ],
                                            ),

                                            Visibility(
                                              visible: !_rideController.rideTypeSelected,
                                              child: Padding(
                                                padding: EdgeInsets.only(top: 20, bottom: 15),
                                                child: Text("* " + AppLocalization.of(context).select_ride_type,
                                                  style: Theme.of(context).textTheme.bodyText1.copyWith(fontWeight: FontWeight.bold, color: Colors.red[400]),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),

                            Visibility(
                              visible: _rideController.showRideSelection,
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: Padding(
                                  padding: EdgeInsets.only(bottom: 35, left: 25, right: 25),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.max,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: <Widget>[

                                      Expanded(
                                        flex: 1,
                                        child: GestureDetector(
                                          behavior: HitTestBehavior.opaque,
                                          onTap: () {

                                            _hideRideSelectionView();
                                          },
                                          child: Material(
                                            elevation: 10,
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(22),
                                            child: Padding(
                                              padding: EdgeInsets.only(top: 12, bottom: 12, left: 40, right: 40),
                                              child: Text(AppLocalization.of(context).cancel.toUpperCase(),
                                                textAlign: TextAlign.center,
                                                style: Theme.of(context).textTheme.headline6.copyWith(color: Colors.black87),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),

                                      SizedBox(width: 20,),

                                      Expanded(
                                        flex: 1,
                                        child: GestureDetector(
                                          behavior: HitTestBehavior.opaque,
                                          onTap: () {

                                            if(_rideController.selectedRideType != null) {

                                              setState(() {
                                                _rideController.rideTypeSelected = true;
                                              });

                                              _rideRepo.requestForRide(context, _rideController.selectedRideType.id, _rideController.pickUpPoint, _rideController.dropOffPoint,
                                                  _pickUpPointText, _destinationPointText);
                                            }
                                            else {

                                              setState(() {
                                                _rideController.rideTypeSelected = false;
                                              });
                                            }
                                          },
                                          child: Material(
                                            elevation: 10,
                                            color: Theme.of(context).accentColor,
                                            borderRadius: BorderRadius.circular(22),
                                            child: Padding(
                                              padding: EdgeInsets.only(top: 12, bottom: 12, left: 40, right: 40),
                                              child: Text(AppLocalization.of(context).confirm.toUpperCase(),
                                                textAlign: TextAlign.center,
                                                style: Theme.of(context).textTheme.headline6.copyWith(color: Colors.white),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
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
                ],
              );
            },
          ),
        ),
      )
    );
  }


  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {

    if(state == AppLifecycleState.resumed && !_isAlertShown) {
      _requestPermission();
    }
  }


  @override
  void dispose() {

    WidgetsBinding.instance.removeObserver(this);

    _rideController.locationPickerController.dispose();
    _rideController.pickUpController.dispose();
    _rideController.destinationController.dispose();
    _rideController.searchController.dispose();
    _rideController.listViewController.dispose();
    _rideController.setAddressController.dispose();
    _rideController.setSearchedAddressController.dispose();
    RideHomeController.searchingRideController.dispose();
    RideHomeController.rideAcceptedController.dispose();
    RideHomeController.rideStartedController.dispose();
    _rideController.completeController.dispose();
    _rideController.beforeStartCancelController.dispose();
    _rideController.afterStartCancelController.dispose();

    super.dispose();
  }


  void _requestPermission() async {

    if(!_isRequested) {

      _isRequested = true;
      Map<Permission, PermissionStatus> results = await permissions.request();

      _isPermissionGranted(results);
    }
  }


  void _isPermissionGranted(Map<Permission, PermissionStatus> results) {

    if(Platform.isAndroid) {

      if(results[Permission.locationAlways].isGranted) {

        _isGpsActive();
      }
      else if(results[Permission.locationAlways].isDenied) {

        _isRequested = false;
        _requestPermission();
      }
      else if(results[Permission.locationAlways].isPermanentlyDenied) {

        if(!_isAlertShown) {
          _forceUserForPermission();
        }
      }
    }
    else if(Platform.isIOS) {

      if(results[Permission.locationAlways].isGranted) {

        _isGpsActive();
      }
      else {

        if(results[Permission.locationWhenInUse].isGranted) {

          _isGpsActive();
        }
        else if(results[Permission.locationWhenInUse].isDenied) {

          _isRequested = false;
          _requestPermission();
        }
        else if(results[Permission.locationWhenInUse].isPermanentlyDenied) {

          if(!_isAlertShown) {
            _forceUserForPermission();
          }
        }
      }
    }
  }


  Future<void> _isGpsActive() async {

    bool serviceEnabled = await Geolocator().isLocationServiceEnabled();

    if(!serviceEnabled) {
      _activateLocationService();
    }
  }


  void _forceUserForPermission() {

    _isAlertShown = true;
    _isRequested = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {

        return WillPopScope(
          onWillPop: () {
            return Future(() => false);
          },
          child: AlertDialog(
            elevation: 10,
            backgroundColor: Theme.of(context).primaryColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
            title: Padding(
              padding: EdgeInsets.only(top: 15),
              child: Row(
                children: <Widget>[

                  Icon(Icons.error, color: Colors.red, size: 30,),

                  SizedBox(width: 15,),

                  Text(AppLocalization.of(context).notice, style: Theme.of(context).textTheme.headline4.copyWith(color: Colors.red),),
                ],
              ),
            ),
            content: Text(AppLocalization.of(context).permission_alert_msg, textAlign: TextAlign.justify, style: Theme.of(context).textTheme.subtitle1.copyWith(color: Colors.black, fontWeight: FontWeight.normal),),
            contentPadding: EdgeInsets.only(left: 30, top: 20, bottom: 20, right: 30),
            actionsPadding: EdgeInsets.only(right: 20, bottom: 10, top: 5),
            actions: <Widget> [

              FlatButton(
                color: Colors.lightBlueAccent,
                textColor: Colors.white,
                child: Text(AppLocalization.of(context).ok),
                onPressed: () {

                  _isAlertShown = false;
                  Navigator.of(context).pop();
                  openAppSettings();
                },
              ),
            ],
          ),
        );
      },
    );
  }


  void _activateLocationService() {

    _isAlertShown = true;
    _isRequested = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {

        return WillPopScope(
          onWillPop: () {
            return Future(() => false);
          },
          child: AlertDialog(
            elevation: 10,
            backgroundColor: Theme.of(context).primaryColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
            title: Padding(
              padding: EdgeInsets.only(top: 15),
              child: Row(
                children: <Widget>[

                  Icon(Icons.error, color: Colors.red, size: 30),

                  SizedBox(width: 15,),

                  Text(AppLocalization.of(context).notice, style: Theme.of(context).textTheme.headline4.copyWith(color: Colors.red),),
                ],
              ),
            ),
            content: Text(AppLocalization.of(context).gps_alert_msg, textAlign: TextAlign.justify, style: Theme.of(context).textTheme.subtitle1.copyWith(color: Colors.black, fontWeight: FontWeight.normal),),
            contentPadding: EdgeInsets.only(left: 30, top: 20, bottom: 20, right: 30),
            actionsPadding: EdgeInsets.only(right: 20, bottom: 10, top: 5),
            actions: <Widget> [

              FlatButton(
                color: Colors.lightBlueAccent,
                textColor: Colors.white,
                child: Text(AppLocalization.of(context).ok),
                onPressed: () {

                  _isAlertShown = false;
                  Navigator.of(context).pop();
                  loc.Location().requestService();
                },
              ),
            ],
          ),
        );
      },
    );
  }


  Future<void> _getUserLocation() async {

    _isEnabled = await Geolocator().isLocationServiceEnabled();

    if(_isEnabled) {

      Position position = await Geolocator().getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

      if(position == null || position.latitude == null || position.longitude == null) {

        position = await Geolocator().getLastKnownPosition(desiredAccuracy: LocationAccuracy.high);
      }

      if(position != null) {

        hideMarkers();

        _rideController.userLocation = LatLng(position.latitude, position.longitude);

        setUserLocationMarker(context);
      }
    }
  }


  Future<void> _initBitmapIcons() async {

    _rideController.currentLocationBitmap = await getBytesFromAsset('assets/img/my_location_pin.png', 150, 150);
    _rideController.pickUpPointBitmap = await getBytesFromAsset('assets/img/blue_pin.png', 150, 150);
    _rideController.destinationPointBitmap = await getBytesFromAsset('assets/img/orange_pin.png', 150, 150);
    _rideController.searchedPointBitmap = await getBytesFromAsset('assets/img/location_picker_pin.png', 180, 180);
  }


  Future<Uint8List> getBytesFromAsset(String path, int width, int height) async {

    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(), targetHeight: height, targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png)).buffer.asUint8List();
  }


  Future<Uint8List> getUintFromAsset(Uint8List uint8list, int width, int height) async {

    ui.Codec codec = await ui.instantiateImageCodec(uint8list, targetHeight: height, targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png)).buffer.asUint8List();
  }


  Future<bool> _onBackPress() async {

    if(requestedRide != null && requestedRide.value.status != null && (requestedRide.value.status == Constants.requested ||
        requestedRide.value.status == Constants.accepted || requestedRide.value.status == Constants.started)) {

    }
    else if(requestedRide != null && requestedRide.value.status != null && requestedRide.value.status == Constants.completed) {

      await resetPage();
      _getUserLocation();

      _rideController.completeController.reverse();
      _rideController.locationPickerController.forward();
    }
    else if(requestedRide != null && requestedRide.value.status != null && requestedRide.value.status == Constants.canceled) {

      await resetPage();
      _getUserLocation();

      if(_rideController.beforeStartCancelController.isCompleted) {

        _rideController.beforeStartCancelController.reverse();
      }

      if(_rideController.afterStartCancelController.isCompleted) {

        _rideController.afterStartCancelController.reverse();
      }

      _rideController.locationPickerController.forward();
    }
    else {

      if(_rideController.locationPickerController.isCompleted) {

        Navigator.pop(context);
        Navigator.of(context).pushNamed('/Service');
      }
      else if(_rideController.pickUpController.isCompleted || _rideController.destinationController.isCompleted) {

        showMainLocationPickerView();
      }
      else if(_rideController.listViewController.isCompleted) {

        hideSearchedListView();
      }
      else if(_rideController.isSelectingPickupPoint || _rideController.isSelectingDropOffPoint) {

        hideMarkers();
        _hideCenterMarkerLocationPicker();
      }
      else if(_rideController.isSearched) {

        _hideSearchedAddressConfirmation();
      }
      else if(_rideController.showRideSelection) {

        _hideRideSelectionView();
      }
      else if(RideHomeController.searchingRideController.isCompleted) {

        RideHomeController.searchingRideController.reverse();

        setState(() {
          _rideController.showRideSelection = true;
        });
      }
    }

    return Future(() => false);
  }


  Future<void> _createPickUpMarker(LatLng latLng) async {

    Marker pickupMarker = Marker(
      markerId: Constants.PICK_UP_POINT_MARKER,
      position: latLng,
      infoWindow: InfoWindow(title: AppLocalization.of(context).pick_up_point),
      icon: BitmapDescriptor.fromBytes(_rideController.pickUpPointBitmap),
    );

    addMarkers(pickupMarker, true);
  }


  Future<void> _createDropOffMarker(LatLng latLng) async {

    Marker dropOffMarker = Marker(
      markerId: Constants.DROP_OFF_POINT_MARKER,
      position: latLng,
      infoWindow: InfoWindow(title: AppLocalization.of(context).drop_off_point),
      icon: BitmapDescriptor.fromBytes(_rideController.destinationPointBitmap),
    );

    addMarkers(dropOffMarker, true);
  }


  Future<void> _createUserLocationMarker(LatLng latLng) async {

    Marker currentLocation = Marker(
      markerId: Constants.USER_LOCATION_MARKER,
      position: latLng,
      infoWindow: InfoWindow(title: AppLocalization.of(context).current_location),
      icon: BitmapDescriptor.fromBytes(_rideController.currentLocationBitmap),
    );

    addMarkers(currentLocation, true);
  }


  Future<void> _createRiderLocationMarker(Position position) async {

    Marker riderLocation = Marker(
      markerId: Constants.USER_LOCATION_MARKER,
      position: LatLng(position.latitude, position.longitude),
      rotation: position.heading,
      draggable: false,
      flat: true,
      zIndex: 2,
      anchor: Offset(0.5, 0.5),
      icon: BitmapDescriptor.fromBytes(_rideController.riderBitmap),
    );

    addMarkers(riderLocation, false);
  }


  Future<void> _createPolyline(List<LatLng> latLngs) async {

    Polyline polyline = Polyline(
      polylineId: PolylineId(""),
      color: Colors.blue,
      endCap: Cap.roundCap,
      startCap: Cap.roundCap,
      width: 7,
      visible: true,
      points: latLngs,
      patterns: <PatternItem>[],
    );

    _placePolylineOnMap(polyline);
  }


  Future<void> _placePolylineOnMap(Polyline polyline) async {

    try {
      setState(() {
        _polyLines.add(polyline);
      });
    }
    catch(e) {
      _polyLines.add(polyline);
    }
  }


  Future<void> _zoomBetweenTwoPoints(LatLng firstPoint, LatLng secondPoint) async {

    LatLngBounds bounds;

    if(firstPoint.latitude > secondPoint.latitude && firstPoint.longitude > secondPoint.longitude) {

      bounds = LatLngBounds(southwest: secondPoint, northeast: firstPoint);
    }
    else if(firstPoint.longitude > secondPoint.longitude) {

      bounds = LatLngBounds(southwest: LatLng(firstPoint.latitude, secondPoint.longitude),
          northeast: LatLng(secondPoint.latitude, firstPoint.longitude));
    }
    else if(firstPoint.latitude > secondPoint.latitude) {

      bounds = LatLngBounds(southwest: LatLng(secondPoint.latitude, firstPoint.longitude),
          northeast: LatLng(firstPoint.latitude, secondPoint.longitude));
    }
    else {

      bounds = LatLngBounds(southwest: firstPoint, northeast: secondPoint);
    }

    _controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 70));
  }


  Future<void> _showMarkerInfo(MarkerId markerID) async {

    await Future.delayed(Duration(milliseconds: 1500));

    try {
      _controller.showMarkerInfoWindow(markerID);
    }
    catch (e) {
      print(e);
    }
  }


  Future<void> _animateCameraToPosition(LatLng latLng, double zoom) async {

    _controller.animateCamera(CameraUpdate.newLatLngZoom(latLng, zoom));
  }


  @override
  void setDropOffAddress(String address) {

    setState(() {
      _destinationPointText = address;
    });

    if(_rideController.searchController.isCompleted) {

      _rideController.searchController.reverse();
    }

    if(_rideController.destinationController.isCompleted) {

      _rideController.destinationController.reverse();
    }

    _rideController.locationPickerController.forward();

    _contact.setAppBarTitle(AppLocalization.of(context).ride);
  }


  @override
  void setPickUpAddress(String address) {

    setState(() {
      _pickUpPointText = address;
    });

    if(_rideController.searchController.isCompleted) {

      _rideController.searchController.reverse();
    }

    if(_rideController.pickUpController.isCompleted) {

      _rideController.pickUpController.reverse();
    }

    _rideController.locationPickerController.forward();

    _contact.setAppBarTitle(AppLocalization.of(context).ride);
  }


  @override
  void showAddressSuggestions(List<Places> addresses) {

    _suggestions = [];

    setState(() {
      _suggestions = addresses;
    });
  }


  @override
  void setAppBarTitle(String title) {

    setState(() {
      _appBarTitle = title;
    });
  }


  void _hideCenterMarkerLocationPicker() {

    if(_rideController.setAddressController.isCompleted) {

      _rideController.setAddressController.reverse();
    }

    if(_rideController.userLocation != null) {

      setUserLocationMarker(context);
    }

    if(_rideController.isSelectingPickupPoint) {

      setState(() {
        _rideController.isSelectingPickupPoint = false;
      });

      _rideController.pickUpController.forward();
      _rideController.searchController.forward();
    }
    else if(_rideController.isSelectingDropOffPoint) {

      setState(() {
        _rideController.isSelectingDropOffPoint = false;
      });

      _rideController.destinationController.forward();
      _rideController.searchController.forward();
    }
  }


  void _hideSearchedAddressConfirmation() {

    setState(() {
      _rideController.isSearched = false;
    });

    _rideController.setSearchedAddressController.reverse();

    _rideController.searchController.forward();
    _rideController.listViewController.forward();
  }


  @override
  void hideMarkers() {

    try {
      setState(() {
        _markers.clear();
      });
    }
    catch(e) {
      _markers.clear();
    }
  }


  @override
  Future<void> addMarkers(Marker marker, bool showInfo) async {

    try {
      setState(() {
        _markers.add(marker);
      });
    }
    catch(e) {
      _markers.add(marker);
    }

    if(showInfo) {
      _showMarkerInfo(marker.markerId);
    }
  }


  @override
  void showPreviousMarkers() {

    if(_rideController.pickUpPoint != null && _rideController.dropOffPoint == null) {

      setPickupPointMarker(context);
    }
    else if(_rideController.pickUpPoint == null && _rideController.dropOffPoint != null) {

      setDestinationPointMarker(context);
    }
    else if(_rideController.pickUpPoint == null && _rideController.dropOffPoint == null && _rideController.userLocation != null) {

      setUserLocationMarker(context);
    }
  }


  @override
  Future<void> setDestinationPointMarker(BuildContext context) async {

    if(_rideController.pickUpPoint != null && _rideController.dropOffPoint != null) {

      showRoutePath();
    }
    else {

      hideMarkers();

      await _createDropOffMarker(_rideController.dropOffPoint);
      _animateCameraToPosition(_rideController.dropOffPoint, 16.5);
    }
  }


  @override
  Future<void> setPickupPointMarker(BuildContext context) async {

    if(_rideController.pickUpPoint != null && _rideController.dropOffPoint != null) {

      showRoutePath();
    }
    else {

      hideMarkers();

      await _createPickUpMarker(_rideController.pickUpPoint);
      _animateCameraToPosition(_rideController.pickUpPoint, 16.5);
    }
  }


  @override
  Future<void> setUserLocationMarker(BuildContext context) async {

    hideMarkers();

    await _createUserLocationMarker(_rideController.userLocation);
    _animateCameraToPosition(_rideController.userLocation, 16.5);
  }


  @override
  Future<void> showSearchedAddressMarker(LatLng latLng, String placeName) async {

    hideMarkers();

    Marker marker = Marker(
      markerId: Constants.SEARCHED_ADDRESS_MARKER,
      position: latLng,
      infoWindow: InfoWindow(title: placeName),
      icon: BitmapDescriptor.fromBytes(_rideController.searchedPointBitmap),
    );

    _animateCameraToPosition(latLng, 16.5);
    addMarkers(marker, true);
  }


  @override
  void clearSuggestions() {

    setState(() {
      _suggestions = [];
    });
  }


  @override
  void hideSearchedListView() {

    hideMarkers();

    _rideController.listViewController.reverse();

    setState(() {
      _rideController.addressSearchController.text = "";
    });

    clearSuggestions();

    if(_rideController.isSearchingPickupPoint) {

      _rideController.isSearchingPickupPoint = false;
      _rideController.pickUpController.forward();
    }
    else if(_rideController.isSearchingDropOffPoint) {

      _rideController.isSearchingDropOffPoint = false;
      _rideController.destinationController.forward();
    }
  }


  @override
  void showMainLocationPickerView() {

    if(_rideController.pickUpPoint != null && _rideController.dropOffPoint != null) {

      showRoutePath();
    }
    else {

      showPreviousMarkers();
    }

    if(_rideController.pickUpController.isCompleted) {

      _rideController.pickUpController.reverse();
    }
    else if(_rideController.destinationController.isCompleted) {

      _rideController.destinationController.reverse();
    }

    _rideController.searchController.reverse();
    _rideController.locationPickerController.forward();

    _contact.setAppBarTitle(AppLocalization.of(context).ride);
  }


  @override
  void hidePolyLines() {

    try {
      setState(() {
        _polyLines.clear();
      });
    }
    catch(e) {
      _polyLines.clear();
    }
  }


  @override
  Future<void> showRoutePath() async {

    hideMarkers();

    _createPickUpMarker(_rideController.pickUpPoint);
    _createDropOffMarker(_rideController.dropOffPoint);

    hidePolyLines();

    _polyLineLatLongs = await _rideController.getPolyLine(_rideController.pickUpPoint, _rideController.dropOffPoint);

    _createPolyline(_polyLineLatLongs);
    _zoomBetweenTwoPoints(_rideController.pickUpPoint, _rideController.dropOffPoint);
  }


  @override
  Future<void> chooseRide() async {

    double distance = 0.0;

    for(int i=0; i<_polyLineLatLongs.length - 1; i++) {

      distance += await _rideController.getDistance(_polyLineLatLongs[i], _polyLineLatLongs[i + 1]);
    }

    setState(() {
      _rideController.totalDistance = distance;
      _rideController.showRideSelection = true;
    });
  }


  void _hideRideSelectionView() {

    setState(() {
      _rideController.showRideSelection = false;
      _rideController.selectedRideType = null;
    });

    _rideController.locationPickerController.forward();
  }


  @override
  void onRequestSent() {

    Screen.keepOn(true);

    _dbHelper.clearRoutePath();

    setState(() {
      _myRide = requestedRide.value;
      _rideController.showRideSelection = false;
    });

    RideHomeController.searchingRideController.forward();
  }


  @override
  void onRequestFailed(BuildContext context, String message) {

    Scaffold.of(context).showSnackBar(SnackBar(content: Text(message)));
  }


  void _setNewPickupPointMarker() {

    hideMarkers();
    hidePolyLines();

    _createPickUpMarker(requestedRide.value.pickupPoint);
    _animateCameraToPosition(requestedRide.value.pickupPoint, 15);
  }


  void _setDropOffPointMarker() {

    hideMarkers();
    hidePolyLines();

    _createDropOffMarker(requestedRide.value.dropOffPoint);
  }


  Future<void> _listenForRiderLocation() async {

    Uint8List bytes = (await NetworkAssetBundle(Uri.parse(_rideController.selectedRideType.markerIcon)).load(_rideController.selectedRideType.markerIcon)).buffer.asUint8List();
    _rideController.riderBitmap = await getUintFromAsset(bytes, 110, 110);

    Timer.periodic(Duration(milliseconds: 2000), (timer) async {

      _timer = timer;

      Position position = await _rideRepo.getRiderLocation(context, requestedRide.value.riderID);

      if(requestedRide.value.status != null && requestedRide.value.status == Constants.accepted) {

        _createRiderLocationMarker(position);
      }
      else if(requestedRide.value.status != null && requestedRide.value.status == Constants.started) {

        if(_timer != null && _timer.isActive && !_rideController.isCanceled) {

          _dbHelper.storePath(position);
          _showRouteToDropOff(position);
        }
      }
      else if(requestedRide.value.status != null && (requestedRide.value.status == Constants.completed || requestedRide.value.status == Constants.canceled)) {

        if(_timer != null && _timer.isActive) {
          timer.cancel();
        }
      }
    });
  }


  Future<void> _showRouteToDropOff(Position position) async {

    if(!_rideController.isCanceled) {

      try {

        List<LatLng> latLngs = await _rideController.getPolyLine(LatLng(position.latitude, position.longitude), requestedRide.value.dropOffPoint);

        _createPolyline(latLngs);
        _createRiderLocationMarker(position);

        if(!_rideController.isShown) {

          _rideController.isShown = true;
          _zoomBetweenTwoPoints(LatLng(position.latitude, position.longitude), requestedRide.value.dropOffPoint);
        }
      }
      catch (e) {
        print(e);
      }
    }
  }


  Future<void> _onRideComplete() async {

    Screen.keepOn(false);

    RideHomeController.rideStartedController.reverse();

    var addresses = await Geocoder.local.findAddressesFromCoordinates(Coordinates(requestedRide.value.pickupPoint.latitude, requestedRide.value.pickupPoint.longitude));
    requestedRide.value.pickupAddress = addresses.first.addressLine;

    addresses = await Geocoder.local.findAddressesFromCoordinates(Coordinates(requestedRide.value.dropOffPoint.latitude, requestedRide.value.dropOffPoint.longitude));
    requestedRide.value.dropOffAddress = addresses.first.addressLine;

    hideMarkers();
    hidePolyLines();

    _createPickUpMarker(requestedRide.value.pickupPoint);
    _createDropOffMarker(requestedRide.value.dropOffPoint);

    List<LatLng> paths  = await _dbHelper.getTotalRoutePath();

    paths.insert(0, requestedRide.value.pickupPoint);
    paths.add(requestedRide.value.dropOffPoint);

    _createPolyline(paths);

    _zoomBetweenTwoPoints(requestedRide.value.pickupPoint, requestedRide.value.dropOffPoint);

    _rideController.completeController.forward();
  }


  @override
  Future<void> onRideCancelled(BuildContext context, Ride ride, {List<LatLng> paths}) async {

    Screen.keepOn(false);

    if(_timer != null && _timer.isActive) {

      _timer.cancel();
    }

    if(_myRide.status == Constants.requested) {

      RideHomeController.searchingRideController.reverse();

      await resetPage();

      _rideController.locationPickerController.forward();

      Scaffold.of(context).showSnackBar(SnackBar(content: Text(AppLocalization.of(context).ride_canceled)));
    }
    else if(_myRide.status == Constants.accepted) {

      RideHomeController.rideAcceptedController.reverse();

      if(ride.cancelledBy == currentUser.value.id) {

        await resetPage();

        _rideController.locationPickerController.forward();

        Scaffold.of(context).showSnackBar(SnackBar(content: Text(AppLocalization.of(context).ride_canceled)));
      }
      else {

        _rideController.beforeStartCancelController.forward();
      }
    }
    else if(_myRide.status == Constants.started) {

      if(ride.cancelledBy == currentUser.value.id) {

        if(!_rideController.isCanceled) {

          requestedRide.value = ride;
          requestedRide.notifyListeners();

          _showRouteTillHere(ride);
        }
      }
      else {

        _showRouteTillHere(ride);
      }
    }
  }


  @override
  Future<void> resetPage() async {

    requestedRide.value = Ride();
    requestedRide.notifyListeners();

    hideMarkers();
    hidePolyLines();

    setState(() {

      _myRide = null;

      _appBarTitle = AppLocalization.of(context).ride;
      _pickUpPointText = AppLocalization.of(context).choose_pickup_point;
      _destinationPointText = AppLocalization.of(context).choose_destination_point;

      _rideController.userLocation = null;
      _rideController.centerLatLng = null;
      _rideController.searchedLatLng = null;

      _rideController.pickUpPoint = null;
      _rideController.dropOffPoint = null;
      _rideController.selectedRideType = null;

      _rideController.isConstructorCalled = false;
      _rideController.isSelectingPickupPoint = false;
      _rideController.isSelectingDropOffPoint = false;
      _rideController.isSearchingPickupPoint = false;
      _rideController.isSearchingDropOffPoint = false;
      _rideController.isSearched = false;
      _rideController.showRideSelection = false;
      _rideController.rideTypeSelected = true;
      _rideController.isShown = false;
      _rideController.isAccepted = false;
      _rideController.isStarted = false;
      _rideController.isCompleted = false;
      _rideController.isCanceled = false;

      _rideController.pointOnMap = "";
      _rideController.searchedAddress = "";

      _rideController.totalDistance = 0.0;
    });
  }


  @override
  Future<void> onCancelConfirmed(BuildContext context, String message) async {

    Position position = await Geolocator().getCurrentPosition();

    if(position != null) {

      List<LatLng> paths  = await _dbHelper.getTotalRoutePath();

      paths.insert(0, requestedRide.value.pickupPoint);
      paths.add(LatLng(position.latitude, position.longitude));

      double distance = await _getDistance(paths);
      double fare = 0;
      double adminCommission = 0;
      String cancelFee = "";

      for(int i=0; i<setting.value.riderTypes.length; i++) {

        if(setting.value.riderTypes[i].id == requestedRide.value.rideTypeID) {

          fare = distance * double.parse(setting.value.riderTypes[i].fee);
          adminCommission = (double.parse(setting.value.riderTypes[i].adminCommission) * fare) / 100;
          cancelFee = setting.value.riderTypes[i].cancelFee;
          break;
        }
      }

      Ride ride = Ride(id: requestedRide.value.id, status: Constants.canceled, dropOffPoint: LatLng(position.latitude, position.longitude), cancellationFee: cancelFee,
      distance: distance.toStringAsFixed(2), rideFee: fare.ceil().toString(), adminCommission: adminCommission.toStringAsFixed(3), cancellationMessage: message);
      _rideRepo.updateRideInfo(context, ride, paths: paths);
    }
  }


  Future<double> _getDistance(List<LatLng> latLngs) async {

    double distance = 0;
    var p = 0.017453292519943295;
    var c = cos;

    for(int i=0; i<latLngs.length - 1; i++) {

      var a = 0.5 - c((latLngs[i+1].latitude - latLngs[i].latitude) * p) / 2 + c(latLngs[i].latitude * p) * c(latLngs[i+1].latitude * p) * (1 - c((latLngs[i+1].longitude - latLngs[i].longitude) * p)) / 2;
      distance += 12742 * asin(sqrt(a));
    }

    return distance;
  }


  Future<void> _showRouteTillHere(Ride ride) async {

    RideHomeController.rideStartedController.reverse();

    Timer(Duration(milliseconds: 1500), () async {

      try {

        if(ride.pickupPoint != null) {

          var addresses = await Geocoder.local.findAddressesFromCoordinates(Coordinates(ride.pickupPoint.latitude, ride.pickupPoint.longitude));
          ride.pickupAddress = addresses.first.addressLine;
        }

        if(ride.dropOffPoint != null) {

          var addresses = await Geocoder.local.findAddressesFromCoordinates(Coordinates(ride.dropOffPoint.latitude, ride.dropOffPoint.longitude));
          ride.dropOffAddress = addresses.first.addressLine;
        }

        hideMarkers();
        hidePolyLines();

        _createPickUpMarker(ride.pickupPoint);

        List<LatLng> paths = await _dbHelper.getTotalRoutePath();

        paths.insert(0, ride.pickupPoint);
        paths.add(ride.dropOffPoint);

        _createPolyline(paths);

        _zoomBetweenTwoPoints(ride.pickupPoint, ride.dropOffPoint);

        _rideController.afterStartCancelController.forward();
      }
      catch (e) {}
    });
  }


  @override
  Future<void> onActiveRideFound(BuildContext context, List<Ride> rides) async {

    if(rides.length > 0) {

      Screen.keepOn(true);

      if(_rideController.locationPickerController.isCompleted) {

        _rideController.locationPickerController.reverse();
      }

      hideMarkers();
      hidePolyLines();

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String rideId = await prefs.getString("selected_ride_id");

      Ride ride = rides.first;

      if(ride.pickupPoint != null) {

        var addresses = await Geocoder.local.findAddressesFromCoordinates(Coordinates(ride.pickupPoint.latitude, ride.pickupPoint.longitude));
        ride.pickupAddress = addresses.first.addressLine;
      }

      if(ride.dropOffPoint != null) {

        var addresses = await Geocoder.local.findAddressesFromCoordinates(Coordinates(ride.dropOffPoint.latitude, ride.dropOffPoint.longitude));
        ride.dropOffAddress = addresses.first.addressLine;
      }

      setState(() {

        for(int i=0; i<setting.value.riderTypes.length; i++) {

          if(setting.value.riderTypes[i].id == rideId) {

            _rideController.selectedRideType = setting.value.riderTypes[i];
          }
        }

        _rideController.pickUpPoint = ride.pickupPoint;
        _rideController.dropOffPoint = ride.dropOffPoint;
      });

      if(ride.status == Constants.requested) {

        _dbHelper.clearRoutePath();

        requestedRide.value = ride;
        requestedRide.notifyListeners();

        _createPickUpMarker(ride.pickupPoint);
        _createDropOffMarker(ride.dropOffPoint);

        _polyLineLatLongs = await _rideController.getPolyLine(ride.pickupPoint, ride.dropOffPoint);

        _createPolyline(_polyLineLatLongs);
        _zoomBetweenTwoPoints(ride.pickupPoint, ride.dropOffPoint);

        setState(() {

          _pickUpPointText = ride.pickupAddress;
          _destinationPointText = ride.dropOffAddress;

          _myRide = requestedRide.value;
          _rideController.showRideSelection = false;

          _currentIndex = 2;
        });

        RideHomeController.searchingRideController.forward();
      }
      else if(ride.status == Constants.accepted) {

        requestedRide.value = ride;
        requestedRide.notifyListeners();

        setState(() {
          _currentIndex = 2;
        });

        RideHomeController.rideAcceptedController.forward();
      }
      else if(ride.status == Constants.started) {

        requestedRide.value = ride;
        requestedRide.notifyListeners();

        setState(() {
          _currentIndex = 2;
        });

        RideHomeController.rideStartedController.forward();
      }
    }
    else {

      showRideHomePage();
    }
  }


  @override
  void onConnectFail(BuildContext context, String message) {

    setState(() {
      _currentIndex = 1;
    });
  }


  @override
  void showRideHomePage() {

    _getUserLocation();

    setState(() {
      _currentIndex = 2;
    });
  }
}