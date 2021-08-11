import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geocoder/geocoder.dart';
import 'package:geolocator/geolocator.dart';
import '../../generated/l10n.dart';
import '../controllers/user_controller.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mvc_pattern/mvc_pattern.dart';
import 'package:permission_handler/permission_handler.dart';

import 'dart:io' show Platform;
import 'package:location/location.dart' as loc;
import '../models/address.dart' as mAddress;

class PickAddress extends StatefulWidget {

  @override
  _PickAddressState createState() => _PickAddressState();
}

class _PickAddressState extends StateMVC<PickAddress> with TickerProviderStateMixin {

  UserController _con;

  _PickAddressState() : super(UserController()) {
    _con = controller;
  }

  FocusNode _focusNode = FocusNode();

  TextEditingController _searchController = TextEditingController();
  TextEditingController _addressController = TextEditingController();

  List<Permission> permissions = [Permission.location, Permission.locationAlways, Permission.locationWhenInUse];
  Completer<GoogleMapController> _controller = Completer();
  Set<Marker> _markers = Set();

  LocationOptions locationOptions;
  StreamSubscription<Position> positionStream;
  static LatLng _currentLocation = LatLng(23.781849, 90.379034);

  CameraPosition _initialPosition = CameraPosition(
    bearing: 0.0,
    tilt: 0.0,
    target: _currentLocation,
    zoom: 12.5,
  );

  String _mLocation = "";
  LatLng _mLatLng;

  AnimationController _animationController;
  Animation<Offset> _offset;

