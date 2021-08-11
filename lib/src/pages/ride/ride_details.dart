import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../controllers/ride/ride_details_controller.dart';
import '../../helpers/constants.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../generated/l10n.dart';
import '../../models/ride.dart';
import 'dart:ui' as ui;

class RideDetails extends StatefulWidget {

  final Ride _ride;

  RideDetails(this._ride);

  @override
  _RideDetailsState createState() => _RideDetailsState();
}

class _RideDetailsState extends State<RideDetails> with TickerProviderStateMixin {

  GoogleMapController _controller;
  RideDetailsController _detailsController;

  Set<Marker> _markers = Set();
  Set<Polyline> _polyLines = Set();

  CameraPosition _initialPosition = CameraPosition(
    bearing: 0.0,
    tilt: 0.0,
    target: LatLng(23.759398, 90.378904),
    zoom: 6.5,
  );

  @override
  void initState() {

    _detailsController = RideDetailsController(this, widget._ride);
    super.initState();
  }


  @override
  void didChangeDependencies() {

    _initBitmapIcons();
    super.didChangeDependencies();
  }


  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        backgroundColor: Colors.white,
        elevation: 5,
        centerTitle: true,
        title: Text(AppLocalization.of(context).details,
          style: Theme.of(context).textTheme.headline6.merge(TextStyle(letterSpacing: 1.3)),
        ),
      ),
      backgroundColor: Theme.of(context).primaryColor,
      body: SafeArea(
        child: Builder(
          builder: (BuildContext context) {

            return Stack(
              children: <Widget>[

                GoogleMap(
                  initialCameraPosition: _initialPosition,
                  onTap: (LatLng latLng) {},
                  onLongPress: (LatLng latLng) {},
                  onMapCreated: (GoogleMapController controller) {

                    _controller = controller;

                    _createPickUpMarker(widget._ride.pickupPoint);
                    _createDropOffMarker(widget._ride.dropOffPoint);
                    _zoomBetweenTwoPoints(widget._ride.pickupPoint, widget._ride.dropOffPoint);
                  },
                  onCameraMove: (CameraPosition cameraPosition) {},
                  onCameraIdle: () {},
                  markers: _markers,
                  polylines: _polyLines,
                  compassEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                  mapType: MapType.normal,
                  myLocationEnabled: false,
                  myLocationButtonEnabled: false,
                  trafficEnabled: false,
                ),

                _detailsController.rideCompleted(context, widget._ride),

                _detailsController.rideCancelledBeforeStart(context, widget._ride),

                _detailsController.rideCancelledAfterStart(context, widget._ride),
              ],
            );
          },
        ),
      ),
    );
  }


  @override
  void dispose() {

    _detailsController.completeController.dispose();
    _detailsController.beforeStartCancelController.dispose();
    _detailsController.afterStartCancelController.dispose();

    super.dispose();
  }


  Future<void> _initBitmapIcons() async {

    _detailsController.pickUpPointBitmap = await getBytesFromAsset('assets/img/blue_pin.png', 150, 150);
    _detailsController.destinationPointBitmap = await getBytesFromAsset('assets/img/orange_pin.png', 150, 150);
  }


  Future<Uint8List> getBytesFromAsset(String path, int width, int height) async {

    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(), targetHeight: height, targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png)).buffer.asUint8List();
  }


  Future<void> _createPickUpMarker(LatLng latLng) async {

    Marker pickupMarker = Marker(
      markerId: Constants.PICK_UP_POINT_MARKER,
      position: latLng,
      infoWindow: InfoWindow(title: AppLocalization.of(context).pick_up_point),
      icon: BitmapDescriptor.fromBytes(_detailsController.pickUpPointBitmap),
    );

    _addMarkers(pickupMarker, true);
  }


  Future<void> _createDropOffMarker(LatLng latLng) async {

    Marker dropOffMarker = Marker(
      markerId: Constants.DROP_OFF_POINT_MARKER,
      position: latLng,
      infoWindow: InfoWindow(title: AppLocalization.of(context).drop_off_point),
      icon: BitmapDescriptor.fromBytes(_detailsController.destinationPointBitmap),
    );

    _addMarkers(dropOffMarker, true);
  }


  Future<void> _addMarkers(Marker marker, bool showInfo) async {

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


  Future<void> _showMarkerInfo(MarkerId markerID) async {

    await Future.delayed(Duration(milliseconds: 1500));

    try {
      _controller.showMarkerInfoWindow(markerID);
    }
    catch (e) {
      print(e);
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
}