  @override
  void initState() {

    _animationController = AnimationController(vsync: this, duration: Duration(milliseconds: 200));
    _offset = Tween<Offset>(begin: Offset(0.0, 1.0), end: Offset.zero).animate(_animationController);

    _requestPermission();

    _getLastLocation();

    locationOptions = LocationOptions(accuracy: LocationAccuracy.high, distanceFilter: 10);

    positionStream = Geolocator().getPositionStream(locationOptions).listen((Position position) {
      if(position != null) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
        });
      }
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    return WillPopScope(
      onWillPop: _onBackPress,
      child: Scaffold(
        key: _con.scaffoldKey,
        appBar: AppBar(
          leading: Icon(Icons.arrow_back, color: Colors.blueGrey),
          title: Text(AppLocalization.of(context).your_address, style: TextStyle(color: Theme.of(context).accentColor),),
          centerTitle: true,
          actions: <Widget>[

            IconButton(
              icon: Icon(Icons.my_location),
              iconSize: 25,
              color: Colors.blue,
              onPressed: _showCurrentLocation,
            ),
          ],
        ),
        body: SafeArea(
          child: Container(
            height: double.infinity,
            width: double.infinity,
            child: Stack(
              children: <Widget>[

                GoogleMap(
                  initialCameraPosition: _initialPosition,
                  onTap: (LatLng latLng) {
                    _pinLocation(latLng);
                  },
                  onLongPress: (LatLng latLng) {},
                  onMapCreated: (GoogleMapController controller) {

                    if(!_controller.isCompleted) {
                      _controller.complete(controller);
                    }
                  },
                  onCameraMove: (CameraPosition cameraPosition) {},
                  markers: _markers,
                  compassEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                  mapType: MapType.normal,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  trafficEnabled: false,
                ),

                Padding(
                  padding: EdgeInsets.only(top: 20, left: 30, right: 30),
                  child: TextField(
                    controller: _searchController,
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.search,
                    style: Theme.of(context).textTheme.bodyText2,
                    onSubmitted: _searchAddress,
                    decoration: InputDecoration(
                      suffixIcon: IconButton(icon: Icon(Icons.search), color: Colors.blue, onPressed: () {
                        _searchAddress(_searchController.text);
                      },),
                      hintText: AppLocalization.of(context).search,
                      hintStyle: Theme.of(context).textTheme.bodyText2.copyWith(color: Colors.black38),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(width: 0, style: BorderStyle.none),
                      ),
                      filled: true,
                      contentPadding: EdgeInsets.all(10),
                      fillColor: Colors.white,
                    ),
                  ),
                ),

                _setAddressView(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {

    _animationController.dispose();
    super.dispose();
  }

  void _requestPermission() async {

    Map<Permission, PermissionStatus> results = await permissions.request();
  }

  Future<void> _pinLocation(LatLng latLng) async {

    _mLatLng = latLng;

    setState(() {
      _markers.clear();
    });

    try {

      final coordinates = Coordinates(latLng.latitude, latLng.longitude);
      var addresses = await Geocoder.local.findAddressesFromCoordinates(coordinates);

      print(addresses.first.addressLine);

      setState(() {
        _mLocation = addresses.first.addressLine;
        _addressController.text = _mLocation;
      });

      Marker marker = Marker(
        markerId: MarkerId(""),
        position: latLng,
        icon: BitmapDescriptor.defaultMarker,
      );

      setState(() {
        _markers.add(marker);
      });

      _animationController.forward();
    }
    catch (error) {
      if(_animationController.isCompleted) {
        _animationController.reverse();
      }
      print(error.toString());
    }
  }

  SlideTransition _setAddressView() {

    return SlideTransition(
      position: _offset,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Material(
          elevation: 10,
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.only(top: 40, left: 30, right: 30, bottom: 25),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[

                TextField(
                  focusNode: _focusNode,
                  controller: _addressController,
                  keyboardType: TextInputType.multiline,
                  maxLines: null,
                  maxLength: 100,
                  textInputAction: TextInputAction.done,
                  style: Theme.of(context).textTheme.headline6.copyWith(color: Colors.black54),
                  decoration: InputDecoration(
                    hintText: AppLocalization.of(context).full_address,
                    hintStyle: Theme.of(context).textTheme.headline6.copyWith(color: Colors.black26),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5),
                      borderSide: BorderSide(width: 2, style: BorderStyle.solid, color: Colors.grey[200]),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5),
                      borderSide: BorderSide(width: 1, style: BorderStyle.solid, color: Colors.black54),
                    ),
                    filled: true,
                    contentPadding: EdgeInsets.all(10),
                    fillColor: Colors.white,
                  ),
                ),

                SizedBox(height: 20,),

                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    mAddress.Address address = mAddress.Address(latitude: _mLatLng.latitude, longitude: _mLatLng.longitude, description: "",
                        address: _addressController.text, isDefault: true);
                    _con.setAddress(address);
                  },
                  child: Container(
                    padding: EdgeInsets.all(10),
                    alignment: Alignment.center,
                    color: Theme.of(context).accentColor,
                    child: Text(AppLocalization.of(context).setAsYourAddress, style: Theme.of(context).textTheme.subtitle1.copyWith(color: Colors.white),),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _searchAddress(String address) async {
    if (address != null && address.isNotEmpty) {
      final GoogleMapController controller = await _controller.future;

      Geolocator().placemarkFromAddress(address).then((result) {
        var lat = result.first.position.latitude;
        var lng = result.first.position.longitude;

        controller.animateCamera(
            CameraUpdate.newLatLngZoom(LatLng(lat, lng), 14.5));
      });
    }
  }

  Future<void> _getLastLocation() async {

    Position position = await Geolocator().getLastKnownPosition();

    if(position != null) {
      if(mounted) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
        });
      }
    }

    if(mounted) {
      setState(() {
        _initialPosition = CameraPosition(
          bearing: 0.0,
          tilt: 0.0,
          target: _currentLocation,
          zoom: 12.5,
        );
      });
    }
  }

  Future<void> _showCurrentLocation() async {
    if (_currentLocation != null) {
      var permissionGranted = false;
      var permanentlyDenied = false;

      if (Platform.isAndroid) {
        permissionGranted = await Permission.location.isGranted;
        permanentlyDenied = await Permission.location.isPermanentlyDenied;
      }
      else if (Platform.isIOS) {
        permissionGranted = await Permission.locationAlways.isGranted;
        permanentlyDenied =
        await Permission.locationAlways.isPermanentlyDenied;

        if (permissionGranted) {
          permissionGranted = await Permission.locationWhenInUse.isGranted;
          permanentlyDenied =
          await Permission.locationWhenInUse.isPermanentlyDenied;
        }
      }

      if (permissionGranted != null && permissionGranted) {
        bool serviceEnabled = await Geolocator().isLocationServiceEnabled();

        if (serviceEnabled) {
          final GoogleMapController controller = await _controller.future;
          controller.animateCamera(
              CameraUpdate.newLatLngZoom(_currentLocation, 16.5));
        }
        else {
          loc.Location().requestService();
        }
      }
      else if (permanentlyDenied != null && permanentlyDenied) {
        openAppSettings();
      }
      else {
        _requestPermission();
      }
    }
  }

  Future<bool> _onBackPress() {

    if(_focusNode.hasFocus) {

      _focusNode.unfocus();
    }
    else {

      if(_animationController.isCompleted) {

        _mLocation = "";
        _mLatLng = null;
        _addressController.text = "";

        setState(() {
          _markers.clear();
        });

        _animationController.reverse();
      }
      else {

        Navigator.pop(context);
        Navigator.of(context).pushNamed('/Profile');
      }
    }

    return Future(() => false);
  }
}